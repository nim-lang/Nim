import strutils

type
  TColor = distinct int32

proc rgb(r, g, b: range[0..255]): TColor = 
  result = TColor(r or g shl 8 or b shl 16)

proc `$`(c: TColor): string =
  result = "#" & toHex(int32(c), 6)

echo rgb(34, 55, 255)

when false:
  type
    TColor = distinct int32
    TColorComponent = distinct int8
  
  proc red(a: TColor): TColorComponent = 
    result = TColorComponent(int32(a) and 0xff'i32)
  
  proc green(a: TColor): TColorComponent = 
    result = TColorComponent(int32(a) shr 8'i32 and 0xff'i32)
  
  proc blue(a: TColor): TColorComponent = 
    result = TColorComponent(int32(a) shr 16'i32 and 0xff'i32)
  
  proc rgb(r, g, b: range[0..255]): TColor = 
    result = TColor(r or g shl 8 or b shl 8)
  
  proc `+!` (a, b: TColorComponent): TColorComponent =  
    ## saturated arithmetic:
    result = TColorComponent(min(ze(int8(a)) + ze(int8(b)), 255))
  
  proc `+` (a, b: TColor): TColor = 
    ## saturated arithmetic for colors makes sense, I think:
    return rgb(red(a) +! red(b), green(a) +! green(b), blue(a) +! blue(b))
  
  rgb(34, 55, 255)
