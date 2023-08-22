# Bug #2022

discard """
  output: '''@[97, 45]
@[true, false]
@[false, false]'''
"""

## The goal of this snippet is to provide and test a construct for general-
## purpose, random-access mapping. I use an AST-manipulation-based approach
## because it's more efficient than using procedure pointers and less
## verbose than defining a new callable type for every invocation of `map`.

import sugar
import macros
import strutils

#===============================================================================
# Define a system for storing copies of ASTs as static strings.
# This serves the same purpose as D's `alias` parameters for types, used heavily
# in its popular `ranges` and `algorithm` modules.

var exprNodes {.compileTime.} = newSeq[NimNode]()

proc refExpr(exprNode: NimNode): string {.compileTime.} =
  exprNodes.add exprNode.copy
  "expr" & $(exprNodes.len - 1)

proc derefExpr(exprRef: string): NimNode {.compileTime.} =
  exprNodes[parseInt(exprRef[4 .. ^1])]

#===============================================================================
# Define a type that allows a callable expression to be mapped onto elements
# of an indexable collection.

type Mapped[Input; predicate: static[string]] = object
  input: Input

macro map(input, predicate: untyped): untyped =
  let predicate = callsite()[2]
  newNimNode(nnkObjConstr).add(
    newNimNode(nnkBracketExpr).add(
      ident"Mapped",
      newNimNode(nnkTypeOfExpr).add(input),
      newLit(refExpr(predicate))),
    newNimNode(nnkExprColonExpr).add(
      ident"input", input))

proc `[]`(m: Mapped, i: int): auto =
  macro buildResult: untyped =
    newCall(
      derefExpr(m.predicate),
      newNimNode(nnkBracketExpr).add(
        newDotExpr(ident"m", ident"input"),
        ident"i"))
  buildResult()

#===============================================================================
# Test out our generic mapping construct.

let a = "a-string".map(ord)
let b = @["a", "seq"].map((e: string) => e == "a")
let c = "another-string".map((e: char) => e == 'o')

echo(@[a[0], a[1]]) # @[97, 45]
echo(@[b[0], b[1]]) # @[true, false]
echo(@[c[0], c[1]]) # @[false, false]
