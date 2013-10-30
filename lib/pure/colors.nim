#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements color handling for Nimrod. It is used by
## the ``graphics`` module.

import strutils

type
  TColor* = distinct int ## a color stored as RGB

proc `==` *(a, b: TColor): bool {.borrow.}
  ## compares two colors.

template extract(a: TColor, r, g, b: expr) {.immediate.}=
  var r = a.int shr 16 and 0xff
  var g = a.int shr 8 and 0xff
  var b = a.int and 0xff

template rawRGB(r, g, b: int): expr =
  TColor(r shl 16 or g shl 8 or b)

template colorOp(op: expr) {.immediate.} =
  extract(a, ar, ag, ab)
  extract(b, br, bg, bb)
  result = rawRGB(op(ar, br), op(ag, bg), op(ab, bb))

proc satPlus(a, b: int): int {.inline.} =
  result = a +% b
  if result > 255: result = 255

proc satMinus(a, b: int): int {.inline.} =
  result = a -% b
  if result < 0: result = 0

proc `+`*(a, b: TColor): TColor =
  ## adds two colors: This uses saturated artithmetic, so that each color
  ## component cannot overflow (255 is used as a maximum).
  colorOp(satPlus)

proc `-`*(a, b: TColor): TColor =
  ## substracts two colors: This uses saturated artithmetic, so that each color
  ## component cannot overflow (255 is used as a maximum).
  colorOp(satMinus)

proc extractRGB*(a: TColor): tuple[r, g, b: range[0..255]] =
  ## extracts the red/green/blue components of the color `a`.
  result.r = a.int shr 16 and 0xff
  result.g = a.int shr 8 and 0xff
  result.b = a.int and 0xff

proc intensity*(a: TColor, f: float): TColor =
  ## returns `a` with intensity `f`. `f` should be a float from 0.0 (completely
  ## dark) to 1.0 (full color intensity).
  var r = toInt(toFloat(a.int shr 16 and 0xff) * f)
  var g = toInt(toFloat(a.int shr 8 and 0xff) * f)
  var b = toInt(toFloat(a.int and 0xff) * f)
  if r >% 255: r = 255
  if g >% 255: g = 255
  if b >% 255: b = 255
  result = rawRGB(r, g, b)

template mix*(a, b: TColor, fn: expr): expr =
  ## uses `fn` to mix the colors `a` and `b`. `fn` is invoked for each component
  ## R, G, and B. This is a template because `fn` should be inlined and the
  ## compiler cannot inline proc pointers yet. If `fn`'s result is not in the
  ## range[0..255], it will be saturated to be so.
  template `><` (x: expr): expr =
    # keep it in the range 0..255
    block:
      var y = x # eval only once
      if y >% 255:
        y = if y < 0: 0 else: 255
      y

  (bind extract)(a, ar, ag, ab)
  (bind extract)(b, br, bg, bb)
  (bind rawRGB)(><fn(ar, br), ><fn(ag, bg), ><fn(ab, bb))


