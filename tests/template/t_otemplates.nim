discard """
  output: "Success"
"""

# Ref:
# http://nim-lang.org/macros.html
# http://nim-lang.org/parseutils.html


# Imports
import tables, parseutils, macros, strutils
import annotate
export annotate


# Fields
const identChars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}


# Procedure Declarations
proc parse_template(node: NimNode, value: string) {.compiletime.}


# Procedure Definitions
proc substring(value: string, index: int, length = -1): string {.compiletime.} =
    ## Returns a string at most `length` characters long, starting at `index`.
    return if length < 0:    value.substr(index)
           elif length == 0: ""
           else:             value.substr(index, index + length-1)


proc parse_thru_eol(value: string, index: int): int {.compiletime.} =
    ## Reads until and past the end of the current line, unless
    ## a non-whitespace character is encountered first
    var remainder: string
    var read = value.parseUntil(remainder, {0x0A.char}, index)
    if remainder.skipWhitespace() == read:
        return read + 1


proc trim_after_eol(value: var string) {.compiletime.} =
    ## Trims any whitespace at end after \n
    var toTrim = 0
    for i in countdown(value.len-1, 0):
        # If \n, return
        if value[i] in [' ', '\t']: inc(toTrim)
        else: break

    if toTrim > 0:
        value = value.substring(0, value.len - toTrim)


proc trim_eol(value: var string) {.compiletime.} =
    ## Removes everything after the last line if it contains nothing but whitespace
    for i in countdown(value.len - 1, 0):
        # If \n, trim and return
        if value[i] == 0x0A.char:
            value = value.substr(0, i)
            break

        # This is the first character
        if i == 0:
            value = ""
            break

        # Skip change
        if not (value[i] in [' ', '\t']): break


proc detect_indent(value: string, index: int): int {.compiletime.} =
    ## Detects how indented the line at `index` is.
    # Seek to the beginning of the line.
    var lastChar = index
    for i in countdown(index, 0):
        if value[i] == 0x0A.char:
            # if \n, return the indentation level
            return lastChar - i
        elif not (value[i] in [' ', '\t']):
            # if non-whitespace char, decrement lastChar
            dec(lastChar)


proc parse_thru_string(value: string, i: var int, strType = '"') {.compiletime.} =
    ## Parses until ending " or ' is reached.
    inc(i)
    if i < value.len-1:
        inc(i, value.skipUntil({'\\', strType}, i))


proc parse_to_close(value: string, index: int, open='(', close=')', opened=0): int {.compiletime.} =
    ## Reads until all opened braces are closed
    ## ignoring any strings "" or ''
    var remainder   = value.substring(index)
    var open_braces = opened
    result = 0

    while result < remainder.len:
        var c = remainder[result]

        if   c == open:  inc(open_braces)
        elif c == close: dec(open_braces)
        elif c == '"':   remainder.parse_thru_string(result)
        elif c == '\'':  remainder.parse_thru_string(result, '\'')

        if open_braces == 0: break
        else: inc(result)


iterator parse_stmt_list(value: string, index: var int): string =
    ## Parses unguided ${..} block
    var read        = value.parse_to_close(index, open='{', close='}')
    var expressions = value.substring(index + 1, read - 1).split({ ';', 0x0A.char })

    for expression in expressions:
        let value = expression.strip
        if value.len > 0:
            yield value

    #Increment index & parse thru EOL
    inc(index, read + 1)
    inc(index, value.parse_thru_eol(index))


iterator parse_compound_statements(value, identifier: string, index: int): string =
    ## Parses through several statements, i.e. if {} elif {} else {}
    ## and returns the initialization of each as an empty statement
    ## i.e. if x == 5 { ... } becomes if x == 5: nil.

    template get_next_ident(expected) =
        var nextIdent: string
        discard value.parseWhile(nextIdent, {'$'} + identChars, i)

        var next: string
        var read: int

        if nextIdent == "case":
            # We have to handle case a bit differently
            read = value.parseUntil(next, '$', i)
            inc(i, read)
            yield next.strip(leading=false) & "\n"

        else:
            read = value.parseUntil(next, '{', i)

            if nextIdent in expected:
                inc(i, read)
                # Parse until closing }, then skip whitespace afterwards
                read = value.parse_to_close(i, open='{', close='}')
                inc(i, read + 1)
                inc(i, value.skipWhitespace(i))
                yield next & ": nil\n"

            else: break


    var i = index
    while true:
        # Check if next statement would be valid, given the identifier
        if identifier in ["if", "when"]:
            get_next_ident([identifier, "$elif", "$else"])

        elif identifier == "case":
            get_next_ident(["case", "$of", "$elif", "$else"])

        elif identifier == "try":
            get_next_ident(["try", "$except", "$finally"])


