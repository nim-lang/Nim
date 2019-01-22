
import 
  x, xlib

when defined(use_pkg_config) or defined(use_pkg_config_static):
    {.pragma: libxrender, cdecl, importc.}
    when defined(use_pkg_config):
        {.passl: gorge("pkg-config xrender --libs").}
    else:
        {.passl: gorge("pkg-config xrender --static --libs").}
else:
    when defined(macosx):
        const 
          libXrender* = "libXrender.dylib"
    else:
        const 
          libXrender* = "libXrender.so"

    
    {.pragma: libxrender, dynlib: libXrender, cdecl, importc.}
#const 
#  libXrender* = "libXrender.so"

#
#  Automatically converted by H2Pas 0.99.15 from xrender.h
#  The following command line parameters were used:
#    -p
#    -T
#    -S
#    -d
#    -c
#    xrender.h
#

type 
  PGlyph* = ptr TGlyph
  TGlyph* = int32
  PGlyphSet* = ptr TGlyphSet
  TGlyphSet* = int32
  PPicture* = ptr TPicture
  TPicture* = int32
  PPictFormat* = ptr TPictFormat
  TPictFormat* = int32

const 
  RENDER_NAME* = "RENDER"
  RENDER_MAJOR* = 0
  RENDER_MINOR* = 0
  constX_RenderQueryVersion* = 0
  X_RenderQueryPictFormats* = 1
  X_RenderQueryPictIndexValues* = 2
  X_RenderQueryDithers* = 3
  constX_RenderCreatePicture* = 4
  constX_RenderChangePicture* = 5
  X_RenderSetPictureClipRectangles* = 6
  constX_RenderFreePicture* = 7
  constX_RenderComposite* = 8
  X_RenderScale* = 9
  X_RenderTrapezoids* = 10
  X_RenderTriangles* = 11
  X_RenderTriStrip* = 12
  X_RenderTriFan* = 13
  X_RenderColorTrapezoids* = 14
  X_RenderColorTriangles* = 15
  X_RenderTransform* = 16
  constX_RenderCreateGlyphSet* = 17
  constX_RenderReferenceGlyphSet* = 18
  constX_RenderFreeGlyphSet* = 19
  constX_RenderAddGlyphs* = 20
  constX_RenderAddGlyphsFromPicture* = 21
  constX_RenderFreeGlyphs* = 22
  constX_RenderCompositeGlyphs8* = 23
  constX_RenderCompositeGlyphs16* = 24
  constX_RenderCompositeGlyphs32* = 25
  BadPictFormat* = 0
  BadPicture* = 1
  BadPictOp* = 2
  BadGlyphSet* = 3
  BadGlyph* = 4
  RenderNumberErrors* = BadGlyph + 1
  PictTypeIndexed* = 0
  PictTypeDirect* = 1
  PictOpClear* = 0
  PictOpSrc* = 1
  PictOpDst* = 2
  PictOpOver* = 3
  PictOpOverReverse* = 4
  PictOpIn* = 5
  PictOpInReverse* = 6
  PictOpOut* = 7
  PictOpOutReverse* = 8
  PictOpAtop* = 9
  PictOpAtopReverse* = 10
  PictOpXor* = 11
  PictOpAdd* = 12
  PictOpSaturate* = 13
  PictOpMaximum* = 13
  PolyEdgeSharp* = 0
  PolyEdgeSmooth* = 1
  PolyModePrecise* = 0
  PolyModeImprecise* = 1
  CPRepeat* = 1 shl 0
  CPAlphaMap* = 1 shl 1
  CPAlphaXOrigin* = 1 shl 2
  CPAlphaYOrigin* = 1 shl 3
  CPClipXOrigin* = 1 shl 4
  CPClipYOrigin* = 1 shl 5
  CPClipMask* = 1 shl 6
  CPGraphicsExposure* = 1 shl 7
  CPSubwindowMode* = 1 shl 8
  CPPolyEdge* = 1 shl 9
  CPPolyMode* = 1 shl 10
  CPDither* = 1 shl 11
  CPLastBit* = 11

type 
  PXRenderDirectFormat* = ptr TXRenderDirectFormat
  TXRenderDirectFormat*{.final.} = object 
    red*: int16
    redMask*: int16
    green*: int16
    greenMask*: int16
    blue*: int16
    blueMask*: int16
    alpha*: int16
    alphaMask*: int16

  PXRenderPictFormat* = ptr TXRenderPictFormat
  TXRenderPictFormat*{.final.} = object 
    id*: TPictFormat
    thetype*: int32
    depth*: int32
    direct*: TXRenderDirectFormat
    colormap*: TColormap


