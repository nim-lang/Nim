#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Pragmas for RTL generation. Has to be an include, because user-defined
# pragmas cannot be exported.

# There are 3 different usages:
# 1) Ordinary imported code.
# 2) Imported from nimrtl.
#    -> defined(useNimRtl) or appType == "lib" and not defined(createNimRtl)
# 3) Exported into nimrtl.
#    -> appType == "lib" and defined(createNimRtl)
when not defined(nimNewShared):
  {.pragma: gcsafe.}

when defined(createNimRtl):
  when defined(useNimRtl):
    {.error: "Cannot create and use nimrtl at the same time!".}
  elif appType != "lib":
    {.error: "nimrtl must be built as a library!".}

when defined(createNimRtl):
  {.pragma: rtl, exportc: "nimrtl_$1", dynlib, gcsafe.}
  {.pragma: inl.}
  {.pragma: compilerRtl, compilerproc, exportc: "nimrtl_$1", dynlib.}
elif defined(useNimRtl):
  when not declared(nimrtlInclrtl):
    # `when` needed because otherwise this could give `ambiguous identifier:` errors.
    # xxx we should instead improve pragmas so that symbol binding happens,
    # as well as allow a way to export pragamas, to avoid inclrtl being an include.
    const nimrtlInclrtl* =
      when defined(windows): "nimrtl.dll"
      elif defined(macosx): "libnimrtl.dylib"
      else: "libnimrtl.so"
  {.pragma: rtl, importc: "nimrtl_$1", dynlib: nimrtlInclrtl, gcsafe.}
  {.pragma: inl.}
  {.pragma: compilerRtl, compilerproc, importc: "nimrtl_$1", dynlib: nimrtlInclrtl.}
else:
  {.pragma: rtl, gcsafe.}
  {.pragma: inl, inline.}
  {.pragma: compilerRtl, compilerproc.}

{.pragma: benign, gcsafe, locks: 0.}

when defined(nimHasSinkInference):
  {.push sinkInference: on.}