const
  colAliceBlue* = TColor(0xF0F8FF)
  colAntiqueWhite* = TColor(0xFAEBD7)
  colAqua* = TColor(0x00FFFF)
  colAquamarine* = TColor(0x7FFFD4)
  colAzure* = TColor(0xF0FFFF)
  colBeige* = TColor(0xF5F5DC)
  colBisque* = TColor(0xFFE4C4)
  colBlack* = TColor(0x000000)
  colBlanchedAlmond* = TColor(0xFFEBCD)
  colBlue* = TColor(0x0000FF)
  colBlueViolet* = TColor(0x8A2BE2)
  colBrown* = TColor(0xA52A2A)
  colBurlyWood* = TColor(0xDEB887)
  colCadetBlue* = TColor(0x5F9EA0)
  colChartreuse* = TColor(0x7FFF00)
  colChocolate* = TColor(0xD2691E)
  colCoral* = TColor(0xFF7F50)
  colCornflowerBlue* = TColor(0x6495ED)
  colCornsilk* = TColor(0xFFF8DC)
  colCrimson* = TColor(0xDC143C)
  colCyan* = TColor(0x00FFFF)
  colDarkBlue* = TColor(0x00008B)
  colDarkCyan* = TColor(0x008B8B)
  colDarkGoldenRod* = TColor(0xB8860B)
  colDarkGray* = TColor(0xA9A9A9)
  colDarkGreen* = TColor(0x006400)
  colDarkKhaki* = TColor(0xBDB76B)
  colDarkMagenta* = TColor(0x8B008B)
  colDarkOliveGreen* = TColor(0x556B2F)
  colDarkorange* = TColor(0xFF8C00)
  colDarkOrchid* = TColor(0x9932CC)
  colDarkRed* = TColor(0x8B0000)
  colDarkSalmon* = TColor(0xE9967A)
  colDarkSeaGreen* = TColor(0x8FBC8F)
  colDarkSlateBlue* = TColor(0x483D8B)
  colDarkSlateGray* = TColor(0x2F4F4F)
  colDarkTurquoise* = TColor(0x00CED1)
  colDarkViolet* = TColor(0x9400D3)
  colDeepPink* = TColor(0xFF1493)
  colDeepSkyBlue* = TColor(0x00BFFF)
  colDimGray* = TColor(0x696969)
  colDodgerBlue* = TColor(0x1E90FF)
  colFireBrick* = TColor(0xB22222)
  colFloralWhite* = TColor(0xFFFAF0)
  colForestGreen* = TColor(0x228B22)
  colFuchsia* = TColor(0xFF00FF)
  colGainsboro* = TColor(0xDCDCDC)
  colGhostWhite* = TColor(0xF8F8FF)
  colGold* = TColor(0xFFD700)
  colGoldenRod* = TColor(0xDAA520)
  colGray* = TColor(0x808080)
  colGreen* = TColor(0x008000)
  colGreenYellow* = TColor(0xADFF2F)
  colHoneyDew* = TColor(0xF0FFF0)
  colHotPink* = TColor(0xFF69B4)
  colIndianRed* = TColor(0xCD5C5C)
  colIndigo* = TColor(0x4B0082)
  colIvory* = TColor(0xFFFFF0)
  colKhaki* = TColor(0xF0E68C)
  colLavender* = TColor(0xE6E6FA)
  colLavenderBlush* = TColor(0xFFF0F5)
  colLawnGreen* = TColor(0x7CFC00)
  colLemonChiffon* = TColor(0xFFFACD)
  colLightBlue* = TColor(0xADD8E6)
  colLightCoral* = TColor(0xF08080)
  colLightCyan* = TColor(0xE0FFFF)
  colLightGoldenRodYellow* = TColor(0xFAFAD2)
  colLightGrey* = TColor(0xD3D3D3)
  colLightGreen* = TColor(0x90EE90)
  colLightPink* = TColor(0xFFB6C1)
  colLightSalmon* = TColor(0xFFA07A)
  colLightSeaGreen* = TColor(0x20B2AA)
  colLightSkyBlue* = TColor(0x87CEFA)
  colLightSlateGray* = TColor(0x778899)
  colLightSteelBlue* = TColor(0xB0C4DE)
  colLightYellow* = TColor(0xFFFFE0)
  colLime* = TColor(0x00FF00)
  colLimeGreen* = TColor(0x32CD32)
  colLinen* = TColor(0xFAF0E6)
  colMagenta* = TColor(0xFF00FF)
  colMaroon* = TColor(0x800000)
  colMediumAquaMarine* = TColor(0x66CDAA)
  colMediumBlue* = TColor(0x0000CD)
  colMediumOrchid* = TColor(0xBA55D3)
  colMediumPurple* = TColor(0x9370D8)
  colMediumSeaGreen* = TColor(0x3CB371)
  colMediumSlateBlue* = TColor(0x7B68EE)
  colMediumSpringGreen* = TColor(0x00FA9A)
  colMediumTurquoise* = TColor(0x48D1CC)
  colMediumVioletRed* = TColor(0xC71585)
  colMidnightBlue* = TColor(0x191970)
  colMintCream* = TColor(0xF5FFFA)
  colMistyRose* = TColor(0xFFE4E1)
  colMoccasin* = TColor(0xFFE4B5)
  colNavajoWhite* = TColor(0xFFDEAD)
  colNavy* = TColor(0x000080)
  colOldLace* = TColor(0xFDF5E6)
  colOlive* = TColor(0x808000)
  colOliveDrab* = TColor(0x6B8E23)
  colOrange* = TColor(0xFFA500)
  colOrangeRed* = TColor(0xFF4500)
  colOrchid* = TColor(0xDA70D6)
  colPaleGoldenRod* = TColor(0xEEE8AA)
  colPaleGreen* = TColor(0x98FB98)
  colPaleTurquoise* = TColor(0xAFEEEE)
  colPaleVioletRed* = TColor(0xD87093)
  colPapayaWhip* = TColor(0xFFEFD5)
  colPeachPuff* = TColor(0xFFDAB9)
  colPeru* = TColor(0xCD853F)
  colPink* = TColor(0xFFC0CB)
  colPlum* = TColor(0xDDA0DD)
  colPowderBlue* = TColor(0xB0E0E6)
  colPurple* = TColor(0x800080)
  colRed* = TColor(0xFF0000)
  colRosyBrown* = TColor(0xBC8F8F)
  colRoyalBlue* = TColor(0x4169E1)
  colSaddleBrown* = TColor(0x8B4513)
  colSalmon* = TColor(0xFA8072)
  colSandyBrown* = TColor(0xF4A460)
  colSeaGreen* = TColor(0x2E8B57)
  colSeaShell* = TColor(0xFFF5EE)
  colSienna* = TColor(0xA0522D)
  colSilver* = TColor(0xC0C0C0)
  colSkyBlue* = TColor(0x87CEEB)
  colSlateBlue* = TColor(0x6A5ACD)
  colSlateGray* = TColor(0x708090)
  colSnow* = TColor(0xFFFAFA)
  colSpringGreen* = TColor(0x00FF7F)
  colSteelBlue* = TColor(0x4682B4)
  colTan* = TColor(0xD2B48C)
  colTeal* = TColor(0x008080)
  colThistle* = TColor(0xD8BFD8)
  colTomato* = TColor(0xFF6347)
  colTurquoise* = TColor(0x40E0D0)
  colViolet* = TColor(0xEE82EE)
  colWheat* = TColor(0xF5DEB3)
  colWhite* = TColor(0xFFFFFF)
  colWhiteSmoke* = TColor(0xF5F5F5)
  colYellow* = TColor(0xFFFF00)
  colYellowGreen* = TColor(0x9ACD32)

  colorNames = [
    ("aliceblue", colAliceBlue),
    ("antiquewhite", colAntiqueWhite),
    ("aqua", colAqua),
    ("aquamarine", colAquamarine),
    ("azure", colAzure),
    ("beige", colBeige),
    ("bisque", colBisque),
    ("black", colBlack),
    ("blanchedalmond", colBlanchedAlmond),
    ("blue", colBlue),
    ("blueviolet", colBlueViolet),
    ("brown", colBrown),
    ("burlywood", colBurlyWood),
    ("cadetblue", colCadetBlue),
    ("chartreuse", colChartreuse),
    ("chocolate", colChocolate),
    ("coral", colCoral),
    ("cornflowerblue", colCornflowerBlue),
    ("cornsilk", colCornsilk),
    ("crimson", colCrimson),
    ("cyan", colCyan),
    ("darkblue", colDarkBlue),
    ("darkcyan", colDarkCyan),
    ("darkgoldenrod", colDarkGoldenRod),
    ("darkgray", colDarkGray),
    ("darkgreen", colDarkGreen),
    ("darkkhaki", colDarkKhaki),
    ("darkmagenta", colDarkMagenta),
    ("darkolivegreen", colDarkOliveGreen),
    ("darkorange", colDarkorange),
    ("darkorchid", colDarkOrchid),
    ("darkred", colDarkRed),
    ("darksalmon", colDarkSalmon),
    ("darkseagreen", colDarkSeaGreen),
    ("darkslateblue", colDarkSlateBlue),
    ("darkslategray", colDarkSlateGray),
    ("darkturquoise", colDarkTurquoise),
    ("darkviolet", colDarkViolet),
    ("deeppink", colDeepPink),
    ("deepskyblue", colDeepSkyBlue),
    ("dimgray", colDimGray),
    ("dodgerblue", colDodgerBlue),
    ("firebrick", colFireBrick),
    ("floralwhite", colFloralWhite),
    ("forestgreen", colForestGreen),
    ("fuchsia", colFuchsia),
    ("gainsboro", colGainsboro),
    ("ghostwhite", colGhostWhite),
    ("gold", colGold),
    ("goldenrod", colGoldenRod),
    ("gray", colGray),
    ("green", colGreen),
    ("greenyellow", colGreenYellow),
    ("honeydew", colHoneyDew),
    ("hotpink", colHotPink),
    ("indianred", colIndianRed),
    ("indigo", colIndigo),
    ("ivory", colIvory),
    ("khaki", colKhaki),
    ("lavender", colLavender),
    ("lavenderblush", colLavenderBlush),
    ("lawngreen", colLawnGreen),
    ("lemonchiffon", colLemonChiffon),
    ("lightblue", colLightBlue),
    ("lightcoral", colLightCoral),
    ("lightcyan", colLightCyan),
    ("lightgoldenrodyellow", colLightGoldenRodYellow),
    ("lightgrey", colLightGrey),
    ("lightgreen", colLightGreen),
    ("lightpink", colLightPink),
    ("lightsalmon", colLightSalmon),
    ("lightseagreen", colLightSeaGreen),
    ("lightskyblue", colLightSkyBlue),
    ("lightslategray", colLightSlateGray),
    ("lightsteelblue", colLightSteelBlue),
    ("lightyellow", colLightYellow),
    ("lime", colLime),
    ("limegreen", colLimeGreen),
    ("linen", colLinen),
    ("magenta", colMagenta),
    ("maroon", colMaroon),
    ("mediumaquamarine", colMediumAquaMarine),
    ("mediumblue", colMediumBlue),
    ("mediumorchid", colMediumOrchid),
    ("mediumpurple", colMediumPurple),
    ("mediumseagreen", colMediumSeaGreen),
    ("mediumslateblue", colMediumSlateBlue),
    ("mediumspringgreen", colMediumSpringGreen),
    ("mediumturquoise", colMediumTurquoise),
    ("mediumvioletred", colMediumVioletRed),
    ("midnightblue", colMidnightBlue),
    ("mintcream", colMintCream),
    ("mistyrose", colMistyRose),
    ("moccasin", colMoccasin),
    ("navajowhite", colNavajoWhite),
    ("navy", colNavy),
    ("oldlace", colOldLace),
    ("olive", colOlive),
    ("olivedrab", colOliveDrab),
    ("orange", colOrange),
    ("orangered", colOrangeRed),
    ("orchid", colOrchid),
    ("palegoldenrod", colPaleGoldenRod),
    ("palegreen", colPaleGreen),
    ("paleturquoise", colPaleTurquoise),
    ("palevioletred", colPaleVioletRed),
    ("papayawhip", colPapayaWhip),
    ("peachpuff", colPeachPuff),
    ("peru", colPeru),
    ("pink", colPink),
    ("plum", colPlum),
    ("powderblue", colPowderBlue),
    ("purple", colPurple),
    ("red", colRed),
    ("rosybrown", colRosyBrown),
    ("royalblue", colRoyalBlue),
    ("saddlebrown", colSaddleBrown),
    ("salmon", colSalmon),
    ("sandybrown", colSandyBrown),
    ("seagreen", colSeaGreen),
    ("seashell", colSeaShell),
    ("sienna", colSienna),
    ("silver", colSilver),
    ("skyblue", colSkyBlue),
    ("slateblue", colSlateBlue),
    ("slategray", colSlateGray),
    ("snow", colSnow),
    ("springgreen", colSpringGreen),
    ("steelblue", colSteelBlue),
    ("tan", colTan),
    ("teal", colTeal),
    ("thistle", colThistle),
    ("tomato", colTomato),
    ("turquoise", colTurquoise),
    ("violet", colViolet),
    ("wheat", colWheat),
    ("white", colWhite),
    ("whitesmoke", colWhiteSmoke),
    ("yellow", colYellow),
    ("yellowgreen", colYellowGreen)]