const 
  PictFormatID* = 1 shl 0
  PictFormatType* = 1 shl 1
  PictFormatDepth* = 1 shl 2
  PictFormatRed* = 1 shl 3
  PictFormatRedMask* = 1 shl 4
  PictFormatGreen* = 1 shl 5
  PictFormatGreenMask* = 1 shl 6
  PictFormatBlue* = 1 shl 7
  PictFormatBlueMask* = 1 shl 8
  PictFormatAlpha* = 1 shl 9
  PictFormatAlphaMask* = 1 shl 10
  PictFormatColormap* = 1 shl 11

type 
  PXRenderVisual* = ptr TXRenderVisual
  TXRenderVisual*{.final.} = object 
    visual*: PVisual
    format*: PXRenderPictFormat

  PXRenderDepth* = ptr TXRenderDepth
  TXRenderDepth*{.final.} = object 
    depth*: int32
    nvisuals*: int32
    visuals*: PXRenderVisual

  PXRenderScreen* = ptr TXRenderScreen
  TXRenderScreen*{.final.} = object 
    depths*: PXRenderDepth
    ndepths*: int32
    fallback*: PXRenderPictFormat

  PXRenderInfo* = ptr TXRenderInfo
  TXRenderInfo*{.final.} = object 
    format*: PXRenderPictFormat
    nformat*: int32
    screen*: PXRenderScreen
    nscreen*: int32
    depth*: PXRenderDepth
    ndepth*: int32
    visual*: PXRenderVisual
    nvisual*: int32

  PXRenderPictureAttributes* = ptr TXRenderPictureAttributes
  TXRenderPictureAttributes*{.final.} = object 
    repeat*: TBool
    alpha_map*: TPicture
    alpha_x_origin*: int32
    alpha_y_origin*: int32
    clip_x_origin*: int32
    clip_y_origin*: int32
    clip_mask*: TPixmap
    graphics_exposures*: TBool
    subwindow_mode*: int32
    poly_edge*: int32
    poly_mode*: int32
    dither*: TAtom

  PXGlyphInfo* = ptr TXGlyphInfo
  TXGlyphInfo*{.final.} = object 
    width*: int16
    height*: int16
    x*: int16
    y*: int16
    xOff*: int16
    yOff*: int16


proc XRenderQueryExtension*(dpy: PDisplay, event_basep: ptr int32, 
                            error_basep: ptr int32): TBool{.libxrender.}
proc XRenderQueryVersion*(dpy: PDisplay, major_versionp: ptr int32, 
                          minor_versionp: ptr int32): TStatus{.libxrender.}
proc XRenderQueryFormats*(dpy: PDisplay): TStatus{.libxrender.}
proc XRenderFindVisualFormat*(dpy: PDisplay, visual: PVisual): PXRenderPictFormat{.
    libxrender.}
proc XRenderFindFormat*(dpy: PDisplay, mask: int32, 
                        `template`: PXRenderPictFormat, count: int32): PXRenderPictFormat{.
    libxrender.}
proc XRenderCreatePicture*(dpy: PDisplay, drawable: TDrawable, 
                           format: PXRenderPictFormat, valuemask: int32, 
                           attributes: PXRenderPictureAttributes): TPicture{.
    libxrender.}
proc XRenderChangePicture*(dpy: PDisplay, picture: TPicture, valuemask: int32, 
                           attributes: PXRenderPictureAttributes){.libxrender.}
proc XRenderFreePicture*(dpy: PDisplay, picture: TPicture){.libxrender.}
proc XRenderComposite*(dpy: PDisplay, op: int32, src: TPicture, mask: TPicture, 
                       dst: TPicture, src_x: int32, src_y: int32, mask_x: int32, 
                       mask_y: int32, dst_x: int32, dst_y: int32, width: int32, 
                       height: int32){.libxrender.}
proc XRenderCreateGlyphSet*(dpy: PDisplay, format: PXRenderPictFormat): TGlyphSet{.
    libxrender.}
proc XRenderReferenceGlyphSet*(dpy: PDisplay, existing: TGlyphSet): TGlyphSet{.
    libxrender.}
proc XRenderFreeGlyphSet*(dpy: PDisplay, glyphset: TGlyphSet){.libxrender.}
proc XRenderAddGlyphs*(dpy: PDisplay, glyphset: TGlyphSet, gids: PGlyph, 
                       glyphs: PXGlyphInfo, nglyphs: int32, images: cstring, 
                       nbyte_images: int32){.libxrender.}
proc XRenderFreeGlyphs*(dpy: PDisplay, glyphset: TGlyphSet, gids: PGlyph, 
                        nglyphs: int32){.libxrender.}
proc XRenderCompositeString8*(dpy: PDisplay, op: int32, src: TPicture, 
                              dst: TPicture, maskFormat: PXRenderPictFormat, 
                              glyphset: TGlyphSet, xSrc: int32, ySrc: int32, 
                              xDst: int32, yDst: int32, str: cstring, 
                              nchar: int32){.libxrender.}
# implementation