proc parse_complex_stmt(value, identifier: string, index: var int): NimNode {.compiletime.} =
    ## Parses if/when/try /elif /else /except /finally statements

    # Build up complex statement string
    var stmtString = newString(0)
    var numStatements = 0
    for statement in value.parse_compound_statements(identifier, index):
        if statement[0] == '$': stmtString.add(statement.substr(1))
        else:                   stmtString.add(statement)
        inc(numStatements)

    # Parse stmt string
    result = parseExpr(stmtString)

    var resultIndex = 0

    # Fast forward a bit if this is a case statement
    if identifier == "case":
        inc(resultIndex)

    while resultIndex < numStatements:

        # Detect indentation
        let indent = detect_indent(value, index)

        # Parse until an open brace `{`
        var read = value.skipUntil('{', index)
        inc(index, read + 1)

        # Parse through EOL
        inc(index, value.parse_thru_eol(index))

        # Parse through { .. }
        read = value.parse_to_close(index, open='{', close='}', opened=1)

        # Add parsed sub-expression into body
        var body       = newStmtList()
        var stmtString = value.substring(index, read)
        trim_after_eol(stmtString)
        stmtString = reindent(stmtString, indent)
        parse_template(body, stmtString)
        inc(index, read + 1)

        # Insert body into result
        var stmtIndex = result[resultIndex].len-1
        result[resultIndex][stmtIndex] = body

        # Parse through EOL again & increment result index
        inc(index, value.parse_thru_eol(index))
        inc(resultIndex)


proc parse_simple_statement(value: string, index: var int): NimNode {.compiletime.} =
    ## Parses for/while

    # Detect indentation
    let indent = detect_indent(value, index)

    # Parse until an open brace `{`
    var splitValue: string
    var read = value.parseUntil(splitValue, '{', index)
    result   = parseExpr(splitValue & ":nil")
    inc(index, read + 1)

    # Parse through EOL
    inc(index, value.parse_thru_eol(index))

    # Parse through { .. }
    read = value.parse_to_close(index, open='{', close='}', opened=1)

    # Add parsed sub-expression into body
    var body       = newStmtList()
    var stmtString = value.substring(index, read)
    trim_after_eol(stmtString)
    stmtString = reindent(stmtString, indent)
    parse_template(body, stmtString)
    inc(index, read + 1)

    # Insert body into result
    var stmtIndex = result.len-1
    result[stmtIndex] = body

    # Parse through EOL again
    inc(index, value.parse_thru_eol(index))


proc parse_until_symbol(node: NimNode, value: string, index: var int): bool {.compiletime.} =
    ## Parses a string until a $ symbol is encountered, if
    ## two $$'s are encountered in a row, a split will happen
    ## removing one of the $'s from the resulting output
    var splitValue: string
    var read = value.parseUntil(splitValue, '$', index)
    var insertionPoint = node.len

    inc(index, read + 1)
    if index < value.len:

        case value[index]
        of '$':
            # Check for duplicate `$`, meaning this is an escaped $
            node.add newCall("add", ident("result"), newStrLitNode("$"))
            inc(index)

        of '(':
            # Check for open `(`, which means parse as simple single-line expression.
            trim_eol(splitValue)
            read = value.parse_to_close(index) + 1
            node.add newCall("add", ident("result"),
                newCall(bindSym"strip", parseExpr("$" & value.substring(index, read)))
            )
            inc(index, read)

        of '{':
            # Check for open `{`, which means open statement list
            trim_eol(splitValue)
            for s in value.parse_stmt_list(index):
                node.add parseExpr(s)

        else:
            # Otherwise parse while valid `identChars` and make expression w/ $
            var identifier: string
            read = value.parseWhile(identifier, identChars, index)

            if identifier in ["for", "while"]:
                ## for/while means open simple statement
                trim_eol(splitValue)
                node.add value.parse_simple_statement(index)

            elif identifier in ["if", "when", "case", "try"]:
                ## if/when/case/try means complex statement
                trim_eol(splitValue)
                node.add value.parse_complex_stmt(identifier, index)

            elif identifier.len > 0:
                ## Treat as simple variable
                node.add newCall("add", ident("result"), newCall("$", ident(identifier)))
                inc(index, read)

        result = true

    # Insert
    if splitValue.len > 0:
        node.insert insertionPoint, newCall("add", ident("result"), newStrLitNode(splitValue))


proc parse_template(node: NimNode, value: string) =
    ## Parses through entire template, outputting valid
    ## Nim code into the input `node` AST.
    var index = 0
    while index < value.len and
          parse_until_symbol(node, value, index): discard


macro tmpli*(body: untyped): untyped =
    result = newStmtList()

    result.add parseExpr("result = \"\"")

    var value = if body.kind in nnkStrLit..nnkTripleStrLit: body.strVal
                else: body[1].strVal

    parse_template(result, reindent(value))


macro tmpl*(body: untyped): untyped =
    result = newStmtList()

    var value = if body.kind in nnkStrLit..nnkTripleStrLit: body.strVal
                else: body[1].strVal

    parse_template(result, reindent(value))


# Run tests
when true:
    include otests
    echo "Success"
