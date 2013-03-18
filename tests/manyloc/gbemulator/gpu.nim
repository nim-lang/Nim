# Part of the Nimrod Gameboy emulator.
# Copyright (C) Dominik Picheta.

import colors, strutils

type
  TGPUMode = enum
    HBlank = 0, VBlank = 1, OAMRead = 2, VRAMRead = 3, 

  TBGTile = enum
    TileSet0, TileSet1
  TBGMap = enum
    TileMap0, TileMap1

  TPaletteKind = enum
    PaletteBG, PaletteObj, PaletteObj1

  PGPU* = ref object
    vram*: array[0 .. 8191, int32]
    mode*: TGPUMode
    clock: int32
    line: int
    palette: array[TPaletteKind, array[0..3, TColor]] # 4 colors. 0-1 (Lightest), 7-8 (Darkest)
    scrollY, scrollX: int32
    bgtilemap: TBGMap
    bgtileset: TBGTile

proc newGPU*(): PGPU =
  new(result)
  
  # Set default palette
  result.palette[PaletteBG] = [colWhite, rgb(192, 192, 192), rgb(96, 96, 96), colBlack]

proc getTileAddr(gpu: PGPU, index: int32): int =
  ## Returns the address of the beginning of the tile at ``index``.
  case gpu.bgtileset
  of TileSet0:
    return 0x1000+(index*16) # Each tile is 2 bytes (16 bits)
  of TileSet1:
    return 0x0000+(index*16)

proc getTileRow(gpu: PGPU, index: int32): array[0..7, int32] =
  let tileAddr = getTileAddr(gpu, index)
  let y = (gpu.line + gpu.scrollY) and 7
  for px in 0 .. 7:
    result[px] = gpu.vram[tileAddr+px] or (gpu.vram[tileAddr+px+1] shl 8)

proc renderLine*(gpu: PGPU) =
  echo("Render Line: ", gpu.line, " scrollX: ", gpu.scrollX, " scrollY: ", gpu.scrollY)
  var mapOffset = if gpu.bgTileMap == TileMap0: 0x1800 else: 0x1C00
  # Get the line of tiles to use.
  mapOffset.inc(((gpu.line + gpu.scrollY) and 0xFF) shr 3)
  echo("MapOffset: ", mapOffset.toHex(4))  
  
  let lineOffset = (gpu.scrollX shr 3) # Which tile to start with in the map line
  
  # Get tile index from background map
  var tileIndex = gpu.vram[mapOffset + lineOffset]
  
  echo("Tile index: ", tileIndex)
  
  echo("bgtileset: ", gpu.bgtileset)

  
  let tile = getTileRow(gpu, tileIndex)

  let y = (gpu.line + gpu.scrollY) and 7
  let x = gpu.scrollX and 7
  let surfaceOffset = gpu.line * 160 * 4

proc next*(gpu: PGPU, time: int) =
  gpu.clock.inc(time)
  #echo("GPU Mode: ", gpu.mode)
  case gpu.mode
  of OAMRead:
    if gpu.clock >= 80:
      # Enter VRAMRead
      gpu.mode = VRAMRead
      gpu.clock = 0
  of VRAMRead:
    if gpu.clock >= 172:
      # Enter HBlank
      gpu.mode = HBlank
      gpu.clock = 0
      
      # Render scanline
      gpu.renderLine()
  of HBlank:
    if gpu.clock >= 204:
      gpu.clock = 0
      gpu.line.inc
      #echo("HBlank line: ", gpu.line)
      if gpu.line == 143:
        # We reached the bottom edge of the screen (screen is 144 pixels in height.)
        # Enter VBlank
        gpu.mode = VBlank
        
        # TODO: Render surface on screen.
      else:
        gpu.mode = OAMRead
  of VBlank:
    if gpu.clock >= 456:
      gpu.clock = 0
      
      # TODO: according to ref, line should be increased and, should wait
      # for line to be greater than 153? then restart the line and mode?
      echo("Vblank done. Line = ", gpu.line)
      gpu.mode = OAMRead
      gpu.line = 0
      