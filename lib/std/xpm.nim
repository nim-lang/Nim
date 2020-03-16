## XPM X-Pixmap raster image standard implemented in pure Nim.
## Has image manipulation funcs, patterns, crop, expand, fill, save to file, etc.
## Uses only ``system.nim`` (without any imports), works on any compiler target,
## including compile-time, JavaScript and NimScript, etc.
## Should work on any embedded devices that can handle ``string``.
## Almost all functions work in-place and are side-effects free.
## Format is loss-less uncompressed and human-readable, UTF-8 but fits ASCII,
## is also valid C source code, supports millions of colors and transparency.
## Pixels are just ``string``, Bitmap is a ``seq[seq[string]]``. Unstable API.
## Check Nimble for multi-format conversions and image lossy compressions.
## * Open Format Spec https://en.wikipedia.org/wiki/X_PixMap
##
## **Since** version 1.2.
##
## **See also:**
## * `Colors <colors.html>`_ module
## * `Sequtils <sequtils.html>`_ module

type
  XPMColorKind* = enum ## XPM Color kind
    xpmColor = "c"     ## Color (Up to millions of colors and transparency)
    xpmMono = "m"      ## Monochrome (Black and white)
    xpmGray = "g"      ## Grayscale (Shades of gray)
    xpmSymbolic = "s"  ## Symbolic (Special color changes based on its context)
  XPMColor* = tuple[key: string, kind: XPMColorKind, value: string] ## XPM Color
  XBase* = ref object of RootObj
    width*, height*: Positive ## Size of the image, must be sync with matrix.
    colors*: seq[XPMColor]    ## Colors, declaration of predefined color values
    matrix*: seq[seq[string]] ## Raster image data bitmap, seqs of strings
    name*: string             ## Image name, will be used for Rendering.
  XPM1* = ref object of XBase ## XPM X-Pixmap 1 Raster Image (Valid C code)
  XPM2* = ref object of XBase ## XPM X-Pixmap 2 Raster Image (Plain-text)
  XPM3* = ref object of XBase ## XPM X-Pixmap 3 Raster Image (Valid C code)

template autoAdjustSize*(this: var XPM1 | XPM2 | XPM3) =
  ## Template to auto-adjust size (width, height). Call this after any resize.
  this.width = this.matrix[0].len
  this.height = this.matrix.len

template setPixel*(this: var XPM1 | XPM2 | XPM3, x, y: Natural, color: string) =
  this.matrix[y][x] = color

template getNchars*(this: XPM1 | XPM2 | XPM3): Positive =
  ## How many characters per color the image has.
  this.colors[0].key.len

template getNcolors*(this: XPM1 | XPM2 | XPM3): Positive =
  ## How many colors the image has.
  this.colors.len

template reset*(this: var XPM1 | XPM2 | XPM3, color: string) =
  ## Reset the image, deletes all the bitmap data and metadata.
  this.matrix = @[@[color]]
  this.autoAdjustSize()

func clear*(this: var XPM1 | XPM2 | XPM3, color: string) {.inline.} =
  for line in this.matrix.mitems:
    for column in line.mitems: column = color

func cropX*(this: var XPM1 | XPM2 | XPM3, newSizeX: Positive) {.inline.} =
  ## Crop horizontally, crops from right-bottom (X axis).
  assert this.width > newSizeX, "newSizeX must be smaller than actual size"
  for line in this.matrix.mitems: line = line[0..newSizeX - 1]
  this.autoAdjustSize()

func cropY*(this: var XPM1 | XPM2 | XPM3, newSizeY: Positive) {.inline.} =
  ## Crop vertically, crops from right-bottom (Y axis).
  assert this.height > newSizeY, "newSizeY must be smaller than actual size"
  this.matrix = this.matrix[0..newSizeY - 1]
  this.autoAdjustSize()

func crop*(this: var XPM1 | XPM2 | XPM3, newSizeX, newSizeY: Positive) =
  ## Crop horizontally and vertically, crops from right-bottom (X and Y axis).
  this.cropX(newSizeX)
  this.cropY(newSizeY)

