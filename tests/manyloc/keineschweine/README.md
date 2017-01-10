keineSchweine
========================
Just a dumb little game

### Dependencies

* nim 0.8.15, Until this version is released I'm working off nim HEAD: https://github.com/Araq/nim
* SFML 2.0 (git), https://github.com/LaurentGomila/SFML
* CSFML 2.0 (git), https://github.com/LaurentGomila/CSFML
* Chipmunk 6.1.1 http://chipmunk-physics.net/downloads.php

### How to build?

* `git clone --recursive https://github.com/fowlmouth/keineSchweine.git somedir`
* `cd somedir`
*  `nim c -r nakefile test` or `nim c -r keineschweine && ./keineschweine`

### Download the game data

You need to download the game data before you can play:
http://dl.dropbox.com/u/37533467/data-08-01-2012.7z

Unpack it to the root directory. You can use the nakefile to do this easily: 

* `nim c -r nakefile`
* `./nakefile download`
