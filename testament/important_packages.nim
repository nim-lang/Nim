import strutils

template pkg(name: string; cmd = "nimble test"; version = ""): untyped =
  packages.add((name, cmd, version))

var packages*: seq[tuple[name, cmd, version: string]] = @[]

pkg "karax"
pkg "cligen"
pkg "glob"
#pkg "regex"
pkg "freeimage", "nim c freeimage.nim"
pkg "zero_functional"
pkg "nimpy", "nim c nimpy.nim"
#pkg "nimongo", "nimble test_ci"
pkg "inim"

pkg "sdl1", "nim c src/sdl.nim"
pkg "iterutils"
pkg "gnuplot"
pkg "c2nim"

#[
    arraymancer
    nimpb
    jester
    nimx
]#
