import std/[strutils, sequtils, strformat, sugar,
            macros, options, tables, json]

import std/matching
{.experimental: "caseStmtMacros".}
{.push hint[XDeclaredButNotUsed]: off.}
{.push hint[ConvFromXtoItselfNotNeeded]: off.}
{.push hint[CondTrue]: off.}

import unittest

template assertEq(a, b: untyped): untyped =
  block:
    let
      aval = a
      bval = b

    if aval != bval:
      raiseAssert("Comparison failed in " &
        $instantiationInfo() &
        " [a: " & $aval & "] [b: " & $bval & "] ")

template testFail(str: string = ""): untyped =
  doAssert false #, "Fail on " & $instantiationInfo() & ": " & str

template multitest(name: string, body: untyped): untyped =
  test name:
    block:
      body

    block:
      static:
        body

template multitestSince(
  name: string,
  minStaticVersion: static[(int,int, int)],
  body: untyped): untyped =

  when (NimMajor, NimMinor, NimPatch) >= minStaticVersion:
    multitest(name, body)
  else:
    test name:
      body


suite "Matching":
  test "Pattern parser tests":
    macro main(): untyped =
      template t(body: untyped): untyped =
        block:
          parseMatchExpr(
            n = (
              quote do:
                body
            )
          )

      doAssert (t true).kind == kItem

      block:
        let s = t [1, 2, all @b, @a]
        doAssert s.seqElems[3].bindVar == some(ident("a"))
        doAssert s.seqElems[2].bindVar == some(ident("b"))
        doAssert s.seqElems[2].patt.bindVar == none(NimNode)

      discard t([1,2,3,4])
      discard t((1,2))
      discard t((@a | @b))
      discard t((a: 12, b: 2))
      # dumpTree: [(0 .. 3) @patt is JString()]
      # dumpTree: [0..3 @patt is JString()]
      discard t([(0 .. 3) @patt is JString()])
      discard t([0..3 @patt is JString()])

      let node = quote: (12 .. 33)

      block:
        case node:
          of Par [_]:
            discard
          else:
            raiseAssert("#[ IMPLEMENT ]#")

        case node:
          of Par[_]:
            discard
          else:
            raiseAssert("#[ IMPLEMENT ]#")

      block:
        node.assertMatch(Par [_] | Par [_])

        node.assertMatch(Par[Infix()])
        node.assertMatch(Par [Infix()])
        node.assertMatch(Par[Infix ()])
        node.assertMatch(Par [Infix ()])

        node.assertMatch(Par [Infix ()])

      block:

        [
          Par     [Infix [_, @lhs, @rhs]] |
          Command [Infix [_, @lhs, @rhs]] |
          Infix   [@infixId, @lhs, @rhs]
        ] := node

        doAssert lhs is NimNode
        doAssert rhs is NimNode
        doAssert infixId is Option[NimNode]
        doAssert lhs == newLit(12)
        doAssert rhs == newLit(33)

      block:
        discard node.matches(
          Call[
            BracketExpr[@ident, opt @outType],
            @body
          ] |
          Command[
            @ident is Ident(),
            Bracket[@outType],
            @body
          ]
        )

        doAssert body is NimNode, $typeof(body)
        doAssert ident is NimNode, $typeof(ident)
        doAssert outType is Option[NimNode]

      block:
        case node:
          of Call[BracketExpr[@ident, opt @outType], @body] |
             Command[@ident is Ident(), Bracket [@outType], @body]
            :
            static:
              doAssert ident is NimNode, $typeof(ident)
              doAssert body is NimNode, $typeof(body)
              doAssert outType is Option[NimNode], $typeof(outType)

          of Call[@head is Ident(), @body]:
            static:
              doAssert head is NimNode
              doAssert body is NimNode

    main()

  test "Pattern parser broken brackets":
    block: JArray[@a, @b] := %*[1, 3]
    block: (JArray [@a, @b]) := %*[1, 3]
    block: (JArray [@a, @b is JString()]) := %[%1, %"hello"]
    block: (JArray [@a, @b is JString ()]) := %[%1, %"hello"]
    block: (JArray [
      @a, @b is JString (getStr: "hello")]) := %[%1, %"hello"]

    block:
      let vals = @[
        %*[["AA", "BB"], "CC"],
        %*["AA", ["BB"], "CC"]
      ]

      template testTypes() {.dirty.} =
        doAssert aa is JsonNode
        doAssert bb is Option[JsonNode]
        doAssert cc is JsonNode

        doAssert aa == %"AA"
        if Some(@bb) ?= bb: doAssert bb == %"BB"
        doAssert cc == %"CC"


      for val in vals:
        case val:
          of JArray[JArray[@aa, opt @bb], @cc] |
             JArray[@aa, JArray[@bb], @cc]
            :
            testTypes()
          else:
            testFail($val)

        block:
          val.assertMatch(
            JArray[JArray[@aa, opt @bb], @cc] |
            JArray[@aa, JArray[@bb], @cc]
          )

          testTypes()

        block:
          val.assertMatch:
            JArray[JArray[@aa, opt @bb], @cc] |
            JArray[@aa, JArray[@bb], @cc]

          testTypes()

        block:
          val.assertMatch:
            JArray [ JArray [@aa, opt @bb] , @cc] |
            JArray [@aa, JArray [@bb], @cc]

          testTypes()

        block:
          val.assertMatch:
            JArray [
              JArray [
                @aa,
                opt @bb
              ] ,
              @cc
            ] |
            JArray [@aa, JArray [
              @bb], @cc]

          testTypes()


  test "Simple uses":
    case (12, 24):
      of (_, 24):
        discard
      else:
        raiseAssert("#[ not possible ]#")


    case [1]:
      of [_]: discard

    case [1,2,3,4]:
      of [_]: testfail()
      of [_, 2, 3, _]:
        discard

    case (1, 2):
      of (3, 4), (1, 2):
        discard
      else:
        testFail()


    assertEq "hehe", case (true, false):
           of (true, _): "hehe"
           else: "2222"

    doAssert (a: 12) ?= (a: 12)
    assertEq "hello world", case (a: 12, b: 12):
           of (a: 12, b: 22): "nice"
           of (a: 12, b: _): "hello world"
           else: "default value"

    doAssert (a: 22, b: 90) ?= (a: 22, b: 90)
    block:
      var res: string

      case (a: 22, b: 90):
        of (b: 91):
          res = "900999"
        elif "some other" == "check":
          res = "rly?"
        elif true:
          res = "default fallback"

        else:
          raiseAssert("#[ not possible ! ]#")

      assertEq res, "default fallback"

    assertEq "000", case %{"hello" : %"world"}:
           of {"999": _}: "nice"
           of {"hello": _}: "000"
           else: "discard"

    assertEq 1, case [(1, 3), (3, 4)]:
                  of [(1, _), _]: 1
                  else: 999

    assertEq 2, case (true, false):
                  of (true, true) | (false, false): 3
                  else: 2

  multitest "Len test":
    macro e(body: untyped): untyped =
      case body:
        of Bracket([Bracket(len: in {1 .. 3})]):
          newLit("Nested bracket !")

        of Bracket(len: in {3 .. 6}):
          newLit(body.toStrLit().strVal() & " matched")

        else:
          newLit("not matched")

    discard e([2,3,4])
    discard e([[1, 3, 4]])
    discard e([3, 4])


  multitest "Regular objects":
    type
      A1 = object
        f1: int

    case A1(f1: 12):
      of (f1: 12):
        discard "> 10"
      else:
        testFail()

    assertEq 10, case A1(f1: 90):
                   of (f1: 20): 80
                   else: 10

  multitest "Private fields":
    type
      A2 = object
        hidden: float

    func public(a: A2): string = $a.hidden

    case A2():
      of (public: _):
        discard
      else:
        testFail()

    case A2(hidden: 8.0):
      of (public: "8.0"): discard
      else: testFail()

  type
    En2 = enum
      enEE
      enEE1
      enZZ

    Obj2 = object
      case kind: En2
        of enEE, enEE1:
          eee: seq[Obj2]
        of enZZ:
          fl: int


  multitest "Case objects":
    case Obj2():
      of EE():
        discard
      of ZZ():
        testFail()

    case Obj2():
      of (kind: in {enEE, enZZ}): discard
      else:
        testFail()


    when false: # FIXME
      const eKinds = {enEE, enEE1}
      case Obj2():
        of (kind: in {enEE} + eKinds): discard
        else:
          testFail()

    case (c: (a: 12)):
      of (c: (a: _)): discard
      else: testfail()

    case [(a: 12, b: 3)]:
      of [(a: 12, b: 22)]: testfail()
      of [(a: _, b: _)]: discard

    case (c: [3, 3, 4]):
      of (c: [_, _, _]): discard
      of (c: _): testfail()

    case (c: [(a: [1, 3])]):
      of (c: [(a: [_])]): testfail()
      else: discard

    case (c: [(a: [1, 3]), (a: [1, 4])]):
      of (c: [(a: [_]), _]): testfail()
      else:
        discard

    case Obj2(kind: enEE, eee: @[Obj2(kind: enZZ, fl: 12)]):
      of enEE(eee: [(kind: enZZ, fl: 12)]):
        discard
      else:
        testfail()

    case Obj2():
      of enEE():
        discard
      of enZZ():
        testfail()
      else:
        testfail()

    case Obj2():
      of (kind: in {enEE, enEE1}):
        discard
      else:
        testfail()

  func len(o: Obj2): int = o.eee.len
  iterator items(o: Obj2): Obj2 =
    for item in o.eee:
      yield item

  multitest "Object items":
    case Obj2(kind: enEE, eee: @[Obj2(), Obj2()]):
      of [_, _]:
        discard
      else:
        testfail()

    case Obj2(kind: enEE, eee: @[Obj2(), Obj2()]):
      of EE(eee: [_, _, _]): testfail()
      of EE(eee: [_, _]): discard
      else: testfail()

    case Obj2(kind: enEE1, eee: @[Obj2(), Obj2()]):
      of EE([_, _]):
        testfail()
      of EE1([_, _, _]):
        testfail()
      of EE1([_, _]):
        discard
      else:
        testfail()



  multitest "Variable binding":
    when false: # NOTE compilation error test
      case (1, 2):
        of ($a, $a, $a, $a):
          discard
        else:
          testfail()

    assertEq "122", case (a: 12, b: 2):
                      of (a: @a, b: @b): $a & $b
                      else: "✠ ♰ ♱ ☩ ☦ ☨ ☧ ⁜ ☥"

    assertEq 12, case (a: 2, b: 10):
                   of (a: @a, b: @b): a + b
                   else: 89

    assertEq 1, case (1, (3, 4, ("e", (9, 2)))):
      of (@a, _): a
      of (_, (@a, @b, _)): a + b
      of (_, (_, _, (_, (@c, @d)))): c * d
      else: 12

    proc tupleOpen(a: (bool, int)): int =
      case a:
        of (true, @capture): capture
        else: -90

    assertEq 12, tupleOpen((true, 12))

  multitest "Infix":
    macro a(): untyped  =
      case newPar(ident "1", ident "2"):
        of Par([@ident1, @ident2]):
          doAssert ident1.strVal == "1"
          doAssert ident2.strVal == "2"
        else:
          doAssert false

    a()

  multitest "Iflet 2":
    macro ifLet2(head: untyped,  body: untyped): untyped =
      case head[0]:
        of Asgn([@lhs is Ident(), @rhs]):
          result = quote do:
            let expr = `rhs`
            if expr.isSome():
              let `lhs` = expr.get()
              `body`
        else:
          head[0].expectKind({nnkAsgn})
          head[0][0].expectKind({nnkIdent})
          error("Expected assgn expression", head[0])

    ifLet2 (nice = some(69)):
      doAssert nice == 69


  when (NimMajor, NimMinor, NimPatch) >= (1, 2, 0):
    multitest "min":
      macro min1(args: varargs[untyped]): untyped =
        let tmp = genSym(nskVar, "minResult")
        result = makeTree(NimNode):
          StmtList:
            VarSection:
              IdentDefs:
                == tmp
                Empty()
                == args[0]

            IfStmt:
              == (block:
                collect(newSeq):
                  for arg in args[1 .. ^1]:
                    makeTree(NimNode):
                      ElifBranch:
                        Infix[== ident("<"), @arg, @tmp]
                        Asgn [@tmp,          @arg]
              )

            == tmp

      macro min2(args: varargs[untyped]): untyped =
        let tmp = genSym(nskVar, "minResult")
        result = makeTree(NimNode):
          StmtList:
            VarSection:
              IdentDefs:
                ==tmp
                Empty()
                ==args[0]

            IfStmt:
              all == (
                block:
                  collect(newSeq):
                    for i in 1 ..< args.len:
                      makeTree(NimNode):
                        ElifBranch:
                          Infix[== ident("<"), ==args[i], ==tmp]
                          Asgn [== tmp,        ==args[i]]
              )

            == tmp

      doAssert min1("a", "b", "c", "d") == "a"
      doAssert min2("a", "b", "c", "d") == "a"

  multitest "Alternative":
    assertEq "matched", case (a: 12, c: 90):
      of (a: 12 | 90, c: _): "matched"
      else: "not matched"

    assertEq 12, case (a: 9):
                  of (a: 9 | 12): 12
                  else: 666


  multitest "Set":
    case [3]:
      of [{2, 3}]: discard
      else: testfail()

    [{'a' .. 'z'}, {' ', '*'}] := "z "

    "hello".assertMatch([all @ident in {'a' .. 'z'}])
    "hello:".assertMatch([pref in {'a' .. 'z'}, opt {':', '-'}])

  multitest "Match assertions":
    [1,2,3].assertMatch([all @res]); assertEq res, @[1,2,3]
    [1,2,3].assertMatch([all @res2]); assertEq res2, @[1,2,3]
    [1,2,3].assertMatch([@first, all @other])
    assertEq first, 1
    assertEq other, @[2, 3]


    block: [@first, all @other] := [1,2,3]
    block: [_, _, _] := @[1,2,3]
    block: (@a, @b) := ("1", "2")
    block: (_, (@a, @b)) := (1, (2, 3))
    block:
      let tmp = @[1,2,3,4,5,6,5,6]
      block: [until @a == 6, .._] := tmp; assertEq a, @[1,2,3,4,5]
      block: [@a, .._] := tmp; assertEq a, 1
      block: [any @a(it < 100)] := tmp; assertEq a, tmp
      block: [pref @a is (1|2|3)] := [1,2,3]; assertEq a, @[1,2,3]
      block: [pref (1|2|3)] := [1,2,3]
      block: [until 3, _] := [1,2,3]
      block: [all 1] := [1,1,1]
      block: doAssert [all 1] ?= [1,1,1]
      block: doAssert not ([all 1] ?= [1,2,3])
      block: [opt @a or 12] := `@`[int]([]); assertEq a, 12
      block: [opt(@a or 12)] := [1]; assertEq a, 1
      block: [opt @a] := [1]; assertEq a, some(1)
      block: [opt @a] := `@`[int]([]); assertEq  a, none(int)
      block: [opt(@a)] := [1]; assertEq a, some(1)
      block:
        {"k": opt @val1 or "12"} := {"k": "22"}.toTable()
        static: doAssert val1 is string
        {"k": opt(@val2 or "12")} := {"k": "22"}.toTable()
        static: doAssert val2 is string
        assertEq val1, val2
        assertEq val1, "22"
        assertEq val2, "22"

      block:
        {"h": Some(@x)} := {"h": some("22")}.toTable()
        doAssert x is string
        doAssert x == "22"

      block:
        {"k": opt @val, "z": opt @val2} := {"z" : "2"}.toTable()
        doAssert val is Option[string]
        doAssert val.isNone()
        doAssert val2 is Option[string]
        doAssert val2.isSome()
        doAssert val2.get() == "2"

      block: [all(@a)] := [1]; assertEq a, @[1]
      block: (f: @hello is ("2" | "3")) := (f: "2"); assertEq hello, "2"
      block: (f: @a(it mod 2 == 0)) := (f: 2); assertEq a, 2
      block: doAssert not ([1,2] ?= [1,2,3])
      block: doAssert [1, .._] ?= [1,2,3]
      block: doAssert [1,2,_] ?= [1,2,3]
      block:
        ## Explicitly use `_` to match whole sequence
        [until @head is 'd', _] := "word"
        ## Can also use trailing `.._`
        [until 'd', .._] := "word"
        assertEq head, @['w', 'o', 'r']

      block:
        [
          [@a, @b],
          [@c, @d, all @e],
          [@f, @g, all @h]
        ] := @[
          @[1,2],
          @[2,3,4,5,6,7],
          @[5,6,7,2,3,4]
        ]

      block: (@a, (@b, @c), @d) := (1, (2, 3), 4)
      block: (Some(@x), @y) := (some(12), none(float))
      block: @hello != nil := (var tmp: ref int; new(tmp); tmp)

      block: [all @head] := [1,2,3]; assertEq head, @[1,2,3]
      block: [all (1|2|3|4|5)] := [1,2,3,4,1,1,2]
      block:
        [until @head is 2, all @tail] := [1,2,3]

        assertEq head, @[1]
        assertEq tail, @[2,3]

      block: (_, _, _) := (1, 2, "fa")
      block: ([1,2,3]) := [1,2,3]
      block: ({0: 1, 1: 2, 2: 3}) := {0: 1, 1: 2, 2: 3}.toTable()


    block:
      block: [0..3 is @head] := @[1,2,3,4]

    case [%*"hello", %*"12"]:
      of [any @elem is JString()]:
        discard
      else:
        testfail()

    case ("foo", 78)
      of ("foo", 78):
        discard
      of ("bar", 88):
        testfail()

    block: Some(@x) := some("hello")

    if (Some(@x) ?= some("hello")) and
       (Some(@y) ?= some("world")):
      assertEq x, "hello"
      assertEq y, "world"
    else:
      discard

  multitest "More examples":
    func butLast(a: seq[int]): int =
      case a:
        of []: raiseAssert(
          "Cannot take one but last from empty seq!")
        of [_]: raiseAssert(
          "Cannot take one but last from seq with only one element!")
        of [@pre, _]:
          return pre
        of [_, all @tail]:
          return butLast(tail)
        else:
          raiseAssert("Not possible")

    assertEq butLast(@[1,2,3,4]), 3

    func butLastGen[T](a: seq[T]): T =
      expand case a:
        of []: raiseAssert(
          "Cannot take one but last from empty seq!")
        of [_]: raiseAssert(
          "Cannot take one but last from seq with only one element!")
        of [@pre, _]: pre
        of [_, all @tail]: butLastGen(tail)
        else: raiseAssert("Not possible")

    assertEq butLastGen(@["1", "2"]), "1"

  multitest "Use in generics":
    func hello[T](a: seq[T]): T =
      [@head, .._] := a
      return head

    doAssert hello(@[1,2,3]) == 1

    proc g1[T](a: seq[T]): T =
      case a:
        of [@a]: discard
        else: testfail()

      expand case a:
        of [_]: discard
        else: testfail()

      expand case a:
        of [_.startsWith("--")]: discard
        else: testfail()

      expand case a:
        of [(len: < 12)]: discard
        else: testfail()

    discard g1(@["---===---=="])


  test "Predicates":
    case ["hello"]:
      of [_.startsWith("--")]:
        testfail()
      of [_.startsWith("==")]:
        testfail()
      else:
        discard


    [all _(it < 10)] := [1,2,3,5,6]
    [all < 10] := [1,2,3,4]
    [all (len: < 10)] := [@[1,2,3,4], @[1,2,3,4]]
    [all _.startsWith("--")] := @["--", "--", "--=="]

    block: [@a.startsWith("--")] := ["--12"]

    proc exception() =
      # This should generate quite nice exception message:

      # Match failure for pattern 'all _.startsWith("--")' expected
      # all elements to match, but item at index 2 failed
      [all _.startsWith("--")] := @["--", "--", "=="]

    expect MatchError:
      exception()

  multitest "One-or-more":
    case [1]:
      of [@a]: assertEq a, 1
      else: testfail()

    case [1]:
      of [all @a]: assertEq a, @[1]
      else: testfail()

    case [1,2,3,4]:
      of [_, until @a is 4, 4]:
        assertEq a, @[2,3]
      else:
        testfail()


    case [1,2,3,4]:
      of [@a, .._]:
        doAssert a is int
        doAssert a == 1
      else:
        testfail()


    case [1,2,3,4]:
      of [all @a]:
        doAssert a is seq[int]
        doAssert a == @[1,2,3,4]
      else:
        testfail()

  multitest "Optional matches":
    case [1,2,3,4]:
      of [pref @a is (1 | 2), _, opt @a or 5]:
        assertEq a, @[1,2,4]


    case [1,2,3]:
      of [pref @a is (1 | 2), _, opt @a or 5]:
        assertEq a, @[1,2,5]

    case [1,2,2,1,1,1]:
      of [all (1 | @a)]:
        doAssert a is seq[int]
        assertEq a, @[2, 2]

  multitest "Tree construction":
    macro testImpl(): untyped =
      let node = makeTree(NimNode):
        IfStmt[
          ElifBranch[== ident("true"),
            Call[
              == ident("echo"),
              == newLit("12")]]]


      IfStmt[ElifBranch[@head, Call[@call, @arg]]] := node
      assertEq head, ident("true")
      assertEq call, ident("echo")
      assertEq arg, newLit("12")

      block:
        let input = "hello"
        # expandMacros:
        Ident(str: @output) := makeTree(NimNode, Ident(str: input))
        assertEq output, input


    testImpl()

  type
    HtmlNodeKind = enum
      htmlBase = "base"
      htmlHead = "head"
      htmlLink = "link"

    HtmlNode = object
      kind*: HtmlNodeKind
      text*: string
      subn*: seq[HtmlNode]

  func add(n: var HtmlNode, s: HtmlNode) = n.subn.add s

  func len(n: HtmlNode): int = n.subn.len
  iterator items(node: HtmlNode): HtmlNode =
    for sn in node.subn:
      yield sn

  multitest "Match assertions custom type; treeRepr syntax":
    HtmlNode(kind: htmlBase).assertMatch:
      Base()

    HtmlNode(
      kind: htmlLink, text: "text-1", subn: @[
        HtmlNode(kind: htmlHead, text: "text-2")]
    ).assertMatch:
      Link(text: "text-1"):
        Head(text: "text-2")


    HtmlNode(
      kind: htmlLink, subn: @[
        HtmlNode(kind: htmlHead, text: "text-2"),
        HtmlNode(kind: htmlHead, text: "text-3", subn: @[
          HtmlNode(kind: htmlBase, text: "text-4"),
          HtmlNode(kind: htmlBase, text: "text-5")
        ])
      ]
    ).assertMatch:
      Link:
        Head(text: "text-2")
        Head(text: "text-3"):
          Base(text: "text-4")
          Base()


  multitestSince "Tree builder custom type", (1, 4, 0):

    discard makeTree(HtmlNode, Base())
    discard makeTree(HtmlNode, base())
    discard makeTree(HtmlNode, base([link()]))
    discard makeTree(HtmlNode):
      base:
        link(text: "hello")

    template wrapper1(body: untyped): untyped =
      makeTree(HtmlNode):
        body

    template wrapper2(body: untyped): untyped =
      makeTree(HtmlNode, body)

    let tmp1 = wrapper1:
      base: link()
      base: link()

    doAssert tmp1 is seq[HtmlNode]


    let tmp3 = wrapper1:
      base:
        base: link()
        base: link()

    doAssert tmp3 is HtmlNode

    let tmp2 = wrapper1:
      base:
        link()

    doAssert tmp2 is HtmlNode

    discard wrapper2:
      base:
        link()


  multitest "Tree construction sequence operators":
    block:
      let inTree = makeTree(HtmlNode):
        base:
          link(text: "link1")
          link(text: "link2")

      inTree.assertMatch:
        base:
          all @elems

      let inTree3 = makeTree(HtmlNode):
        base:
          all @elems

      assertEq inTree3, inTree



  multitest "withItCall":
    macro withItCall(head: typed, body: untyped): untyped =
      result = newStmtList()
      result.add quote do:
        var it {.inject.} = `head`

      for stmt in body:
        case stmt:
          of (
            kind: in {nnkCall, nnkCommand},
            [@head is Ident(), all @arguments]
          ):
            result.add newCall(newDotExpr(
              ident "it", head
            ), arguments)
          else:
            result.add stmt

      result.add ident("it")

      result = newBlockStmt(result)


    let res {.used.} = @[12,3,3].withItCall do:
      it = it.filterIt(it < 4)
      it.add 99


  multitest "Examples from documentation":
    block: [@a] := [1]; doAssert (a is int) and (a == 1)
    block:
      {"key" : @val} := {"key" : "val"}.toTable()
      doAssert val is string
      doAssert val == "val"

    block: [any @a] := [1,2,3]; doAssert a is seq[int]
    block:
      [any @a(it < 3)] := [1, 2, 3]
      doAssert a is seq[int]
      assertEq a, @[1, 2]

    block:
      [until @a == 6, _] := [1, 2, 3, 6]
      doAssert a is seq[int]
      doAssert a == @[1, 2, 3]

    block:
      [all @a == 6] := [6, 6, 6]
      doAssert a is seq[int]
      doAssert a == @[6, 6, 6]

    block:
      [any @a > 100] := [1, 2, 101]

      doAssert @a is seq[int]
      assertEq @a, @[101]

    block:
      [any @a(it > 100)] := [1, 2, 101]
      [any @b > 100] := [1, 2, 101]
      doAssert a == b

    block:
      [_ in {2 .. 10}] := [2]

    block:
      [any @a in {2 .. 10}] := [1, 2, 3]
      [any in {2 .. 10}] := [1, 2, 3]
      [any _ in {2 .. 10}] := [1, 2, 3]

    block:
      [none @a in {6 .. 10}] := [1, 2, 3]
      doAssert a is seq[int]
      doAssert a == @[1, 2, 3]

      [none in {6 .. 10}] := [1, 2, 3]
      [none @b(it in {6 .. 10})] := [1, 2, 3]

    block:
      [opt @val or 12] := [1]
      doAssert val is int
      doAssert val  == 1

    block:
      [_, opt @val] := [1]
      doAssert val is Option[int]
      doAssert val.isNone()

    block:
      [0 .. 3 @val, _] := [1, 2, 3, 4, 5]
      doAssert val is seq[int]
      doAssert val == @[1, 2, 3, 4]
      [0 .. 1 @val1, 2 .. 3 @val2] := [1, 2, 3, 4]
      doAssert val1 is seq[int] and val1 == @[1, 2]
      doAssert val2 is seq[int] and val2 == @[3, 4]

    block:
      let val = (1, 2, "fa")
      doAssert (_, _, _) ?= val
      doAssert not ((@a, @a, _) ?= val)

    block:
      case (true, false):
        of (@a, @a):
          testfail()
        of (@a, _):
          doAssert a == true

    block:
      block: (fld: @val) := (fld: 12); doAssert val == 12
      block: (@val, _) := (12, 2); doAssert val == 12
      block:
        (@val, @val) := (12, 12); doAssert val == 12
        block: doAssert (@a, @a) ?= (12, 12)
        block: doAssert not ((@a, @a) ?= (12, 3))

      block:
        doAssert [_, _] ?= [12, 2]
        doAssert not ([_, _] ?= [12, 2, 2])

      block:
        doAssert [_, .._] ?= [12]
        doAssert not ([_, _, .._] ?= [12])

      block:
        [_, all @val] := [12, 2, 2]; doAssert val == @[2, 2]

        # Note that
        block:
          # Does not work, because `assert` internally uses `if` and
          # all variables declared inside are not accesible to the
          # outside scope
          doAssert [_, all @val] ?= [12, 2, 2]
          when false: # NOTE - will not compile
            doAssert val == @[2, 2]

    block:
      [until @val is 12, _] := [2, 13, 12]
      doAssert val == @[2, 13]

    block:
      [until @val is 12, @val] := [2, 13, 12]
      doAssert val == @[2, 13, 12]


  multitest "Generic types":
    type
      GenKind = enum
        ptkToken
        ptkNterm

      Gen[Kind, Lex] = ref object
        kindFld: Kind
        case tkind*: GenKind
          of ptkNterm:
            subnodes*: seq[Gen[Kind, Lex]]
          of ptkToken:
            lex*: Lex

    func add[K, L](g: var Gen[K, L], t: Gen[K, L]) =
      g.subnodes.add t

    func kind[K, L](g: Gen[K, L]): K = g.kindFld

    block:
      type
        Kind1 = enum
          k1_val
          k2_val
          k3_val

      const kTokens = {k1_val, k2_val}
      block:
        k1_val(lex: @lex) := Gen[Kind1, string](
          tkind: ptkToken,
          kindFld: k1_val,
          lex: "Hello"
        )

      func `kind=`(g: var Gen[Kind1, string], k: Kind1) =
        if k in kTokens:
          g = Gen[Kind1, string](kindFld: k, tkind: ptkToken)
        else:
          g = Gen[Kind1, string](kindFld: k, tkind: ptkNterm)


      let tree = makeTree(Gen[Kind1, string]):
        k3_val:
          k2_val(lex: "Hello")
          k1_val(lex: "Nice")

      doAssert tree.kind == k3_val

    block:
      (lex: @lex) := Gen[void, string](tKind: ptkToken, lex: "hello")






  multitest "Nested objects":
    type
      Lvl3 = object
        f3: float

      Lvl2 = object
        f2: Lvl3

      Lvl1 = object
        f1: Lvl2

    doAssert Lvl1().f1.f2.f3 < 10
    doAssert (f1.f2.f3: < 10) ?= Lvl1()

    case Lvl1():
      of (f1.f2.f3: < 10):
        discard
      of (f1: (f2: (f3: < 10))):
        discard
      else:
        testfail()

  multitest "Nested key access":
    let val = (@[1,2,3], @[3,4,5])

    case val:
      of ((len: <= 3), (len: <= 3)):
        discard
      else:
        testfail()

    let val2 = (hello: @[1,2,3])

    case val2:
      of (hello.len: <= 3):
        discard
      else:
        testfail()


    let val3 = (hello3: @[@[@["eee"]]])
    if false: discard (hello3[0][1][2].len: < 10) ?= val3
    doAssert (hello3[0][0][0].len: < 10) ?= val3
    doAssert (hello3: is [[[(len: < 10)]]]) ?= val3

  test "Match failure exceptions":
    try:
      [all 12] := [2,3,4]
    except MatchError:
      let msg = getCurrentExceptionMsg()
      doAssert "all 1" in msg
      doAssert "all elements" in msg


    expect MatchError:
      [any 1] := [2,3,4]

    try:
      [any 1] := [2,3,4]

    except MatchError:
      let msg = getCurrentExceptionMsg()
      doAssert "any 1" in msg

    [any is (1 | 2)] := [1, 2]

    try:
      [_, any is (1 | 2)] := [3,4,5]

      testfail("_, any is (1 | 2)")

    except MatchError:
      let msg = getCurrentExceptionMsg()
      doAssert "any is (1 | 2)" in msg
      doAssert "[any is (1 | 2)]" notin msg

    expect MatchError:
      [none is 12] := [1, 2, 12]

    expect MatchError:
      [_, _, _] := [1, 2]

    try:
      [_, _, _] := [1, 2]
    except MatchError:
      doAssert "range '3 .. 3'" in getCurrentExceptionMsg()

    try:
      [_, opt _] := [1, 2, 3]
    except MatchError:
      doAssert "range '1 .. 2'" in getCurrentExceptionMsg()


    try:
      [(1 | 2)] := [3]
      testfail("[(1 | 2)] := [3]")
    except MatchError:
      doAssert "pattern '(1 | 2)'" in getCurrentExceptionMsg()


    1 := 1

    expect MatchError:
      1 := 2

    expect MatchError:
      (1, 2) := (2, 1)

    expect MatchError:
      (@a, @a) := (2, 3)

    expect MatchError:
      (_(it < 12), 1) := (14, 1)


  test "Positional matching":
    [0 is 0] := @[0]

    expect MatchError:
      [1 is 0] := @[0]


  test "Compilation errors":
    # NOTE that don't know how to correctly test compilation errors,
    # /without/ actuall failing compilation, so I just set `when true`
    # things to see if error is correct

    when false: # Invalid field. NOTE - I'm not sure whether this
      # should be allowed or not, so for now it is disabled. But
      # technically this should not be that hard to allow explicit
      # function calls as part of path expressions.

      # Error: Malformed path access - expected either field name, or
      # bracket access, but found 'fld.call()' of kind nnkCall
      (fld.call(): _) := 12


  multitest "Use in templates":
    template match1(a: typed): untyped =
      [@nice, @hh69] := a

    match1([12, 3])

    doAssert nice == 12
    doAssert hh69 == 3


  type
    Root = ref object of RootObj
      fld1: int
      fld2: float

    SubRoot = ref object of Root
      fld3: int


  multitest "Ref object field matching":
    case (fld3: 12):
      of (fld3: @subf):
        discard
      else:
        testfail()

    var tmp: Root = SubRoot(fld3: 12)
    doAssert tmp.SubRoot().fld3 == 12
    case tmp:
      of of SubRoot(fld3: @subf):
        doAssert subf == 12
      else:
        testfail()

  multitest "Ref object in maps, subfields and sequences":
    block:
      @[SubRoot(), Root()].assertMatch([any of SubRoot()])

    block:
      @[SubRoot(fld1: 12), Root(fld1: 33)].assertMatch(
        [all of Root(fld1: @vals)])

      assertEq vals, @[12, 33]

    block:
      let val = {12 : SubRoot(fld1: 33)}.toTable()

      val.assertMatch({
        12 : of SubRoot(fld1: @fld1)
      })


      val.assertMatch({
        12 : of Root(fld1: fld1)
      })

      assertEq fld1, 33

  test "Multiple kinds of derived objects":
    type
      Base1 = ref object of RootObj
        fld: int

      First1 = ref object of Base1
        first: float

      Second1 = ref object of Base1
        second: string

    let elems: seq[Base1] = @[
      Base1(fld: 123),
      First1(fld: 456, first: 0.123),
      Second1(fld: 678, second: "test"),
      nil
    ]

    for elem in elems:
      case elem:
        of of First1(fld: @capture1, first: @first):
          # Only capture `Frist1` elements
          doAssert capture1 == 456
          doAssert first == 0.123

        of of Second1(fld: @capture2, second: @second):
          # Capture `second` field in derived object
          doAssert capture2 == 678
          doAssert second == "test"

        of of Base1(fld: @default):
          # Match all *non-nil* base elements
          doAssert default == 123

        else:
          doAssert isNil(elem)

    var first: Base1 = First1()
    doAssert matches(first, of First1(first: @tmp2))
    doAssert not matches(first, of Second1(second: @tmp3))

  test "non-derived ref type":
    type
      RefType = ref object
      RegType = object
        fld: float

    doAssert matches(RefType(), of RefType())

    doAssert matches(RegType(fld: 0.123), RegType(fld: @capture))
    doAssert matches(RegType(fld: 0.123), RegType(fld: 0.123))

    let varn = RegType()
    doAssert matches(varn, RegType())

    var zzz: RegType
    doAssert matches(addr zzz, of RegType())

    var pt: ptr RegType = nil
    doAssert not matches(pt, of RegType())

  multitest "Custom object unpackers":
    type
      Point = object
        x: int
        y: int
        metadata: string ## Some field that you dont' want to unpack

    proc `[]`(p: Point, idx: static[FieldIndex]): auto =
      when idx == 0:
        p.x
      elif idx == 1:
        p.y
      else:
        static:
          error("Cannot unpack `Point` into three-tuple")

    let point = Point(x: 12, y: 13)

    (@x, @y) := point

    assertEq x, 12
    assertEq y, 13


  test "Nested access paths":
    case [[[[[[12]]]]]]:
      of [@test]: discard
      of [[@test]]: discard
      of [[[[[@test]]]]]: discard

    case (a: (b: (c: 12))):
      of (a: @hello): discard
      of (a: (b: @hello)): discard
      of (a.b: @hello): discard
      of (a.b.c: @hello): discard
      of (a.b.c: 12): discard

    (a: (b: (c: 12))) := (a: (b: (c: 12)))
    (a.b.c: 12) := (a: (b: (c: 12)))
    (a[0][0]: 12) := (a: (b: (c: 12)))

    case (a: [2]):
      of (a: @val): discard
      of (a[0]: @val): discard
      of (a[^1]: @val): discard






