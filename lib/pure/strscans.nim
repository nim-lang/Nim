#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##[
This module contains a `scanf`:idx: macro that can be used for extracting
substrings from an input string. This is often easier than regular expressions.
Some examples as an apetizer:

.. code-block:: nim
  # check if input string matches a triple of integers:
  const input = "(1,2,4)"
  var x, y, z: int
  if scanf("($i,$i,$i)", input, x, y, z):
    echo "matches and x is ", x, " y is ", y, " z is ", z

  # check if input string matches an ISO date followed by an identifier followed
  # by whitespace and a floating point number:
  var year, month, day: int
  var identifier: string
  var myfloat: float
  if scanf("$i-$i-$i $w$s$f", input, year, month, day, identifier, myfloat):
    echo "yes, we have a match!"

As can be seen from the examples, strings are matched verbatim except for
substrings starting with ``$``. These constructions are available:

=================   ========================================================
``$i``              Matches an integer. This uses ``parseutils.parseInt``.
``$f``              Matches a floating pointer number. Uses ``parseFloat``.
``$w``              Matches an ASCII identifier: ``[A-Z-a-z_][A-Za-z_0-9]*``.
``$s``              Skips optional whitespace.
``$$``              Matches a single dollar sign.
``$.``              Matches if the end of the input string has been reached.
``$*``              Matches until the token following the ``$*`` was found.
                    The match is allowed to be of 0 length.
``$+``              Matches until the token following the ``$+`` was found.
                    The match must consist of at least one char.
``${foo}``          User defined matcher. Uses the proc ``foo`` to perform
                    the match. See below for more details.
``$[foo]``          Call user defined proc ``foo`` to **skip** some optional
                    parts in the input string. See below for more details.
=================   ========================================================

Even though ``$*`` and ``$+`` look similar to the regular expressions ``.*``
and ``.+`` they work quite differently, there is no non-deterministic
state machine involved and the matches are non-greedy. ``[$*]``
matches ``[xyz]`` via ``parseutils.parseUntil``.

Furthermore no backtracking is performed, if parsing fails after a value
has already been bound to a matched subexpression this value is not restored
to its original value. This rarely causes problems in practice and if it does
for you, it's easy enough to bind to a temporary variable first.


Startswith vs full match
========================

``scanf`` returns true if the input string **starts with** the specified
pattern. If instead it should only return true if theres is also nothing
left in the input, append ``$.`` to your pattern.


User definable matchers
=======================

One very nice advantage over regular expressions is that ``scanf`` is
extensible with ordinary Nim procs. The proc is either enclosed in ``${}``
or in ``$[]``. ``${}`` matches and binds the result
to a variable (that was passed to the ``scanf`` macro) while ``$[]`` merely
optional tokens.


In this example, we define a helper proc ``skipSep`` that skips some separators
which we then use in our scanf pattern to help us in the matching process:

.. code-block:: nim

  proc someSep(input: string; start: int; seps: set[char] = {':','-','.'}): int =
    # Note: The parameters and return value must match to what ``scanf`` requires
    result = 0
    while input[start+result] in seps: inc result

  if scanf("$w${someSep}$w", input, key, value):
    ...

It also possible to pass arguments to a user definable matcher:

.. code-block:: nim

  proc ndigits(input: string; start: int; intVal: var int; n: int): int =
    # matches exactly ``n`` digits. Matchers need to return 0 if nothing
    # matched or otherwise the number of processed chars.
    var x = 0
    var i = 0
    while i < n and i+start < input.len and input[i+start] in {'0'..'9'}:
      x = x * 10 + input[i+start].ord - '0'.ord
      inc i
    # only overwrite if we had a match
    if i == n:
      result = n
      intVal = x

  # match an ISO date extracting year, month, day at the same time.
  # Also ensure the input ends after the ISO date:
  var year, month, day: int
  if scanf("${ndigits(4)}-${ndigits(2)}-${ndigits(2)}$.", "2013-01-03", year, month, day):
    ...

]##


import macros, parseutils

proc conditionsToIfChain(n, idx, res: NimNode; start: int): NimNode =
  assert n.kind == nnkStmtList
  if start >= n.len: return newAssignment(res, newLit true)
  var ifs: NimNode = nil
  if n[start+1].kind == nnkEmpty:
    ifs = conditionsToIfChain(n, idx, res, start+3)
  else:
    ifs = newIfStmt((n[start+1],
                    newTree(nnkStmtList, newCall(bindSym"inc", idx, n[start+2]),
                                     conditionsToIfChain(n, idx, res, start+3))))
  result = newTree(nnkStmtList, n[start], ifs)

proc notZero(x: NimNode): NimNode = newCall(bindSym"!=", x, newLit 0)

proc buildUserCall(x: string; args: varargs[NimNode]): NimNode =
  let y = parseExpr(x)
  result = newTree(nnkCall)
  if y.kind in nnkCallKinds: result.add y[0]
  else: result.add y
  for a in args: result.add a
  if y.kind in nnkCallKinds:
    for i in 1..<y.len: result.add y[i]

