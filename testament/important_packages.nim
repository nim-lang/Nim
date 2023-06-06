##[
## note 1
`useHead` should ideally be used as the default but lots of packages (e.g. `chronos`)
don't have release tags (or have really old ones compared to HEAD), making it
impossible to test them reliably here.

packages listed here should ideally have regularly updated release tags, so that:
* we're testing recent versions of the package
* the version that's tested is stable enough even if HEAD may occasionally break

## note 2: D20210308T165435:here
nimble packages should be testable as follows:
git clone $url $dir && cd $dir
NIMBLE_DIR=$TMP_NIMBLE_DIR XDG_CONFIG_HOME= nimble install --depsOnly -y
NIMBLE_DIR=$TMP_NIMBLE_DIR XDG_CONFIG_HOME= nimble test

if this fails (e.g. nimcrypto), it could be because a package lacks a `tests/nim.cfg` with `--path:..`,
so the above commands would've worked by accident with `nimble install` but not with `nimble install --depsOnly`.
When this is the case, a workaround is to test this package here by adding `--path:$srcDir` on the test `cmd`.
]##

type NimblePackage* = object
  name*, cmd*, url*: string
  useHead*: bool
  allowFailure*: bool
    ## When true, we still run the test but the test is allowed to fail.
    ## This is useful for packages that currently fail but that we still want to
    ## run in CI, e.g. so that we can monitor when they start working again and
    ## are reminded about those failures without making CI fail for unrelated PRs.

var packages*: seq[NimblePackage]

proc pkg(name: string; cmd = "nimble test"; url = "", useHead = true, allowFailure = false) =
  packages.add NimblePackage(name: name, cmd: cmd, url: url, useHead: useHead, allowFailure: allowFailure)

pkg "alea", allowFailure = true
pkg "argparse"
pkg "arraymancer", "nim c tests/tests_cpu.nim"
pkg "ast_pattern_matching", "nim c -r --oldgensym:on tests/test1.nim", allowFailure = true
pkg "asyncthreadpool"
pkg "awk"
pkg "bigints", url = "https://github.com/Araq/nim-bigints"
pkg "binaryheap", "nim c -r binaryheap.nim"
pkg "BipBuffer"
pkg "blscurve", allowFailure = true # pending https://github.com/status-im/nim-blscurve/issues/39
pkg "bncurve"
pkg "brainfuck", "nim c -d:release -r tests/compile.nim"
pkg "bump", "nim c --gc:arc --path:. -r tests/tbump.nim", "https://github.com/disruptek/bump", allowFailure = true
pkg "c2nim", "nim c testsuite/tester.nim"
pkg "cascade"
pkg "cello"
pkg "chroma"
pkg "chronicles", "nim c -o:chr -r chronicles.nim", url = "https://github.com/nim-lang/nim-chronicles"
pkg "chronos", "nim c -r -d:release tests/testall"
pkg "cligen", "nim c --path:. -r cligen.nim"
pkg "combparser", "nimble test --gc:orc"
pkg "compactdict"
pkg "comprehension", "nimble test", "https://github.com/alehander92/comprehension"
pkg "criterion", allowFailure = true # pending https://github.com/disruptek/criterion/issues/3 (wrongly closed)
pkg "datamancer"
pkg "dashing", "nim c tests/functional.nim"
pkg "delaunay"
pkg "docopt"
pkg "easygl", "nim c -o:egl -r src/easygl.nim", "https://github.com/jackmott/easygl"
pkg "elvis"
pkg "fidget"
pkg "fragments", "nim c -r fragments/dsl.nim", allowFailure = true # pending https://github.com/nim-lang/packages/issues/2115 
pkg "fusion"
pkg "gara"
pkg "glob"
pkg "ggplotnim", "nim c -d:noCairo -r tests/tests.nim"
pkg "gittyup", "nimble test", "https://github.com/disruptek/gittyup", allowFailure = true
pkg "gnuplot", "nim c gnuplot.nim"
# pkg "gram", "nim c -r --gc:arc --define:danger tests/test.nim", "https://github.com/disruptek/gram"
  # pending https://github.com/nim-lang/Nim/issues/16509
