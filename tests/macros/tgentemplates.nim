# bug #1140

import parseutils, macros

proc parse_until_symbol(node: NimNode, value: string, index: var int): bool {.compiletime.} =
    var splitValue: string
    var read = value.parseUntil(splitValue, '$', index)

    # when false:
    if false:
        var identifier: string
        read = value.parseWhile(identifier, {}, index)
        node.add newCall("add", ident("result"), newCall("$", ident(identifier)))

    if splitValue.len > 0:
        node.insert node.len, newCall("add", ident("result"), newStrLitNode(splitValue))

proc parse_template(node: NimNode, value: string) {.compiletime.} =
    var index = 0
    while index < value.len and
        parse_until_symbol(node, value, index): discard

macro tmpli*(body: expr): stmt =
    result = newStmtList()
    result.add parseExpr("result = \"\"")
    result.parse_template body[1].strVal


proc actual: string = tmpli html"""
    <p>Test!</p>
    """

proc another: string = tmpli html"""
    <p>what</p>
    """