func cropCenteredX*(this: var XPM1 | XPM2 | XPM3, newSizeX: Positive) {.inline.} =
  ## Horizontally centered crop, crops from borders (X axis).
  assert this.width > newSizeX, "newSizeX must be smaller than actual size"
  var i = 0
  for line in this.matrix:
    this.matrix[i] = line[newSizeX div 2 .. this.matrix[0].len - newSizeX div 2]
    inc i
  this.autoAdjustSize()

func cropCenteredY*(this: var XPM1 | XPM2 | XPM3, newSizeY: Positive) {.inline.} =
  ## Vertically centered crop, crops from borders (Y axis).
  assert this.height > newSizeY, "newSizeY must be smaller than actual size"
  this.matrix = this.matrix[newSizeY div 2 .. this.matrix.len - newSizeY div 2]
  this.autoAdjustSize()

func cropCentered*(this: var XPM1 | XPM2 | XPM3, newSizeX, newSizeY: Positive) =
  ## Centered crop horizontally and vertically (X and Y axis).
  this.cropCenteredX(newSizeX)
  this.cropCenteredY(newSizeY)

func expandX*(this: var XPM1 | XPM2 | XPM3, newSizeX: Positive, color: string) =
  ## Expand image horizontally, grows from right-bottom, increments size (X axis)
  assert newSizeX > this.width, "newSizeX must be bigger than actual size"
  for line in this.matrix.mitems:
    for _ in 1 .. (newSizeX - this.width): line.add color
  this.autoAdjustSize()

func expandY*(this: var XPM1 | XPM2 | XPM3, newSizeY: Positive, color: string) =
  ## Expand image vertically, grows from right-bottom, increments size (Y axis)
  assert newSizeY > this.height, "newSizeY must be bigger than actual size"
  var fill = newSeq[string](this.width)
  for column in fill.mitems: column = color
  for _ in 1 .. (newSizeY - this.height): this.matrix.add fill
  this.autoAdjustSize()

func expand*(this: var XPM1 | XPM2 | XPM3,
    newSizeX, newSizeY: Positive, color: string) =
  ## Expand horizontally and vertically, grows from right-bottom (X and Y axis)
  this.expandX(newSizeX, color)
  this.expandY(newSizeY, color)

func expandCenteredX*(this: var XPM1 | XPM2 | XPM3,
    newSizeX: Positive, color: string) =
  ## Centered expand image horizontally, increments size (X axis).
  assert newSizeX > this.width, "newSizeX must be bigger than actual size"
  for line in this.matrix.mitems:
    var newMatrix: seq[string]
    for _ in 1 .. ((newSizeX - line.len) div 2): newMatrix.add color
    for column in line: newMatrix.add column
    for _ in 1 .. ((newSizeX - line.len) div 2): newMatrix.add color
    line = newMatrix
  this.autoAdjustSize()

func expandCenteredY*(this: var XPM1 | XPM2 | XPM3,
    newSizeY: Positive, color: string) =
  ## Centered expand image vertically, increments size (Y axis).
  assert newSizeY > this.height, "newSizeY must be bigger than actual size"
  var base = newSeq[string](this.width)
  for col in base.mitems: col = color
  var newMatrix: seq[seq[string]]
  for _ in 1.. ((newSizeY - this.height) div 2): newMatrix.add base
  for row in this.matrix: newMatrix.add row
  for _ in 1.. ((newSizeY - this.height) div 2): newMatrix.add base
  this.matrix = newMatrix
  this.autoAdjustSize()

func expandCentered*(this: var XPM1 | XPM2 | XPM3,
    newSizeX, newSizeY: Positive, color: string) =
  ## Centered expand horizontally and vertically (X and Y axis).
  this.expandCenteredX(newSizeX, color)
  this.expandCenteredY(newSizeY, color)

func fillRect*(this: var XPM1 | XPM2 | XPM3,
    x, y: Natural, width, height: Positive, color: string) {.inline.} =
  ## Fill up a rectangle on the image with given color (X and Y axis).
  for h in 0 ..< height:
    for w in 0 ..< width: this.matrix[y + h][x + w] = color

func setPixelStripe*(this: var XPM1 | XPM2 | XPM3, x, y: Natural,
  vertical: bool, color0, color1: string, stroke = 2.Positive) {.inline.} =
  ## Set a pixel color on an Stripped pattern on the image (X or Y axis).
  this.matrix[y][x] = if ((if vertical: y else: x) mod stroke == 0): color0
                      else: color1