pkg "hts", "nim c -o:htss src/hts.nim"
pkg "httpauth"
pkg "illwill", "nimble examples"
pkg "inim"
pkg "itertools", "nim doc src/itertools.nim"
pkg "iterutils"
pkg "jstin"
pkg "karax", "nim c -r tests/tester.nim"
pkg "kdtree", "nimble test -d:nimLegacyRandomInitRand", "https://github.com/jblindsay/kdtree"
pkg "loopfusion"
pkg "lockfreequeues"
pkg "macroutils"
# pkg "manu"
pkg "markdown"
pkg "memo"
pkg "msgpack4nim", "nim c -r tests/test_spec.nim"
pkg "nake", "nim c nakefile.nim"
pkg "neo", "nim c -d:blas=openblas tests/all.nim"
pkg "nesm", "nimble tests" # notice plural 'tests'
pkg "netty"
pkg "nico", allowFailure = true
pkg "nicy", "nim c -r src/nicy.nim"
pkg "nigui", "nim c -o:niguii -r src/nigui.nim"
pkg "nimcrypto", "nim r --path:. tests/testall.nim" # `--path:.` workaround needed, see D20210308T165435
pkg "NimData", "nim c -o:nimdataa src/nimdata.nim"
pkg "nimes", "nim c src/nimes.nim"
pkg "nimfp", "nim c -o:nfp -r src/fp.nim"
pkg "nimgame2", "nim c -d:nimLegacyConvEnumEnum nimgame2/nimgame.nim"
  # XXX Doesn't work with deprecated 'randomize', will create a PR.
pkg "nimgen", "nim c -o:nimgenn -r src/nimgen/runcfg.nim"
pkg "nimlsp", allowFailure = true
pkg "nimly", "nim c -r tests/test_readme_example.nim"
pkg "nimongo", "nimble test_ci", allowFailure = true
pkg "nimph", "nimble test", "https://github.com/disruptek/nimph", allowFailure = true
pkg "nimpy", "nim c -r tests/nimfrompy.nim"
pkg "nimquery"
pkg "nimsl"
pkg "nimsvg"
pkg "nimterop", "nimble minitest"
pkg "nimwc", "nim c nimwc.nim"
pkg "nimx", "nim c --threads:on test/main.nim", allowFailure = true
pkg "nitter", "nim c src/nitter.nim", "https://github.com/zedeus/nitter"
# pkg "norm", "testament r tests/sqlite/trows.nim"
pkg "npeg", "nimble testarc"
pkg "numericalnim", "nimble nimCI"
pkg "optionsutils"
pkg "ormin", "nim c -o:orminn ormin.nim"
pkg "parsetoml"
pkg "patty"
pkg "pixie"
pkg "plotly", "nim c examples/all.nim"
pkg "pnm"
pkg "polypbren"
pkg "prologue", "nimble tcompile"
pkg "protobuf", "nim c -o:protobuff -r src/protobuf.nim"
pkg "pylib"
pkg "rbtree"
pkg "react", "nimble example"
pkg "regex", "nim c src/regex"
pkg "results", "nim c -r results.nim"
pkg "RollingHash", "nim c -r tests/test_cyclichash.nim"
pkg "rosencrantz", "nim c -o:rsncntz -r rosencrantz.nim"
pkg "sdl1", "nim c -r src/sdl.nim"
pkg "sdl2_nim", "nim c -r sdl2/sdl.nim"
pkg "sigv4", "nim c --gc:arc -r sigv4.nim", "https://github.com/disruptek/sigv4"
pkg "sim"
pkg "snip", "nimble test", "https://github.com/genotrance/snip"
pkg "stint", "nim r stint.nim"
pkg "strslice"
pkg "strunicode", "nim c -r src/strunicode.nim"
pkg "supersnappy"
pkg "synthesis"
pkg "telebot", "nim c -o:tbot -r src/telebot.nim"
pkg "tempdir"
pkg "templates"
pkg "tensordsl", "nim c -r tests/tests.nim", "https://krux02@bitbucket.org/krux02/tensordslnim.git"
pkg "terminaltables", "nim c src/terminaltables.nim"
pkg "termstyle", "nim c -r termstyle.nim"
pkg "timeit"
pkg "timezones"
pkg "tiny_sqlite"
pkg "unicodedb", "nim c -d:release -r tests/tests.nim"
pkg "unicodeplus", "nim c -d:release -r tests/tests.nim"
pkg "unpack"
pkg "weave", "nimble test_gc_arc"
pkg "websocket", "nim c websocket.nim"
pkg "winim", "nim c winim.nim"
pkg "with"
pkg "ws", allowFailure = true
pkg "yaml", "nim c -r test/tserialization.nim"
pkg "zero_functional", "nim c -r -d:nimNoLentIterators test.nim"
pkg "zippy"
