#!/usr/bin/perl
use strict;
use warnings;

# -h
if (@ARGV && $ARGV[0] eq '-h') {
    print "Snake\r\n";
    print " Launch: ./snake.pl\r\n";
    print " The game involves moving around the board and collecting stars to earn points.\r\n";
    print " You can move using the following keys: w (up), s (down), a (left), d (right), q (exit the game).\r\n";
    print " The game ends in a loss if the snake goes out of bounds or collides with itself.\r\n";
    print " The goal of the game is to collect all the stars on the board, which means victory.\r\n";
    print " The snake grows after eating a star, and the game becomes increasingly difficult as the snake gets longer.\r\n";
    print " You can end the game at any time by pressing 'q'.\r\n";
    print " Good luck!\r\n";
    exit 0;
}

my $boardSize;
# star can be also collected by snake
my $fruit="★";
my $head="◆";
my $body="◇";
my $empty=" ";

my $score=0;

# if true the snake will be bigger in the next step
my $addTail=0;

my @board = ();
my @snake;

my $gameOver=0;
# UP/RIGHT/DOWN/LEFT
my $direction="";

# Pressed key -> direction
my %keys=(
    'w' => "UP",
    'W' => "UP",
    'd' => "RIGHT",
    'D' => "RIGHT",
    's' => "DOWN",
    'S' => "DOWN",
    'a' => "LEFT",
    'A' => "LEFT",
);

# Storing free cells to know where fruit can be created and to know when snake hit it's body
# Keys are "row:column"
my %freeCells=();

# ANSI colors
my $red = "\e[31m";  # red
my $green = "\e[32m";  # green
my $yellow = "\e[33m"; # yellow
my $reset = "\e[0m";  # reset colot

# get integer from user
sub get_valid_integer {
    my ($min, $max) = @_; # validation range

    while (1) {
        print "Enter the size of board from range [$min, $max]: ";
        chomp(my $input = <STDIN>);

        # check if input is integer and in range
        if ($input =~ /^\d+$/ && $input >= $min && $input <= $max) {
            return $input;
        } else {
            print "Error: enter integer from range [$min, $max].\n";
        }
    }
}

sub initialize_board {
    for (my $i = 0; $i < $boardSize; $i++) {
        my @row = ($empty) x $boardSize;
        push @board, \@row;

        for(my $j =0; $j < $boardSize; $j++){
            my $key = join(":", $i, $j);
            $freeCells{$key}= 1;
        }
    }
}

# Reset snake position
sub reset_snake{
    my $centerXY = int(($boardSize-1)/2);
    @snake = (
        {row => $centerXY , col => $centerXY},
        {row => $centerXY , col => $centerXY-1},
        {row => $centerXY , col => $centerXY-2}
    );

    for (my $i=1; $i < scalar @snake ; $i++){
        my $key = join(":", $snake[$i]->{row}, $snake[$i]->{col});
        delete $freeCells{$key};
    }
}

sub print_border_row {
    my ($width, $startElem, $insideElem, $endElem) = @_;

    print "$startElem";
    for (my $i=0; $i < $width-2; $i++){
        print $insideElem;
    }
    print "$endElem\r\n";
}

sub print_board {
    print "\033[H";  # cursors to begin of the terminal
    print_border_row(3 + $boardSize*2, '╔', '═', '╗');

    foreach my $row (@board){
        print '║ ';
        foreach my $cell (@$row){
            if ($cell eq $head || $cell eq $body){
                print "$green$cell $reset"
            }elsif ($cell eq $fruit){
                print "$yellow$cell $reset"
            }else{
                print "$cell ";
            }
        }
        printf "║\r\n";
    }

    print_border_row(3 + $boardSize*2, '╚', '═', '╝');
}

# set snake on board
sub set_snake{
    my $char;
    for (my $i=0; $i < scalar @snake ; $i++){
        # head
        if ($i == 0){
            $char=$head;
        }else{ # body
            $char=$body;
        }
        $board[$snake[$i]->{row}][$snake[$i]->{col}] = $char;
    }
}

sub get_delta_row_col{
    my $deltaRow = 0;
    my $deltaCol = 0;
    if ($direction eq "UP"){
        $deltaRow=-1;
    }elsif ($direction eq "DOWN"){
        $deltaRow=1;
    }elsif ($direction eq "RIGHT"){
        $deltaCol=1;
    }elsif ($direction eq "LEFT"){
        $deltaCol=-1;
    }

    return ($deltaRow, $deltaCol);
}

