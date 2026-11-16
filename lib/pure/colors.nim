#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements color handling for Nim,
## namely color mixing and parsing the CSS color names.

import std/[strutils, math]
from std/algorithm import binarySearch

type
  Color* = distinct uint32 ## A color stored as RGBA, e.g. `0xff00ccff`.

proc r*(c: Color): uint8 =
  (uint32(c) shr 24).uint8

proc g*(c: Color): uint8 =
  (uint32(c) shr 16).uint8

proc b*(c: Color): uint8 =
  (uint32(c) shr 8).uint8

proc a*(c: Color): uint8 =
  c.uint8

proc `r=`*(c: var Color, value: uint8) =
  c = Color((uint32(c) and 0x00ffffff'u32) or (value.uint32 shl 24))

proc `g=`*(c: var Color, value: uint8) =
  c = Color((uint32(c) and 0xff00ffff'u32) or (value.uint32 shl 16))

proc `b=`*(c: var Color, value: uint8) =
  c = Color((uint32(c) and 0xffff00ff'u32) or (value.uint32 shl 8))

proc `a=`*(c: var Color, value: uint8) =
  c = Color((uint32(c) and 0xffffff00'u32) or value.uint32)

proc `==`*(a, b: Color): bool {.borrow.}
  ## Compares two colors.
  ##
  ##   ```Nim
  ##   var
  ##     a = Color(0xff_00_ff_ff)
  ##     b = colFuchsia
  ##     c = Color(0x00_ff_cc_ff)
  ##   assert a == b
  ##   assert not (a == c)
  ##   ```

template extract(c: Color, r, g, b, a: untyped) =
  var r = uint8(c.uint32 shr 24 and 0xff)
  var g = uint8(c.uint32 shr 16 and 0xff)
  var b = uint8(c.uint32 shr 8 and 0xff)
  var a = uint8(c.uint32 and 0xff)

template rawRgba(r, g, b, a: uint8): Color =
  Color(r.uint32 shl 24 or g.uint32 shl 16 or b.uint32 shl 8 or a.uint32)

template colorOp(op): Color =
  extract(c1, c1r, c1g, c1b, c1a)
  extract(c2, c2r, c2g, c2b, c2a)
  rawRgba(op(c1r, c2r), op(c1g, c2g), op(c1b, c2b), op(c1a, c2a))

proc satPlus(c1, c2: uint8): uint8 {.inline.} =
  result = uint8(min(c1.int + c2.int, 255))

proc satMinus(c1, c2: uint8): uint8 {.inline.} =
  result = uint8(max(c1.int - c2.int, 0))

proc `+`*(c1, c2: Color): Color =
  ## Adds two colors.
  ##
  ## This uses saturated arithmetic, so that each color
  ## component cannot overflow (255 is used as a maximum).
  ##
  runnableExamples:
    var
      a = Color(0xaa_00_ff_ff)
      b = Color(0x11_cc_cc_ff)
    assert a + b == Color(0xbb_cc_ff_ff)

  colorOp(satPlus)

proc `-`*(c1, c2: Color): Color =
  ## Subtracts two colors.
  ##
  ## This uses saturated arithmetic, so that each color
  ## component cannot underflow (0 is used as a minimum).
  ##
  runnableExamples:
    var
      a = Color(0xff_33_ff_ff)
      b = Color(0x11_ff_cc_ff)
    assert a - b == Color(0xee_00_33_00)

  colorOp(satMinus)

proc extractRgba*(c: Color): tuple[r, g, b, a: uint8] =
  ## Extracts the red/green/blue/alpha components of the color `c`.
  ##
  runnableExamples:
    var
      a = Color(0xff_00_ff_ff)
      b = Color(0x00_ff_cc_ff)
    assert extractRgba(a) == (r: 255'u8, g: 0'u8, b: 255'u8, a: 255'u8)
    assert extractRgba(b) == (r: 0'u8, g: 255'u8, b: 204'u8, a: 255'u8)
    echo extractRgba(a)
    echo typeof(extractRgba(a))
    echo extractRgba(b)
    echo typeof(extractRgba(b))
  result.r = uint8(c.uint32 shr 24 and 0xff)
  result.g = uint8(c.uint32 shr 16 and 0xff)
  result.b = uint8(c.uint32 shr 8 and 0xff)
  result.a = uint8(c.uint32 and 0xff)

proc intensity*(c: Color, f: float): Color =
  ## Returns `c` with intensity `f`. `f` must be a float from 0.0 (completely
  ## dark) to 1.0 (full color intensity).
  ##
  runnableExamples:
    var
      a = Color(0xff_00_ff_ff)
      b = Color(0x00_42_cc_ff)
    assert a.intensity(0.5) == Color(0x80_00_80_ff)
    assert b.intensity(0.5) == Color(0x00_21_66_ff)

  if f < 0.0 or f > 1.0:
    raise newException(ValueError, "intensity factor must be between 0.0 and 1.0")

  var r = uint8(round(float(c.uint32 shr 24 and 0xff) * f))
  var g = uint8(round(float(c.uint32 shr 16 and 0xff) * f))
  var b = uint8(round(float(c.uint32 shr 8 and 0xff) * f))
  var a = uint8(c.uint32 and 0xff)
  result = rawRgba(r, g, b, a)

template mix*(a, b: Color, fn: untyped): untyped =
  ## Uses `fn` to mix the colors `a` and `b`.
  ##
  ## `fn` is invoked for each component R, G, B, and A.
  ## If `fn`'s result is not in the between 0 and 255, it will be clamped.
  ##
  runnableExamples:
    var
      a = Color(0x0a2814ff)
      b = Color(0x050a03ff)

    proc myMix(x, y: int): int =
      2 * x - 3 * y

    assert mix(a, b, myMix) == Color(0x05_32_1f_00)

  extract(a, ar, ag, ab, aa)
  extract(b, br, bg, bb, ba)
  rawRgba(
    clamp(fn(ar.int, br.int), 0, 255).uint8,
    clamp(fn(ag.int, bg.int), 0, 255).uint8,
    clamp(fn(ab.int, bb.int), 0, 255).uint8,
    clamp(fn(aa.int, ba.int), 0, 255).uint8
  )


const
  colAliceBlue* = Color(0xF0F8FFFF)
  colAntiqueWhite* = Color(0xFAEBD7FF)
  colAqua* = Color(0x00FFFFFF)
  colAquamarine* = Color(0x7FFFD4FF)
  colAzure* = Color(0xF0FFFFFF)
  colBeige* = Color(0xF5F5DCFF)
  colBisque* = Color(0xFFE4C4FF)
  colBlack* = Color(0x000000FF)
  colBlanchedAlmond* = Color(0xFFEBCDFF)
  colBlue* = Color(0x0000FFFF)
  colBlueViolet* = Color(0x8A2BE2FF)
  colBrown* = Color(0xA52A2AFF)
  colBurlyWood* = Color(0xDEB887FF)
  colCadetBlue* = Color(0x5F9EA0FF)
  colChartreuse* = Color(0x7FFF00FF)
  colChocolate* = Color(0xD2691EFF)
  colCoral* = Color(0xFF7F50FF)
  colCornflowerBlue* = Color(0x6495EDFF)
  colCornsilk* = Color(0xFFF8DCFF)
  colCrimson* = Color(0xDC143CFF)
  colCyan* = Color(0x00FFFFFF)
  colDarkBlue* = Color(0x00008BFF)
  colDarkCyan* = Color(0x008B8BFF)
  colDarkGoldenRod* = Color(0xB8860BFF)
  colDarkGray* = Color(0xA9A9A9FF)
  colDarkGreen* = Color(0x006400FF)
  colDarkGrey* = Color(0xA9A9A9FF)
  colDarkKhaki* = Color(0xBDB76BFF)
  colDarkMagenta* = Color(0x8B008BFF)
  colDarkOliveGreen* = Color(0x556B2FFF)
  colDarkorange* = Color(0xFF8C00FF)
  colDarkOrchid* = Color(0x9932CCFF)
  colDarkRed* = Color(0x8B0000FF)
  colDarkSalmon* = Color(0xE9967AFF)
  colDarkSeaGreen* = Color(0x8FBC8FFF)
  colDarkSlateBlue* = Color(0x483D8BFF)
  colDarkSlateGray* = Color(0x2F4F4FFF)
  colDarkSlateGrey* = Color(0x2F4F4FFF)
  colDarkTurquoise* = Color(0x00CED1FF)
  colDarkViolet* = Color(0x9400D3FF)
  colDeepPink* = Color(0xFF1493FF)
  colDeepSkyBlue* = Color(0x00BFFFFF)
  colDimGray* = Color(0x696969FF)
  colDimGrey* = Color(0x696969FF)
  colDodgerBlue* = Color(0x1E90FFFF)
  colFireBrick* = Color(0xB22222FF)
  colFloralWhite* = Color(0xFFFAF0FF)
  colForestGreen* = Color(0x228B22FF)
  colFuchsia* = Color(0xFF00FFFF)
  colGainsboro* = Color(0xDCDCDCFF)
  colGhostWhite* = Color(0xF8F8FFFF)
  colGold* = Color(0xFFD700FF)
  colGoldenRod* = Color(0xDAA520FF)
  colGray* = Color(0x808080FF)
  colGreen* = Color(0x008000FF)
  colGreenYellow* = Color(0xADFF2FFF)
  colGrey* = Color(0x808080FF)
  colHoneyDew* = Color(0xF0FFF0FF)
  colHotPink* = Color(0xFF69B4FF)
  colIndianRed* = Color(0xCD5C5CFF)
  colIndigo* = Color(0x4B0082FF)
  colIvory* = Color(0xFFFFF0FF)
  colKhaki* = Color(0xF0E68CFF)
  colLavender* = Color(0xE6E6FAFF)
  colLavenderBlush* = Color(0xFFF0F5FF)
  colLawnGreen* = Color(0x7CFC00FF)
  colLemonChiffon* = Color(0xFFFACDFF)
  colLightBlue* = Color(0xADD8E6FF)
  colLightCoral* = Color(0xF08080FF)
  colLightCyan* = Color(0xE0FFFFFF)
  colLightGoldenRodYellow* = Color(0xFAFAD2FF)
  colLightGray* = Color(0xD3D3D3FF)
  colLightGreen* = Color(0x90EE90FF)
  colLightGrey* = Color(0xD3D3D3FF)
  colLightPink* = Color(0xFFB6C1FF)
  colLightSalmon* = Color(0xFFA07AFF)
  colLightSeaGreen* = Color(0x20B2AAFF)
  colLightSkyBlue* = Color(0x87CEFAFF)
  colLightSlateGray* = Color(0x778899FF)
  colLightSlateGrey* = Color(0x778899FF)
  colLightSteelBlue* = Color(0xB0C4DEFF)
  colLightYellow* = Color(0xFFFFE0FF)
  colLime* = Color(0x00FF00FF)
  colLimeGreen* = Color(0x32CD32FF)
  colLinen* = Color(0xFAF0E6FF)
  colMagenta* = Color(0xFF00FFFF)
  colMaroon* = Color(0x800000FF)
  colMediumAquaMarine* = Color(0x66CDAAFF)
  colMediumBlue* = Color(0x0000CDFF)
  colMediumOrchid* = Color(0xBA55D3FF)
  colMediumPurple* = Color(0x9370DBFF)
  colMediumSeaGreen* = Color(0x3CB371FF)
  colMediumSlateBlue* = Color(0x7B68EEFF)
  colMediumSpringGreen* = Color(0x00FA9AFF)
  colMediumTurquoise* = Color(0x48D1CCFF)
  colMediumVioletRed* = Color(0xC71585FF)
  colMidnightBlue* = Color(0x191970FF)
  colMintCream* = Color(0xF5FFFAFF)
  colMistyRose* = Color(0xFFE4E1FF)
  colMoccasin* = Color(0xFFE4B5FF)
  colNavajoWhite* = Color(0xFFDEADFF)
  colNavy* = Color(0x000080FF)
  colOldLace* = Color(0xFDF5E6FF)
  colOlive* = Color(0x808000FF)
  colOliveDrab* = Color(0x6B8E23FF)
  colOrange* = Color(0xFFA500FF)
  colOrangeRed* = Color(0xFF4500FF)
  colOrchid* = Color(0xDA70D6FF)
  colPaleGoldenRod* = Color(0xEEE8AAFF)
  colPaleGreen* = Color(0x98FB98FF)
  colPaleTurquoise* = Color(0xAFEEEEFF)
  colPaleVioletRed* = Color(0xDB7093FF)
  colPapayaWhip* = Color(0xFFEFD5FF)
  colPeachPuff* = Color(0xFFDAB9FF)
  colPeru* = Color(0xCD853FFF)
  colPink* = Color(0xFFC0CBFF)
  colPlum* = Color(0xDDA0DDFF)
  colPowderBlue* = Color(0xB0E0E6FF)
  colPurple* = Color(0x800080FF)
  colRebeccaPurple* = Color(0x663399FF)
  colRed* = Color(0xFF0000FF)
  colRosyBrown* = Color(0xBC8F8FFF)
  colRoyalBlue* = Color(0x4169E1FF)
  colSaddleBrown* = Color(0x8B4513FF)
  colSalmon* = Color(0xFA8072FF)
  colSandyBrown* = Color(0xF4A460FF)
  colSeaGreen* = Color(0x2E8B57FF)
  colSeaShell* = Color(0xFFF5EEFF)
  colSienna* = Color(0xA0522DFF)
  colSilver* = Color(0xC0C0C0FF)
  colSkyBlue* = Color(0x87CEEBFF)
  colSlateBlue* = Color(0x6A5ACDFF)
  colSlateGray* = Color(0x708090FF)
  colSlateGrey* = Color(0x708090FF)
  colSnow* = Color(0xFFFAFAFF)
  colSpringGreen* = Color(0x00FF7FFF)
  colSteelBlue* = Color(0x4682B4FF)
  colTan* = Color(0xD2B48CFF)
  colTeal* = Color(0x008080FF)
  colThistle* = Color(0xD8BFD8FF)
  colTomato* = Color(0xFF6347FF)
  colTurquoise* = Color(0x40E0D0FF)
  colViolet* = Color(0xEE82EEFF)
  colWheat* = Color(0xF5DEB3FF)
  colWhite* = Color(0xFFFFFFFF)
  colWhiteSmoke* = Color(0xF5F5F5FF)
  colYellow* = Color(0xFFFF00FF)
  colYellowGreen* = Color(0x9ACD32FF)

  colorNames = {
    "aliceblue": colAliceBlue,
    "antiquewhite": colAntiqueWhite,
    "aqua": colAqua,
    "aquamarine": colAquamarine,
    "azure": colAzure,
    "beige": colBeige,
    "bisque": colBisque,
    "black": colBlack,
    "blanchedalmond": colBlanchedAlmond,
    "blue": colBlue,
    "blueviolet": colBlueViolet,
    "brown": colBrown,
    "burlywood": colBurlyWood,
    "cadetblue": colCadetBlue,
    "chartreuse": colChartreuse,
    "chocolate": colChocolate,
    "coral": colCoral,
    "cornflowerblue": colCornflowerBlue,
    "cornsilk": colCornsilk,
    "crimson": colCrimson,
    "cyan": colCyan,
    "darkblue": colDarkBlue,
    "darkcyan": colDarkCyan,
    "darkgoldenrod": colDarkGoldenRod,
    "darkgray": colDarkGray,
    "darkgreen": colDarkGreen,
    "darkgrey": colDarkGrey,
    "darkkhaki": colDarkKhaki,
    "darkmagenta": colDarkMagenta,
    "darkolivegreen": colDarkOliveGreen,
    "darkorange": colDarkorange,
    "darkorchid": colDarkOrchid,
    "darkred": colDarkRed,
    "darksalmon": colDarkSalmon,
    "darkseagreen": colDarkSeaGreen,
    "darkslateblue": colDarkSlateBlue,
    "darkslategray": colDarkSlateGray,
    "darkslategrey": colDarkSlateGrey,
    "darkturquoise": colDarkTurquoise,
    "darkviolet": colDarkViolet,
    "deeppink": colDeepPink,
    "deepskyblue": colDeepSkyBlue,
    "dimgray": colDimGray,
    "dimgrey": colDimGrey,
    "dodgerblue": colDodgerBlue,
    "firebrick": colFireBrick,
    "floralwhite": colFloralWhite,
    "forestgreen": colForestGreen,
    "fuchsia": colFuchsia,
    "gainsboro": colGainsboro,
    "ghostwhite": colGhostWhite,
    "gold": colGold,
    "goldenrod": colGoldenRod,
    "gray": colGray,
    "green": colGreen,
    "greenyellow": colGreenYellow,
    "grey": colGrey,
    "honeydew": colHoneyDew,
    "hotpink": colHotPink,
    "indianred": colIndianRed,
    "indigo": colIndigo,
    "ivory": colIvory,
    "khaki": colKhaki,
    "lavender": colLavender,
    "lavenderblush": colLavenderBlush,
    "lawngreen": colLawnGreen,
    "lemonchiffon": colLemonChiffon,
    "lightblue": colLightBlue,
    "lightcoral": colLightCoral,
    "lightcyan": colLightCyan,
    "lightgoldenrodyellow": colLightGoldenRodYellow,
    "lightgray": colLightGray,
    "lightgreen": colLightGreen,
    "lightgrey": colLightGrey,
    "lightpink": colLightPink,
    "lightsalmon": colLightSalmon,
    "lightseagreen": colLightSeaGreen,
    "lightskyblue": colLightSkyBlue,
    "lightslategray": colLightSlateGray,
    "lightslategrey": colLightSlateGrey,
    "lightsteelblue": colLightSteelBlue,
    "lightyellow": colLightYellow,
    "lime": colLime,
    "limegreen": colLimeGreen,
    "linen": colLinen,
    "magenta": colMagenta,
    "maroon": colMaroon,
    "mediumaquamarine": colMediumAquaMarine,
    "mediumblue": colMediumBlue,
    "mediumorchid": colMediumOrchid,
    "mediumpurple": colMediumPurple,
    "mediumseagreen": colMediumSeaGreen,
    "mediumslateblue": colMediumSlateBlue,
    "mediumspringgreen": colMediumSpringGreen,
    "mediumturquoise": colMediumTurquoise,
    "mediumvioletred": colMediumVioletRed,
    "midnightblue": colMidnightBlue,
    "mintcream": colMintCream,
    "mistyrose": colMistyRose,
    "moccasin": colMoccasin,
    "navajowhite": colNavajoWhite,
    "navy": colNavy,
    "oldlace": colOldLace,
    "olive": colOlive,
    "olivedrab": colOliveDrab,
    "orange": colOrange,
    "orangered": colOrangeRed,
    "orchid": colOrchid,
    "palegoldenrod": colPaleGoldenRod,
    "palegreen": colPaleGreen,
    "paleturquoise": colPaleTurquoise,
    "palevioletred": colPaleVioletRed,
    "papayawhip": colPapayaWhip,
    "peachpuff": colPeachPuff,
    "peru": colPeru,
    "pink": colPink,
    "plum": colPlum,
    "powderblue": colPowderBlue,
    "purple": colPurple,
    "rebeccapurple": colRebeccaPurple,
    "red": colRed,
    "rosybrown": colRosyBrown,
    "royalblue": colRoyalBlue,
    "saddlebrown": colSaddleBrown,
    "salmon": colSalmon,
    "sandybrown": colSandyBrown,
    "seagreen": colSeaGreen,
    "seashell": colSeaShell,
    "sienna": colSienna,
    "silver": colSilver,
    "skyblue": colSkyBlue,
    "slateblue": colSlateBlue,
    "slategray": colSlateGray,
    "slategrey": colSlateGrey,
    "snow": colSnow,
    "springgreen": colSpringGreen,
    "steelblue": colSteelBlue,
    "tan": colTan,
    "teal": colTeal,
    "thistle": colThistle,
    "tomato": colTomato,
    "turquoise": colTurquoise,
    "violet": colViolet,
    "wheat": colWheat,
    "white": colWhite,
    "whitesmoke": colWhiteSmoke,
    "yellow": colYellow,
    "yellowgreen": colYellowGreen}

proc `$`*(c: Color): string =
  ## Converts a color into its textual representation.
  ##
  runnableExamples:
    assert $colFuchsia == "#FF00FFFF"
  result = '#' & toHex(int(c), 8)

proc colorNameCmp(x: tuple[name: string, col: Color], y: string): int =
  result = cmpIgnoreCase(x.name, y)

proc parseColor*(name: string): Color =
  ## Parses `name` to a color value.
  ##
  ## If no valid color could be parsed `ValueError` is raised.
  ## Case insensitive.
  ##
  runnableExamples:
    var
      a = "silver"
      b = "#0179fcff"
      c = "#zzmmttxx"
    assert parseColor(a) == Color(0xc0_c0_c0_ff)
    assert parseColor(b) == Color(0x01_79_fc_ff)
    doAssertRaises(ValueError): discard parseColor(c)

  if name.len > 0 and name[0] == '#':
    if name.len == 9:
      result = Color(parseHexInt(name))
    elif name.len == 7:
      result = Color(parseHexInt(name & "ff"))
    elif name.len == 4 or name.len == 5:
      var rrggbbaa = newStringOfCap(9)
      rrggbbaa.add('#')
      for c in name[1 .. ^1]:
        rrggbbaa.add(c)
        rrggbbaa.add(c)
      if name.len == 4:
        rrggbbaa.add("ff")
      result = Color(parseHexInt(rrggbbaa))
    else:
      raise newException(ValueError, "invalid color: " & name)
  else:
    var idx = binarySearch(colorNames, name, colorNameCmp)
    if idx < 0: raise newException(ValueError, "unknown color: " & name)
    result = colorNames[idx][1]

proc isColor*(name: string): bool =
  ## Returns true if `name` is a known color name or a hexadecimal color
  ## prefixed with `#`. Case insensitive.
  ##
  runnableExamples:
    var
      a = "silver"
      b = "#0179fcff"
      c = "#zzmmttxx"
    assert a.isColor
    assert b.isColor
    assert not c.isColor

  if name.len == 0: return false
  if name[0] == '#':
    if name.len notin [4, 5, 7, 9]: return false
    for i in 1 ..< name.len:
      if name[i] notin HexDigits: return false
    result = true
  else:
    result = binarySearch(colorNames, name, colorNameCmp) >= 0

proc rgba*(r, g, b, a: uint8): Color =
  ## Constructs a color from RGBA values.
  ##
  runnableExamples:
    assert rgba(0, 255, 128, 0) == Color(0x00_ff_80_00)

  result = rawRgba(r, g, b, a)

proc opacity*(c: Color, f: float): Color =
  ## Returns `c` with opacity `f`. `f` must be a float from 0.0 (completely
  ## transparent) to 1.0 (completely opaque).
  ##
  runnableExamples:
    var
      a = Color(0xff_00_ff_ff)
      b = Color(0x00_42_cc_80)
    assert a.opacity(0.5) == Color(0xff_00_ff_80)
    assert b.opacity(0.5) == Color(0x00_42_cc_80)
    
  if f < 0.0 or f > 1.0:
    raise newException(ValueError, "Opacity factor must be between 0.0 and 1.0")

  let alpha = uint32(round(255.0 * f))
  result = Color((c.uint32 and 0xffffff00'u32) or alpha)
