discard """
  output: '''Match failed: spam
Match failed: ham'''
joinable: false
"""

# bug #6220

import nre
import options
import strutils except isAlpha, isLower, isUpper, isSpace
from unicode import isAlpha, isLower, isUpper, isTitle, isWhiteSpace
import os

const debugLex = false

template debug(enable: bool, text: string): typed =
  when enable:
    echo(text)

type
  Parser[N, T] = proc(text: T, start: int, nodes: var seq[Node[N]]): int {.closure.}

  RuleObj[N, T] = object
    parser: Parser[N, T]
    kind: N

  Rule[N, T] = ref RuleObj[N, T]

  NodeKind = enum
    terminal,
    nonterminal

  Node*[N] = object of RootObj
    # Uncomment the following lines and the compiler crashes
    # case nodeKind: NodeKind
    #   of nonterminal:
    #     kids: Node[N]
    #   of terminal:
    #     discard
    start*: int
    length*: int
    kind*: N


  NonTerminal[N] = object of Node
    children: seq[Node[N]]

proc newRule[N, T](parser: Parser, kind: N): Rule[N, T] =
  new(result)
  result.parser = parser
  result.kind = kind

proc newRule[N, T](kind: N): Rule[N, T] =
  new(result)
  result.kind = kind

proc initNode[N](start: int, length: int, kind: N): Node[N] =
  result.start = start
  result.length = length
  result.kind = kind

proc initNode[N](start: int, length: int, children: seq[Node[N]], kind: N): NonTerminal[N] =
  result.start = start
  result.length = length
  result.kind = kind
  result.children = children

proc substr[T](text: T, first, last: int): T =
  text[first .. last]

proc continuesWith[N](text: seq[Node[N]], subtext: seq[N], start: Natural): bool =
  let length = len(text)
  var pos = 0
  while pos < len(subtext):
    let textpos = start + pos
    if textpos == len(text):
      return false
    if text[textpos].kind != subtext[pos].kind:
      return false
    pos+=1
  return true


proc render*[N, T](text: T, nodes: seq[Node[N]]): string =
  ## Uses a sequence of Nodes to render a given text string
  result = ""
  for node in nodes:
    result.add("<" & node.value(text) & ">")

proc render*[N, T](rule: Rule[N, T], text: string): string =
  ## Uses a rule to render a given text string
  render(text, rule.parse(text))

proc render*[N, T](text: T, nodes: seq[Node[N]], source: string): string =
  result = ""
  for node in nodes:
    result.add("[" & node.value(text, source) & "]")

proc render*[N, T, X](rule: Rule[N, T], text: seq[Node[X]], source: string): string =
  ## Uses a rule to render a given series of nodes, providing the source string
  text.render(rule.parse(text, source = source), source)

proc annotate*[N, T](node: Node[N], text: T): string =
  result = "<" & node.value(text) & ":" & $node.kind & ">"

proc annotate*[N, T](nodes: seq[Node[N]], text: T): string =
  result = ""
  for node in nodes:
    result.add(node.annotate(text))

proc annotate*[N, T](rule: Rule[N, T], text: T): string =
  annotate(rule.parse(text), text)

proc value*[N, T](node: Node[N], text: T): string =
  result = $text.substr(node.start, node.start + node.length - 1)

proc value*[N, X](node: Node[N], text: seq[Node[X]], source: string): string =
  result = ""
  for n in node.start ..< node.start + node.length:
    result &= text[n].annotate(source)

proc parse*[N, T](rule: Rule[N, T], text: T, start = 0, source: string = ""): seq[Node[N]] =
  result = newSeq[Node[N]]()
  debug(debugLex, "Parsing: " & $text)
  let length = rule.parser(text, start, result)

  when T is string:
    if length == -1:
      echo("Match failed: " & $text)
      result = @[]
    elif length == len(text):
      debug(debugLex, "Matched: " & $text & " => " & $len(result) & " tokens: " & text.render(result))
    else:
      echo("Matched first " & $length & " symbols: " & $text & " => " & $len(result) & " tokens: " & text.render(result))
  else:
    if length == -1:
      echo("Match failed: " & $text)
      result = @[]
    elif length == len(text):
      debug(debugLex, "Matched: " & $text & " => " & $len(result) & " tokens: " & text.render(result, source))
    else:
      echo("Matched first " & $length & " symbols: " & $text & " => " & $len(result) & " tokens: " & text.render(result, source))


proc literal*[N, T, P](pattern: P, kind: N): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    if start == len(text):
      return -1
    doAssert(len(text)>start, "Attempting to match at $#, string length is $# " % [$start, $len(text)])
    when P is string or P is seq[N]:
      debug(debugLex, "Literal[" & $kind & "]: testing " & $pattern & " at " & $start & ": " & $text[start..start+len(pattern)-1])
      if text.continuesWith(pattern, start):
        let node = initNode(start, len(pattern), kind)
        nodes.add(node)
        debug(debugLex, "Literal: matched <" & $text[start ..< start+node.length] & ":" & $node.length & ">" )
        return node.length
    elif P is char:
      debug(debugLex, "Literal[" & $kind & "]: testing " & $pattern & " at " & $start & ": " & $text[start])
      if text[start] == pattern:
        let node = initNode(start, 1, kind)
        nodes.add(node)
        return 1
    else:
      debug(debugLex, "Literal[" & $kind & "]: testing " & $pattern & " at " & $start & ": " & $text[start])
      if text[start].kind == pattern:
        let node = initNode(start, 1, kind)
        nodes.add(node)
        return 1
    return -1
  result = newRule[N, T](parser, kind)

