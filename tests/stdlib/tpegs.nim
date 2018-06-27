discard """
  output: '''
PEG AST traversal output
------------------------
pkNonTerminal: Sum @(2, 3)
  pkSequence: (Product (('+' / '-') Product)*)
    pkNonTerminal: Product @(3, 7)
      pkSequence: (Value (('*' / '/') Value)*)
        pkNonTerminal: Value @(4, 5)
          pkOrderedChoice: (([0-9] [0-9]*) / ('(' Expr ')'))
            pkSequence: ([0-9] [0-9]*)
              pkCharChoice: [0-9]
              pkGreedyRepSet: [0-9]*
            pkSequence: ('(' Expr ')')
              pkChar: '('
              pkNonTerminal: Expr @(1, 4)
                pkNonTerminal: Sum @(2, 3)
              pkChar: ')'
        pkGreedyRep: (('*' / '/') Value)*
          pkSequence: (('*' / '/') Value)
            pkOrderedChoice: ('*' / '/')
              pkChar: '*'
              pkChar: '/'
            pkNonTerminal: Value @(4, 5)
    pkGreedyRep: (('+' / '-') Product)*
      pkSequence: (('+' / '-') Product)
        pkOrderedChoice: ('+' / '-')
          pkChar: '+'
          pkChar: '-'
        pkNonTerminal: Product @(3, 7)

Event parser output
-------------------
Sum pkSequence@(2, 3): parsing @0
  Product pkSequence@(3, 7): parsing @0
    Value pkOrderedChoice@(4, 5): parsing @0
      Expr pkNonTerminal@(1, 4): parsing @1
        Sum pkSequence@(2, 3): parsing @1
          Product pkSequence@(3, 7): parsing @1
            Value pkOrderedChoice@(4, 5): parsing @1
              5
            5
          Product pkSequence@(3, 7): parsing @3
            Value pkOrderedChoice@(4, 5): parsing @3
              3
            3
          5+3
        5+3
      (5+3)
    Value pkOrderedChoice@(4, 5): parsing @6
      2
    (5+3)/2
  Product pkSequence@(3, 7): parsing @8
    Value pkOrderedChoice@(4, 5): parsing @8
      7
    Value pkOrderedChoice@(4, 5): parsing @10
      22
    7*22
  (5+3)/2+7*22
'''
"""

import strutils, streams
import pegs

const
  indent = "  "

let
  pegAst = """
Expr <- Sum
Sum <- Product (('+' / '-') Product)*
Product <- Value (('*' / '/') Value)*
Value <- [0-9]+ / '(' Expr ')'
  """.peg
  txt = "(5+3)/2-7*22"

var
  outp = newStringStream()
  processed: seq[string] = @[]

proc prt(outp: Stream, kind: PegKind, s: string; level: int = 0) =
  outp.writeLine indent.repeat(level) & "$1: $2" % [$kind, s]

proc recLoop(p: Peg, level: int = 0) =
  case p.kind
  of pkEmpty..pkWhitespace:
    discard
  of pkTerminal, pkTerminalIgnoreCase, pkTerminalIgnoreStyle:
    outp.prt(p.kind, $p, level)
  of pkChar, pkGreedyRepChar:
    outp.prt(p.kind, $p, level)
  of pkCharChoice, pkGreedyRepSet:
    outp.prt(p.kind, $p, level)
  of pkNonTerminal:
    outp.prt(p.kind,
      "$1 @($3, $4)" % [p.nt.name, $p.nt.rule.kind, $p.nt.line, $p.nt.col], level)
    if not(p.nt.name in processed):
      processed.add p.nt.name
      p.nt.rule.recLoop level+1
  of pkBackRef..pkBackRefIgnoreStyle:
    outp.prt(p.kind, $p, level)
  else:
    outp.prt(p.kind, $p, level)
    for s in items(p):
      s.recLoop level+1

pegAst.recLoop
echo "PEG AST traversal output"
echo "------------------------"
echo outp.data

proc prt(outp: Stream, s: string, level: int = 0) =
  outp.writeLine indent.repeat(level) & s

outp = newStringStream()
var level: int = 0
let eParse = pegAst.eventParser:
  pkNonTerminal:
    enter:
      outp.prt("$1 $2@($3, $4): parsing @$5" %
        [p.nt.name, $p.nt.rule.kind, $p.nt.line, $p.nt.col, $start], level)
      level.inc
    leave:
      if -1 < length:
        outp.prt(txt.substr(start, start+length-1), level)
      level.dec
let pLen = eParse(txt)
assert txt.len == pLen
echo "Event parser output"
echo "-------------------"
echo outp.data

var
  stack: seq[float] = @[]
let
  arithExprParse = pegAst.eventParser:
    pkNonTerminal:
      enter:
        let ntName {.inject.} = p.nt.name.toLowerAscii
        echo "start of non-terminal symbol: ", ntName 
      leave:
        echo "end of non-terminal symbol: ", ntName 
        var
          matchStr: string = ""
          opInd: int = -1
        if length > 0:
          matchStr = txt.substr(start, start+length-1)
          opInd = matchStr.find(peg("'+'/'-'/'*'/'/'"))
        case ntName
        of "value":
          if opInd == -1:
            stack.add matchStr.parseFloat
            echo "new stack: ", stack 
        of "sum", "product":
          if stack.len == 2:
            if opInd == -1:
              echo "--> nope"
            else:
              echo "--> ", matchStr[opInd]
              stack[^2] = case matchStr[opInd]
              of '+': stack[^2] + stack[^1]
              of '-': stack[^2] - stack[^1]
              of '*': stack[^2] * stack[^1]
              else: stack[^2] / stack[^1]
              stack.setLen 1
              echo "new stack: ", stack 
echo "Arithmetic expression parser output"
echo "-----------------------------------"
let aepLen = arithExprParse(txt)
assert txt.len == aepLen