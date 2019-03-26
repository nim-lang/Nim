import strutils

template pkg(name: string; cmd = "nimble test"; version = ""; hasDeps = false): untyped =
  packages.add((name, cmd, version, hasDeps))

var packages*: seq[tuple[name, cmd, version: string; hasDeps: bool]] = @[]


pkg "arraymancer", "nim c src/arraymancer.nim", "", true
pkg "ast_pattern_matching", "nim c tests/test1.nim"
pkg "blscurve", "", "", true
pkg "bncurve", "nim c tests/tarith.nim", "", true
pkg "c2nim", "nim c testsuite/tester.nim"
pkg "chronicles", "nim c -o:chr chronicles.nim", "", true
# pkg "chronos", "nim c tests/teststream.nim"
pkg "cligen", "nim c -o:cligenn cligen.nim"
pkg "compactdict", "nim c tests/test1.nim"
pkg "criterion"
pkg "docopt"
pkg "gara", "nim c tests/test_gara.nim"
pkg "glob"
pkg "gnuplot"
pkg "hts", "nim c tests/all.nim"
pkg "inim"
pkg "itertools", "nim doc src/itertools.nim"
pkg "iterutils"
pkg "karax", "nim c tests/tester.nim"
pkg "loopfusion"
pkg "nake", "nim c nakefile.nim"
pkg "neo", "nim c -d:blas=openblas tests/all.nim", "", true
pkg "nigui", "nim c -o:niguii src/nigui.nim"
pkg "nimcrypto", "nim c tests/testapi.nim"
pkg "NimData", "nim c -o:nimdataa src/nimdata.nim", "", true
pkg "nimes", "nim c src/nimes.nim", "", true
pkg "nimgame2", "nim c nimgame2/nimgame.nim", "", true
pkg "nimongo", "nimble test_ci", "", true
pkg "nimpy", "nim c tests/nimfrompy.nim"
pkg "nimsl", "nim c test.nim"
pkg "nimsvg"
# pkg "nimx", "nim c --threads:on test/main.nim", "", true
pkg "parsetoml"
pkg "patty"
pkg "plotly", "nim c examples/all.nim", "", true
pkg "protobuf", "nim c -o:protobuff src/protobuf.nim", "", true
pkg "regex", "nim c src/regex"
pkg "rosencrantz", "nim c -o:rsncntz rosencrantz.nim"
pkg "sdl1", "nim c src/sdl.nim"
pkg "sdl2_nim", "nim c sdl2/sdl.nim"
pkg "stint", "nim c -o:stintt stint.nim"
pkg "zero_functional", "nim c test.nim"
