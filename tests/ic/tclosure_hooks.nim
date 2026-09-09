discard """
  description: '''IC vs `nim c`: closure environments, their hooks and their owners'''
"""

#? metamorphic

# A closure's environment type — and the `=destroy`/`=copy` the compiler lifts
# for it — is minted by the BACKEND, during the `lower` stage, and exists in no
# module's semmed NIF. The per-module backend has to decide which translation
# unit emits such a routine, and the owner walk it uses lands on the module of
# the ORIGINAL generic: for a generic closure iterator defined in one module and
# instantiated in another, that is a module which never sees the instance, so the
# env's `=destroy` was emitted by nobody (`undefined reference to
# eqdestroy__c485__…`). Every referencing TU emits it now.
#
# The steps then move the captured state around, because the env's LAYOUT is what
# decides whether those hooks are trivial: a body-only edit that adds a capture
# changes the env type of a routine whose importers do not re-sem.

#!FILE clleaf.nim
type Ev* = proc (s: string): string {.closure.}

proc leafMaker*(tag: string): Ev =
  var n = 0
  proc outer(s: string): string =
    proc inner(t: string): string =
      inc n
      tag & ":" & t & ":" & $n
    inner(s)
  result = outer

iterator leafIter*[T](xs: seq[T]): T {.closure.} =
  for x in xs: yield x

#!FILE clmid.nim
import clleaf

proc midMaker*(tag: string): Ev =
  let base = leafMaker(tag & "/mid")
  var calls = 0
  result = proc (s: string): string =
    inc calls
    base(s) & "#" & $calls

proc midIter*(): seq[string] =
  # instantiates `leafIter[string]` HERE, not where it is defined
  result = @[]
  for x in leafIter(@["p", "q"]): result.add x

#!FILE main.nim
import clleaf, clmid

let t = midMaker("top")
echo t("Alpha")
echo t("Beta")
echo midIter()

# an instance only the main module has
var fs: seq[float] = @[]
for x in leafIter(@[1.5, 2.5]): fs.add x
echo fs
#!STEP

# body-only edit that GROWS the environment: a second captured local
#!FILE clleaf.nim
type Ev* = proc (s: string): string {.closure.}

proc leafMaker*(tag: string): Ev =
  var n = 0
  var seen: seq[string] = @[]
  proc outer(s: string): string =
    proc inner(t: string): string =
      inc n
      seen.add t
      tag & ":" & t & ":" & $n & ":" & $seen.len
    inner(s)
  result = outer

iterator leafIter*[T](xs: seq[T]): T {.closure.} =
  var i = 0
  for x in xs:
    inc i
    yield x
#!STEP

# and shrink it again
#!FILE clleaf.nim
type Ev* = proc (s: string): string {.closure.}

proc leafMaker*(tag: string): Ev =
  var n = 0
  proc outer(s: string): string =
    proc inner(t: string): string =
      inc n
      tag & ":" & t & ":" & $n
    inner(s)
  result = outer

iterator leafIter*[T](xs: seq[T]): T {.closure.} =
  for x in xs: yield x
#!STEP
