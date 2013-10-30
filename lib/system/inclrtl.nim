#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
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

when defined(createNimRtl):
  when defined(useNimRtl):
    {.error: "Cannot create and use nimrtl at the same time!".}
  elif appType != "lib":
    {.error: "nimrtl must be built as a library!".}

when defined(createNimRtl):
  {.pragma: rtl, exportc: "nimrtl_$1", dynlib.}
  {.pragma: inl.}
  {.pragma: compilerRtl, compilerproc, exportc: "nimrtl_$1", dynlib.}
elif defined(useNimRtl):
  when hostOS == "windows":
    const nimrtl* = "nimrtl.dll"
  elif hostOS == "macosx":
    const nimrtl* = "nimrtl.dylib"
  else:
    const nimrtl* = "libnimrtl.so"
  {.pragma: rtl, importc: "nimrtl_$1", dynlib: nimrtl.}
  {.pragma: inl.}
  {.pragma: compilerRtl, compilerproc, importc: "nimrtl_$1", dynlib: nimrtl.}
else:
  {.pragma: rtl.}
  {.pragma: inl, inline.}
  {.pragma: compilerRtl, compilerproc.}

when not defined(nimsuperops):
  {.pragma: operator.}
