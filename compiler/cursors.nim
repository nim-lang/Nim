#
#
#           The Nim Compiler
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents, trees,
  strutils, options, dfa, lowerings, tables, modulegraphs, msgs,
  lineinfos, parampatterns

##[
This module implements "cursor" detection. A cursor is a local variable
that is used for navigation in a datastructure, it does not "own" the
data it aliases but it might update the underlying datastructure.

Two primary examples for cursors that I have in mind and that are critical
for optimization:

1. Local string variable introduced by ``for x in a``::

  var i = 0
  while i < a.len:
    let cursor = a[i]
    use cursor
    inc i

2. Local ``ref`` variable for navigation::

  var cursor = listHead
  while cursor != nil:
    use cursor
    cursor = cursor.next

Cursors are very interesting for the optimizer because they can be copyMem'ed
and don't need a destructor.

More formally, a cursor is a variable that is set on all paths to
a *location* or a proc call that produced a ``lent/var`` type. All statements
that come after these assignments MUST not mutate what the cursor aliases.

Mutations *through* the cursor are allowed if the cursor has ref semantics.

Look at this complex real world example taken from the compiler itself:

.. code-block:: Nim

  proc getTypeName(m: BModule; typ: PType; sig: SigHash): Rope =
    var t = typ
    while true:
      if t.sym != nil and {sfImportc, sfExportc} * t.sym.flags != {}:
        return t.sym.loc.r

      if t.kind in irrelevantForBackend:
        t = t.lastSon
      else:
        break
    let typ = if typ.kind in {tyAlias, tySink, tyOwned}: typ.lastSon else: typ
    if typ.loc.r == nil:
      typ.loc.r = typ.typeName & $sig
    result = typ.loc.r
    if result == nil: internalError(m.config, "getTypeName: " & $typ.kind)

Here `t` is a cursor but without a control flow based analysis we are unlikely
to detect it.

]##

# Araq: I owe you an implementation. For now use the .cursor pragma. :-/
