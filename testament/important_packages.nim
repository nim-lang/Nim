import os

template pkg(name: string; hasDeps = false; cmd = "nimble test"; url = ""): untyped =
  packages.add((name, cmd, hasDeps, url))

var packages*: seq[tuple[name, cmd: string; hasDeps: bool; url: string]] = @[]

pkg "alea", true
pkg "argparse"
pkg "arraymancer", true, "nim c tests/tests_cpu.nim"
pkg "ast_pattern_matching", false, "nim c -r --oldgensym:on tests/test1.nim"
pkg "asyncmysql", true
pkg "awk", true
pkg "bigints"
pkg "binaryheap", false, "nim c -r binaryheap.nim"
pkg "BipBuffer"
# pkg "blscurve", true # pending https://github.com/status-im/nim-blscurve/issues/39
pkg "bncurve", true
pkg "brainfuck", true
pkg "bump", true, "nimble test", "https://github.com/disruptek/bump"
pkg "c2nim", false, "nim c testsuite/tester.nim"
pkg "cascade"
pkg "cello", true
pkg "chroma"
pkg "chronicles", true, "nim c -o:chr -r chronicles.nim"
when not defined(osx): # testdatagram.nim(560, 54): Check failed
  pkg "chronos", true
pkg "cligen", false, "nim c -o:cligenn -r cligen.nim"
pkg "coco", true
pkg "combparser"
pkg "compactdict"
pkg "comprehension", false, "nimble test", "https://github.com/alehander42/comprehension"
pkg "criterion"
pkg "dashing", false, "nim c tests/functional.nim"
pkg "delaunay"
pkg "docopt"
pkg "easygl", true, "nim c -o:egl -r src/easygl.nim", "https://github.com/jackmott/easygl"
pkg "elvis"
pkg "fidget", true, "nim c -r tests/runNative.nim"
pkg "fragments", false, "nim c -r fragments/dsl.nim"
pkg "gara"
pkg "ggplotnim", true, "nimble testCI"
# pkg "gittyup", true, "nimble test", "https://github.com/disruptek/gittyup"
pkg "glob"
pkg "gnuplot"
pkg "hts", false, "nim c -o:htss src/hts.nim"
# pkg "httpauth", true
pkg "illwill", false, "nimble examples"
# pkg "inim", true # pending https://github.com/inim-repl/INim/issues/74
pkg "itertools", false, "nim doc src/itertools.nim"
pkg "iterutils"
pkg "jstin"
pkg "karax", false, "nim c -r tests/tester.nim"
pkg "kdtree", false, "nimble test", "https://github.com/jblindsay/kdtree"
pkg "loopfusion"
pkg "macroutils"
pkg "markdown"
pkg "memo"
pkg "msgpack4nim"
pkg "nake", false, "nim c nakefile.nim"
pkg "neo", true, "nim c -d:blas=openblas tests/all.nim"
pkg "nesm"
# pkg "nico", true
pkg "nicy", false, "nim c -r src/nicy.nim"

when defined(osx):
  # xxx: do this more generally by installing non-nim dependencies automatically
  # as specified in nimble file and calling `distros.foreignDepInstallCmd`, but
  # it currently would fail work if a package is already installed.
  doAssert execShellCmd("brew ls --versions gtk+3 || brew install gtk+3") == 0
pkg "nigui", false, "nim c -o:niguii -r src/nigui.nim"

pkg "nimcrypto", false, "nim c -r tests/testall.nim"
pkg "NimData", true, "nim c -o:nimdataa src/nimdata.nim"
pkg "nimes", true, "nim c src/nimes.nim"
pkg "nimfp", true, "nim c -o:nfp -r src/fp.nim"
pkg "nimgame2", true, "nim c nimgame2/nimgame.nim"
pkg "nimgen", true, "nim c -o:nimgenn -r src/nimgen/runcfg.nim"
pkg "nimlsp", true
pkg "nimly", true
# pkg "nimongo", true, "nimble test_ci"
# pkg "nimph", true, "nimble test", "https://github.com/disruptek/nimph"
pkg "nimpy", false, "nim c -r tests/nimfrompy.nim"
pkg "nimquery"
pkg "nimsl", true
pkg "nimsvg"
# pkg "nimterop", true
pkg "nimwc", true, "nim c nimwc.nim"
pkg "nimx", true, "nim c --threads:on test/main.nim"
pkg "nitter", true, "nim c src/nitter.nim", "https://github.com/zedeus/nitter"
pkg "norm", true, "nim c -r tests/tsqlite.nim"
pkg "npeg"
pkg "numericalnim", true
pkg "optionsutils"
pkg "ormin", true, "nim c -o:orminn ormin.nim"
pkg "parsetoml"
pkg "patty"
pkg "plotly", true, "nim c --oldgensym:on examples/all.nim"
pkg "pnm"
pkg "polypbren"
pkg "prologue", true, "nim c -r tests/test_compile/test_compile.nim"
pkg "protobuf", true, "nim c -o:protobuff -r src/protobuf.nim"
pkg "pylib"
pkg "rbtree"
pkg "react", false, "nimble example"
pkg "regex", true, "nim c src/regex"
pkg "result", false, "nim c -r result.nim"
pkg "RollingHash"
pkg "rosencrantz", false, "nim c -o:rsncntz -r rosencrantz.nim"
pkg "sdl1", false, "nim c -r src/sdl.nim"
pkg "sdl2_nim", false, "nim c -r sdl2/sdl.nim"
pkg "sigv4", true, "nimble test", "https://github.com/disruptek/sigv4"
pkg "snip", false, "nimble test", "https://github.com/genotrance/snip"
pkg "stint", false, "nim c -o:stintt -r stint.nim"
pkg "strslice"
pkg "strunicode", true, "nim c -r src/strunicode.nim"
pkg "synthesis"
pkg "telebot", true, "nim c -o:tbot -r src/telebot.nim"
pkg "tempdir"
pkg "templates"
pkg "tensordsl", false, "nim c -r tests/tests.nim", "https://krux02@bitbucket.org/krux02/tensordslnim.git"
pkg "terminaltables", false, "nim c src/terminaltables.nim"
pkg "termstyle"
pkg "timeit"
pkg "timezones"
pkg "tiny_sqlite"
pkg "unicodedb"
pkg "unicodeplus", true
pkg "unpack"
pkg "websocket", false, "nim c websocket.nim"
# pkg "winim", true
pkg "with"
pkg "ws"
pkg "yaml"
pkg "zero_functional", false, "nim c -r test.nim"
