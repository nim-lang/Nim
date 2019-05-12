#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Default ref implementation used by Nim's core.

# We cannot use the allocator interface here as we require a heap walker to
# exist. Thus we import 'alloc' directly here to get our own heap that is
# all under the GC's control and can use the ``allObjects`` iterator which
# is crucial for the "sweep" phase.
import typelayouts, alloc

type
  TracingGc = ptr object of Allocator
    visit*: proc (fieldAddr: ptr pointer; a: Allocator) {.nimcall.}

  GcColor = enum
    white = 0, black = 1, grey = 2 ## to flip the meaning of white/black
                                   ## perform (1 - col)

  GcHeader = object
    t: ptr TypeLayout
    color: GcColor
  Cell = ptr GcHeader

  GcFrame {.core.} = object
    prev: ptr GcFrame
    marker: proc (self: GcFrame; a: Allocator)

  Phase = enum
    None, Marking, Sweeping

  GcHeap = object
    r: MemRegion
    phase: Phase
    currBlack, currWhite: GcColor
    greyStack: seq[Cell]

var
  gch {.threadvar, compilerProc.}: GcHeap

proc `=trace`[T](a: ref T) =
  if not marked(a):
    mark(a)
    `=trace`(a[])

template usrToCell(p: pointer): Cell =

template cellToUsr(cell: Cell): pointer =
  cast[pointer](cast[ByteAddress](cell)+%ByteAddress(sizeof(GcHeader)))

template usrToCell(usr: pointer): Cell =
  cast[Cell](cast[ByteAddress](usr)-%ByteAddress(sizeof(GcHeader)))

template markGrey(x: Cell) =
  if x.color == gch.currWhite and phase == Marking:
    x.color = grey
    add(gch.greyStack, x)

proc `=`[T](dest: var ref T; src: ref T) =
  ## full write barrier implementation.
  if src != nil:
    let s = usrToCell(src)
    markGrey(s)
  system.`=`(dest, src)

proc linkGcFrame(f: ptr GcFrame) {.core.}
proc unlinkGcFrame() {.core.}

proc setGcFrame(f: ptr GcFrame) {.core.}

proc registerGlobal(p: pointer; t: ptr TypeLayout) {.core.}
proc unregisterGlobal(p: pointer; t: ptr TypeLayout) {.core.}

proc registerThreadvar(p: pointer; t: ptr TypeLayout) {.core.}
proc unregisterThreadvar(p: pointer; t: ptr TypeLayout) {.core.}

proc newImpl(t: ptr TypeLayout): pointer =
  let r = cast[Cell](rawAlloc(t.size + sizeof(GcHeader)))
  r.typ = t
  result = r +! sizeof(GcHeader)

template new*[T](x: var ref T) =
  x = newImpl(getTypeLayout(x))


when false:
  # implement these if your GC requires them:
  proc writeBarrierLocal() {.core.}
  proc writeBarrierGlobal() {.core.}

  proc writeBarrierGeneric() {.core.}
