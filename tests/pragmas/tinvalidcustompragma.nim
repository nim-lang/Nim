discard """
  cmd: "nim check $file"
"""

# issue #21652
type Foo = object
template foo() {.tags:[Foo].} = #[tt.Error
                     ^ invalid pragma: tags: [Foo]]#
  discard

{.foobar.} #[tt.Error
  ^ invalid pragma: foobar]#
type A = enum a {.foobar.} #[tt.Error
                  ^ invalid pragma: foobar]#
for b {.foobar.} in [1]: discard #[tt.Error
        ^ invalid pragma: foobar]#
template foobar {.pragma.}
{.foobar.} #[tt.Error
  ^ cannot attach a custom pragma to 'tinvalidcustompragma'; custom pragmas are not supported for modules]#
type A = enum a {.foobar.} #[tt.Error
                  ^ cannot attach a custom pragma to 'a'; custom pragmas are not supported for enum fields]#
for b {.foobar.} in [1]: discard #[tt.Error
        ^ cannot attach a custom pragma to 'b'; custom pragmas are not supported for `for` loop variables]#

# module-wide pragmas are rejected inside a routine
proc inProc() =
  {.localPassC: "-DX".} #[tt.Error
              ^ the 'localPassC' pragma applies to the whole module and must be at module level, not inside a routine]#
  {.passC: "-DX".} #[tt.Error
         ^ the 'passC' pragma applies to the whole module and must be at module level, not inside a routine]#
  {.passL: "-lm".} #[tt.Error
         ^ the 'passL' pragma applies to the whole module and must be at module level, not inside a routine]#
  {.compile: "x.c".} #[tt.Error
           ^ the 'compile' pragma applies to the whole module and must be at module level, not inside a routine]#
  {.link: "x.o".} #[tt.Error
        ^ the 'link' pragma applies to the whole module and must be at module level, not inside a routine]#
let inLambda = proc () =
  {.localPassC: "-DX".} #[tt.Error
              ^ the 'localPassC' pragma applies to the whole module and must be at module level, not inside a routine]#
template inTemplate() =
  {.passC: "-DX".} #[tt.Error
         ^ the 'passC' pragma applies to the whole module and must be at module level, not inside a routine]#
proc usesTemplate() =
  inTemplate()
inTemplate() # expanded at module level: fine
