type
  CheckRedeclsContext = object
    config: ConfigRef
    scopes: seq[TStrTable]

const nkOpenScopeKinds = {nkProcDef, nkMethodDef, nkConverterDef, nkOfBranch, nkElifBranch, nkExceptBranch,
                          nkElse, nkIfStmt, nkForStmt, nkWhileStmt, nkCaseStmt, nkTryStmt,
                          nkFinally, nkBlockStmt, nkBlockExpr}

proc semCheckRedeclsImpl(c: var CheckRedeclsContext; n: PNode) =
  if isAtom(n):
    discard
  elif n.kind in {nkVarSection, nkLetSection}:
    for i in 0..<n.len:
      let n2 = n[i]
      if n2.kind == nkIdentDefs:
        for j in 0 ..< (n2.len - 2):
          if n2[j].kind == nkSym:
            let sym = n2[j].sym
            if c.scopes[^1].strTableContains(sym):
              localError(c.config, sym.info, errGenerated,
                "Declaration of '$1' is duplicated by template or macro and their scopes are overlapping" % [sym.name.s])
            else:
              strTableAdd(c.scopes[^1], sym)

        # n2[^1] is an initializer can have var/let sections
        semCheckRedeclsImpl(c, n2[^1])
  elif n.kind == nkTypeOfExpr or (n.kind == nkCall and n.len > 0 and (let i = n[0].getPIdent; i != nil and i.s == "typeof")):
    #[
      ```nim
      proc foo =
        var a = 0
        discard typeof((var a = 0; a))(1)
      ```
      Above code fail to compile as `var a = 0` in `typeof` actually declares `a`.
      But this proc ignores var sections in `typeof` because there are templates likes:
      ```nim
        template foo(x: typed) =
          discard x
          discard typeof(x)(1)

        proc bar =
          foo((var a = 0; a))
      ```
    ]#
    discard
  else:
    let isOpenScope = n.kind in nkOpenScopeKinds
    if isOpenScope:
      c.scopes.add initStrTable()

    when false:
      if n.kind == nkProcDef and n[0].kind == nkSym and n[0].sym.name.s == "bar":
        debug(n[bodyPos])
        #echo renderTree(n[bodyPos])

    for i in 0..<n.len:
      semCheckRedeclsImpl(c, n[i])

    if isOpenScope:
      discard c.scopes.pop

proc semCheckRedecls(c: PContext; n: PNode) =
  var ctx = CheckRedeclsContext(config: c.config,
    scopes: newSeqOfCap[TStrTable](8))
  ctx.scopes.add initStrTable()
  semCheckRedeclsImpl(ctx, n)
