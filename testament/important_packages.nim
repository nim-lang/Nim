##[
## note
`useHead` should ideally be used as the default but lots of packages (e.g. `chronos`)
don't have release tags (or have really old ones compared to HEAD), making it
impossible to test them reliably here.

packages listed here should ideally have regularly updated release tags, so that:
* we're testing recent versions of the package
* the version that's tested is stable enough even if HEAD may occasionally break
]##


#[
xxx instead of pkg1, pkg2, use the more flexible `NIM_TESTAMENT_BATCH` (see #14823).
]#

template pkg1(name: string; cmd = "nimble test"; url = "", useHead = true): untyped =
  packages1.add((name, cmd, url, useHead))

template pkg2(name: string; cmd = "nimble test"; url = "", useHead = true): untyped =
  packages2.add((name, cmd, url, useHead))

var packages1*: seq[tuple[name, cmd: string; url: string, useHead: bool]] = @[]
var packages2*: seq[tuple[name, cmd: string; url: string, useHead: bool]] = @[]

# packages A-M
# pkg1 "alea"
pkg1 "argparse"
pkg1 "arraymancer", "nim c tests/tests_cpu.nim"
# pkg1 "ast_pattern_matching", "nim c -r --oldgensym:on tests/test1.nim"
pkg1 "awk"
pkg1 "bigints", url = "https://github.com/Araq/nim-bigints"
pkg1 "binaryheap", "nim c -r binaryheap.nim"
pkg1 "BipBuffer"
# pkg1 "blscurve" # pending https://github.com/status-im/nim-blscurve/issues/39
pkg1 "bncurve"
pkg1 "brainfuck", "nim c -d:release -r tests/compile.nim"
pkg1 "bump", "nim c --gc:arc --path:. -r tests/tbump.nim", "https://github.com/disruptek/bump"
pkg1 "c2nim", "nim c testsuite/tester.nim"
pkg1 "cascade"
pkg1 "cello"
pkg1 "chroma"
pkg1 "chronicles", "nim c -o:chr -r chronicles.nim"
# when not defined(osx): # testdatagram.nim(560, 54): Check failed
#   pkg1 "chronos", "nim c -r -d:release tests/testall"
  # pending https://github.com/nim-lang/Nim/issues/17130
pkg1 "cligen", "nim c --path:. -r cligen.nim"
pkg1 "combparser", "nimble test --gc:orc"
pkg1 "compactdict"
pkg1 "comprehension", "nimble test", "https://github.com/alehander42/comprehension"
# pkg1 "criterion" # pending https://github.com/disruptek/criterion/issues/3 (wrongly closed)
pkg1 "dashing", "nim c tests/functional.nim"
pkg1 "delaunay"
pkg1 "docopt"
pkg1 "easygl", "nim c -o:egl -r src/easygl.nim", "https://github.com/jackmott/easygl"
pkg1 "elvis"
# pkg1 "fidget" # pending https://github.com/treeform/fidget/issues/133
pkg1 "fragments", "nim c -r fragments/dsl.nim"
pkg1 "fusion"
pkg1 "gara"
pkg1 "glob"
pkg1 "ggplotnim", "nim c -d:noCairo -r tests/tests.nim"
# pkg1 "gittyup", "nimble test", "https://github.com/disruptek/gittyup"
pkg1 "gnuplot", "nim c gnuplot.nim"
# pkg1 "gram", "nim c -r --gc:arc --define:danger tests/test.nim", "https://github.com/disruptek/gram"
  # pending https://github.com/nim-lang/Nim/issues/16509
pkg1 "hts", "nim c -o:htss src/hts.nim"
# pkg1 "httpauth"
pkg1 "illwill", "nimble examples"
pkg1 "inim"
pkg1 "itertools", "nim doc src/itertools.nim"
pkg1 "iterutils"
pkg1 "jstin"
pkg1 "karax", "nim c -r tests/tester.nim"
pkg1 "kdtree", "nimble test", "https://github.com/jblindsay/kdtree"
pkg1 "loopfusion"
pkg1 "macroutils"
pkg1 "manu"
pkg1 "markdown"
pkg1 "memo"
pkg1 "msgpack4nim", "nim c -r tests/test_spec.nim"

