#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from injectdestructors2.nim

proc isLastRead(location: PNode; c: var Con; pc, until: int): int =
  var pc = pc
  while pc < c.g.len and pc < until:
    case c.g[pc].kind
    of def:
      if defInstrTargets(c.g[pc], location):
        # the path leads to a redefinition of 's' --> abandon it.
        return high(int)
      inc pc
    of use:
      if useInstrTargets(c.g[pc], location):
        c.otherRead = c.g[pc].n
        return -1
      inc pc
    of goto:
      pc = pc + c.g[pc].dest
    of fork:
      # every branch must lead to the last read of the location:
      var variantA = pc + 1
      var variantB = pc + c.g[pc].dest
      while variantA != variantB:
        if min(variantA, variantB) < 0: return -1
        if max(variantA, variantB) >= c.g.len or min(variantA, variantB) >= until:
          break
        if variantA < variantB:
          variantA = isLastRead(location, c, variantA, min(variantB, until))
        else:
          variantB = isLastRead(location, c, variantB, min(variantA, until))
      pc = min(variantA, variantB)
  return pc

proc isLastRead(n: PNode; c: var Con): bool =
  # first we need to search for the instruction that belongs to 'n':
  c.otherRead = nil
  var instr = -1
  let m = dfa.skipConvDfa(n)

  for i in 0..<c.g.len:
    # This comparison is correct and MUST not be ``instrTargets``:
    if c.g[i].kind == use and c.g[i].n == m:
      if instr < 0:
        instr = i
        break

  dbg: echo "starting point for ", n, " is ", instr, " ", n.kind

  if instr < 0: return false
  # we go through all paths beginning from 'instr+1' and need to
  # ensure that we don't find another 'use X' instruction.
  if instr+1 >= c.g.len: return true

  result = isLastRead(n, c, instr+1, int.high) >= 0
  dbg: echo "ugh ", c.otherRead.isNil, " ", result

proc isFirstWrite(location: PNode; c: var Con; pc, until: int): int =
  var pc = pc
  while pc < until:
    case c.g[pc].kind
    of def:
      if defInstrTargets(c.g[pc], location):
        # a definition of 's' before ours makes ours not the first write
        return -1
      inc pc
    of use:
      if useInstrTargets(c.g[pc], location):
        return -1
      inc pc
    of goto:
      pc = pc + c.g[pc].dest
    of fork:
      # every branch must not contain a def/use of our location:
      var variantA = pc + 1
      var variantB = pc + c.g[pc].dest
      while variantA != variantB:
        if min(variantA, variantB) < 0: return -1
        if max(variantA, variantB) > until:
          break
        if variantA < variantB:
          variantA = isFirstWrite(location, c, variantA, min(variantB, until))
        else:
          variantB = isFirstWrite(location, c, variantB, min(variantA, until))
      pc = min(variantA, variantB)
  return pc

proc isFirstWrite(n: PNode; c: var Con): bool =
  # first we need to search for the instruction that belongs to 'n':
  var instr = -1
  let m = dfa.skipConvDfa(n)

  for i in countdown(c.g.len-1, 0): # We search backwards here to treat loops correctly
    if c.g[i].kind == def and c.g[i].n == m:
      if instr < 0:
        instr = i
        break

  if instr < 0: return false
  # we go through all paths going to 'instr' and need to
  # ensure that we don't find another 'def/use X' instruction.
  if instr == 0: return true

  result = isFirstWrite(n, c, 0, instr) >= 0
