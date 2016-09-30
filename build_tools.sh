./bin/nim c --noNimblePath -p:compiler -o:./bin/nimble dist/nimble/src/nimble.nim
./bin/nim c --noNimblePath -p:compiler -o:./bin/nimsuggest dist/nimsuggest/nimsuggest.nim
./bin/nim c -o:./bin/nimgrep tools/nimgrep.nim
