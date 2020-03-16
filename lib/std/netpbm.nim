## NetPBM raster bitmap image standard implemented in pure Nim.
## Has image manipulation funcs, patterns, crop, expand, fill, save to file, etc.
## Uses only ``system.nim`` (without any imports), works on any compiler target,
## including compile-time, JavaScript and NimScript, etc.
## Should work on any embedded devices that can handle ``string``.
## Almost all functions work in-place and are side-effects free.
## Format is loss-less uncompressed and human-readable, UTF-8 but fits ASCII.
## Pixels are just ``byte``, Bitmap is a ``seq[seq[byte]]``. Unstable API.
## Check Nimble for multi-format conversions and image lossy compressions.
## * Open Format Spec https://en.wikipedia.org/wiki/Netpbm_format
##
## **Since** version 1.2.
##
## **See also:**
## * `Colors <colors.html>`_ module
## * `Sequtils <sequtils.html>`_ module
# https://docs.rs/image/latest/image/pnm/struct.PNMEncoder.html

type
  NetPBMBase* = ref object of RootObj
    width*, height*: Positive ## Size of the image, must be sync with matrix.
    matrix*: seq[seq[byte]]   ## Raster image data bitmap bytes (0 ~ 255).
    maxvalue*: byte           ## Maximum value of the format (1 or 255).
  PBM* = ref object of NetPBMBase ## NetPBM Raster Bitmap Image (PBM format).
  PGM* = ref object of NetPBMBase ## NetPBM Raster Bitmap Image (PGM format).

template autoAdjustSize*(this: var PBM | PGM) =
  ## Template to auto-adjust size (width, height). Call this after any resize.
  this.width = this.matrix[0].len
  this.height = this.matrix.len

template setPixel*(this: var PBM | PGM, x, y: Natural, color: byte) =
  this.matrix[y][x] = color

template reset*(this: var PBM | PGM, color: byte) =
  this.matrix = @[@[color]]
  this.autoAdjustSize()

func clear*(this: var PBM | PGM, color: byte) {.inline.} =
  for line in this.matrix.mitems:
    for column in line.mitems: column = color

func cropX*(this: var PBM | PGM, newSizeX: Positive) {.inline.} =
  ## Crop horizontally, crops from right-bottom (X axis).
  assert this.width > newSizeX, "newSizeX must be smaller than actual size"
  for line in this.matrix.mitems: line = line[0..newSizeX - 1]
  this.autoAdjustSize()

func cropY*(this: var PBM | PGM, newSizeY: Positive) {.inline.} =
  ## Crop vertically, crops from right-bottom (Y axis).
  assert this.height > newSizeY, "newSizeY must be smaller than actual size"
  this.matrix = this.matrix[0..newSizeY - 1]
  this.autoAdjustSize()

func crop*(this: var PBM | PGM, newSizeX, newSizeY: Positive) =
  ## Crop horizontally and vertically, crops from right-bottom (X and Y axis).
  this.cropX(newSizeX)
  this.cropY(newSizeY)

func cropCenteredX*(this: var PBM | PGM, newSizeX: Positive) {.inline.} =
  ## Horizontally centered crop, crops from borders (X axis).
  assert this.width > newSizeX, "newSizeX must be smaller than actual size"
  var i = 0
  for line in this.matrix:
    this.matrix[i] = line[newSizeX div 2 .. this.matrix[0].len - newSizeX div 2]
    inc i
  this.autoAdjustSize()

func cropCenteredY*(this: var PBM | PGM, newSizeY: Positive) {.inline.} =
  ## Vertically centered crop, crops from borders (Y axis).
  assert this.height > newSizeY, "newSizeY must be smaller than actual size"
  this.matrix = this.matrix[newSizeY div 2 .. this.matrix.len - newSizeY div 2]
  this.autoAdjustSize()

func cropCentered*(this: var PBM | PGM, newSizeX, newSizeY: Positive) =
  ## Centered crop horizontally and vertically (X and Y axis).
  this.cropCenteredX(newSizeX)
  this.cropCenteredY(newSizeY)

