import
  tri_engine/config,
  tri_engine/math/vec

from strutils import
  formatFloat,
  TFloatFormat,
  `%`,
  ffDecimal

type
  TColor* = tuple[r, g, b, a: TR]

converter toColor*(o: uint32): TColor =
  ## Convert an integer to a color. This is mostly useful when the integer is specified as a hex
  ## literal such as 0xFF00007F, which is 100% red, with 50% alpha.
  ## TODO: turn this into a template that can take either 4 or 8 characters?
  ((((o and 0xff000000'u32) shr 24).TR / 255.0).TR,
   (((o and 0xff0000'u32) shr 16).TR / 255.0).TR,
   (((o and 0xff00'u32) shr 8).TR / 255.0).TR,
   (((o and 0xff'u32)).TR / 255.0).TR)

converter toV4*(o: TColor): TV4[TR] =
  cast[TV4[TR]](o)

proc newColor*(r, g, b: TR=0.0, a: TR=1.0): TColor =
  (r, g, b, a)

proc white*(rgb, a: TR=1.0): TColor =
  (rgb, rgb, rgb, a)

proc red*(r, a: TR=1.0): TColor =
  newColor(r=r, a=a)

proc green*(g, a: TR=1.0): TColor =
  newColor(g=g, a=a)

proc yellow*(rg, a: TR=1.0): TColor =
  newColor(r=rg, g=rg, a=a)

proc blue*(b, a: TR=1.0): TColor =
  newColor(b=b, a=a)

proc cyan*(gb, a: TR=1.0): TColor =
  newColor(g=gb, b=gb, a=a)

proc purple*(rb, a: TR=1.0): TColor =
  newColor(r=rb, b=rb, a=a)

proc `$`*(o: TColor): string =
  proc f(f: float): string =
    f.formatFloat(precision=2, format=ffDecimal)

  "(r: $#, g: $#, b: $#, s: $#)" % [f(o.r), f(o.g), f(o.b), f(o.a)]
