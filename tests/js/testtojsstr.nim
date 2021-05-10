let s: string = "И\n"
let cs = s.cstring

doAssert $cs == "И\n"
doAssert s == "И\n"