sub move_snake{
    my ($newRow, $newCol) = @_;

    # removing old tail from board
    $board[$snake[-1]->{row}][$snake[-1]->{col}] = $empty;
    # head is now body
    $board[$snake[0]->{row}][$snake[0]->{col}] = $body;

    # tail cell is free
    $freeCells{join(":", $snake[-1]->{row}, $snake[-1]->{col})} = 1;

    my $snakeSize = scalar @snake;
        
    # Snake is growing
    if ($addTail){
        my $cell ={row => $snake[-1]->{row} , col => $snake[-1]->{col}};
        push @snake, $cell;

        $addTail=0;
    }

    # moving snake body
    for (my $i = $snakeSize-1; $i > 0; $i--){
        $snake[$i]->{row} = $snake[$i-1]->{row};
        $snake[$i]->{col} = $snake[$i-1]->{col};
    }
    # moving head
    $snake[0]->{row} = $newRow;
    $snake[0]->{col} = $newCol;

    $board[$snake[0]->{row}][$snake[0]->{col}] = $head;

    # new head cell is no longer free
    delete $freeCells{join(":", $snake[0]->{row}, $snake[0]->{col})};
}

sub check_game_over{
    my ($newRow, $newCol) = @_;

    # No more free cells -> win
    if (scalar keys %freeCells == 0){
        $gameOver=2;
        return;
    }

    # Board bounds
    if ($snake[0]->{row} < 0 || $snake[0]->{row} > $boardSize-1 || $snake[0]->{col} < 0 || $snake[0]->{col} > $boardSize-1){
        $gameOver=1
    }

    # Snake hit it's body
    if(!exists $freeCells{join(":", $newRow, $newCol)}){
        $gameOver=1;
    }
}

# check if snake ate fruit
sub check_fruit{
    my ($newRow, $newCol) = @_;

    if($board[$newRow][$newCol] eq $fruit){
        place_fruit();
        $addTail=1;
        $score++;
    }
}

sub place_fruit{
    # all free cells
    my @cells = keys %freeCells;
    my @randomCell = split(':', $cells[int(rand(scalar @cells))]);
    $board[$randomCell[0]][$randomCell[1]] = $fruit;
}

sub move_cursor_to{
    my ($row, $col) = @_;
    
    $row++;
    $col = $col*2+1;
 
    # cursor -> (row, col)
    printf "\033[%d;%dH", "$row", "$col"
}

sub print_instructions{
    move_cursor_to(1, $boardSize+2);
    print "SNAKE";
    move_cursor_to(2, $boardSize+2);
    print "Press q to exit";
    move_cursor_to(3, $boardSize+2);
    print "Moving around -> w/s/a/d";
    move_cursor_to(4, $boardSize+2);
    print "Score: $score";
}

$boardSize = get_valid_integer(10, 30);

initialize_board();
reset_snake();
set_snake();
place_fruit();

system("clear");
# Raw mode in terminal
system("stty raw -echo");

# hide cursor
printf "\033[?25l";

# Preparing bit mask for select
# vec EXPR,OFFSET,BITS
my $rin='';
vec($rin, fileno(STDIN),  1) = 1;

while (!$gameOver) {
    print_board();
    print_instructions();

    my ($deltaRow, $deltaCol) = get_delta_row_col();
    my $newRow = $snake[0]->{row} + $deltaRow;
    my $newCol = $snake[0]->{col} + $deltaCol;

    check_game_over($newRow, $newCol);
    if ($gameOver){
        last;
    }
    check_fruit($newRow, $newCol);

    if ($direction ne ""){
        move_snake($newRow, $newCol);
    }

    my $char = '';
    # select RBITS,WBITS,EBITS,TIMEOUT
    # The main need here is non-blocking input reading from the user. The select function allows monitoring file descriptors, including STDIN.
    # select(undef, undef, undef, 0.25) acts as a sleep for 250 milliseconds.
    if (select( my $r = $rin, undef, undef, 0.25)){
        $char = getc(STDIN);
    }

    if (exists $keys{$char}) {
        # lowercase key pressed
        my $keyPressed = lc($char);
        # Snake cannot turn around 
        if (!(
                ($keyPressed eq 'w' && $direction eq "DOWN") ||
                ($keyPressed eq 's' && $direction eq "UP") ||
                ($keyPressed eq 'd' && $direction eq "LEFT") || 
                ($keyPressed eq 'a' && $direction eq "RIGHT") ||
                ($keyPressed eq 'a' && $direction eq "")
            )){
            $direction = $keys{$char};
        }
    }

    # Exit the game
    if ($char eq 'q' || $char eq 'Q'){
        $gameOver=1;
        last;
    }
}

if ( $gameOver == 1 ){
    move_cursor_to(7, $boardSize+2);
    printf "GAME OVER GRY\r\n";
}elsif ( $gameOver == 2){
    move_cursor_to(7, $boardSize+2);
    printf "CONGRATULATIONS!!!\r\n";
    move_cursor_to(8, $boardSize+2);
    printf "YOU WON\r\n";
}

# currect cursor postion
move_cursor_to($boardSize+2, 0);
# back to normal terminal mode
system("stty sane");

# show cursor
printf "\033[?25h";
