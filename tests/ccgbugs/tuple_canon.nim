# bug #2250

import
    math, strutils

type
    Meters = float
    Point2[T] = tuple[x, y: T]

    HexState* = enum
        hsOn, hsOff

    Index = uint16

    HexGrid* = object
        w, h: int                       ## Width and height of the hex grid.
        radius: Meters                  ## Radius of circle that circumscribes a hexagon.
        grid: seq[HexState]             ## Information on what hexes are drawn.

    HexVtxIndex = enum
        hiA, hiB, hiC, hiD, hiE, hiF

    HexCoord* = Point2[int]

const
    HexDY = sqrt(1.0 - (0.5 * 0.5))     # dy from center to midpoint of 1-2
    HexDX = sqrt(1.0 - (HexDY * HexDY)) # dx from center to midpoint of 1-5 (0.5)


let
    hexOffsets : array[HexVtxIndex, Point2[float]] = [
                  (-1.0, 0.0),
                  (-HexDX, -HexDY),
                  (HexDX, -HexDY),
                  (1.0, 0.0),
                  (HexDX, HexDY),
                  (-HexDX, HexDY)]

    evenSharingOffsets : array[HexVtxIndex, tuple[hc: HexCoord; idx: HexVtxIndex]] = [
            ((0,0), hiA),
            ((0,0), hiB),
            ((1,-1), hiA),
            ((1,0), hiB),
            ((1,0), hiA),
            ((0,1), hiB)]

    oddSharingOffsets : array[HexVtxIndex, tuple[hc: HexCoord; idx: HexVtxIndex]] = [
            ((0,0), hiA),
            ((0,0), hiB),
            ((1,0), hiA),
            ((1,1), hiB),
            ((1,1), hiA),
            ((0,1), hiB)]

template odd*(i: int) : expr =
    (i and 1) != 0

proc vidx(hg: HexGrid; col, row: int; i: HexVtxIndex) : Index =
    #NOTE: this variation compiles
    #var offset : type(evenSharingOffsets[i])
    #
    #if odd(col):
    #    offset = oddSharingOffsets[i]
    #else:
    #    offset = evenSharingOffsets[i]

    let
        #NOTE: this line generates the bad code
        offset = (if odd(col): oddSharingOffsets[i] else: evenSharingOffsets[i])
        x = col + 1 + offset.hc.x
        y = row + 1 + offset.hc.y

    result = Index(x*2 + y * (hg.w + 2)*2 + int(offset.idx))

proc go() =
    var hg : HexGrid

    echo "vidx ", $vidx(hg, 1, 2, hiC)

go()
