
# bug #1513

import os, parseutils, strutils, ropes, macros

var
  code {.compileTime.} = ""
  start {.compileTime.} = 0
  line {.compileTime.} = 1
  cpp {.compileTime.} = ""
  token {.compileTime.} = ""

proc log(msg: string) {.compileTime.} =
    echo msg

proc asmx64() {.compileTime} =

  #log "code = $1" % code

  const asmx64pre = "{.emit: \"\"\"{x64asm& x= *x64asm_ptr(`asm0`); try {"
  const asmx64post = "} catch (Xbyak::Error e) { printf (\"asmx64 error: %s\\n\", e.what ()); }}\"\"\".} "

  const xp = "x."

  const symbolStart = { '_', 'a'..'z', 'A' .. 'Z' }
  const symbol = { '0'..'9' } + symbolStart
  const eolComment = { ';' }
  const endOfLine = { '\l', '\r' }
  const leadingWhiteSpace = { ' ' }

  const end_or_comment = endOfLine + eolComment + { '\0' }

  const passthrough_start = { '{', '`' }
  const passthrough_end = { '}', '`', '\0' }

  const end_or_symbol_or_comment_or_passthrough = symbolStart + end_or_comment + passthrough_start


  proc abortAsmParse(err:string) =
    discard

  let codeLen = code.len
  #let codeEnd = codeLen-1
  cpp.add asmx64pre

  #log "{$1}\n" % [code]

  type asmParseState = enum leading, mnemonic, betweenArguments, arguments, endCmd, skipToEndOfLine

  var state:asmParseState = leading

  proc checkEnd(err:string) =
    let ch = code[start]
    if int(ch) == 0:
      abortAsmParse(err)

  proc get_passthrough() =
    inc start
    let prev_start = start
    let prev_token = token
    start += code.parseUntil(token, passthrough_end, start)
    checkEnd("Failed to find passthrough end delimiter from offset $1 for:$2\n$3" % [$prev_start, $(code[prev_start-prev_token.len..prev_start]), token[1..token.len-1]])
    inc start
    cpp.add "`"
    cpp.add token
    cpp.add "`"

  var inparse = true

  proc checkCmdEnd() =
    if codeLen == start:
      state = endCmd
      inparse = false

  while inparse:
    checkCmdEnd()

    log("state=$1 start=$2" % [$state, $start])

    case state:
    of leading:

      echo "b100 ", start
      start += code.skipWhile(leadingWhiteSpace, start)
      echo "b200 ", start
      let ch = code[start]
      if ch in endOfLine:
        inc(line)
        #echo "c100 ", start, ' ', code
        start += code.skipWhile(endOfline, start)
        #echo "c200 ", start, ' ', code
        continue
      elif ch in symbolStart:
        state = mnemonic
      elif ch in eolComment:
        state = skipToEndOfLine
      elif ch in passthrough_start:
        get_passthrough()
        echo "d100 ", start
        start += code.parseUntil(token, end_or_symbol_or_comment_or_passthrough, start)
        echo "d200 ", start
        cpp.add token
        state = mnemonic
      elif int(ch) == 0:
        break
      else:
        abortAsmParse("after '$3' illegal character at offset $1: $2" % [$start, $(int(ch)), token])

    of mnemonic:
      echo "e100 ", start
      start += code.parseWhile(token, symbol, start)
      echo "e200 ", start
      cpp.add xp
      cpp.add token
      cpp.add "("
      state = betweenArguments

    of betweenArguments:
      let tmp = start
      let rcode = code
      start += rcode.parseUntil(token, end_or_symbol_or_comment_or_passthrough, tmp)
      cpp.add token

      if codeLen <= start:
        state = endCmd
        continue

      let ch = code[start]
      if ch in passthrough_start:
        get_passthrough()
        continue
      if(ch in {'x', 'X'}) and('0' == code[start-1]):
        token = $(code[start])
        cpp.add token
        inc start
        continue
      state = arguments

    of arguments:
      if code[start] in end_or_comment:
        state = endCmd
        continue
      start += code.parseWhile(token, symbol, start)
      cpp.add xp
      cpp.add token
      state = betweenArguments

    of endCmd:
      cpp.add ");\n"
      state = skipToEndOfLine

    of skipToEndOfLine:
      echo "a100 ", start
      start += code.skipUntil(endOfLine, start)
      echo "a200 ", start
      start += code.skipWhile(endOfline, start)
      echo "a300 ", start
      inc line
      state = leading

  cpp.add asmx64post

  echo($cpp)

macro asmx64x(code_in:untyped) : typed =
  code = $code_in
  echo("code.len = $1, code = >>>$2<<<" % [$code.len, code])
  asmx64()
  discard result

asmx64x """
    mov rax, {m}
    ret
"""
