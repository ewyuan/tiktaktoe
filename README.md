# Tik Tak Toe
A Tic-Tac-Toe-like game implemented in Verilog
<div align="center"><img width="40%" src="https://i.gyazo.com/07045d2abff0c05cab31483fa36a3084.png"/></div>

## Getting started

### Prerequisites 
* Altera DE1-SoC Board
* Intel Quartus

### How to run
1. Create a project in Quartus
2. Add VGA folder into project
3. Import DE1_SoC.qsf into pin assignments
4. Compile project

## Playing the game
### How to win
To win the game, one player must connect 5 squares in a row.

### How to move
To make a turn, the player must use KEY[3] to move left, KEY[1] to move right and KEY[2] to place the block down. Once a square has been placed down, the program automatically changes to the next player. If a player attempts to place a square down on an already occupied grid position, that player will lose their turn and the program will automatically change to the next player.

