# Simple Genetic Programming Approach

## Usage
 > `$ mame/mame64 s1945ii -script random_move.lua -window -speed 100`<br>
 > If you don't want to hear / see what is going on, then use this:<br>
 > `$ mame/mame64 s1945ii -script random_move.lua -window -speed 100 -sound none -video none`

## Explanation

The white box represents AI's sight. Every 3 frames, AI evaluates risk of each move(left, right, up, down, stay) and selects one with the least risk. Risk evaluation is done by multiplying some weight matrix with the status of the AI's sight. Hence the trainer tries to learn the best weights.

Actually, Its performance is not remarkable because I coded this to show that the Lua coroutine is very useful when coding trainers, not to show the power of genetic programming :)

### [Video Link][Video]


[Video]: https://youtu.be/k6Ir8yd9iOk
