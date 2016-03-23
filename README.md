# strikersii_ai
AI playing Strikers 1945 II.

## HOW TO
---
1. Clone repository
 > `$ git clone https://github.com/aikorea/strikersii_ai/`

2. Init & update submodule
 > `$ git submodule init`
 > `$ git submodule update`

3. Build or download MAME from http://mamedev.org/release.html
 > `$ cd mame`
 > `$ make`

4. Download [Strikers 1945 2][ROM] rom to `$(pwd)/roms/s1945ii.zip`.

5. Run game with script.
 > `$ mame/mame64 s1945ii -script random_move.lua -window`


## Sample
---
- [Video Link][Video]
- [Genetic programming approach][GP]


[ROM]: http://doperoms.com/roms/mame/s1945ii.zip.html/689168/S1945ii.zip.html
[Video]: https://youtu.be/resr2K0z1Aw
[GP]: ./blob/master/genetic/README.md
