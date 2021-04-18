import std/importutils
import stdtest/testutils
import mimportutils

template main =
  block: # privateAccess
    assertAll:
      var a: A
      var b = initB() # B is private
      compiles(a.a0)
      compiles(b.b0)
      not compiles(a.ha1)
      not compiles(b.hb1)

    block:
      assertAll:
        privateAccess A
        compiles(a.ha1)
        a.ha1 == 0.0
        not compiles(a.hb1)
        privateAccess b.typeof
        b.hb1 = 3
        type B2 = b.typeof
        let b2 = B2(b0: 4, hb1: 5)
        b.hb1 == 3
        b2 == B2(b0: 4, hb1: 5)

    assertAll:
      not compiles(a.ha1)
      not compiles(b.hb1)

    block:
      assertAll:
        not compiles(C(c0: 1, hc1: 2))
        privateAccess C
        let c = C(c0: 1, hc1: 2)
        c.hc1 == 2

    block:
      assertAll:
        privateAccess PA
        var pa = PA(a0: 1, ha1: 2)
        pa.ha1 == 2
        pa.ha1 = 3
        pa.ha1 == 3

    block:
      assertAll:
        var a = A(a0: 1)
        var a2 = a.addr
        not compiles(a2.ha1)
        privateAccess PtA
        a2.type is PtA
        a2.ha1 = 2
        a2.ha1 == 2
        a.ha1 = 3
        a2.ha1 == 3

    block:
      disableVm:
        assertAll:
          var a = A.create()
          defer: dealloc(a)
          a is PtA
          a.typeof is PtA
          not compiles(a.ha1)
          privateAccess a.typeof
          a.ha1 = 2
          a.ha1 == 2
          a[].ha1 = 3
          a.ha1 == 3

    block:
      disableVm:
        assertAll:
          var a = A.create()
          defer: dealloc(a)
          privateAccess PtA
          a.ha1 == 0

static: main()
main()