proc `$`*(c: TColor): string =
  ## converts a color into its textual representation. Example: ``#00FF00``.
  result = '#' & toHex(int(c), 6)

proc binaryStrSearch(x: openarray[tuple[name: string, col: TColor]],
                     y: string): int =
  var a = 0
  var b = len(x) - 1
  while a <= b:
    var mid = (a + b) div 2
    var c = cmp(x[mid].name, y)
    if c < 0: a = mid + 1
    elif c > 0: b = mid - 1
    else: return mid
  result = - 1

proc parseColor*(name: string): TColor =
  ## parses `name` to a color value. If no valid color could be
  ## parsed ``EInvalidValue`` is raised.
  if name[0] == '#':
    result = TColor(parseHexInt(name))
  else:
    var idx = binaryStrSearch(colorNames, name)
    if idx < 0: raise newException(EInvalidValue, "unkown color: " & name)
    result = colorNames[idx][1]

proc isColor*(name: string): bool =
  ## returns true if `name` is a known color name or a hexadecimal color
  ## prefixed with ``#``.
  if name[0] == '#':
    for i in 1 .. name.len-1:
      if name[i] notin {'0'..'9', 'a'..'f', 'A'..'F'}: return false
    result = true
  else:
    result = binaryStrSearch(colorNames, name) >= 0

proc rgb*(r, g, b: range[0..255]): TColor =
  ## constructs a color from RGB values.
  result = rawRGB(r, g, b)

