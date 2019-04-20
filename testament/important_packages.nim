import strutils

template pkg(name: string; cmd = "nimble test"; hasDeps = false; url = ""): untyped =
  packages.add((name, cmd, hasDeps, url))

var packages*: seq[tuple[name, cmd: string; hasDeps: bool; url: string]] = @[]


pkg "argparse"
pkg "arraymancer", "nim c -r src/arraymancer.nim", true
pkg "ast_pattern_matching", "nim c -r tests/test1.nim"
pkg "binaryheap", "nim c -r binaryheap.nim"
pkg "blscurve", "", true
pkg "bncurve", "", true
pkg "c2nim", "nim c testsuite/tester.nim"
pkg "cascade"
pkg "chroma"
pkg "chronicles", "nim c -o:chr -r chronicles.nim", true
pkg "chronos"
pkg "cligen", "nim c -o:cligenn -r cligen.nim"
pkg "combparser"
pkg "compactdict"
pkg "comprehension", "", false, "https://github.com/alehander42/comprehension"
pkg "criterion"
pkg "dashing", "nim c tests/functional.nim"
pkg "docopt"
pkg "fragments", "nim c -r fragments/dsl.nim"
pkg "gara"
pkg "glob"
pkg "gnuplot"
# pkg "godot", "nim c -r godot/godot.nim" # not yet compatible with Nim 0.19
pkg "hts", "nim c -o:htss -r src/hts.nim"
pkg "inim"
pkg "itertools", "nim doc src/itertools.nim"
pkg "iterutils"
pkg "jstin"
pkg "karax", "nim c -r tests/tester.nim"
pkg "loopfusion"
pkg "msgpack4nim"
pkg "nake", "nim c nakefile.nim"
pkg "neo", "nim c -d:blas=openblas tests/all.nim", true
# pkg "nico", "", true
pkg "nicy", "nim c src/nicy.nim"
pkg "nigui", "nim c -o:niguii -r src/nigui.nim"
pkg "nimcrypto", "nim c -r tests/testapi.nim"
pkg "NimData", "nim c -o:nimdataa src/nimdata.nim", true
pkg "nimes", "nim c src/nimes.nim", true
pkg "nimfp", "nim c -o:nfp -r src/fp.nim", true
pkg "nimgame2", "nim c nimgame2/nimgame.nim", true
pkg "nimgen", "nim c -o:nimgenn -r src/nimgen/runcfg.nim", true
# pkg "nimlsp", "", true
# pkg "nimly", "nim c -r tests/test_nimly", true
pkg "nimongo", "nimble test_ci", true
pkg "nimpy", "nim c -r tests/nimfrompy.nim"
pkg "nimquery"
pkg "nimsl", "", true
pkg "nimsvg"
pkg "nimx", "nim c --threads:on test/main.nim", true
pkg "norm", "nim c -o:normm src/norm.nim"
pkg "npeg"
pkg "ormin", "nim c -o:orminn ormin.nim", true
pkg "parsetoml"
pkg "patty"
pkg "plotly", "nim c examples/all.nim", true
pkg "protobuf", "nim c -o:protobuff -r src/protobuf.nim", true
pkg "regex", "nim c src/regex", true
pkg "result", "nim c -r result.nim"
pkg "rosencrantz", "nim c -o:rsncntz -r rosencrantz.nim"
pkg "sdl1", "nim c -r src/sdl.nim"
pkg "sdl2_nim", "nim c -r sdl2/sdl.nim"
pkg "stint", "nim c -o:stintt -r stint.nim"
pkg "strunicode", "nim c -r src/strunicode.nim", true
pkg "tiny_sqlite"
pkg "unicodedb"
pkg "unicodeplus", "", true
pkg "unpack"
pkg "yaml"
pkg "zero_functional", "nim c -r test.nim"
