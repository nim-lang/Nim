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
@[5.0]
+
@[5.0, 3.0]
@[8.0]

/
@[8.0, 2.0]
@[4.0]

-
@[4.0, 7.0]
-*
@[4.0, 7.0, 22.0]
@[4.0, 154.0]
-
@[-150.0]
'''
"""

import strutils, streams
import pegs

const
  indent = "  "

let
  pegAst = """
Expr    <- Sum
Sum     <- Product (('+' / '-')Product)*
Product <- Value (('*' / '/')Value)*
Value   <- [0-9]+ / '(' Expr ')'
  """.peg
  txt = "(5+3)/2-7*22"

block:
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

block:
  var
    pStack: seq[string] = @[]
    valStack: seq[float] = @[]
    opStack = ""
  let
    parseArithExpr = pegAst.eventParser:
      pkNonTerminal:
        enter:
          pStack.add p.nt.name
        leave:
          pStack.setLen pStack.high
          if length > 0:
            let matchStr = s.substr(start, start+length-1)
            case p.nt.name
            of "Value":
              try:
                valStack.add matchStr.parseFloat
                echo valStack
              except ValueError:
                discard
            of "Sum", "Product":
              try:
                let val = matchStr.parseFloat
              except ValueError:
                if valStack.len > 1 and opStack.len > 0:
                  valStack[^2] = case opStack[^1]
                  of '+': valStack[^2] + valStack[^1]
                  of '-': valStack[^2] - valStack[^1]
                  of '*': valStack[^2] * valStack[^1]
                  else: valStack[^2] / valStack[^1]
                  valStack.setLen valStack.high
                  echo valStack
                  opStack.setLen opStack.high
                  echo opStack
      pkChar:
        leave:
          if length == 1 and "Value" != pStack[^1]:
            let matchChar = s[start]
            opStack.add matchChar
            echo opStack
  echo "Event parser output"
  echo "-------------------"
  let pLen = parseArithExpr(txt)
  assert txt.len == pLen
