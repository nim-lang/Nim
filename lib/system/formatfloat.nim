when not defined(nimPreviewSlimSystem):
  import std/formatfloat
  export formatfloat
  {.deprecated: "use `std/formatfloat`".}
else:
  {.error: "use `std/formatfloat`".}
