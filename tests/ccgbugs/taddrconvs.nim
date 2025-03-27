discard """
  targets: "c cpp"
  matrix: "--mm:refc; --mm:orc"
"""

{.emit:"""
void foo(unsigned long long* x)
{
}
""".}

block:
  proc foo(x: var culonglong) {.importc: "foo", nodecl.}

  proc main(x: var uint64) =
    var m = uint64(12)
    foo(culonglong m)

  var u = uint64(12)
  main(u)

block:
  proc foo(x: var culonglong) {.importc: "foo", nodecl.}

  proc main() =
    var m = uint64(12)
    foo(culonglong(m))
  main()
