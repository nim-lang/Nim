import ../ccgbugs/mseq_importc_alias

type CIntAlias = cint

var values: seq[CIntAlias]
resizeCints(values, 2)
doAssert cintLen(values) == 2
