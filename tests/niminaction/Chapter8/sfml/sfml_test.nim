discard """
action: compile
cmd: "nim cpp --passC:-std=c++17 --passL:-std=c++17 $options $file"
disabled: "windows"
disabled: osx
disabled: "arm64"
"""

import sfml, os
var window = newRenderWindow(videoMode(800, 600), "SFML works!")

var event: Event
discard window.pollEvent(event)
window.clear(newColor(29, 64, 153, 255))
window.display()

sleep(1000)
