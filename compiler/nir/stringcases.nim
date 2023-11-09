#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## included from ast2ir.nim

#[

case s
of "abc", "abbd":
  echo 1
of "hah":
  echo 2
of "gah":
  echo 3

# we produce code like this:

if s[0] <= 'a':
  if s == "abc: goto L1
  elif s == "abbd": goto L1
else:
  if s[2] <= 'h':
    if s == "hah": goto L2
    elif s == "gah": goto L3
goto afterCase

L1:
  echo 1
  goto afterCase
L2:
  echo 2
  goto afterCase
L3:
  echo 3
  goto afterCase

afterCase: ...

]#

# We split the set of strings into 2 sets of roughly the same size.
# The condition used for splitting is a (position, char) tuple.
# Every string of length > position for which s[position] <= char is in one
# set else it is in the other set.

from std/sequtils import addUnique

type
  Key = (LitId, LabelId)

proc splitValue(strings: BiTable[string]; a: openArray[Key]; position: int): (char, float) =
  var cand: seq[char] = @[]
  for t in items a:
    let s = strings[t[0]]
    if s.len > position: cand.addUnique s[position]

  result = ('\0', -1.0)
  for disc in items cand:
    var hits = 0
    for t in items a:
      let s = strings[t[0]]
      if s.len > position and s[position] <= disc:
        inc hits
    # the split is the better, the more `hits` is close to `a.len / 2`:
    let grade = 100000.0 - abs(hits.float - a.len.float / 2.0)
    if grade > result[1]:
      result = (disc, grade)

proc tryAllPositions(strings: BiTable[string]; a: openArray[Key]): (char, int) =
  var m = 0
  for t in items a:
    m = max(m, strings[t[0]].len)

  result = ('\0', -1)
  var best = -1.0
  for i in 0 ..< m:
    let current = splitValue(strings, a, i)
    if current[1] > best:
      best = current[1]
      result = (current[0], i)

type
  SearchKind = enum
    LinearSearch, SplitSearch
  SearchResult* = object
    case kind: SearchKind
    of LinearSearch:
      a: seq[Key]
    of SplitSearch:
      span: int
      best: (char, int)

proc emitLinearSearch(strings: BiTable[string]; a: openArray[Key]; dest: var seq[SearchResult]) =
  var d = SearchResult(kind: LinearSearch, a: @[])
  for x in a: d.a.add x
  dest.add d

proc split(strings: BiTable[string]; a: openArray[Key]; dest: var seq[SearchResult]) =
  if a.len <= 4:
    emitLinearSearch strings, a, dest
  else:
    let best = tryAllPositions(strings, a)
    var groupA: seq[Key] = @[]
    var groupB: seq[Key] = @[]
    for t in items a:
      let s = strings[t[0]]
      if s.len > best[1] and s[best[1]] <= best[0]:
        groupA.add t
      else:
        groupB.add t
    if groupA.len == 0 or groupB.len == 0:
      emitLinearSearch strings, a, dest
    else:
      let toPatch = dest.len
      dest.add SearchResult(kind: SplitSearch, span: 1, best: best)
      split strings, groupA, dest
      split strings, groupB, dest
      let dist = dest.len - toPatch
      assert dist > 0
      dest[toPatch].span = dist

proc toProblemDescription(c: var ProcCon; n: PNode): (seq[Key], LabelId) =
  result = (@[], newLabels(c.labelGen, n.len))
  assert n.kind == nkCaseStmt
  for i in 1..<n.len:
    let it = n[i]
    let thisBranch = LabelId(result[1].int + i - 1)
    if it.kind == nkOfBranch:
      for j in 0..<it.len-1:
        assert it[j].kind in {nkStrLit..nkTripleStrLit}
        result[0].add (c.lit.strings.getOrIncl(it[j].strVal), thisBranch)

proc decodeSolution(c: var ProcCon; dest: var Tree; s: seq[SearchResult]; i: int;
                    selector: Value; info: PackedLineInfo) =
  case s[i].kind
  of SplitSearch:
    let thenA = i+1
    let elseA = thenA + (if s[thenA].kind == LinearSearch: 1 else: s[thenA].span)
    let best = s[i].best

    let tmp = getTemp(c, Bool8Id, info)
    buildTyped dest, info, Asgn, Bool8Id:
      dest.copyTree tmp
      buildTyped dest, info, Call, Bool8Id:
        c.addUseCodegenProc dest, "nimStrAtLe", info
        dest.copyTree selector
        dest.addIntVal c.lit.numbers, info, c.m.nativeIntId, best[1]
        dest.addIntVal c.lit.numbers, info, Char8Id, best[0].int

    template then() =
      c.decodeSolution dest, s, thenA, selector, info
    template otherwise() =
      c.decodeSolution dest, s, elseA, selector, info
    buildIfThenElse tmp, then, otherwise
    freeTemp c, tmp

  of LinearSearch:
    let tmp = getTemp(c, Bool8Id, info)
    for x in s[i].a:
      buildTyped dest, info, Asgn, Bool8Id:
        dest.copyTree tmp
        buildTyped dest, info, Call, Bool8Id:
          c.addUseCodegenProc dest, "eqStrings", info
          dest.copyTree selector
          dest.addStrLit info, x[0]
      buildIf tmp:
        c.code.gotoLabel info, Goto, x[1]
    freeTemp c, tmp

proc genStringCase(c: var ProcCon; n: PNode; d: var Value) =
  let (problem, firstBranch) = toProblemDescription(c, n)
  var solution: seq[SearchResult] = @[]
  split c.lit.strings, problem, solution

  # XXX Todo move complex case selector into a temporary.
  let selector = c.genx(n[0])

  let info = toLineInfo(c, n.info)
  decodeSolution c, c.code, solution, 0, selector, info

  let lend = newLabel(c.labelGen)
  c.code.addLabel info, Goto, lend
  for i in 1..<n.len:
    let it = n[i]
    let thisBranch = LabelId(firstBranch.int + i - 1)
    c.code.addLabel info, Label, thisBranch
    if it.kind == nkOfBranch:
      gen(c, it.lastSon, d)
      c.code.addLabel info, Goto, lend
    else:
      gen(c, it.lastSon, d)

  c.code.addLabel info, Label, lend
  freeTemp c, selector