macro scanf*(pattern: static[string]; input: string; results: varargs[typed]): bool =
  ## See top level documentation of his module of how ``scanf`` works.
  template matchBind(parser) {.dirty.} =
    var resLen = genSym(nskLet, "resLen")
    conds.add newLetStmt(resLen, newCall(bindSym(parser), input, results[i], idx))
    conds.add resLen.notZero
    conds.add resLen

  var i = 0
  var p = 0
  var idx = genSym(nskVar, "idx")
  var res = genSym(nskVar, "res")
  result = newTree(nnkStmtListExpr, newVarStmt(idx, newLit 0), newVarStmt(res, newLit false))
  var conds = newTree(nnkStmtList)
  var fullMatch = false
  while p < pattern.len:
    if pattern[p] == '$':
      inc p
      case pattern[p]
      of '$':
        var resLen = genSym(nskLet, "resLen")
        conds.add newLetStmt(resLen, newCall(bindSym"skip", input, newLit($pattern[p]), idx))
        conds.add resLen.notZero
        conds.add resLen
      of 'w':
        if i < results.len or getType(results[i]).typeKind != ntyString:
          matchBind "parseIdent"
        else:
          error("no string var given for $w")
        inc i
      of 'i':
        if i < results.len or getType(results[i]).typeKind != ntyInt:
          matchBind "parseInt"
        else:
          error("no int var given for $d")
        inc i
      of 'f':
        if i < results.len or getType(results[i]).typeKind != ntyFloat:
          matchBind "parseFloat"
        else:
          error("no float var given for $f")
        inc i
      of 's':
        conds.add newCall(bindSym"inc", idx, newCall(bindSym"skipWhitespace", input, idx))
        conds.add newEmptyNode()
        conds.add newEmptyNode()
      of '.':
        if p == pattern.len-1:
          fullMatch = true
        else:
          error("invalid format string")
      of '*', '+':
        if i < results.len or getType(results[i]).typeKind != ntyString:
          var min = ord(pattern[p] == '+')
          var q=p+1
          var token = ""
          while q < pattern.len and pattern[q] != '$':
            token.add pattern[q]
            inc q
          var resLen = genSym(nskLet, "resLen")
          conds.add newLetStmt(resLen, newCall(bindSym"parseUntil", input, results[i], newLit(token), idx))
          conds.add newCall(bindSym"!=", resLen, newLit min)
          conds.add resLen
        else:
          error("no string var given for $" & pattern[p])
        inc i
      of '{':
        inc p
        var nesting = 0
        let start = p
        while true:
          case pattern[p]
          of '{': inc nesting
          of '}':
            if nesting == 0: break
            dec nesting
          of '\0': error("expected closing '}'")
          else: discard
          inc p
        let expr = pattern.substr(start, p-1)
        if i < results.len:
          var resLen = genSym(nskLet, "resLen")
          conds.add newLetStmt(resLen, buildUserCall(expr, input, results[i], idx))
          conds.add newCall(bindSym"!=", resLen, newLit 0)
          conds.add resLen
        else:
          error("no var given for $" & expr)
        inc i
      of '[':
        inc p
        var nesting = 0
        let start = p
        while true:
          case pattern[p]
          of '[': inc nesting
          of ']':
            if nesting == 0: break
            dec nesting
          of '\0': error("expected closing ']'")
          else: discard
          inc p
        let expr = pattern.substr(start, p-1)
        conds.add newCall(bindSym"inc", idx, buildUserCall(expr, input, idx))
        conds.add newEmptyNode()
        conds.add newEmptyNode()
      else: error("invalid format string")
      inc p
    else:
      var token = ""
      while p < pattern.len and pattern[p] != '$':
        token.add pattern[p]
        inc p
      var resLen = genSym(nskLet, "resLen")
      conds.add newLetStmt(resLen, newCall(bindSym"skip", input, newLit(token), idx))
      conds.add resLen.notZero
      conds.add resLen
  result.add conditionsToIfChain(conds, idx, res, 0)
  if fullMatch:
    result.add newCall(bindSym">=", idx, newCall(bindSym"len", input))
  else:
    result.add res

when isMainModule:
  proc twoDigits(input: string; x: var int; start: int): int =
    if input[start] == '0' and input[start+1] == '0':
      result = 2
      x = 13
    else:
      result = 0

  proc someSep(input: string; start: int; seps: set[char] = {';',',','-','.'}): int =
    result = 0
    while input[start+result] in seps: inc result

  var key, val: string
  var intval: int
  var floatval: float
  doAssert scanf("$w$s::$s$w$s$i  $f", "abc:: xyz 89  33.25", key, val, intval, floatVal)
  doAssert key == "abc"
  doAssert val == "xyz"
  doAssert intval == 89
  doAssert floatVal == 33.25

  let xx = scanf("$$$i", "$abc", intval)
  doAssert xx == false


  let xx2 = scanf("$$$i", "$1234", intval)
  doAssert xx2

  let yy = scanf("$[someSep]Breakpoint${twoDigits}$[someSep({';','.','-'})] [$+]$.", ";.--Breakpoint00 [output]", intVal, key)
  doAssert yy
  doAssert key == "output"
  doAssert intVal == 13
