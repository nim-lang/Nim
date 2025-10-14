# included from nifdecoder.nim

proc expect(n: var Cursor; k: NifKind) =
  if n.kind == k:
    inc n
  else:
    when defined(debug):
      writeStackTrace()
    quit "[NIF decoder] expected: " & $k & " but got: " & $n.kind & toString n

const SysTypeKinds = {tyBool, tyChar, tyString, tyInt .. tyUInt64}

proc getSysTypeSym(c: var DecodeContext; typeKind: TTypeKind): PSym =
  assert typeKind in SysTypeKinds
  if typeKind in c.sysTypes:
    result = c.sysTypes[typeKind]
  else:
    let ident = c.graph.cache.getIdent(toNifTag typeKind)
    result = newSym(skType, ident, c.idgen, c.owner, unknownLineInfo)
    var typ = newType(typeKind, c.idgen, nil)
    typ.sym = result
    result.typ = typ
    c.sysTypes[typeKind] = result

proc getSysType(c: var DecodeContext; typeKind: TTypeKind): PType =
  # This will be replaced with magicsys.getSysType
  assert typeKind in SysTypeKinds
  getSysTypeSym(c, typeKind).typ

proc readTypeKind(n: var Cursor; tag: string): TTypeKind =
  if tag.len == 1:
    case tag[0]
    of 'i':
      inc n
      assert n.kind == IntLit
      case pool.integers[n.intId]
      of -1: result = tyInt
      of 8: result = tyInt8
      of 16: result = tyInt16
      of 32: result = tyInt32
      of 64: result = tyInt64
      else: assert false
      inc n
    of 'u':
      inc n
      assert n.kind == IntLit
      case pool.integers[n.intId]
      of -1: result = tyUInt
      of 8: result = tyUInt8
      of 16: result = tyUInt16
      of 32: result = tyUInt32
      of 64: result = tyUInt64
      else: assert false
      inc n
    of 'f':
      inc n
      assert n.kind == IntLit
      case pool.integers[n.intId]
      of -1: result = tyFloat
      of 32: result = tyFloat32
      of 64: result = tyFloat64
      else: assert false
      inc n
    of 'c':
      inc n
      assert n.kind == IntLit
      case pool.integers[n.intId]
      of 8: result = tyChar
      else: assert false
      inc n
    else:
      result = parseTypeKind(tag)
      inc n
  else:
    result = parseTypeKind(tag)
    inc n

proc fromNifTypeImpl(c: var DecodeContext; n: var Cursor; kind: TTypeKind; res: PType) =
  case kind
  of tyEnum:
    res.n = newNode(nkEnumTy)
    while n.kind != ParRi:
      var sym = fromNifSymDef(c, n, nkEnumTy)
      sym.sym.typ = res
      res.n.add sym
    expect n, ParRi
  of tyFromExpr:
    res.n = fromNif(c, n)
  of tyStatic:
    res.addAllowNil fromNifType(c, n)
    res.n = fromNif(c, n)
  of tyObject:
    # inheritance:
    res.addAllowNil fromNifType(c, n)
    res.n = fromNif(c, n)
  else:
    while n.kind != ParRi:
      res.addAllowNil fromNifType(c, n)
    expect n, ParRi

proc fromNifType(c: var DecodeContext; n: var Cursor): PType =
  case n.kind
  of Symbol:
    let s = n.symId
    result = c.types.getOrDefault(s)
    if result == nil:
      let symA = c.nifSymToPSym.getOrDefault(s)
      if symA != nil:
        assert symA.kind == skType
        result = symA.typ
      assert symA != nil
      #[
      else:
        result = loadType(s, c)
        c.types[s] = LoadedType(state: Loaded, typ: result)
      ]#
    inc n
  of ParLe:
    let tag = pool.tags[n.tag]
    if tag == "missing":
      result = nil
    else:
      let k = readTypeKind(n, tag)
      if k in SysTypeKinds:
        result = getSysType(c, k)
      else:
        #echo "Create non SysTypeKinds type: ", k, ": ", tag
        result = newType(k, c.idgen, c.owner)
      if n.kind == ParLe and pool.tags[n.tag] == "tf":
        inc n
        if n.kind == Ident:
          result.flags = parseTypeFlags pool.strings[n.litId]
          inc n
        else:
          expect n, Ident
        expect n, ParRi
      fromNifTypeImpl c, n, k, result
  else:
    expect n, ParLe