func expandX*(this: var PBM | PGM, newSizeX: Positive, color: byte) =
  ## Expand image horizontally, grows from right-bottom, increments size (X axis)
  assert newSizeX > this.width, "newSizeX must be bigger than actual size"
  for line in this.matrix.mitems:
    for _ in 1 .. (newSizeX - this.width): line.add color
  this.autoAdjustSize()

func expandY*(this: var PBM | PGM, newSizeY: Positive, color: byte) =
  ## Expand image vertically, grows from right-bottom, increments size (Y axis)
  assert newSizeY > this.height, "newSizeY must be bigger than actual size"
  var fill = newSeq[byte](this.width)
  for column in fill.mitems: column = color
  for _ in 1 .. (newSizeY - this.height): this.matrix.add fill
  this.autoAdjustSize()

func expand*(this: var PBM | PGM, newSizeX, newSizeY: Positive, color: byte) =
  ## Expand horizontally and vertically, grows from right-bottom (X and Y axis)
  this.expandX(newSizeX, color)
  this.expandY(newSizeY, color)

func expandCenteredX*(this: var PBM | PGM, newSizeX: Positive, color: byte) =
  ## Centered expand image horizontally, increments size (X axis).
  assert newSizeX > this.width, "newSizeX must be bigger than actual size"
  for line in this.matrix.mitems:
    var newMatrix: seq[byte]
    for _ in 1 .. ((newSizeX - line.len) div 2): newMatrix.add color
    for column in line: newMatrix.add column
    for _ in 1 .. ((newSizeX - line.len) div 2): newMatrix.add color
    line = newMatrix
  this.autoAdjustSize()

func expandCenteredY*(this: var PBM | PGM, newSizeY: Positive, color: byte) =
  ## Centered expand image vertically, increments size (Y axis).
  assert newSizeY > this.height, "newSizeY must be bigger than actual size"
  var base = newSeq[byte](this.width)
  for col in base.mitems: col = color
  var newMatrix: seq[seq[byte]]
  for _ in 1.. ((newSizeY - this.height) div 2): newMatrix.add base
  for row in this.matrix: newMatrix.add row
  for _ in 1.. ((newSizeY - this.height) div 2): newMatrix.add base
  this.matrix = newMatrix
  this.autoAdjustSize()

func expandCentered*(this: var PBM | PGM,
    newSizeX, newSizeY: Positive, color: byte) =
  ## Centered expand horizontally and vertically (X and Y axis).
  this.expandCenteredX(newSizeX, color)
  this.expandCenteredY(newSizeY, color)

func fillRect*(this: var PBM | PGM,
  x, y: Natural, width, height: Positive, color: byte) =
  ## Fill up a rectangle on the image with given color (X and Y axis).
  for h in 0 ..< height:
    for w in 0 ..< width: this.matrix[y + h][x + w] = color

func setPixelStripe*(this: var PBM | PGM, x, y: Natural,
  vertical: bool, color0, color1: byte, stroke = 2.Positive) {.inline.} =
  ## Set a pixel color on an Stripped pattern on the image (X or Y axis).
  this.matrix[y][x] = if ((if vertical: y else: x) mod stroke == 0): color0
                      else: color1

func fillRectStripe*(this: var PBM | PGM, x, y: Natural, width, height: Positive,
    vertical: bool, color0, color1: byte, stroke = 2.Positive) =
  ## Fill up a rectangle on an Stripped pattern with given color (X and Y axis)
  for h in 0 ..< height:
    for w in 0 ..< width:
      this.setPixelStripe(x + w, y + h, vertical, color0, color1, stroke)

func setPixelGrid(this: var PBM | PGM, x, y: Natural,
    color0, color1: byte, stroke = 2.Positive) {.inline.} =
  ## Set a pixel color on a Grid pattern on the image (X or Y axis).
  this.matrix[y][x] = if (y mod stroke == 0 and x mod stroke == 0): color0
                      else: color1

func fillRectGrid*(this: var PBM | PGM, x, y: Natural, width, height: Positive,
    color0, color1: byte, stroke = 2.Positive) =
  ## Fill up a rectangle on an Stripped pattern on the image with given color (X and Y axis).
  for h in 0 ..< height:
    for w in 0 ..< width:
      this.setPixelGrid(x + w, y + h, color0, color1, stroke)

