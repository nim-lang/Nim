type GoodImportcType {.importc: "signed char", nodecl.} = char
  # "good" in sense the sizeof will match
type BadImportcType {.importc: "unsigned char", nodecl.} = uint64
  # "sizeof" check will fail

echo GoodImportcType.default
echo BadImportcType.default