func fillRectStripe*(this: var XPM1 | XPM2 | XPM3,
    x, y: Natural, width, height: Positive, vertical: bool,
    color0, color1: string, stroke = 2.Positive) =
  ## Fill up a rectangle on an Stripped pattern on the image with given color (X and Y axis).
  for h in 0 ..< height:
    for w in 0 ..< width:
      this.setPixelStripe(x + w, y + h, vertical, color0, color1, stroke)

func setPixelGrid(this: var XPM1 | XPM2 | XPM3, x, y: Natural,
  color0, color1: string, stroke = 2.Positive) {.inline.} =
  ## Set a pixel color on a Grid pattern on the image (X or Y axis).
  this.matrix[y][x] = if (y mod stroke == 0 and x mod stroke == 0): color0
                      else: color1

func fillRectGrid*(this: var XPM1 | XPM2 | XPM3,
    x, y: Natural, width, height: Positive,
    color0, color1: string, stroke = 2.Positive) =
  ## Fill up a rectangle on an Stripped pattern on the image with given color (X and Y axis).
  for h in 0 ..< height:
    for w in 0 ..< width:
      this.setPixelGrid(x + w, y + h, color0, color1, stroke)

func setPixelDotted(this: var XPM1 | XPM2 | XPM3, x, y: Natural,
  color0, color1: string, stroke = 2.Positive) {.inline.} =
  ## Set a pixel color on an Dotted pattern on the image (X or Y axis).
  this.matrix[y][x] = if (y mod stroke == 0 or x mod stroke == 0): color0
                      else: color1

func fillRectDotted*(this: var XPM1 | XPM2 | XPM3,
    x, y: Natural, width, height: Positive,
    color0, color1: string, stroke = 2.Positive) =
  ## Fill up a rectangle on an Dotted pattern on the image with given color (X and Y axis).
  for h in 0 ..< height:
    for w in 0 ..< width:
      this.setPixelDotted(x + w, y + h, color0, color1, stroke)

func `$`*(this: XPM1): string =
  result = (
    "#define " & this.name & "_format 1\n" &
    "#define " & this.name & "_width " & $this.width & "\n" &
    "#define " & this.name & "_height " & $this.height & "\n" &
    "#define " & this.name & "_ncolors " & $this.getNcolors() & "\n" &
    "#define " & this.name & "_chars_per_pixel " & $this.getNchars() & "\n" &
    "static char *" & this.name & "_colors[] = {\n"
  ) # ^ Header as per Spec.    v Color predefined "Declarations" as per Spec.
  for col in this.colors:
    result.add "  \"" & col.key & "\", \"" & col.value & "\",\n"
  result.add "};\nstatic char *" & this.name & "_pixels[] = {\n"
  for line in this.matrix: # Bitmap processing.
    var row = "  \""
    for pixel in line: row.add $pixel
    result.add row & "\",\n"
  result.add "};\n"

func `$`*(this: XPM2): string =
  result = (
    "! XPM2\n" & $this.width & "\t" & $this.height & "\t" &
    $this.getNcolors() & "\t" & $this.getNchars() & "\n"
  ) # ^ Header as per Spec.    v Color predefined "Declarations" as per Spec.
  for col in this.colors:
    result.add col.key & "\t" & $col.kind & "\t" & col.value & "\n"
  for line in this.matrix: # Bitmap processing.
    var row = ""
    for pixel in line: row.add $pixel
    result.add row & "\n"

func `$`*(this: XPM3): string =
  result = (
    "/* XPM */\nstatic char *" & this.name & "_xpm[] = {\n  \"" &
    $this.width & " " & $this.height & " " &
    $this.getNcolors() & " " & $this.getNchars() & "\",\n"
  ) # ^ Header as per Spec.    v Color predefined "Declarations" as per Spec.
  for col in this.colors:
    result.add "  \"" & col.key & " " & $col.kind & " " & col.value & "\",\n"
  for line in this.matrix: # Bitmap processing.
    var row = "  \""
    for pixel in line: row.add $pixel
    result.add row & "\",\n"
  result.add "};\n"

proc writeFile*(this: XPM1 | XPM2 | XPM3, path: string) {.inline.} =
  ## Save a image to a file. File extension can be omitted.
  writeFile(path & ".xpm", $this)

