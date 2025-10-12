# included from nifdecoder.nim

proc expect(n: var Cursor; k: NifKind) =
  if n.kind == k:
    inc n
  else:
    when defined(debug):
      writeStackTrace()
    quit "[NIF decoder] expected: " & $k & " but got: " & $n.kind & toString n

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
  of tyFromExpr, tyEnum:
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
    when true:
      assert result != nil
    else:
      if result == nil:
        let symA = c.syms.getOrDefault(s).sym
        if symA != nil:
          assert symA.kind == skType
          result = symA.typ
        else:
          result = loadType(s, c)
          c.types[s] = LoadedType(state: Loaded, typ: result)
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