func setPixelDotted(this: var PBM | PGM, x, y: Natural,
    color0, color1: byte, stroke = 2.Positive) {.inline.} =
  ## Set a pixel color on an Dotted pattern on the image (X or Y axis).
  this.matrix[y][x] = if (y mod stroke == 0 or x mod stroke == 0): color0
                      else: color1

func fillRectDotted*(this: var PBM | PGM, x, y: Natural,
    width, height: Positive, color0, color1: byte, stroke = 2.Positive) =
  ## Fill up a rectangle on an Dotted pattern with given color (X and Y axis).
  for h in 0 ..< height:
    for w in 0 ..< width:
      this.setPixelDotted(x + w, y + h, color0, color1, stroke)

func darken*(this: var PGM, amount = 1.Positive) {.inline.} =
  ## Darken the colors of the image (more dark).
  for line in this.matrix.mitems:
    for bite in line.mitems: dec bite, amount

func lighten*(this: var PGM, amount = 1.Positive) {.inline.} =
  ## Lighten the colors of the image (more light).
  for line in this.matrix.mitems:
    for bite in line.mitems: inc bite, amount

func invert*(this: var PBM) {.inline.} =
  ## Invert the colors of the image.
  for line in this.matrix.mitems:
    for bite in line.mitems: bite = if bite == 0: 1 else: 0

func `$`*(this: PBM | PGM): string =
  result = (
    (when this is PBM: "P1\n" else: "P2\n") & # Header (standard).
    $this.width & " " & $this.height & "\n" & # Width Height (integer).
    $this.maxvalue & "\n")                    # Max Value (standard).
  for line in this.matrix:                    # Bitmap processing.
    var row = ""
    for bite in line: row.add $bite & " "
    result.add row & "\n"

proc writeFile*(this: PBM | PGM, path: string) {.inline.} =
  ## Save a image to a file. File extension can be omitted.
  writeFile(path & (when this is PBM: ".pbm" else: ".pgm"), $this)

func newPbm*(width, height: Positive): PBM =
  ## Create an new empty Image.
  var data: seq[seq[byte]]
  for i in 0 ..< height: data.add newSeq[byte](width)
  result = PBM(width: width, height: height, matrix: data, maxvalue: 1.byte)
  result.clear(0.byte)
  result.autoAdjustSize()

func newPgm*(width, height: Positive): PGM =
  ## Create an new empty Image.
  var data: seq[seq[byte]]
  for i in 0 ..< height: data.add newSeq[byte](width)
  result = PGM(width: width, height: height, matrix: data, maxvalue: 255.byte)
  result.clear(255.byte)
  result.autoAdjustSize()




runnableExamples:
  static:
    let image1x1Pixel = newPbm(1, 1)
    image1x1Pixel.matrix[0][0] = 0.byte
    image1x1Pixel.matrix[0][0] = 1.byte
    doAssert image1x1Pixel.matrix is seq[seq[byte]]
    ## image1x1Pixel.writeFile("example")

runnableExamples:
  static:
    let image1x1Pixel = newPgm(1, 1)
    image1x1Pixel.matrix[0][0] = 255.byte
    image1x1Pixel.matrix[0][0] = 0.byte
    doAssert image1x1Pixel.matrix is seq[seq[byte]]
    ## image1x1Pixel.writeFile("example")

