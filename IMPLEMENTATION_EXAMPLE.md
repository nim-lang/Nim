# Implementation Example: Enhanced Type Mismatch Messages

## Overview
This document shows how to implement one of the suggested improvements: better type mismatch error messages with inline annotations.

## Current vs Proposed

### Current Error
```
test.nim(10, 5) Error: type mismatch: got <int, string>
but expected one of:
proc add(x, y: int): int
```

### Proposed Error (with --errorStyle:rust)
```
Error:[E0234]: type mismatch in call to 'add'
 --> test.nim(10, 5)
    |
 10 |   add(42, "hello")
    |       ^^  ^^^^^^^ expected 'int', found 'string'
    |       |
    |       this argument matches
    |
note: candidate function signature
 --> system.nim(150, 6)
    |
150 | proc add(x, y: int): int
    |      ^^^    --  --- required parameter types
    |
help: convert the string to an integer
    | add(42, parseInt("hello"))
```

## Implementation Plan

### 1. Enhance semcall.nim - Track Argument Matching

```nim
# In compiler/semcall.nim

type
  TArgMatch* = object
    ## Track how each argument matches (or doesn't match) a parameter
    argIndex*: int
    paramIndex*: int
    argType*: PType
    expectedType*: PType
    matched*: bool
    reason*: string  # Why it didn't match

  TOverloadMatch* = object
    ## Track how well an overload matches the call
    sym*: PSym
    matches*: seq[TArgMatch]
    score*: int  # How close the match is
    failReason*: string

proc analyzeArgumentMatch(c: PContext, f: PType, arg: PNode,
                         paramIdx: int): TArgMatch =
  ## Analyze how well an argument matches a parameter
  result.argIndex = arg.info.line.int  # simplified
  result.paramIndex = paramIdx
  result.argType = arg.typ
  result.expectedType = f[paramIdx]

  if sameType(result.argType, result.expectedType):
    result.matched = true
    result.reason = ""
  else:
    result.matched = false
    # Determine specific reason
    if result.argType.kind == tyInt and result.expectedType.kind == tyString:
      result.reason = "cannot convert 'int' to 'string' implicitly"
    elif result.argType.kind == tyString and result.expectedType.kind == tyInt:
      result.reason = "cannot convert 'string' to 'int' (use parseInt)"
    # ... more cases
    else:
      result.reason = "type mismatch: got '$1' but expected '$2'" %
                      [typeToString(result.argType), typeToString(result.expectedType)]

proc rankOverloadMatches(matches: seq[TOverloadMatch]): seq[TOverloadMatch] =
  ## Sort overload matches by how close they are to matching
  ## This shows the "most likely intended" match first
  result = matches
  result.sort do (a, b: TOverloadMatch) -> int:
    # Count how many parameters matched
    let aMatches = a.matches.countIt(it.matched)
    let bMatches = b.matches.countIt(it.matched)
    result = cmp(bMatches, aMatches)  # Descending
```

### 2. Enhance msgs.nim - Format Detailed Type Mismatch

