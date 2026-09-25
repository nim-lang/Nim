# Helper for tlocalpassc.nim: make the C compiler prove that a module-level
# `{.localPassC.}` pragma survives the IC backend reload.
when defined(gcc) or defined(clang):
  {.localPassC: "-DNIM_IC_LOCAL_PASSC".}
  {.
    emit: """/*TYPESECTION*/
#ifndef NIM_IC_LOCAL_PASSC
#error "IC lost the module's localPassC option"
#endif
"""
  .}

proc localPassCAnswer*(): int =
  42
