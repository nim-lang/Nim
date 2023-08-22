import macros, parseutils

# Generate tags
macro make(names: untyped{nkBracket}): untyped =
    result = newStmtList()

    for i in 0 .. names.len-1:
        result.add newProc(
            name   = ident($names[i]).postfix("*"),
            params = [
                ident("string"),
                newIdentDefs(
                    ident("content"),
                    ident("string")
                )
            ],
            body = newStmtList(
                parseStmt("reindent(content)")
            )
        )


iterator lines(value: string): string =
    var i = 0
    while i < value.len:
        var line: string
        inc(i, value.parseUntil(line, 0x0A.char, i) + 1)
        yield line


proc reindent*(value: string, preset_indent = 0): string =
    var indent = -1

    # Detect indentation!
    for ln in lines(value):
        var read = ln.skipWhitespace()

        # If the line is empty, ignore it for indentation
        if read == ln.len: continue

        indent = if indent < 0: read
                 else: min(indent, read)

    # Create a precursor indent as-needed
    var precursor = newString(0)
    for i in 1 .. preset_indent:
        precursor.add(' ')

    # Re-indent
    result = newString(0)

    for ln in lines(value):
        var value = ln.substr(indent)

        result.add(precursor)

        if value.len > 0:
            result.add(value)
            result.add(0x0A.char)

    return result


#Define tags
make([ html, xml, glsl, js, css, rst ])


when isMainModule:
    ## Test tags

    const script = js"""
        var x = 5;
        console.log(x.toString());
    """

    const styles = css"""
        .someRule {
            width: 500px;
        }
    """

    const body = html"""
        <ul>
            <li>1</li>
            <li>2</li>
            <li>
                <a hef="#google">google</a>
            </li>
        </ul>
    """

    const info = xml"""
        <item>
            <i>1</i>
            <i>2</i>
        </item>
    """

    const shader = glsl"""
        void main()
        {
            gl_Position = gl_ProjectionMatrix
                        * gl_ModelViewMatrix
                        * gl_Vertex;
        }
    """


    echo script
    echo styles
    echo body
    echo info
    echo shader
