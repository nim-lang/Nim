import mseqimportcfloatalias, mseqplainfloatseq

var imported: seq[CFloatAlias] = @[CFloatAlias(1)]
var plain = @[2'f32]

clearImported(imported)
clearPlain(plain)

doAssert imported.len == 0
doAssert plain.len == 0