# these two are special snowflakes
pkg1 "nimcrypto", "nim c -r tests/testall.nim"
pkg1 "stint", "nim c -o:stintt -r stint.nim"


# packages N-Z
pkg2 "nake", "nim c nakefile.nim"
pkg2 "neo", "nim c -d:blas=openblas tests/all.nim"
# pkg2 "nesm", "nimble tests" # notice plural 'tests'
# pkg2 "nico"
pkg2 "nicy", "nim c -r src/nicy.nim"
pkg2 "nigui", "nim c -o:niguii -r src/nigui.nim"
pkg2 "NimData", "nim c -o:nimdataa src/nimdata.nim"
pkg2 "nimes", "nim c src/nimes.nim"
pkg2 "nimfp", "nim c -o:nfp -r src/fp.nim"
when false:
  pkg2 "nimgame2", "nim c nimgame2/nimgame.nim"
  # XXX Doesn't work with deprecated 'randomize', will create a PR.
pkg2 "nimgen", "nim c -o:nimgenn -r src/nimgen/runcfg.nim"
pkg2 "nimlsp"
pkg2 "nimly", "nim c -r tests/test_readme_example.nim"
# pkg2 "nimongo", "nimble test_ci"
# pkg2 "nimph", "nimble test", "https://github.com/disruptek/nimph"
pkg2 "nimpy", "nim c -r tests/nimfrompy.nim"
pkg2 "nimquery"
pkg2 "nimsl"
pkg2 "nimsvg"
pkg2 "nimterop", "nimble minitest"
pkg2 "nimwc", "nim c nimwc.nim"
# pkg2 "nimx", "nim c --threads:on test/main.nim"
# pkg2 "nitter", "nim c src/nitter.nim", "https://github.com/zedeus/nitter"
pkg2 "norm", "nim c -r tests/sqlite/trows.nim"
pkg2 "npeg", "nimble testarc"
pkg2 "numericalnim", "nim c -r tests/test_integrate.nim"
# pkg2 "optionsutils" # pending changing test from `Some` to `some` (etc) in tests/test2.nim, refs #17147
pkg2 "ormin", "nim c -o:orminn ormin.nim"
pkg2 "parsetoml"
pkg2 "patty"
pkg2 "plotly", "nim c examples/all.nim"
pkg2 "pnm"
pkg2 "polypbren"
pkg2 "prologue", "nimble tcompile"
pkg2 "protobuf", "nim c -o:protobuff -r src/protobuf.nim"
pkg2 "pylib"
pkg2 "rbtree"
pkg2 "react", "nimble example"
pkg2 "regex", "nim c src/regex"
pkg2 "result", "nim c -r result.nim"
pkg2 "RollingHash", "nim c -r tests/test_cyclichash.nim"
pkg2 "rosencrantz", "nim c -o:rsncntz -r rosencrantz.nim"
pkg2 "sdl1", "nim c -r src/sdl.nim"
pkg2 "sdl2_nim", "nim c -r sdl2/sdl.nim"
pkg2 "sigv4", "nim c --gc:arc -r sigv4.nim", "https://github.com/disruptek/sigv4"
pkg2 "snip", "nimble test", "https://github.com/genotrance/snip"
pkg2 "strslice"
pkg2 "strunicode", "nim c -r src/strunicode.nim"
pkg2 "synthesis"
pkg2 "telebot", "nim c -o:tbot -r src/telebot.nim"
pkg2 "tempdir"
pkg2 "templates"
pkg2 "tensordsl", "nim c -r tests/tests.nim", "https://krux02@bitbucket.org/krux02/tensordslnim.git"
pkg2 "terminaltables", "nim c src/terminaltables.nim"
pkg2 "termstyle", "nim c -r termstyle.nim"
pkg2 "timeit"
pkg2 "timezones"
pkg2 "tiny_sqlite"
pkg2 "unicodedb", "nim c -d:release -r tests/tests.nim"
pkg2 "unicodeplus", "nim c -d:release -r tests/tests.nim"
pkg2 "unpack"
pkg2 "websocket", "nim c websocket.nim"
# pkg2 "winim"
pkg2 "with"
pkg2 "ws"
pkg2 "yaml", "nim build"
pkg2 "zero_functional", "nim c -r -d:nimWorkaround14447 test.nim"
pkg2 "zippy"