proc token[N, T](pattern: T, kind: N): Rule[N, T] =
  when T is not string:
     {.fatal: "Token is only supported for strings".}
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    debug(debugLex, "Token[" & $kind & "]: testing " & pattern & " at " & $start)
    if start == len(text):
      return -1
    doAssert(len(text)>start, "Attempting to match at $#, string length is $# " % [$start, $len(text)])
    let m = text.match(re(pattern), start)
    if m.isSome:
      let node = initNode(start, len(m.get.match), kind)
      nodes.add(node)
      result = node.length
      debug(debugLex, "Token: matched <" & text[start ..< start+node.length] & ":" & $node.length & ">" )
    else:
      result = -1
  result = newRule[N, T](parser, kind)

proc chartest[N, T, S](testfunc: proc(s: S): bool, kind: N): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    if start == len(text):
      return -1
    doAssert(len(text)>start, "Attempting to match at $#, string length is $# " % [$start, $len(text)])
    if testfunc(text[start]):
      nodes.add(initNode(start, 1, kind))
      result = 1
    else:
      result = -1
  result = newRule[N, T](parser, kind)

proc any*[N, T, S](symbols: T, kind: N): Rule[N, T] =
  let test = proc(s: S): bool =
    when S is string:
      debug(debugLex, "Any[" & $kind & "]: testing for " & symbols.replace("\n", "\\n").replace("\r", "\\r"))
    else:
      debug(debugLex, "Any[" & $kind & "]: testing for " & $symbols)
    result = s in symbols
  result = chartest[N, T, S](test, kind)

