
#
#
#           The Nim Compiler
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Computes MD5 digest of symbol's type signature and implementation body.
## The implmentation differs from the one used in the compiler internally,
## as proc and vars body are recursively hashed as well. Hence changes in
## underlying symbols proporate up the calling tree.
##
## Such digest is rather useful building block in implementing incremental
## computations. Papers on this topic:
## http://en.wikipedia.org/wiki/Incremental_computing
## http://www.cs.umd.edu/~mwh/papers/nominal-adapton-tr.pdf
##
## Strictly not a sempass plugin as it is used in VM, not in the semantic pass.

import ".." / [pluginsupport, ast, astalgo,
  magicsys, semdata, sighashes, msgs, renderer, modulegraphs]

import tables, md5

template `&=`[T: SomeNumber|char](c: var MD5Context, v: T) =
  md5Update(c, cast[cstring](unsafeAddr(v)), sizeof(v))

template `&=`(c: var MD5Context, v: enum) =
  var tmp = char(v)
  c &= tmp

template `&=`(c: var MD5Context, v: openarray[char]) =
  md5Update(c, v, v.len)

proc hashTree(c: var MD5Context, n: PNode)
proc procSymDigest(sym: PSym): MD5Digest

proc hashNonProcSym(c: var MD5Context, s: PSym) =
  var it = s
  while it != nil:
    c &= it.name.s
    c &= "."
    it = it.owner

proc hashVarSym(c: var MD5Context, s: PSym) =
  assert: s.kind in {skParam, skResult, skVar, skLet, skConst, skForVar}
  if sfGlobal notin s.flags:
    c &= s.kind
    c &= s.name.s
  else:
    hashNonProcSym(c, s)
    # this one works for let and const but not for var. True variables can change value
    # later on. it is user resposibility to hash his global state if required
    if s.ast != nil and s.ast.kind == nkIdentDefs:
      hashTree(c, s.ast[^1])
    else:
      hashTree(c, s.ast)

proc hashTree(c: var MD5Context, n: PNode) =
  if n == nil:
    c &= "nil"
    return

  c &= n.kind
  case n.kind
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    c &= n.ident.s
  of nkSym:
    if n.sym.kind in skProcKinds:
      c &= $procSymDigest(n.sym)
    elif n.sym.kind in {skParam, skResult, skVar, skLet, skConst, skForVar}:
      c.hashVarSym(n.sym)
    else:
      c.hashNonProcSym(n.sym)
  of nkProcDef, nkFuncDef, nkTemplateDef, nkMacroDef:
    discard # we track usage of proc symbols not their definition
  of nkCharLit..nkUInt64Lit:
    c &= n.intVal
  of nkFloatLit..nkFloat64Lit:
    c &= n.floatVal
  of nkStrLit..nkTripleStrLit:
    c &= n.strVal
  else:
    for i in 0..<n.len:
      hashTree(c, n.sons[i])

var procSymHashes {.global.} = initTable[int, MD5Digest](2)
  ## Global cache of proc sym digest is used as
  ## they same procs are used over and over again.

proc procSymDigest(sym: PSym): MD5Digest =
  ## compute unique digest of the proc/func/method symbols
  ## recursing into invoked symbols as well
  assert(sym.kind in skProcKinds, $sym.kind)

  procSymHashes.withValue(sym.id, value):
    return value[]

  var c: MD5Context
  md5Init(c)
  c.hashType(sym.typ, {CoProc})
  c &= sym.kind
  c.md5Final(result)
  procSymHashes[sym.id] = result # protect from recursion in the body

  if sym.ast != nil:
    md5Init(c)
    c.md5Update(cast[cstring](result.addr), sizeof(result))
    c.hashTree(sym.ast[bodyPos])
    c.md5Final(result)
    procSymHashes[sym.id] = result

proc symBodyDigest*(g: ModuleGraph, n: PNode): PNode =
  ## compute symbol implementation digest
  ## MD5 digest returned as string

  assert: n.kind == nkSym
  result = newNodeIT(nkStrLit, n.info, getSysType(g, n.info, tyString))
  result.strVal =
    case n.sym.kind
      of skProcKinds: $procSymDigest(n.sym)
      else:
        var c: MD5Context
        md5Init(c)
        c.hashTree(n)
        var digest: MD5Digest
        c.md5Final(digest)
        $digest