func newXpmColor*(key: string, kind: XPMColorKind, value: string): XPMColor {.inline.} =
  ## Create a new XPM Color.
  assert key.len > 0 and value.len > 2, "Color must not be empty string"
  result = (key: key, kind: kind, value: value)

template genMatrix(width, height: Positive, bgColor: string): seq[seq[string]] =
  assert bgColor.len > 0
  var row = newSeqOfCap[string](width)
  for i in 1..width: row.add bgColor
  var data = newSeqOfCap[seq[string]](height)
  for i in 1..width: data.add row
  data

func newXpm1*(width, height: Positive,
    colors: seq[XPMColor], bgColor: string, name = ""): XPM1 =
  ## Create a new empty image with ``bgColor`` as background color.
  let x = genMatrix(width, height, bgColor)
  result = XPM1(width: width, height: height, colors: colors, matrix: x, name: name)

func newXpm2*(width, height: Positive,
    colors: seq[XPMColor], bgColor: string, name = ""): XPM2 =
  ## Create a new empty image with ``bgColor`` as background color.
  let x = genMatrix(width, height, bgColor)
  result = XPM2(width: width, height: height, colors: colors, matrix: x, name: name)

func newXpm3*(width, height: Positive,
    colors: seq[XPMColor], bgColor: string, name = ""): XPM3 =
  ## Create a new empty image with ``bgColor`` as background color.
  let x = genMatrix(width, height, bgColor)
  result = XPM3(width: width, height: height, colors: colors, matrix: x, name: name)




runnableExamples:
  static:
    const palette = @[
      newXpmColor("a", XPMColorKind.xpmColor, "#fff"), ## Hexadecimal
      newXpmColor("b", XPMColorKind.xpmColor, "blue"), ## Named color
      newXpmColor("c", XPMColorKind.xpmColor, "none"), ## Transparency
    ]
    let
      xpm1img = newXpm1(1, 1, colors = palette,
        bgColor = "a", name = "cthulhu")
      xpm2img = newXpm2(1, 1, colors = palette,
        bgColor = "a", name = "azathoth")
      xpm3img = newXpm3(1, 1, colors = palette,
        bgColor = "a", name = "shoggoth")
    xpm1img.setPixel(0, 0, "c")
    xpm2img.setPixel(0, 0, "b")
    xpm3img.setPixel(0, 0, "a")
    doAssert xpm1img.matrix is seq[seq[string]]
    doAssert xpm2img.matrix is seq[seq[string]]
    doAssert xpm3img.matrix is seq[seq[string]]
    ## xpm1img.writeFile("xpm1img")
    ## xpm2img.writeFile("xpm2img")
    ## xpm3img.writeFile("xpm3img")

runnableExamples:
  static:
    const
      sierpinskiTriangle = @[@["1", "0"],
                            @["1", "1"]]

      sierpinskiSquare = @[@["1", "1", "1"],
                          @["1", "0", "1"],
                          @["1", "1", "1"]]

      vicsek = @[@["1", "0", "1"],
                @["0", "1", "0"],
                @["1", "0", "1"]]

      snowflake = @[@["1", "1", "0"],
                    @["1", "0", "1"],
                    @["0", "1", "1"]]

      hexaflake = @[@["1", "1", "0"],
                    @["1", "1", "1"],
                    @["0", "1", "1"]]

      spiral = @[@["0", "0", "1", "1", "0"],
                @["1", "0", "1", "0", "0"],
                @["1", "1", "1", "1", "1"],
                @["0", "0", "1", "0", "1"],
                @["0", "1", "1", "0", "0"]]

      palette = @[
        newXpmColor("1", XPMColorKind.xpmColor, "red"),
        newXpmColor("0", XPMColorKind.xpmColor, "none"),
      ] #           ^ char            ^ kind    ^ value

    let image = newXpm3(480, 480, palette, bgColor = "0", name = "fractals")

    proc renderFractal(data: seq[seq[string]], x0 = 0, y0 = 0, x1 = 480, y1 = 480) =
      ## Just a recursive proc, calls itself drawing pixels (X and Y axis).
      var xd = x1 - x0 - 1
      var yd = y1 - y0 - 1
      if xd < 2 and yd < 2:
        image.matrix[x0][y0] = "1"
        return
      for i in 0 ..< len(data):
        for k in 0 ..< len(data[0]):
          if data[i][k] != "0": renderFractal(data,
            x0 + xd * k div len(data[0]), y0 + yd * i div len(data),
            x0 + xd * (k + 1) div len(data[0]), y0 + yd * (i + 1) div len(data))
    ## Draw all fractals at compile-time, on top of each other for faster testing
    renderFractal(spiral)
    renderFractal(hexaflake)
    renderFractal(snowflake)
    renderFractal(vicsek)
    renderFractal(sierpinskiSquare)
    renderFractal(sierpinskiTriangle)
    ## image.writeFile("fractals")

