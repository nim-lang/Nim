type
  InlineAsmSyntaxKind* = enum
    GCCExtendedAsm
    VisualCPP
  
  TargetProps* = object
    inlineAsmSyntax*: set[InlineAsmSyntaxKind] # for example in icc {GCCExtendedAsm, VisualCPP}
