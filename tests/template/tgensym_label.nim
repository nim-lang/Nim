
# bug #5417
import macros

macro genBody: untyped =
  let sbx = genSym(nskLabel, "test")
  when true:
    result = quote do:
      block `sbx`:
        break `sbx`
  else:
    template foo(s1, s2) =
      block s1:
        break s2
    result = getAst foo(sbx, sbx)

proc test() =
  genBody()
