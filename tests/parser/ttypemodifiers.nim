discard """
nimout: '''
StmtList
  TypeSection
    TypeDef
      Ident "BarePtr"
      Empty
      PtrTy
    TypeDef
      Ident "GenericPtr"
      Empty
      PtrTy
        Bracket
          Ident "int"
    TypeDef
      Ident "PrefixPtr"
      Empty
      PtrTy
        Ident "int"
    TypeDef
      Ident "PtrTuple"
      Empty
      PtrTy
        TupleConstr
          Ident "int"
          Ident "string"
    TypeDef
      Ident "BareRef"
      Empty
      RefTy
    TypeDef
      Ident "GenericRef"
      Empty
      RefTy
        Bracket
          Ident "int"
    TypeDef
      Ident "RefTupleCl"
      Empty
      RefTy
        TupleTy
    TypeDef
      Ident "RefTupleType"
      Empty
      RefTy
        TupleConstr
          Ident "int"
          Ident "string"
    TypeDef
      Ident "RefTupleVars"
      Empty
      RefTy
        TupleConstr
          Ident "a"
          Ident "b"
    TypeDef
      Ident "BareStatic"
      Empty
      Ident "static"
    TypeDef
      Ident "GenericStatic"
      Empty
      BracketExpr
        Ident "static"
        Ident "int"
    TypeDef
      Ident "PrefixStatic"
      Empty
      Command
        Ident "static"
        Ident "int"
    TypeDef
      Ident "StaticTupleCl"
      Empty
      Command
        Ident "static"
        TupleClassTy
    TypeDef
      Ident "StaticTuple"
      Empty
      Command
        Ident "static"
        TupleConstr
          Ident "int"
          Ident "string"
    TypeDef
      Ident "BareType"
      Empty
      Ident "type"
    TypeDef
      Ident "GenericType"
      Empty
      BracketExpr
        Ident "type"
        Ident "float"
    TypeDef
      Ident "TypeTupleGen"
      Empty
      BracketExpr
        Ident "type"
        TupleClassTy
    TypeDef
      Ident "TypeTupleCl"
      Empty
      Command
        Ident "type"
        TupleClassTy
    TypeDef
      Ident "TypeInstance"
      Empty
      Command
        Ident "type"
        BracketExpr
          Ident "Foo"
          RefTy
    TypeDef
      Ident "bareTypeDesc"
      Empty
      Ident "typedesc"
    TypeDef
      Ident "TypeOfVar"
      Empty
      Call
        Ident "type"
        Ident "a"
    TypeDef
      Ident "TypeOfVarAlt"
      Empty
      Command
        Ident "type"
        Par
          Ident "a"
    TypeDef
      Ident "TypeOfTuple1"
      Empty
      Call
        Ident "type"
        Ident "a"
    TypeDef
      Ident "TypeOfTuple2"
      Empty
      Call
        Ident "type"
        Ident "a"
        Ident "b"
    TypeDef
      Ident "TypeOfTuple1A"
      Empty
      Command
        Ident "type"
        TupleConstr
          Ident "a"
    TypeDef
      Ident "TypeOfTuple2A"
      Empty
      Command
        Ident "type"
        TupleConstr
          Ident "a"
          Ident "b"
    TypeDef
      Ident "TypeTuple"
      Empty
      Command
        Ident "type"
        TupleConstr
          Ident "int"
          Ident "string"
    TypeDef
      Ident "GenericTypedesc"
      Empty
      BracketExpr
        Ident "typedesc"
        Ident "int"
    TypeDef
      Ident "T"
      Empty
      Ident "type"
  ProcDef
    Ident "foo"
    Empty
    Empty
    FormalParams
      Ident "type"
      IdentDefs
        Ident "bareType"
        Ident "type"
        Empty
      IdentDefs
        Ident "genType"
        BracketExpr
          Ident "type"
          Ident "int"
        Empty
      IdentDefs
        Ident "typeInt"
        Command
          Ident "type"
          Ident "int"
        Empty
      IdentDefs
        Ident "typeIntAlt"
        Call
          Ident "type"
          Ident "int"
        Empty
      IdentDefs
        Ident "typeOfVar"
        Call
          Ident "type"
          Ident "a"
        Empty
      IdentDefs
        Ident "typeDotType"
        DotExpr
          Ident "foo"
          Ident "type"
        Empty
      IdentDefs
        Ident "typeTupleCl"
        Command
          Ident "type"
          TupleClassTy
        Empty
      IdentDefs
        Ident "bareStatic"
        Ident "static"
        Empty
      IdentDefs
        Ident "genStatic"
        BracketExpr
          Ident "static"
          Ident "int"
        Empty
      IdentDefs
        Ident "staticInt"
        Command
          Ident "static"
          Ident "int"
        Empty
      IdentDefs
        Ident "staticVal1"
        Command
          Ident "static"
          IntLit 10
        Empty
      IdentDefs
        Ident "staticVal2"
        Call
          Ident "static"
          StrLit "str"
        Empty
      IdentDefs
        Ident "staticVal3"
        Command
          Ident "static"
          StrLit "str"
        Empty
      IdentDefs
        Ident "staticVal4"
        CallStrLit
          Ident "static"
          RStrLit "str"
        Empty
      IdentDefs
        Ident "staticDotVal"
        DotExpr
          IntLit 10
          Ident "static"
        Empty
      IdentDefs
        Ident "bareRef"
        RefTy
        Empty
      IdentDefs
        Ident "refTuple1"
        RefTy
          Par
            Ident "int"
        Empty
      IdentDefs
        Ident "refTuple1A"
        RefTy
          TupleConstr
            Ident "int"
        Empty
      IdentDefs
        Ident "refTuple2"
        RefTy
          TupleConstr
            Ident "int"
            Ident "string"
        Empty
      IdentDefs
        Ident "genRef"
        RefTy
          Bracket
            Ident "int"
        Empty
      IdentDefs
        Ident "refInt"
        RefTy
          Ident "int"
        Empty
      IdentDefs
        Ident "refCall"
        RefTy
          Par
            Ident "a"
        Empty
      IdentDefs
        Ident "macroCall1"
        Command
          Ident "foo"
          Ident "bar"
        Empty
      IdentDefs
        Ident "macroCall2"
        Call
          Ident "foo"
          Ident "bar"
        Empty
      IdentDefs
        Ident "macroCall3"
        Call
          DotExpr
            Ident "foo"
            Ident "bar"
          Ident "baz"
        Empty
      IdentDefs
        Ident "macroCall4"
        Call
          BracketExpr
            Ident "foo"
            Ident "bar"
          Ident "baz"
        Empty
      IdentDefs
        Ident "macroCall5"
        Command
          Ident "foo"
          Command
            Ident "bar"
            Ident "baz"
        IntLit 10
    Empty
    Empty
    StmtList
      Asgn
        Ident "staticTen"
        Command
          Ident "static"
          IntLit 10
      Asgn
        Ident "staticA"
        Call
          Ident "static"
          Ident "a"
      Asgn
        Ident "staticCall"
        Command
          Ident "static"
          Call
            Ident "foo"
            IntLit 1
      Asgn
        Ident "staticStrCall"
        Command
          Ident "static"
          CallStrLit
            Ident "foo"
            RStrLit "x"
      Asgn
        Ident "staticChainCall"
        Command
          Ident "static"
          Command
            Ident "foo"
            Ident "bar"
      Asgn
        Ident "typeTen"
        Command
          Ident "type"
          IntLit 10
      Asgn
        Ident "typeA"
        Call
          Ident "type"
          Ident "a"
      Asgn
        Ident "typeCall"
        Command
          Ident "type"
          Call
            Ident "foo"
            IntLit 1
      Asgn
        Ident "typeStrCall"
        Command
          Ident "type"
          CallStrLit
            Ident "foo"
            RStrLit "x"
      Asgn
        Ident "typeChainCall"
        Command
          Ident "type"
          Command
            Ident "foo"
            Ident "bar"
      Asgn
        Ident "normalChainCall"
        Command
          Ident "foo"
          Command
            Ident "bar"
            Ident "baz"
      Asgn
        Ident "normalTupleCall2"
        Call
          Ident "foo"
          Ident "a"
          Ident "b"
      StaticStmt
        StmtList
          Ident "singleStaticStmt"
      StaticStmt
        StmtList
          Ident "staticStmtList1"
          Ident "staticStmtList2"
'''
"""