runnableExamples:
  static:
    const palette = @[
      newXpmColor("0", XPMColorKind.xpmColor, "#fff"),
      newXpmColor("1", XPMColorKind.xpmColor, "#000"),
    ]
    var img = newXpm3(2, 2, palette, "0", "name")
    img.setPixel(0, 1, "1")
    img.setPixel(1, 0, "1")
    doAssert img.width == 2 and img.height == 2 and img.matrix.len == 2
    doAssert img.getNchars() == 1
    doAssert img.getNcolors() == 2
    doAssert img.matrix == @[@["0", "1"],
                            @["1", "0"]]
    img.matrix = @[@["0", "1"],  # Direct Assign of matrix
                  @["1", "0"]]
    img.expandX(3, "0")
    doAssert img.matrix == @[@["0", "1", "0"],
                            @["1", "0", "0"]]
    img.expandY(3, "0")
    doAssert img.matrix == @[@["0", "1", "0"],
                            @["1", "0", "0"],
                            @["0", "0", "0"]]
    img.cropX(2)
    doAssert img.matrix == @[@["0", "1"],
                            @["1", "0"],
                            @["0", "0"]]
    img.cropY(2)
    doAssert img.matrix == @[@["0", "1"],
                            @["1", "0"]]
    img.expandCenteredX(4, "0")
    doAssert img.matrix == @[@["0", "0", "1", "0"],
                            @["0", "1", "0", "0"]]
    img.expandCenteredY(4, "0")
    doAssert img.matrix == @[@["0", "0", "0", "0"],
                            @["0", "0", "1", "0"],
                            @["0", "1", "0", "0"],
                            @["0", "0", "0", "0"]]
    img.fillRect(0, 0, 2, 2, "1")
    doAssert img.matrix == @[@["1", "1", "0", "0"],
                            @["1", "1", "1", "0"],
                            @["0", "1", "0", "0"],
                            @["0", "0", "0", "0"]]
    img.clear("0")
    doAssert img.matrix == @[@["0", "0", "0", "0"],
                            @["0", "0", "0", "0"],
                            @["0", "0", "0", "0"],
                            @["0", "0", "0", "0"]]
    img.fillRectStripe(0, 0, img.width - 1, img.height - 1,
      vertical = true, "1", "0")
    doAssert img.matrix == @[@["1", "1", "1", "0"], # 1 1 1 0
                            @["0", "0", "0", "0"],
                            @["1", "1", "1", "0"], # 1 1 1 0
                            @["0", "0", "0", "0"]]
    img.clear("0")
    img.fillRectStripe(0, 0, img.width - 1, img.height - 1,
      vertical = false, "1", "0")
    doAssert img.matrix == @[@["1", "0", "1", "0"],
                            @["1", "0", "1", "0"],
                            @["1", "0", "1", "0"],
                            @["0", "0", "0", "0"]]
    img.clear("0")
    img.fillRectGrid(0, 0, img.width, img.height, "0",  "1",)  # Grid pattern
    doAssert img.matrix == @[@["0", "1", "0", "1"],
                            @["1", "1", "1", "1"],
                            @["0", "1", "0", "1"],
                            @["1", "1", "1", "1"]]
    img.clear("0")
    img.fillRectDotted(0, 0, img.width, img.height, "0",  "1",) # Dotted pattern
    doAssert img.matrix == @[@["0", "0", "0", "0"],
                            @["0", "1", "0", "1"],
                            @["0", "0", "0", "0"],
                            @["0", "1", "0", "1"]]
    ## image.writeFile("example")
    doAssert $img == """/* XPM */
static char *name_xpm[] = {
  "4 4 2 1",
  "0 c #fff",
  "1 c #000",
  "0000",
  "0101",
  "0000",
  "0101",
};
"""
