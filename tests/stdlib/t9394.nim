import terminal, colors

let codeFg = ansiForegroundColorCode(colAliceBlue)
let codeBg = ansiBackgroundColorCode(colAliceBlue)

doAssert codeFg == "\27[38;2;240;248;255m"
doAssert codeBg == "\27[48;2;240;248;255m"