proc ignore*[N, T](rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    result = rule.parser(text, start, mynodes)
  result = newRule[N, T](parser, rule.kind)

proc combine*[N, T](rule: Rule[N, T], kind: N): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    result = rule.parser(text, start, mynodes)
    nodes.add(initNode(start, result, kind))
  result = newRule[N, T](parser, kind)

proc build*[N, T](rule: Rule[N, T], kind: N): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    result = rule.parser(text, start, mynodes)
    let nonTerminal = initNode(start, result, mynodes, kind)
    nodes.add(nonTerminal)
  result = newRule[N, T](parser, kind)

proc fail*[N, T](message: string, kind: N): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    let lineno = countLines(text[0..start])
    var startline = start
    var endline = start
    while startline>0:
      if text[startline] in NewLines:
        break
      startline-=1
    while endline < len(text):
      if text[endline] in NewLines:
        break
      endline+=1
    let charno = start-startline
    echo text.substr(startline, endline)
    echo ' '.repeat(max(charno,0)) & '^'
    raise newException(ValueError, "Position: " & $start & " Line: " & $lineno & ", Symbol: " & $charno & ": " & message)
  result = newRule[N, T](parser, kind)

proc `+`*[N, T](left: Rule[N, T], right: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    doAssert(not isNil(left.parser), "Left hand side parser is nil")
    let leftlength = left.parser(text, start, mynodes)
    if leftlength == -1:
      return leftlength
    doAssert(not isNil(right.parser), "Right hand side parser is nil")
    let rightlength = right.parser(text, start+leftlength, mynodes)
    if rightlength == -1:
      return rightlength
    result = leftlength + rightlength
    nodes.add(mynodes)
  result = newRule[N, T](parser, left.kind)

proc `/`*[N, T](left: Rule[N, T], right: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    doAssert(not isNil(left.parser), "Left hand side of / is not fully defined")
    let leftlength = left.parser(text, start, mynodes)
    if leftlength != -1:
      nodes.add(mynodes)
      return leftlength
    mynodes = newSeq[Node[N]]()
    doAssert(not isNil(right.parser), "Right hand side of / is not fully defined")
    let rightlength = right.parser(text, start, mynodes)
    if rightlength == -1:
      return rightlength
    nodes.add(mynodes)
    return rightlength
  result = newRule[N, T](parser, left.kind)

proc `?`*[N, T](rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    let success = rule.parser(text, start, nodes)
    return if success != -1: success else: 0
  result = newRule[N, T](parser, rule.kind)

proc `+`*[N, T](rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var success = rule.parser(text, start, nodes)
    if success == -1:
      return success
    var total = 0
    while success != -1 and start+total < len(text):
      total += success
      success = rule.parser(text, start+total, nodes)
    return total
  result = newRule[N, T](parser, rule.kind)

proc `*`*[N, T](rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    let success = (+rule).parser(text, start, nodes)
    return if success != -1: success else: 0
  result = newRule[N, T](parser, rule.kind)

#Note: this consumes - for zero-width lookahead see !
proc `^`*[N, T](rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    let success = rule.parser(text, start, mynodes)
    return if success == -1: 1 else: -1
  result = newRule[N, T](parser, rule.kind)

proc `*`*[N, T](repetitions: int, rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    var total = 0
    for i in 0..<repetitions:
      let success = rule.parser(text, start+total, mynodes)
      if success == -1:
        return success
      else:
        total += success
    nodes.add(mynodes)
    return total
  result = newRule[N, T](parser, rule.kind)

# Positive zero-width lookahead
proc `&`*[N, T](rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    let success = rule.parser(text, start, mynodes)
    return if success != -1: 0 else: -1
  result = newRule[N, T](parser, rule.kind)

# Negative zero-width lookahead
proc `!`*[N, T](rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    let failure = rule.parser(text, start, mynodes)
    return if failure == -1: 0 else: -1
  result = newRule[N, T](parser, rule.kind)

proc `/`*[N, T](rule: Rule[N, T]): Rule[N, T] =
  let parser = proc (text: T, start: int, nodes: var seq[Node[N]]): int =
    var mynodes = newSeq[Node[N]]()
    var length = 0
    var success = rule.parser(text, start+length, mynodes)
    while success == -1 and start+length < len(text):
      length += 1
      success = rule.parser(text, start+length, mynodes)
    if start+length >= len(text):
      result = -1
    else:
      nodes.add(initNode(start, length, rule.kind))
      nodes.add(mynodes)
      result = length + success
  result = newRule[N, T](parser, rule.kind)

proc `->`*(rule: Rule, production: Rule) =
  doAssert(not isnil(production.parser), "Right hand side of -> is nil - has the rule been defined yet?")
  rule.parser = production.parser

template grammar*[K](Kind, Text, Symbol: typedesc; default: K, code: untyped): typed {.hint[XDeclaredButNotUsed]: off.} =

    proc newRule(): Rule[Kind, Text] {.inject.} = newRule[Kind, Text](default)
    proc chartest(testfunc: proc(c: Symbol): bool): Rule[Kind, Text] {.inject.} = chartest[Kind, Text, Symbol](testfunc, default)
    proc literal[P](pattern: P, kind: K): Rule[Kind, Text] {.inject.} = literal[Kind, Text, P](pattern, kind)
    proc literal[P](pattern: P): Rule[Kind, Text] {.inject.} = literal[Kind, Text, P](pattern, default)

    when Text is string:
      proc token(pattern: string): Rule[Kind, Text] {.inject.} = token(pattern, default)
      proc fail(message: string): Rule[Kind, Text] {.inject.} = fail[Kind, Text](message, default)
      let alpha {.inject.} = chartest[Kind, Text, Symbol](isAlphaAscii, default)
      let alphanumeric {.inject.}= chartest[Kind, Text, Symbol](isAlphaNumeric, default)
      let digit {.inject.} = chartest[Kind, Text, Symbol](isDigit, default)
      let lower {.inject.} = chartest[Kind, Text, Symbol](isLowerAscii, default)
      let upper {.inject.} = chartest[Kind, Text, Symbol](isUpperAscii, default)
      let isspace = proc (x: char): bool = x.isSpaceAscii and not (x in NewLines)
      let space {.inject.} = chartest[Kind, Text, Symbol](isspace, default)
      let isnewline = proc (x: char): bool = x in NewLines
      let newline {.inject.} = chartest[Kind, Text, Symbol](isnewline, default)
      let alphas {.inject.} = combine(+alpha, default)
      let alphanumerics {.inject.} = combine(+alphanumeric, default)
      let digits {.inject.} = combine(+digit, default)
      let lowers {.inject.} = combine(+lower, default)
      let uppers {.inject.} = combine(+upper, default)
      let spaces {.inject.} = combine(+space, default)
      let newlines {.inject.} = combine(+newline, default)

    proc any(chars: Text): Rule[Kind, Text] {.inject.} = any[Kind, Text, Symbol](chars, default)
    proc combine(rule: Rule[Kind, Text]): Rule[Kind, Text] {.inject.} = combine[Kind, Text](rule, default)

    code

template grammar*[K](Kind: typedesc; default: K, code: untyped): typed {.hint[XDeclaredButNotUsed]: off.} =
  grammar(Kind, string, char, default, code)

block:
  type DummyKind = enum dkDefault
  grammar(DummyKind, string, char, dkDefault):
    let rule = token("h[a]+m") + ignore(token(r"\s+")) + (literal("eggs") / literal("beans"))
    var text = "ham beans"
    discard rule.parse(text)

    var recursive = newRule()
    recursive -> (literal("(") + recursive + literal(")")) / token(r"\d+")
    for test in ["spam", "57", "(25)", "((25))"]:
      discard recursive.parse(test)

    let repeated = +literal("spam") + ?literal("ham") + *literal("salami")
    for test in ["ham", "spam", "spamspamspam" , "spamham", "spamsalami", "spamsalamisalami"]:
      discard  repeated.parse(test)
