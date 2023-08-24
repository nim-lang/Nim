block: # basic template generic parameter substitution
  block: # issue #13527
    template typeNameTempl[T](a: T): string = $T
    proc typeNameProc[T](a: T): string = $T
    doAssert typeNameTempl(1) == typeNameProc(1)
    doAssert typeNameTempl(true) == typeNameProc(true)
    doAssert typeNameTempl(1.0) == typeNameProc(1.0)
    doAssert typeNameTempl(1u8) == typeNameProc(1u8)

    template isDefault[T](a: T): bool = a == default(T)
    doAssert isDefault(0.0)

  block: # issue #17240
    func to(c: int, t: typedesc[float]): t = discard
    template converted[I, T](i: seq[I], t: typedesc[T]): seq[T] =
      var result = newSeq[T](2)
      result[0] = i[0].to(T)
      result
    doAssert newSeq[int](3).converted(float) == @[0.0, 0.0]

  block: # issue #6340
    type A[T] = object
      v: T
    proc foo(x: int): string = "int"
    proc foo(x: typedesc[int]): string = "typedesc[int]"
    template fooT(x: int): string = "int"
    template fooT(x: typedesc[int]): string = "typedesc[int]"
    proc foo[T](x: A[T]): (string, string) =
      (foo(T), fooT(T))
    template fooT[T](x: A[T]): (string, string) =
      (foo(T), fooT(T))
    var x: A[int]
    doAssert foo(x) == fooT(x)

  block: # issue #20033
    template run[T](): T = default(T)
    doAssert run[int]() == 0

import options, tables

block: # complex cases of above with imports
  block: # issue #19576, complex case
    type RegistryKey = object
      key, val: string
    var regKey = @[RegistryKey(key: "abc", val: "def")]
    template findFirst[T](s: seq[T], pred: proc(x: T): bool): Option[T] =
      var res = none(T) # important line
      for x in s:
        if pred(x):
          res = some(x)
          break
      res
    proc getval(searchKey: string): Option[string] =
      let found = regKey.findFirst(proc (rk: RegistryKey): bool = rk.key == searchKey)
      if found.isNone: none(string)
      else: some(found.get().val)
    doAssert getval("strange") == none(string)
    doAssert getval("abc") == some("def")
  block: # issue #19076
    block: # case 1
      var tested: Table[string,int]
      template `[]`[V](t:Table[string,V],key:string):untyped =
        $V
      doAssert tested["abc"] == "int"
      template `{}`[V](t:Table[string,V],key:string):untyped =
        ($V, tables.`[]`(t, key))
      doAssert (try: tested{"abc"} except KeyError: ("not there", 123)) == ("not there", 123)
      tables.`[]=`(tested, "abc", 456)
      doAssert tested["abc"] == "int"
      doAssert tested{"abc"} == ("int", 456)
    block: # case 2
      type Foo[A,T] = object
        t:T
      proc init[A,T](f:type Foo,a:typedesc[A],t:T):Foo[A,T] = Foo[A,T](t:t)
      template fromOption[A](o:Option[A]):auto =
        when o.isSome:
          Foo.init(A,35)
        else:
          Foo.init(A,"hi")
      let op = fromOption(some(5))
