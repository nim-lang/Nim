discard """
  output: '''
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
'''
"""

import strutils, streams
import pegs

const
  indent = "  "

let
  pegSrc = """
Expr <- Sum
Sum <- Product (('+' / '-') Product)*
Product <- Value (('*' / '/') Value)*
Value <- [0-9]+ / '(' Expr ')'
  """
  pegAst: Peg = pegSrc.peg

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
    for s in sons(p):
      s.recLoop level+1

pegAst.recLoop
echo outp.data