import macros

dumpTree:
  type
    BarePtr       = ptr
    GenericPtr    = ptr[int]
    PrefixPtr     = ptr int
    PtrTuple      = ptr (int, string)
    BareRef       = ref
    GenericRef    = ref[int]
    RefTupleCl    = ref tuple
    RefTupleType  = ref (int, string)
    RefTupleVars  = ref (a, b)
    BareStatic    = static                # Used to be Error: invalid indentation
    GenericStatic = static[int]
    PrefixStatic  = static int
    StaticTupleCl = static tuple
    StaticTuple   = static (int, string)
    BareType      = type
    GenericType   = type[float]
    TypeTupleGen  = type[tuple]
    TypeTupleCl   = type tuple            # Used to be Error: invalid indentation
    TypeInstance  = type Foo[ref]
    bareTypeDesc  = typedesc
    TypeOfVar     = type(a)
    TypeOfVarAlt  = type (a)              # Used to be Error: invalid indentation
    TypeOfTuple1  = type(a,)
    TypeOfTuple2  = type(a,b)
    TypeOfTuple1A = type (a,)             # Used to be Error: invalid indentation
    TypeOfTuple2A = type (a,b)            # Used to be Error: invalid indentation
    TypeTuple     = type (int, string)    # Used to be Error: invalid indentation
    GenericTypedesc = typedesc[int]
    T = type

  proc foo(
    bareType        : type,
    genType         : type[int],
    typeInt         : type int,
    typeIntAlt      : type(int),
    typeOfVar       : type(a),
    typeDotType     : foo.type,
    typeTupleCl     : type tuple,         # Used to be Error: ')' expected
    bareStatic      : static,             # Used to be Error: expression expected, but found ','
    genStatic       : static[int],
    staticInt       : static int,
    staticVal1      : static 10,
    staticVal2      : static("str"),
    staticVal3      : static "str",
    staticVal4      : static"str",        # Used to be Error: expression expected, but found 'str'
    staticDotVal    : 10.static,
    bareRef         : ref,
    refTuple1       : ref (int),
    refTuple1A      : ref (int,),
    refTuple2       : ref (int,string),
    genRef          : ref[int],
    refInt          : ref int,
    refCall         : ref(a),
    macroCall1      : foo bar,
    macroCall2      : foo(bar),
    macroCall3      : foo.bar(baz),
    macroCall4      : foo[bar](baz),
    macroCall5      : foo bar baz = 10
  ): type =
    staticTen       = static 10
    staticA         = static(a)
    # staticAspace    = static (a)          # With newTypedesc: Error: invalid indentation
    # staticAtuple    = static (a,)         # With newTypedesc: Error: invalid indentation
    # staticTuple     = static (a,b)        # With newTypedesc: Error: invalid indentation
    # staticTypeTuple = static (int,string) # With newTypedesc: Error: invalid indentation
    staticCall      = static foo(1)
    staticStrCall   = static foo"x"
    staticChainCall = static foo bar

    typeTen         = type 10
    typeA           = type(a)
    # typeAspace    = type (a)            # Error: invalid indentation
    # typeAtuple    = type (a,)           # Error: invalid indentation
    # typeTuple     = type (a,b)          # Error: invalid indentation
    # typeTypeTuple = type (int,string)   # Error: invalid indentation
    typeCall        = type foo(1)
    typeStrCall     = type foo"x"
    typeChainCall   = type foo bar

    normalChainCall = foo bar baz
    # normalTupleCall1 = foo(a,)          # Error: invalid indentation
    normalTupleCall2 = foo(a,b)
    # normalTupleCall3 = foo (a,b)        # Error: invalid indentation

    static: singleStaticStmt
    static:
      staticStmtList1
      staticStmtList2
