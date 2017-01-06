# Copyright (C) 2014-2015 Oleh Prypin <blaxpirit@gmail.com>
#
# This file is part of nim-random.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


## This module is just a convenience import. It exports `random.mersenne` and
## `random.urandom` and defines a global instance of Mersenne twister with
## alias procedures that use this instance.


import times, macros, strutils
import random.mersenne, random.urandom
import random/private/util
export mersenne, urandom


var mersenneTwisterInst*: MersenneTwister
  ## A global instance of Mersenne twister used by the alias functions of this
  ## module.
  ##
  ## When the module is imported, it is seeded using an array of bytes provided
  ## by ``urandom``, or, in case of failure, using the current time.
  ##
  ## Due to this silent fallback and the fact that any other code can use this
  ## global instance (and there is no thread safety), it is not recommended to
  ## use it (through the functions in this module or otherwise) if you have any
  ## concerns for security.

try:
  mersenneTwisterInst = initMersenneTwister(urandom(2500))
except OSError:
  mersenneTwisterInst = initMersenneTwister(uint32(uint(epochTime()*256)))

{.warning[Deprecated]: off.}


# Create all the alias functions based on common.nim.
# For example:
#     proc shuffle*(rng: var RNG; arr: var RAContainer)
# Becomes:
#     proc shuffle*(arr: var RAContainer) {.inline.} =
#       mersenneTwisterInst.shuffle(arr)

macro makeAliases(): stmt {.immediate.} =
  let body = parseStmt(staticRead("random/common.nim"))
  result = newStmtList()

  for top in body.children:
    if top.kind notin {nnkProcDef, nnkIteratorDef}:
      continue # we only want procs and iterators
    if top.name.kind != nnkPostfix:
      continue # ignore non-public

    top[3].del(1) # delete first formal argument

    var pragma = newNimNode(nnkPragma).add(newIdentNode("inline"))
    if "deprecated" in $top[4].toStrLit():
      pragma.add(newIdentNode("deprecated"))
    top[4] = pragma

    var args = newSeq[NimNode]() # collect arg names
    var first = true
    for arglist in top[3].children:
      if not first: # ignore first node (the return type)
        for i in 0 .. <arglist.len-2: # ignore two last nodes (type)
          args.add arglist[i]
      first = false

    # mersenneTwisterInst.proc(args)
    var body = newCall(
      newDotExpr(newIdentNode("mersenneTwisterInst"), top.name[1]),
      args
    )
    if top.kind == nnkIteratorDef:
      # wrap it in
      # for x in [...]: yield x
      body = newNimNode(nnkForStmt).add(
        newIdentNode("x"), body,
        newStmtList(newNimNode(nnkYieldStmt).add(newIdentNode("x")))
      )

    top[6] = newStmtList(body)

    result.add top

makeAliases()
