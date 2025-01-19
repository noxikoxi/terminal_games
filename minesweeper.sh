#!/bin/bash
rows=0
cols=0
bombs=0

if [ $# -gt 0 ] && [ "$1" = "-h" ]; then
    echo "Minesweeper"
    echo -e " Run: ./minesweeper.sh"
    echo -e " First, the game will ask you to enter the number of rows, columns, and bombs.\r\n  These define the map characteristics and the number of hidden bombs.\r\n"
    echo -e " You can navigate the map using the keys w\s\a\d;\r\n  The green element indicates the currently selected cell.\r\n"
    echo -e " At the start, all cells are hidden, represented by \"#\";\r\n  to uncover a selected cell, press 'o'.\r\n"
    echo -e " To place a flag on a cell, press 'p'. Cells with flags cannot be uncovered;\r\n  you can remove a flag by selecting it and pressing 'p' again.\r\n"
    echo -e " To exit the game, press 'q'.\r\n"
    echo -e " Each cell contains a number that represents the count of bombs in its vicinity;\r\n  (neighboring cells have coordinates that differ by at most one, i.e., left/right/up/down and diagonally).\r\n"
    echo " The player's goal is to uncover every cell that is not a bomb. Uncovering a bomb results in a loss."
    echo " Good luck!"
    exit 0
fi

while [ $rows -lt 5 ]; do
    read -p "Enter the number of rows: " rows
    if [[ ! "$rows" =~ ^-?[0-9]+$ ]]; then
        echo -E "Please enter a positive integer."
        rows=0
    fi
    if (( $rows < 5 || $rows > 30 )); then
        echo -E "The entered number must be within the range [5, 30]."
        rows=0
    fi
done

while [ $cols -lt 5 ]; do
    read -p "Enter the number of columns: " cols
    if [[ ! "$cols" =~ ^-?[0-9]+$ ]]; then
        echo -E "Please enter a positive integer."
        cols=0
    fi
    if (( $cols < 5 || $cols > 30 )); then
        echo -E "The entered number must be within the range [5, 30]."
        cols=0
    fi
done

while [ $bombs -lt 1 ]; do
    read -p "Enter the number of bombs: " bombs
    if [[ ! "$bombs" =~ ^-?[0-9]+$ ]]; then
        echo -E "Please enter a positive integer."
        bombs=0
    fi
    if (( $bombs < 1 || $bombs >= $rows*$cols )); then
        echo -E "The entered number must be within the range [1, total_cells)."
        bombs=0
    fi
done

declare -a board # 9 -> it's a mine, board stores information about bombs 
declare -a visible # Visible cells
declare -a flagged # Flagged cells
totalCells=$((rows*cols))
selectedCell=(0 0)
gameOver="0"
checkedCells="0"

print_border_row(){
    local width=$1
    local startElem=$2
    local insideElem=$3
    local endElem=$4
    printf $startElem
    for ((i=0; i<$width-2; i++)); do
        printf $insideElem
    done
    printf "$endElem\r\n"
}

get_index(){
    local row=$1
    local col=$2
    echo $((row * cols + col))
}

initialize_board() {
    for ((i=0; i<$totalCells; i++)); do
        board[$i]=0
        visible[$i]=0
        flagged[$i]=0
    done
}

place_mines(){
    local bombPlacements=()
    local row
    local col
    local neighbours
    local new_row
    local new_col
    for (( i=0; i<bombs; i++)); do
        bombPlacements+=("1")
    done
    for (( i=0; i<totalCells-bombs; i++)); do
        bombPlacements+=("0")
    done

    # shuffling the table with shuf
    bombPlacements=($(echo "${bombPlacements[@]}" | tr ' ' '\n' | shuf | tr '\n' ' '))

    for (( i=0; i<totalCells; i++ )); do
        # Bomb is on this position
        if [ ${bombPlacements[$i]} -eq 1 ]; then
            board[$i]="9"
            col=$((i%cols))
            row=$((i/cols))
            neighbours=()
            for (( delta_row=-1; delta_row <= 1; delta_row++ ));do
                for (( delta_col=-1; delta_col <= 1; delta_col++ ));do
                    new_row=$((row+delta_row))
                    new_col=$((col+delta_col))
                    # cell is valid 
                    if [[ $new_row -ge 0 && $new_row -lt $rows && $new_col -ge 0 && $new_col -lt $cols ]]; then
                        neighbours+=($(get_index $new_row $new_col))
                    fi

                done
            done
            for neighbour in "${neighbours[@]}";do
                # cell is not a bomb
                if [[ ${board[$neighbour]} -ne "9" ]];then
                    ((board[$neighbour]++))
                fi
            done
        fi
    done
}

print_cell(){
    local index=$1
    if [ ${flagged[$index]} -eq "1" ]; then
        printf "F "
    else
        if [ ${visible[$index]} -eq "1" ]; then
            printf "${board[$index]} "
        else
            printf "# "
        fi
    fi
}

print_board(){
    local index
    move_cursor_to 0 0
    print_border_row $((cols*2+3)) '╔' '═' '╗'
    for (( row=0; row<rows; row++ )); do
    printf '║ '
        for (( col=0; col<cols; col++ )); do
            index=$(get_index $row $col)
            # different color for selected cell
            if [[ ${selectedCell[0]} -eq $row && ${selectedCell[1]} -eq $col ]]; then
                printf "\033[32m"
            fi

            print_cell "$index"

            # back to normal color
            if [[ ${selectedCell[0]} -eq $row && ${selectedCell[1]} -eq $col ]]; then
                printf "\033[0m"
            fi
        done
        printf "║\r\n"
    done
    print_border_row $((cols*2+3)) '╚' '═' '╝'
}

print_instructions(){
    move_cursor_to 1 $((cols+2))
    printf "MINESWEEPER"
    move_cursor_to 2 $((cols+2))
    printf "Nacinij q aby wyjsc"
    move_cursor_to 3 $((cols+2))
    printf "Poruszanie się -> w/s/a/d"
    move_cursor_to 4 $((cols+2))
    printf "Odkryj komórke -> o"
    move_cursor_to 5 $((cols+2))
    printf "Postaw falgę -> p"
}

change_selected(){
    local char=$1

    print_cell $(get_index ${selectedCell[0]} ${selectedCell[1]})
    

    if [[ $char == "w" || $char == "W" ]];then
        if [[ ${selectedCell[0]} -gt 0 ]]; then
            ((selectedCell[0]--))
        fi
    elif [[ $char == "s" || $char == "S" ]]; then
        if [[ ${selectedCell[0]} -lt $((rows-1)) ]]; then
            ((selectedCell[0]++))
        fi
    elif [[ $char == "a" || $char == "A" ]]; then
        if [[ ${selectedCell[1]} -gt 0 ]]; then
            ((selectedCell[1]--))
        fi
    elif [[ $char == "d" || $char == "D" ]]; then
        if [[ ${selectedCell[1]} -lt $((cols-1)) ]]; then
            ((selectedCell[1]++))
        fi
    fi
    # 0 0 is not correct cursor position, because of it there is +1
    move_cursor_to $((selectedCell[0] +1)) $((selectedCell[1] +1))

    # green
    printf "\033[32m"

    print_cell $(get_index ${selectedCell[0]} ${selectedCell[1]})

    move_cursor_to $((selectedCell[0] +1)) $((selectedCell[1] +1))

    # back to normal color
    printf "\033[0m"
}

check_cell(){
    local index=$(get_index selectedCell[0] selectedCell[1])
    if [[ ${flagged[$index]} -ne "1" && ${visible[$index]} -ne "1"  ]]; then
        visible[$index]="1"
        ((checkedCells++))
    fi

    if [ ${board[$index]} -eq "9" ]; then
        gameOver="1"
    fi
}

place_flag(){
    local index=$(get_index selectedCell[0] selectedCell[1])
    if [ ${visible[$index]} -ne "1" ]; then
        # !flagged
        flagged[$index]=$(( 1 - ${flagged[$index]} ))
    fi
}

# Cursor is moving with selected board cell to overwrite it's content instead of cleaning terminal
move_cursor_to(){
    local row=$1
    local col=$2

    ((row = row + 1))
    ((col = col*2+1))
    
    # cursor -> (row, col)
    printf "\033[%d;%dH" "$row" "$col"
}

reset_print() {
    clear
    print_board
    print_instructions
    move_cursor_to $((selectedCell[0]+1)) $((selectedCell[1]+1))
}

# in case of chaning terminal size
trap 'reset_print' WINCH

check_win(){
    if [[ $checkedCells -eq $((rows*cols-bombs)) && $gameOver -eq '0' ]]; then
        gameOver="2"
    fi
}

initialize_board
place_mines
reset_print

# Raw mode
stty raw -echo
# hide cursor
printf "\033[?25l"

while [[ $gameOver -eq "0" ]]; do 
    char=$(dd bs=1 count=1 2>/dev/null)

    if [[ $char == 'q' || $char == 'Q' ]]; then
        gameOver="3"
    elif [[ $char == "o" || $char == "O" ]]; then
        check_cell 
    elif [[ $char == "p" || $char == "P" ]]; then
        place_flag
    fi

    change_selected $char
    check_win
done

# back to standard terminal mode
stty sane
# show cursor
printf "\033[?25h"

clear
print_board
if [ $gameOver -eq "1" ]; then
    move_cursor_to 1 $((cols+2))
    printf "BOOOM!!!\r\n"
    move_cursor_to 2 $((cols+2))
    printf "KONIEC GRY\r\n"
elif [ $gameOver -eq "2" ]; then
    move_cursor_to 1 $((cols+2))
    printf "GRATULACJE!!!\r\n"
    move_cursor_to 2 $((cols+2))
    printf "WYGRAŁEŚ\r\n"
fi
# cursor valid position
move_cursor_to $((rows+2)) 0