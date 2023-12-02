type
  InlineAsmSyntax* = enum
    None
    GCCExtendedAsm
    VisualCPP
  
  TargetProps* = object
    inlineAsmSyntax*: InlineAsmSyntax
