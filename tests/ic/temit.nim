# Regression: a module-scope `{.emit.}` in an imported module must survive the
# `nim ic` backend reload (see memit.nim). Before the fix the dropped `#define`
# made the generated C fail to compile, so `nim ic` exited non-zero.
import memit

doAssert emitAnswer() == 42
echo emitAnswer()