```nim
# In compiler/msgs.nim

proc formatTypeMismatchError*(conf: ConfigRef; info: TLineInfo;
                              callName: string;
                              matches: seq[TOverloadMatch];
                              args: seq[PNode]): string =
  ## Format a detailed type mismatch error with all overload candidates

  result = "type mismatch in call to '$1'" % callName

  if optRustStyleErrors in conf.globalOptions:
    # Rust-style formatting
    result.add("\n --> " & conf.toFileLineCol(info))

    # Show the call site with inline type annotations
    let sourceLine = conf.sourceLine(info)
    let lineNum = $info.line
    let gutter = align(lineNum, 3)

    result.add("\n    |")
    result.add("\n" & gutter & " | " & sourceLine)
    result.add("\n    | ")

    # Add annotations for each argument
    # This requires parsing the source to find argument positions
    # Simplified version:
    for i, arg in args:
      if i < matches[0].matches.len:
        let m = matches[0].matches[i]
        if not m.matched:
          # Add caret and annotation
          let colPos = arg.info.col
          result.add(spaces(colPos))
          result.add("^")
          result.add(" expected '")
          result.add(typeToString(m.expectedType))
          result.add("', found '")
          result.add(typeToString(m.argType))
          result.add("'")
          result.add("\n    | ")

    # Show each candidate
    for idx, match in matches:
      result.add("\n")
      result.add("note: candidate ")
      result.add($(idx + 1))
      result.add(" of ")
      result.add($matches.len)
      result.add("\n --> ")
      result.add(conf.toFileLineCol(match.sym.info))
      result.add("\n    |")

      # Show procedure signature
      let sigLine = conf.sourceLine(match.sym.info)
      let sigLineNum = $match.sym.info.line
      let sigGutter = align(sigLineNum, 3)
      result.add("\n" & sigGutter & " | " & sigLine)

      # Explain why this candidate didn't match
      if not match.matches.allIt(it.matched):
        result.add("\n    |")
        result.add("\n    = note: ")

        let failedArgs = match.matches.filterIt(not it.matched)
        if failedArgs.len == 1:
          result.add(failedArgs[0].reason)
        else:
          result.add("multiple arguments don't match:")
          for arg in failedArgs:
            result.add("\n      - parameter ")
            result.add($(arg.paramIndex + 1))
            result.add(": ")
            result.add(arg.reason)

proc emitTypeMismatchError*(c: PContext; info: TLineInfo;
                           callName: string;
                           matches: seq[TOverloadMatch];
                           args: seq[PNode]) =
  ## Emit a type mismatch error with suggestions

  let msg = formatTypeMismatchError(c.config, info, callName, matches, args)
  c.config.localError(info, errGenerated, msg)

  # Add helpful suggestions
  if matches.len > 0:
    let bestMatch = matches[0]
    for m in bestMatch.matches:
      if not m.matched:
        # Suggest type conversions if available
        let suggestion = suggestTypeConversion(m.argType, m.expectedType)
        if suggestion != "":
          c.config.addDiagnosticHelp(suggestion)

proc suggestTypeConversion*(fromType, toType: PType): string =
  ## Suggest how to convert between types
  case fromType.kind
  of tyString:
    case toType.kind
    of tyInt: return "use 'parseInt(...)' to convert string to int"
    of tyFloat: return "use 'parseFloat(...)' to convert string to float"
    of tyBool: return "use 'parseBool(...)' to convert string to bool"
    else: discard
  of tyInt:
    case toType.kind
    of tyString: return "use '$' operator to convert int to string"
    of tyFloat: return "use 'float(...)' to convert int to float"
    else: discard
  # ... more cases

  return ""
```

### 3. Integration in Semantic Analysis

```nim
# In compiler/semcall.nim - where overload resolution happens

proc reportTypeMismatch(c: PContext, n: PNode, candidates: seq[PSym]) =
  ## Called when no overload matches

  # Collect detailed match information for each candidate
  var matches: seq[TOverloadMatch]
  for candidate in candidates:
    var match = TOverloadMatch(sym: candidate)

    # Analyze each argument against this candidate's parameters
    for i in 0..<n.len-1:  # Skip the first node (the call itself)
      let arg = n[i+1]
      let paramMatch = analyzeArgumentMatch(c, candidate.typ, arg, i)
      match.matches.add(paramMatch)

    matches.add(match)

  # Rank matches by how close they are
  matches = rankOverloadMatches(matches)

  # Extract argument nodes
  var args: seq[PNode]
  for i in 1..<n.len:
    args.add(n[i])

  # Emit the enhanced error
  emitTypeMismatchError(c, n.info, getProcHeader(candidates[0]), matches, args)
```

## Benefits

1. **Immediate clarity**: See exactly which argument is wrong
2. **Inline annotations**: No need to count positions
3. **All candidates shown**: Understand all available options
4. **Actionable suggestions**: Know how to fix the error
5. **Context preserved**: See original source with annotations

## Testing

```nim
# Test case
proc add(x, y: int): int = x + y
proc add(x, y: float): float = x + y
proc add(x, y: string): string = x & y

# This should produce the enhanced error:
echo add(42, "hello")
```

Expected output with `--errorStyle:rust`:
```
Error:[E0234]: type mismatch in call to 'add'
 --> test.nim(7, 6)
    |
  7 | echo add(42, "hello")
    |      ^^^  ^^  ^^^^^^^ expected 'int' or 'float' or 'string', found 'string'
    |      |    |
    |      |    this argument matches in candidate 1
    |
note: candidate 1 of 3
 --> test.nim(1, 6)
    |
  1 | proc add(x, y: int): int = x + y
    |      ^^^ --  --  --- required types
    |
    = note: argument 2 expected 'int', found 'string'

note: candidate 2 of 3
 --> test.nim(2, 6)
    |
  2 | proc add(x, y: float): float = x + y
    |      ^^^ --  --  ----- required types
    |
    = note: argument 1 expected 'float', found 'int'
    = note: argument 2 expected 'float', found 'string'

note: candidate 3 of 3
 --> test.nim(3, 6)
    |
  3 | proc add(x, y: string): string = x & y
    |      ^^^ --  --  ------ required types
    |
    = note: argument 1 expected 'string', found 'int'

help: convert the integer to string
    | echo add($42, "hello")
```

## Next Steps

1. Implement `TArgMatch` and `TOverloadMatch` types
2. Enhance `resolveOverload` to collect match information
3. Add inline annotation formatting
4. Implement type conversion suggestions
5. Add tests for various mismatch scenarios
6. Update documentation