runnableExamples:
  static:
    const
      sierpinskiTriangle = @[@[1.byte, 0],
                            @[1.byte, 1]]

      sierpinskiSquare = @[@[1.byte, 1, 1],
                          @[1.byte, 0, 1],
                          @[1.byte, 1, 1]]

      vicsek = @[@[1.byte, 0, 1],
                @[0.byte, 1, 0],
                @[1.byte, 0, 1]]

      snowflake = @[@[1.byte, 1, 0],
                    @[1.byte, 0, 1],
                    @[0.byte, 1, 1]]

      hexaflake = @[@[1.byte, 1, 0],
                    @[1.byte, 1, 1],
                    @[0.byte, 1, 1]]

      spiral = @[@[0.byte, 0, 1, 1, 0],
                @[1.byte, 0, 1, 0, 0],
                @[1.byte, 1, 1, 1, 1],
                @[0.byte, 0, 1, 0, 1],
                @[0.byte, 1, 1, 0, 0]]

    let image = newPbm(480, 480) # Small for faster testing, ugly but fast

    proc renderFractal(data: seq[seq[byte]], x0 = 0, y0 = 0, x1 = 480, y1 = 480) =
      ## Just a recursive proc, calls itself drawing pixels (X and Y axis).
      var xd = x1 - x0 - 1
      var yd = y1 - y0 - 1
      if xd < 2 and yd < 2:
        image.matrix[x0][y0] = image.maxvalue
        return
      for i in 0 ..< len(data):
        for k in 0 ..< len(data[0]):
          if data[i][k] > 0: renderFractal(data,
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
    var img = newPbm(2, 2)
    img.setPixel(0, 1, 1)
    img.setPixel(1, 0, 1)
    doAssert img.width == 2 and img.height == 2 and img.matrix.len == 2
    doAssert img.matrix == @[@[0.byte, 1],
                            @[1.byte, 0]]
    img.matrix = @[@[0.byte, 1],  # Direct Assign of matrix
                  @[1.byte, 0]]
    img.expandX(3, 0.byte)
    doAssert img.matrix == @[@[0.byte, 1, 0],
                            @[1.byte, 0, 0]]
    img.expandY(3, 0.byte)
    doAssert img.matrix == @[@[0.byte, 1, 0],
                            @[1.byte, 0, 0],
                            @[0.byte, 0, 0]]
    img.cropX(2)
    doAssert img.matrix == @[@[0.byte, 1],
                            @[1.byte, 0],
                            @[0.byte, 0]]
    img.cropY(2)
    doAssert img.matrix == @[@[0.byte, 1],
                            @[1.byte, 0]]
    img.expandCenteredX(4, 0.byte)
    doAssert img.matrix == @[@[0.byte, 0, 1, 0],
                            @[0.byte, 1, 0, 0]]
    img.expandCenteredY(4, 0.byte)
    doAssert img.matrix == @[@[0.byte, 0, 0, 0],
                            @[0.byte, 0, 1, 0],
                            @[0.byte, 1, 0, 0],
                            @[0.byte, 0, 0, 0]]
    img.fillRect(0, 0, 2, 2, 1.byte)
    doAssert img.matrix == @[@[1.byte, 1, 0, 0],
                            @[1.byte, 1, 1, 0],
                            @[0.byte, 1, 0, 0],
                            @[0.byte, 0, 0, 0]]
    img.clear(0.byte)
    doAssert img.matrix == @[@[0.byte, 0, 0, 0],
                            @[0.byte, 0, 0, 0],
                            @[0.byte, 0, 0, 0],
                            @[0.byte, 0, 0, 0]]
    img.fillRectStripe(0, 0, img.width - 1, img.height - 1,
      vertical = true, 1.byte, 0.byte)
    doAssert img.matrix == @[@[1.byte, 1, 1, 0], # 1 1 1 0
                            @[0.byte, 0, 0, 0],
                            @[1.byte, 1, 1, 0], # 1 1 1 0
                            @[0.byte, 0, 0, 0]]
    img.clear(0.byte)
    img.fillRectStripe(0, 0, img.width - 1, img.height - 1,
      vertical = false, 1.byte, 0.byte)
    doAssert img.matrix == @[@[1.byte, 0, 1, 0],
                            @[1.byte, 0, 1, 0],
                            @[1.byte, 0, 1, 0],
                            @[0.byte, 0, 0, 0]]
    img.clear(0.byte)
    img.fillRectGrid(0, 0, img.width, img.height, 0.byte,  1.byte)  # Grid pattern
    doAssert img.matrix == @[@[0.byte, 1, 0, 1],
                            @[1.byte, 1, 1, 1],
                            @[0.byte, 1, 0, 1],
                            @[1.byte, 1, 1, 1]]
    img.clear(0.byte)
    img.fillRectDotted(0, 0, img.width, img.height, 0.byte, 1.byte) # Dotted pattern
    doAssert img.matrix == @[@[0.byte, 0, 0, 0],
                            @[0.byte, 1, 0, 1],
                            @[0.byte, 0, 0, 0],
                            @[0.byte, 1, 0, 1]]
    ## image.writeFile("example")
