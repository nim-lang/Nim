discard """
  output: '''
'''
"""

block:
  type
    TilesetCT[n: static int] = int
    TilesetRT = int
    Tileset = TilesetCT | TilesetRT

  func prepareTileset(tileset: var Tileset) = discard

  #func prepareTileset(tileset: Tileset): Tileset =
  #  result = tileset
  #  result.prepareTileset

  var parsedTileset: TilesetRT
  prepareTileset(parsedTileset)
