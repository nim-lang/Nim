
template pkg(name: string; cmd = "nimble test"; hasDeps = false; url = ""): untyped =
  packages.add((name, cmd, hasDeps, url))

var packages*: seq[tuple[name, cmd: string; hasDeps: bool; url: string]] = @[]


pkg "argparse"
pkg "arraymancer", "nim c tests/tests_cpu.nim", true
pkg "ast_pattern_matching", "nim c -r --oldgensym:on tests/test1.nim"
pkg "asyncmysql", "", true
pkg "bigints"
pkg "binaryheap", "nim c -r binaryheap.nim"
pkg "blscurve", "", true
pkg "bncurve", "", true
pkg "c2nim", "nim c testsuite/tester.nim"
pkg "cascade"
pkg "chroma"
pkg "chronicles", "nim c -o:chr -r chronicles.nim", true
pkg "chronos", "", true
pkg "cligen", "nim c -o:cligenn -r cligen.nim"
pkg "coco", "", true
pkg "combparser"
pkg "compactdict"
pkg "comprehension", "", false, "https://github.com/alehander42/comprehension"
pkg "criterion"
pkg "dashing", "nim c tests/functional.nim"
pkg "docopt"
pkg "easygl", "nim c -o:egl -r src/easygl.nim", true, "https://github.com/jackmott/easygl"
pkg "elvis"
pkg "fragments", "nim c -r fragments/dsl.nim"
pkg "gara"
pkg "glob"
pkg "gnuplot"
# pkg "godot", "nim c -r godot/godot.nim" # not yet compatible with Nim 0.19
pkg "hts", "nim c -o:htss -r src/hts.nim"
pkg "illwill", "nimble examples"
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
pkg "nimcrypto", "nim c -r tests/testall.nim"
pkg "NimData", "nim c -o:nimdataa src/nimdata.nim", true
pkg "nimes", "nim c src/nimes.nim", true
pkg "nimfp", "nim c -o:nfp -r src/fp.nim", true
pkg "nimgame2", "nim c nimgame2/nimgame.nim", true
pkg "nimgen", "nim c -o:nimgenn -r src/nimgen/runcfg.nim", true
# pkg "nimlsp", "", true
pkg "nimly", "nim c -r tests/test_nimly", true
# pkg "nimongo", "nimble test_ci", true
pkg "nimpy", "nim c -r tests/nimfrompy.nim"
pkg "nimquery"
pkg "nimsl", "", true
pkg "nimsvg"
# pkg "nimterop", "", true
pkg "nimx", "nim c --threads:on test/main.nim", true
pkg "norm", "nim c -r tests/tsqlite.nim", true
pkg "npeg"
pkg "ormin", "nim c -o:orminn ormin.nim", true
pkg "parsetoml"
pkg "patty"
pkg "plotly", "nim c --oldgensym:on examples/all.nim", true
pkg "pnm"
pkg "polypbren"
pkg "protobuf", "nim c -o:protobuff -r src/protobuf.nim", true
pkg "rbtree"
pkg "react", "nimble example"
pkg "regex", "nim c src/regex", true
pkg "result", "nim c -r result.nim"
pkg "rosencrantz", "nim c -o:rsncntz -r rosencrantz.nim"
pkg "sdl1", "nim c -r src/sdl.nim"
pkg "sdl2_nim", "nim c -r sdl2/sdl.nim"
pkg "snip", "", false, "https://github.com/genotrance/snip"
pkg "stint", "nim c -o:stintt -r stint.nim"
pkg "strunicode", "nim c -r src/strunicode.nim", true
pkg "telebot", "nim c -o:tbot --oldgensym:on -r telebot.nim", true
pkg "tempdir"
pkg "tensordsl", "nim c -r tests/tests.nim", false, "https://krux02@bitbucket.org/krux02/tensordslnim.git"
pkg "tiny_sqlite"
pkg "unicodedb"
pkg "unicodeplus", "", true
pkg "unpack"
# pkg "winim", "", true
pkg "with"
pkg "ws"
pkg "yaml"
pkg "zero_functional", "nim c -r test.nim"
