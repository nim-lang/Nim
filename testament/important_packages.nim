
template pkg(name: string; hasDeps = false; cmd = "nimble test"; url = ""): untyped =
  packages.add((name, cmd, hasDeps, url))

var packages*: seq[tuple[name, cmd: string; hasDeps: bool; url: string]] = @[]


pkg "argparse"
pkg "arraymancer", true, "nim c tests/tests_cpu.nim"
pkg "ast_pattern_matching", false, "nim c -r --oldgensym:on tests/test1.nim"
pkg "asyncmysql", true
pkg "bigints"
pkg "binaryheap", false, "nim c -r binaryheap.nim"
# pkg "blscurve", true # pending https://github.com/status-im/nim-blscurve/issues/39
pkg "bncurve", true
pkg "c2nim", false, "nim c testsuite/tester.nim"
pkg "cascade"
pkg "chroma"
pkg "chronicles", true, "nim c -o:chr -r chronicles.nim"
# disable until my chronos fix was merged
#pkg "chronos", true
pkg "cligen", false, "nim c -o:cligenn -r cligen.nim"
pkg "coco", true
pkg "combparser"
pkg "compactdict"
pkg "comprehension", false, "nimble test", "https://github.com/alehander42/comprehension"
pkg "criterion"
pkg "dashing", false, "nim c tests/functional.nim"
pkg "docopt"
pkg "easygl", true, "nim c -o:egl -r src/easygl.nim", "https://github.com/jackmott/easygl"
pkg "elvis"
pkg "fragments", false, "nim c -r fragments/dsl.nim"
pkg "gara"
pkg "ggplotnim", true, "nimble testCI"
pkg "glob"
pkg "gnuplot"
pkg "hts", false, "nim c -o:htss src/hts.nim"
pkg "illwill", false, "nimble examples"
pkg "inim"
pkg "itertools", false, "nim doc src/itertools.nim"
pkg "iterutils"
pkg "jstin"
pkg "karax", false, "nim c -r tests/tester.nim"
pkg "loopfusion"
pkg "msgpack4nim"
pkg "nake", false, "nim c nakefile.nim"
pkg "neo", true, "nim c -d:blas=openblas tests/all.nim"
# pkg "nico", true
pkg "nicy", false, "nim c src/nicy.nim"
pkg "nigui", false, "nim c -o:niguii -r src/nigui.nim"
pkg "nimcrypto", false, "nim c -r tests/testall.nim"
pkg "NimData", true, "nim c -o:nimdataa src/nimdata.nim"
pkg "nimes", true, "nim c src/nimes.nim"
pkg "nimfp", true, "nim c -o:nfp -r src/fp.nim"
#pkg "nimgame2", true, "nim c nimgame2/nimgame.nim"
pkg "nimgen", true, "nim c -o:nimgenn -r src/nimgen/runcfg.nim"
# pkg "nimlsp", true
pkg "nimly", true
# pkg "nimongo", true, "nimble test_ci"
pkg "nimpy", false, "nim c -r tests/nimfrompy.nim"
pkg "nimquery"
pkg "nimsl", true
pkg "nimsvg"
# pkg "nimterop", true
pkg "nimx", true, "nim c --threads:on test/main.nim"
pkg "norm", true, "nim c -r tests/tsqlite.nim"
pkg "npeg"
pkg "ormin", true, "nim c -o:orminn ormin.nim"
pkg "parsetoml"
pkg "patty"
pkg "plotly", true, "nim c --oldgensym:on examples/all.nim"
pkg "pnm"
pkg "polypbren"
pkg "protobuf", true, "nim c -o:protobuff -r src/protobuf.nim"
pkg "rbtree"
pkg "react", false, "nimble example"
pkg "regex", true, "nim c src/regex"
pkg "result", false, "nim c -r result.nim"
pkg "rosencrantz", false, "nim c -o:rsncntz -r rosencrantz.nim"
pkg "sdl1", false, "nim c -r src/sdl.nim"
pkg "sdl2_nim", false, "nim c -r sdl2/sdl.nim"
pkg "snip", false, "nimble test", "https://github.com/genotrance/snip"
pkg "stint", false, "nim c -o:stintt -r stint.nim"
pkg "strunicode", true, "nim c -r src/strunicode.nim"
pkg "telebot", true, "nim c -o:tbot --oldgensym:on -r telebot.nim"
pkg "tempdir"
pkg "tensordsl", false, "nim c -r tests/tests.nim", "https://krux02@bitbucket.org/krux02/tensordslnim.git"
pkg "tiny_sqlite"
pkg "unicodedb"
pkg "unicodeplus", true
pkg "unpack"
# pkg "winim", true
pkg "with"
pkg "ws"
pkg "yaml"
pkg "zero_functional", false, "nim c -r test.nim"
