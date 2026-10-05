import mseqimportcuintalias, mseqplainuint32

var imported: seq[cuint] = @[cuint(1)]
var plain: seq[uint32] = @[2'u32]

clearCuint(imported)
clearUint32(plain)

doAssert imported.len == 0
doAssert plain.len == 0