suite "Gara tests":
  ## Test suite copied from gara pattern matching
  type
    Rectangle = object
      a: int
      b: int

    Repo = ref object
      name: string
      author: Author
      commits: seq[Commit]

    Author = object
      name: string
      email: Email

    Email = object
      raw: string

    # just an example: nice for match
    CommitType = enum ctNormal, ctMerge, ctFirst, ctFix

    Commit = ref object
      message: string
      case kind: CommitType:
        of ctNormal:
          diff: string # simplified
        of ctMerge:
          original: Commit
          other: Commit
        of ctFirst:
          code: string
        of ctFix:
          fix: string

  multitest "Capturing":
    let a = 2
    case [a]: ## Wrap in `[]` to trigger `match` macro, otherwise it
              ## will be treated as regular case match.
      of [@b == 2]:
        assertEq b, 2
      else:
        testfail()


  multitest "Object":
    let a = Rectangle(a: 2, b: 0)

    case a:
      of (a: 4, b: 1):
        testfail()
      of (a: 2, b: @b):
        assertEq b, 0
      else :
        testfail()

  multitest "Subpattern":
    let repo = Repo(
      name: "ExampleDB",
      author: Author(
        name: "Example Author",
        email: Email(raw: "example@exampledb.org")),
      commits: @[
        Commit(kind: ctFirst, message: "First", code: "e:0"),
        Commit(kind: ctNormal, message: "Normal", diff: "+e:2\n-e:0")
    ])


    case repo:
      of (name: "New", commits: == @[]):
        testfail()
      of (
        name: @name,
        author: (
          name: "Example Author",
          email: @email
        ),
        commits: @commits
      ):
        assertEq name, "ExampleDB"
        assertEq email.raw, "example@exampledb.org"
      else:
        testfail()

  test "Sequence":
    let a = @[
      Rectangle(a: 2, b: 4),
      Rectangle(a: 4, b: 4),
      Rectangle(a: 4, b: 4)
    ]

    case a:
      of []:
        testfail()
      of [_, all @others is (a: 4, b: 4)]:
        assertEq others, a[1 .. ^1]
      else:
        testfail()

    # _ is always true, (a: 4, b: 4) didn't match element 2

    # _ is alway.. a.a was 4, but a.b wasn't 4 => not a match

    block:
      [until @vals == 5, .._] := @[2, 3, 4, 5]
      doAssert vals == @[2, 3, 4]


    block:
      [@a, @b] := @[2, 3]


  test "Sequence subpattern":
    let a = @[
      Rectangle(a: 2, b: 4),
      Rectangle(a: 4, b: 0),
      Rectangle(a: 4, b: 4),
      Rectangle(a: 4, b: 4)
    ]

    case a:
      of []:
        fail()
      of [_, _, all (a: @list)]:
        check(list == @[4, 4])
      else:
        fail()

  test "Sequence subpatterns 2":
    let inseq = @[1,2,3,4,5,6,5,6]

    [0 .. 2 is < 10, .._] := inseq
    doAssert not matches(inseq, [0 .. 2 is < 10])
    [0 .. 2 @elems1 is < 10, .._] := inseq
    doAssert elems1 == @[1, 2, 3]

    [12] := [12]
    [[12]] := [[12]]
    [[12], [13]] := [[12], [13]]
    [0 .. 2 is 12] := [12, 12, 12]
    # [0 is 12] := [12]
    [^1 is 12] := [12]

    expect MatchError:
      [^1 is 12] := [13]

    [^1 is (12, 12)] := [(12, 12)]

    [0 is 12, ^1 is 13] := [12, 13]

    expect MatchError:
      [0 is 12, ^1 is 13] := [12, 14]


    expect MatchError:
      [0 is 2, ^1 is 13] := [12, 13]


    expect MatchError:
      # NOTE that's not how it supposed to be used, but it should work
      # anyway.
      [^1 is 13, 0 is 2] := [12, 13]

    [^1 is 13, 0 is 2] := [2, 13]


    # [^1 is 13, 0 is 2] := [12, 13]


  test "Variant":
    let a = Commit(kind: ctNormal, message: "e", diff: "z")

    case a:
      of Merge(original: @original, other: @other):
        fail()
      of Normal(message: @message):
        check(message == "e")
      else:
        fail()

  multitest "Custom unpackers":
    let repo = Repo(
      name: "ExampleDB",
      author: Author(
        name: "Example Author",
        email: Email(raw: "example@exampledb.org")),
      commits: @[
        Commit(kind: ctFirst, message: "First", code: "e:0"),
        Commit(kind: ctNormal, message: "Normal", diff: "+e:2\n-e:0")
    ])

    let email = repo.author.email

    proc data(email: Email): tuple[name: string, domain: string] =
      let words = email.raw.split('@', 1)
      (name: words[0], domain: words[1])

    proc tokens(email: Email): seq[string] =
      # work for js slow
      result = @[]
      var token = ""
      for i, c in email.raw:
        if not c.isAlphaNumeric():
          if token.len > 0:
            result.add(token)
            token = ""
          result.add($c)
        else:
          token.add(c)
      if token.len > 0:
        result.add(token)

    # WARNING multiple calls for `tokens`. It might be possible to
    # wrap each field access into macro helper that determines
    # whether or not expressions is a function, or just regular
    # field access, and cache execution results, but right now I
    # have no idea how to implement this without redesing of the
    # whole pattern matching construction (and even /with it/ I'm
    # not really sure). So the thing is - expression like
    when false:
      (tokens: [@token, @token]) ?= Email()
    # Internallt access `tokens` multiple times - to get number of
    # elements, and each element. E.g. assumption was made that
    # `obj.tokens` is a cheap expression to evaluate. But in this
    # case we get
    when false:
      let expr_25420001 = Email_25095022()
      block failBlock:
        var pos_25420002 = 0
        if not contains({2..2}, len(tokens(expr_25420001))): # Call to `tokens`
          break failBlock
        ## lkPos @token
        ## Set variable token vkRegular
        if token == tokens(expr_25420001)[pos_25420002]: # Second call
          true
        # ...
        ## lkPos @token
        ## Set variable token vkRegular
        if token == tokens(expr_25420001)[pos_25420002]: # Third call
          true
        # ...

    # Access `tokens` for different indices - `pos_25420002`. Using
    # intermediate variable is not an option, since this would create
    # copies each time, for each field access. But! this is not that
    # big of an issue if we can `lent` everything, so this can
    # probably be solved when view types become more stable. And no,
    # it is not possible to determien whether or not `tokens` is a
    # field or not, since pattern matching DSL does not have
    # information about structure of the object being matched - this
    # is one of the main assumptions that was made, so changing this
    # is not possible without complete redesign and severe cuts in
    # functionality.


    # Note that above this just what I think at the moment, I would be
    # glad if someone told me I'm missing something.


    case email:
      of (data: (name: "academy")):
        testfail()

      of (tokens: [_, _, _, _, @token]):
        assertEq token, "org"

  multitest "if":
    let b = @[4, 0]

    case b:
      of [_, @t(it mod 2 == 0)]:
        assertEq t, 0
      else:
        testfail()

  multitest "unification":
    let b = @["nim", "nim", "c++"]

    var res = ""
    case ["nim", "nim", "C++"]:
      of [@x, @x, @x]: discard
      of [@x, @x, _]: res = x

    assertEq res, "nim"



    case b:
      of [@x, @x, @x]:
        testfail()
      of [@x, @x, _]:
        assertEq x, "nim"
      else:
        testfail()

  multitest "option":
    let a = some[int](3)

    case a:
      of Some(@i):
        assertEq i, 3
      else:
        testfail()


  multitest "nameless tuple":
    let a = ("a", "b")

    case a:
      of ("a", "c"):
        testfail()
      of ("a", "c"):
        testfail()
      of ("a", @c):
        assertEq c, "b"
      else:
        testfail()

  multitest "ref":
    type
      Node = ref object
        name: string
        children: seq[Node]

    let node = Node(name: "2")

    case node:
      of (name: @name):
        assertEq name, "2"
      else:
        testfail()

    let node2: Node = nil

    case node2:
      of (isNil: false, name: "4"):
        testfail()
      else:
        discard

  multitest "weird integers":
    let a = 4

    case [a]:
      of [4'i8]:
        discard
      else:
        testfail()

  multitest "dot access":
    let a = Rectangle(b: 4)

    case a:
      of (b: == a.b):
        discard
      else:
        testfail()

  multitest "arrays":
    let a = [1, 2, 3, 4]

    case a:
      of [1, @a, 3, @b, 5]:
        testfail()
      of [1, @a, 3, @b]:
        assertEq a, 2
        assertEq b, 4
      else:
        testfail()

  multitest "bool":
    let a = Rectangle(a: 0, b: 0)

    if a.matches((b: 0)):
      discard
    else:
      testfail()

suite "More tests":
  multitest "Matching boolean tables":
    case (true, false, false):
      of (true, false, false):
        discard

      of (false, true, true):
        testFail("Impossible")

      else:
        testFail("Impossible")


  test "Funcall results":
    [@head, all @trail] := split("a|b|c|d|e", '|')
    doAssert head == "a"
    doAssert trail == @["b", "c", "d", "e"]

    case split("1,2,3,4,5", ','):
      of [@head == "1", until @skip == "5", .._]:
        doAssert skip == @["2", "3", "4"]
        doAssert head == "1"

      else:
        testFail("Pattern failed")


  multitest "Enumparse":
    type
      Dir1 = enum
        dirUp
        dirDown

    proc parseDirection(str: string): Dir1 =
      case str:
        of "up": dirUp
        of "down": dirDown
        else:
          raiseAssert(
            &"Incorrect direction string expected up/down, but found: {str}")


    for cmd in ["quit", "look", "get test", "go up", "drop a b c d"]:
      case cmd.split(" "):
        of ["quit"]:
          doAssert "quit" in cmd

        of ["look"]:
          doAssert "look" in cmd

        of ["get", @objectName]:
          doAssert "get" in cmd
          doASsert objectName == "test"

        of ["go", (parseDirection: @direction)]:
          case direction:
            of dirUp:
              doAssert "go up" in cmd

            else:
              testFail("Wrong enum value parse")

        of ["drop", all @args]:
          doAssert "drop" in cmd
          doAssert args == @["a", "b", "c", "d"]

        else:
          testFail("Unmatched command " & cmd)

  test "Composing array patterns":
    for patt in [@["a", "b", "d"], @["a", "XXX", "d"]]:
      case patt:
        of ["z", @alt1] | ["q", @alt1]:
          static:
            doAssert alt1 is string

        of ["z", @alt2] | ["q", @alt3]:
          static:
            doAssert alt2 is Option[string]
            doAssert alt3 is Option[string]


        of ["a", "b"] | ["a", "b", @altTail]:
          doAssert altTail is Option[string]
          doAssert altTail.get() == "d"

        of ["a", "***", "d"] | ["a", _, "d"]:
          doAssert patt ==  @["a", "XXX", "d"]

        else:
          testFail("Unmatched patter " & $patt)

  test "Alternative subpattern capture":
    case @["a", "b"]:
      of ["a", @second is ("a"|"b"|"c")]:
        doAssert second == "b"

      else:
        testFail()

  test "Use external var in enum; explicit `case`":
    let varname = 404
    match case 404:
      of 200:
        testFail()

      of varname:
        doAssert true

      else:
        testFail()


  test "Nested custom unpacker":
    type
      UserType1 = object
        fld1: float
        fld2: string
        case isDefault: bool
          of true: fld3: float
          of false: fld4: string

      UserType2 = object
        userFld: UserType1
        fld4: float


    proc `[]`(obj: UserType1, idx: static[FieldIndex]): auto =
      when idx == 0:
        obj.fld1

      elif idx == 1:
        obj.fld2

      elif idx == 2:
        if obj.isDefault:
          obj.fld3

        else:
          obj.fld4

      else:
        static:
          error("Indvalid index for `UserType1` field " &
            "- expected value in range[0..2], but got " & $idx
          )

    proc `[]`(obj: UserType2, idx: static[FieldIndex]): auto =
      when idx == 0:
        obj.userFld

      elif idx == 1:
        obj.fld4

      else:
        static:
          error("Indvalid index for `UserType2` field " &
            "- expected value in range[0..1], but got " & $idx
          )

    block:
      (@fld1, @fld2, _) := UserType1(fld1: 0.1, fld2: "hello")

      doAssert fld1 == 0.1
      doAssert fld2 == "hello"

    block:
      (fld1: @fld1, fld2: @fld2) := UserType1(fld1: 0.1, fld2: "hello")

      doAssert fld1 == 0.1
      doAssert fld2 == "hello"

    block:
      ((@fld1, @fld2, _), _) := UserType2(userFld: UserType1(fld1: 0.1, fld2: "hello"))

      doAssert fld1 == 0.1
      doAssert fld2 == "hello"


  test "`is`":
    (a: is 42) := (a: 42)
    (a: 42) := (a: 42)
    (a: == 42) := (a: 42)

    # expandMacros:
    (a: (@a, @b)) := (a: (1, 2))
    (a: (1, 2)) := (a: (1, 2))
    (a: == (1, 2)) := (a: (1, 2))


  test "Nested case objects":
    type
      Kind2 = enum
        kkFirst

      Object4 = ref object
        val: int
        case kind: Kind2
          of kkFirst:
            nested: Object4

    block:
      assertMatch(
        Object4(kind: kkFirst,
                nested: Object4(
                  kind: kkFirst,
                  nested: Object4(
                    kind: kkFirst,
                    val: 10))),
        First(
          nested: First(
            nested: First(
              val: @capture))))

      doAssert capture == 10

  test "Line scanner":
    iterator splitLines(str: string, sep: set[char]): seq[string] =
      for line in str.split(sep):
        yield line.split(" ")

    for line in splitLines("# a|#+ b :|#+ begin_txt :", {'|'}):
      case line:
        of ["#+", @name.startsWith("begin"), .._]:
          assertEq name, "begin_txt"

        of ["#+", @name, .._]:
          assertEq name, "b"

        of ["#", @name, .._]:
          assertEq name, "a"

        else:
          testFail()

  test "Alt pattern in sequence of ref objects":
    type
      Base = ref object of RootObj
        field1: int

      Derived1 = ref object of Base
        derived1: string

      Derived2 = ref object of Base
        derived2: string

    let objs = [
      Base(), Derived1(derived1: "hello"), Derived2(derived2: "world")]

    objs.assertMatch([any (
      of Derived1(derived1: @vals) |
      of Derived2(derived2: @vals))
    ])

    assertEq vals, @["hello", "world"]

  type
    Ast1Kind = enum
      akFirst1
      akSecond1
      akThird1

    Ast1 = object
      case kind1: Ast1Kind
        of akFirst1:
          first: string
        of akSecond1:
          second: int
        of akThird1:
          asdf: int
          third: seq[Ast1]

    Ast2Kind = enum
      akFirst2
      akSecond2
      akThird2

    Ast2 = object
      case kind2: Ast2Kind
        of akFirst2:
          first: string
        of akSecond2:
          second: int
        of akThird2:
          third: seq[Ast2]

  func `kind=`(a1: var Ast1, k: Ast1Kind) = a1 = Ast1(kind1: k)
  func `kind=`(a2: var Ast2, k: Ast2Kind) = a2 = Ast2(kind2: k)

  func kind(a1: Ast1): Ast1Kind = a1.kind1
  func kind(a2: Ast2): Ast2Kind = a2.kind2

  func add(a1: var Ast1, sub: Ast1) = a1.third.add sub
  func add(a2: var Ast2, sub: Ast2) = a2.third.add sub

  func len(a1: Ast1): int = a1.third.len

  iterator items(a1: Ast1): Ast1 =
    for it in a1.third:
      yield it

  multitestSince "AST-AST conversion using pattern matching", (1, 2, 0):
    func convert(a1: Ast1): Ast2 =
      case a1:
        of First1(first: @value):
          return makeTree(Ast2):
            First2(first: value & "Converted")
        of Second1(second: @value):
          return makeTree(Ast2):
            Second2(second: value + 12)
        of Third1(third: @subnodes):
          return makeTree(Ast2):
            Third2(third: == subnodes.map(convert))

    let val = makeTree(Ast1):
      Third1:
        First1(first: "Someval")
        First1(first: "Someval")
        First1(first: "Someval")
        Second1(second: 12)

    discard val.convert()

  test "Match tree with statement list":
    Ast1().assertMatch:
      First1()

    Ast1().assertMatch:
      First1(first: "")

    Ast1(kind1: akThird1, third: @[Ast1(), Ast1()]).assertMatch:
      Third1(asdf: 0):
        First1()
        First1()

    Ast1(kind1: akThird1, third: @[Ast1()]).assertMatch:
      Third1(asdf: 0):
        First1()

    Ast1().assertMatch:
      First1(first: "")


  test "Raise error":
    expect MatchError:
      Ast1().assertMatch:
        Third1()

    expect MatchError:
      Ast1().assertMatch:
        First1(first: "zzzzzzzzzzz")

    expect MatchError:
      Ast1(kind1: akThird1, third: @[Ast1(), Ast1()]).assertMatch:
        Third1(asdf: 0):
          Second1()
          Third1()

    expect MatchError:
      Ast1(kind1: akThird1, third: @[Ast1()]).assertMatch:
        Third1(asdf: 0):
          First1()
          First1()

    expect MatchError:
      Ast1(kind1: akFirst1).assertMatch:
        Third1(first: "")

  test "Pure enums":
    type
      Pure1 {.pure.} = enum
        left
        right

      PureAst1 = object
        kind: Pure1

    left() := PureAst1(kind: Pure1.left)

  test "Fully qualified, snake case":
    type
      Snake1 = enum
        sn_left
        sn_right

      SnakeAst1 = object
        kind: Snake1

    sn_left() := SnakeAst1(kind: sn_left)
    left() := SnakeAst1(kind: sn_left)

  test "Option patterns":
    block:
      [any @x < 12] := @[1, 2, 3]
      [any @y is < 12] := @[1, 2, 3]
      [any @z is 12] := @[12]
      [any @w is == 12] := @[12]

    block:
      Some(Some([any @x < 12])) := some(some(@[1, 2, 3]))
      doAssert x is seq[int]
      doAssert x == @[1, 2, 3]

    block:
      [any @elems is Some()] := [none(int), some(12)]
      doAssert elems is seq[Option[int]]
      doAssert elems.len == 1
      doAssert elems[0].get() == 12

    block:
      [any is Some(@elem)] := [some(12)]
      doAssert elem is seq[int]
      doAssert elem.len == 1
      doAssert elem[0] == 12

    block:
      Some(Some(@x)) := some(some(12))
      doAssert x is int
      doAssert x == 12

    block:
      None() := none(int)


    block:
      Some(Some(None())) := some some none int



import std/[deques, lists]

suite "stdlib container matches":
  test "Ques":
    var que = initDeque[(int, string)]()
    que.addLast (12, "hello")
    que.addLast (3, "iiiiii")

    [any (_ < 12, @vals)] := que

    assertEq vals, @["iiiiii"]



suite "Article examples":
  test "Object matching":
    type
      Obj = object
        fld1: int8

    func len(o: Obj): int = 0

    case Obj():
      of (fld1: < -10):
        testFail()

      of (len: > 10):
        # can use results of function evaluation as fields - same idea as
        # method call syntax in regular code.
        testFail()

      of (fld1: in {1 .. 10}):
        testFail()

      of (fld1: @capture):
        doAssert capture == 0

      else:
        testFail()




  test "Nested tuples unpacking":
    (@a, (@b, _), _) := ("hello", ("world", 11), 0.2)

  test "Simple string scanner":
    "2019 school start".assertMatch([
      # Capture all prefix integers
      pref @year in {'0' .. '9'},
      # Then skip all whitespaces
      until notin {' '},
      # And store remained of the string in `events` variable
      all @event
    ])

    doAssert year == "2019".toSeq()
    doAssert event == "school start".toSeq()

  test "Tokenized string scanner":
    func allIs(str: string, chars: set[char]): bool = str.allIt(it in chars)

    "2019-10-11 school start".split({'-', ' '}).assertMatch([
      pref @dateParts(it.allIs({'0' .. '9'})),
      pref _(it.allIs({' '})),
      all @text
    ])

    doAssert dateParts == @["2019", "10", "11"]
    doAssert text == @["school", "start"]


  test "Pattern matching lexer":
    type
      Lexer = object
        buf: seq[string]
        bufpos: int

    var maxbuf: int = 0
    iterator items(lex: Lexer): string =
      for i in lex.bufpos .. lex.buf.high:
        maxbuf = max(maxbuf, i)
        yield lex.buf[i]

    func len(lex: Lexer): int = lex.buf.len - lex.bufpos
    func isAllnum(str: string): bool = str.allIt(it in {'0' .. '9'})

    var lexer = Lexer(buf: @["2019", "10", "11", "hello", "world"])


    if lexer.matches([
      # `isAlnum` is converted to `[somePos].isAlnum == true`, and can be
      # used to check for properties of particular sequence elements, even
      # though there are no such fields in the element itself.
      @year  is (isAllnum: true, len: 4),
      @month is (isAllnum: true, len: 2),
                # Capturing results of procs is also possible, though there
                # is no particular guarantee wrt. to number of times proc
                # could be executed, so some caution is necessary.
                (isAllnum: true, len: 2, parseInt: @day),
      .._
    ]):
      assertEq year, "2019"
      assertEq month, "10"
      assertEq day, 11
      assertEq lexer.buf[maxbuf], "hello"

    else:
      testFail()

  test "Small parts":
    let txt = """
root:x:0:0::/root:/bin/bash
bin:x:1:1::/:/usr/bin/nologin
daemon:x:2:2::/:/usr/bin/nologin
mail:x:8:12::/var/spool/mail:/usr/bin/nologin
"""
    for line in txt.strip().split("\n"):
      [@username, 1 .. 6 is _, @shell] := line.split(":")

    block:
      [@a, _] := "A|B".split("|")
      doAssert a is string
      doAssert a == "A"

    block:
      case parseJson("""{ "key" : "value" }"""):
        of { "key" : JInt() }:
          testFail()

        of { "key" : (getStr: @val) }:
          doAssert val is string, $typeof(val)


    block:
      let it: seq[string] = "A|B".split("|")
      [@a.startsWith("A"), .._] := it
      doAssert a is string
      doAssert a == "A"

    block:
      (1, 2) | (@a, _) := (12, 3)

      doAssert a is Option[int]

    macro test1(): untyped =
      var inBody: NimNode
      if false:
        Call[BracketExpr[@ident, opt @outType], @body] := inBody

        static:
          doAssert ident is NimNode
          doAssert outType is Option[NimNode]
          doAssert body is NimNode

      if false:
        Command[@ident is Ident(), Bracket[@outType], @body] := inBody

        static:
          doAssert ident is NimNode
          doAssert outType is NimNode
          doAssert body is NimNode

      if false:
        Call[BracketExpr[@ident, opt @outType], @body] |
        Command[@ident is Ident(), Bracket[@outType], @body] := inBody

        static:
          doAssert ident is NimNode
          doAssert outType is Option[NimNode]
          doAssert body is NimNode

      block:
        var a = nnkBracketExpr.newTree(ident "map", ident "string")

        a.assertMatch:
          BracketExpr:
            @head
            @typeParam

        doAssert head.strVal() == "map"
        doAssert typeParam.strVal() == "string"

    test1()

  test "example from documentation":
    case [(1, 3), (3, 4)]:
      of [(1, @a), _]:
        doASsert a == 3

      else:
        fail()

  test "Match proc declaration":
    macro unpackProc(procDecl: untyped): untyped =
      procDecl.assertMatch(
        ProcDef[
          # Match proc name in full form
          @name is ( # And get standalone `Ident`
            Postfix[_, @procIdent] | # Either in exported form
            (@procIdent is Ident()) # Or regular proc definition
          ),
          _, # Skip term rewriting template
          _, # Skip generic parameters
          [ # Match arguments/return types
            @returnType, # Get return type

            # Match full `IdentDefs` for first argument, and extract it's name
            # separately
            @firstArg is IdentDefs[@firstArgName, _, _],

            # Match all remaining arguments. Collect both `IdentDefs` into
            # sequence, and extract each argument separately
            all @trailArgs is IdentDefs[@trailArgsName, _, _]
          ],
          .._
        ]
      )

    proc testProc1(arg1: int) {.unpackProc.} =
      discard

  multitest "Flow macro":
    type
      FlowStageKind = enum
        fskMap
        fskFilter
        fskEach

      FlowStage = object
        outputType: Option[NimNode]
        kind: FlowStageKind
        body: NimNode


    func identToKind(id: NimNode): FlowStageKind =
      if id.eqIdent("map"):
        fskMap
      elif id.eqIdent("filter"):
        fskFilter
      elif id.eqIdent("each"):
        fskEach
      else:
        raiseAssert("#[ IMPLEMENT ]#")

    proc rewrite(node: NimNode, idx: int): NimNode =
      case node:
        of Ident(strVal: "it"):
          result = ident("it" & $idx)
        of (kind: in nnkTokenKinds):
          result = node
        else:
          result = newTree(node.kind)
          for subn in node:
            result.add subn.rewrite(idx)

    func makeTypeAssert(
      expType, body, it: NimNode): NimNode =
      let
        bodyLit = body.toStrLit().strVal().strip().newLit()
        pos = body.lineInfoObj()
        ln = newLit((filename: pos.filename, line: pos.line))

      return quote do:
        when not (`it` is `expType`):
          static:
            {.line: `ln`.}: # To get correct line number when `error`
                            # is used it is necessary to use
                            # `{.line.}` pragma.
              error "\n\nExpected type " & $(typeof(`expType`)) &
                ", but expression \e[4m" & `bodyLit` &
                "\e[24m has type of " & $(typeof(`it`))


    func evalExprFromStages(stages: seq[FlowStage]): NimNode =
      block:
        var expr = stages[^1].body
        if Some(@expType) ?= stages[^1].outputType:
#          ^^             ^^
#          |              |
#          |              Pattern matching operator to determine whether
#          |              right part matches pattern on the left.
#          |
#          Special support for matching `Option[T]` types -

          let assrt = makeTypeAssert(expType, expr, expr)
          # If type assertion is not `none` add type checking.

          expr = quote do:
            `assrt`
            `expr`

      result = newStmtList()
      for idx, stage in stages:
        # Rewrite body
        let body = stage.body.rewrite(idx)


        case stage.kind:
          # If stage is a filter it is converted into `if` expression
          # and new new variables are injected.
          of fskFilter:
            result.add quote do:
              let stageOk = ((`body`))
              if not stageOk:
                continue

          of fskEach:
            # `each` has no variables or special formatting - just
            # rewrite body and paste it back to resulting code
            result.add body
          of fskMap:
            # Create new identifier for injected node and assign
            # result of `body` to it.
            let itId = ident("it" & $(idx + 1))
            result.add quote do:
              let `itId` = `body`

            # If output type for stage needs to be explicitly checked
            # create type assertion.
            if Some(@expType) ?= stage.outputType:
              result.add makeTypeAssert(expType, stage.body, itId)



    func typeExprFromStages(stages: seq[FlowStage], arg: NimNode): NimNode =
      let evalExpr = evalExprFromStages(stages)
      var resTuple = nnkPar.newTree(ident "it0")

      for idx, stage in stages:
        if stage.kind notin {fskFilter, fskEach}:
          resTuple.add ident("it" & $(idx + 1))

      let lastId = newLit(stages.len - 1)

      result = quote do:
        block:
          (
            proc(): auto = # `auto` annotation allows to derive type
                           # of the proc from any assingment withing
                           # proc body - we take advantage of this,
                           # and avoid building type expression
                           # manually.
              for it0 {.inject.} in `arg`:
                `evalExpr`
                result = `resTuple`
#               ^^^^^^^^^^^^^^^^^^^
#               |
#               Type of the return will be derived from this assinment.
#               Even though it is placed within loop body, it will still
#               derive necessary return type
          )()[`lastId`]
#          ^^^^^^^^^^^^
#          | |
#          | Get last element from proc return type
#          |
#          After proc is declared we call it immediatey


    macro flow(arg, body: untyped): untyped =
      # Parse input DSl into sequence of `FlowStage`
      var stages: seq[FlowStage]
      for elem in body:
        if elem.matches(
            Call[BracketExpr[@ident, opt @outType], @body] |
            # `map[string]:`
            Command[@ident is Ident(), Bracket [@outType], @body] |
            # `map [string]:`
            Call[@ident is Ident(), @body]
            # just `map:`, without type argument
          ):
            stages.add FlowStage(
              kind: identToKind(ident),
              outputType: outType,
              body: body
            )

      # Create eval expression
      let evalExpr = evalExprFromStages(stages)

      if stages[^1].kind notin {fskEach}:
        # If last stage has return type (not `each`) then we need to
        # accumulate results in temporary variable.
        let resExpr = typeExprFromStages(stages, arg)
        let lastId = ident("it" & $stages.len)
        let resId = ident("res")
        result = quote do:
          var `resId`: seq[typeof(`resExpr`)]

          for it0 {.inject.} in `arg`:
            `evalExpr`
            `resId`.add `lastid`

          `resId`
      else:
        result = quote do:
          for it0 {.inject.} in `arg`:
            `evalExpr`


      result = newBlockStmt(result)

    let data = """
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
news:x:9:13:news:/etc/news:
uucp:x:10:14:uucp:/var/spool/uucp:/sbin/nologin
operator:x:11:0:operator:/root:/sbin/nologin
games:x:12:100:games:/usr/games:/sbin/nologin
gopher:x:13:30:gopher:/var/gopher:/sbin/nologin
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin
nobody:x:99:99:Nobody:/:/sbin/nologin
nscd:x:28:28:NSCD Daemon:/:/sbin/nologin"""

    # expandMacros:
    let res = flow data.split("\n"):
      map[seq[string]]:
        it.split(":")
      filter:
        let shell = it[^1]
        it.len > 1 and shell.endsWith("bash")
      map:
        shell

    doAssert res is seq[string]

