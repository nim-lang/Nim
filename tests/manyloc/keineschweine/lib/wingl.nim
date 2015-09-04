import
  gl, windows

proc wglGetExtensionsStringARB*(hdc: HDC): cstring{.dynlib: dllname,
    importc: "wglGetExtensionsStringARB".}
const
  WGL_FRONT_COLOR_BUFFER_BIT_ARB* = 0x00000001
  WGL_BACK_COLOR_BUFFER_BIT_ARB* = 0x00000002
  WGL_DEPTH_BUFFER_BIT_ARB* = 0x00000004
  WGL_STENCIL_BUFFER_BIT_ARB* = 0x00000008

proc WinChoosePixelFormat*(DC: HDC, p2: PPixelFormatDescriptor): int{.
    dynlib: "gdi32", importc: "ChoosePixelFormat".}
proc wglCreateBufferRegionARB*(hDC: HDC, iLayerPlane: TGLint, uType: TGLuint): THandle{.
    dynlib: dllname, importc: "wglCreateBufferRegionARB".}
proc wglDeleteBufferRegionARB*(hRegion: THandle){.dynlib: dllname,
    importc: "wglDeleteBufferRegionARB".}
proc wglSaveBufferRegionARB*(hRegion: THandle, x: TGLint, y: TGLint,
                             width: TGLint, height: TGLint): BOOL{.
    dynlib: dllname, importc: "wglSaveBufferRegionARB".}
proc wglRestoreBufferRegionARB*(hRegion: THandle, x: TGLint, y: TGLint,
                                width: TGLint, height: TGLint, xSrc: TGLint,
                                ySrc: TGLint): BOOL{.dynlib: dllname,
    importc: "wglRestoreBufferRegionARB".}
proc wglAllocateMemoryNV*(size: TGLsizei, readFrequency: TGLfloat,
                          writeFrequency: TGLfloat, priority: TGLfloat): PGLvoid{.
    dynlib: dllname, importc: "wglAllocateMemoryNV".}
proc wglFreeMemoryNV*(pointer: PGLvoid){.dynlib: dllname,
    importc: "wglFreeMemoryNV".}
const
  WGL_IMAGE_BUFFER_MIN_ACCESS_I3D* = 0x00000001
  WGL_IMAGE_BUFFER_LOCK_I3D* = 0x00000002

proc wglCreateImageBufferI3D*(hDC: HDC, dwSize: DWORD, uFlags: UINT): PGLvoid{.
    dynlib: dllname, importc: "wglCreateImageBufferI3D".}
proc wglDestroyImageBufferI3D*(hDC: HDC, pAddress: PGLvoid): BOOL{.
    dynlib: dllname, importc: "wglDestroyImageBufferI3D".}
proc wglAssociateImageBufferEventsI3D*(hdc: HDC, pEvent: PHandle,
                                       pAddress: PGLvoid, pSize: PDWORD,
                                       count: UINT): BOOL{.dynlib: dllname,
    importc: "wglAssociateImageBufferEventsI3D".}
proc wglReleaseImageBufferEventsI3D*(hdc: HDC, pAddress: PGLvoid, count: UINT): BOOL{.
    dynlib: dllname, importc: "wglReleaseImageBufferEventsI3D".}
proc wglEnableFrameLockI3D*(): BOOL{.dynlib: dllname,
                                     importc: "wglEnableFrameLockI3D".}
proc wglDisableFrameLockI3D*(): BOOL{.dynlib: dllname,
                                      importc: "wglDisableFrameLockI3D".}
proc wglIsEnabledFrameLockI3D*(pFlag: PBOOL): BOOL{.dynlib: dllname,
    importc: "wglIsEnabledFrameLockI3D".}
proc wglQueryFrameLockMasterI3D*(pFlag: PBOOL): BOOL{.dynlib: dllname,
    importc: "wglQueryFrameLockMasterI3D".}
proc wglGetFrameUsageI3D*(pUsage: PGLfloat): BOOL{.dynlib: dllname,
    importc: "wglGetFrameUsageI3D".}
proc wglBeginFrameTrackingI3D*(): BOOL{.dynlib: dllname,
                                        importc: "wglBeginFrameTrackingI3D".}
proc wglEndFrameTrackingI3D*(): BOOL{.dynlib: dllname,
                                      importc: "wglEndFrameTrackingI3D".}
proc wglQueryFrameTrackingI3D*(pFrameCount: PDWORD, pMissedFrames: PDWORD,
                               pLastMissedUsage: PGLfloat): BOOL{.
    dynlib: dllname, importc: "wglQueryFrameTrackingI3D".}
const
  WGL_NUMBER_PIXEL_FORMATS_ARB* = 0x00002000
  WGL_DRAW_TO_WINDOW_ARB* = 0x00002001
  WGL_DRAW_TO_BITMAP_ARB* = 0x00002002
  WGL_ACCELERATION_ARB* = 0x00002003
  WGL_NEED_PALETTE_ARB* = 0x00002004
  WGL_NEED_SYSTEM_PALETTE_ARB* = 0x00002005
  WGL_SWAP_LAYER_BUFFERS_ARB* = 0x00002006
  WGL_SWAP_METHOD_ARB* = 0x00002007
  WGL_NUMBER_OVERLAYS_ARB* = 0x00002008
  WGL_NUMBER_UNDERLAYS_ARB* = 0x00002009
  WGL_TRANSPARENT_ARB* = 0x0000200A
  WGL_TRANSPARENT_RED_VALUE_ARB* = 0x00002037
  WGL_TRANSPARENT_GREEN_VALUE_ARB* = 0x00002038
  WGL_TRANSPARENT_BLUE_VALUE_ARB* = 0x00002039
  WGL_TRANSPARENT_ALPHA_VALUE_ARB* = 0x0000203A
  WGL_TRANSPARENT_INDEX_VALUE_ARB* = 0x0000203B
  WGL_SHARE_DEPTH_ARB* = 0x0000200C
  WGL_SHARE_STENCIL_ARB* = 0x0000200D
  WGL_SHARE_ACCUM_ARB* = 0x0000200E
  WGL_SUPPORT_GDI_ARB* = 0x0000200F
  WGL_SUPPORT_OPENGL_ARB* = 0x00002010
  WGL_DOUBLE_BUFFER_ARB* = 0x00002011
  WGL_STEREO_ARB* = 0x00002012
  WGL_PIXEL_TYPE_ARB* = 0x00002013
  WGL_COLOR_BITS_ARB* = 0x00002014
  WGL_RED_BITS_ARB* = 0x00002015
  WGL_RED_SHIFT_ARB* = 0x00002016
  WGL_GREEN_BITS_ARB* = 0x00002017
  WGL_GREEN_SHIFT_ARB* = 0x00002018
  WGL_BLUE_BITS_ARB* = 0x00002019
  WGL_BLUE_SHIFT_ARB* = 0x0000201A
  WGL_ALPHA_BITS_ARB* = 0x0000201B
  WGL_ALPHA_SHIFT_ARB* = 0x0000201C
  WGL_ACCUM_BITS_ARB* = 0x0000201D
  WGL_ACCUM_RED_BITS_ARB* = 0x0000201E
  WGL_ACCUM_GREEN_BITS_ARB* = 0x0000201F
  WGL_ACCUM_BLUE_BITS_ARB* = 0x00002020
  WGL_ACCUM_ALPHA_BITS_ARB* = 0x00002021
  WGL_DEPTH_BITS_ARB* = 0x00002022
  WGL_STENCIL_BITS_ARB* = 0x00002023
  WGL_AUX_BUFFERS_ARB* = 0x00002024
  WGL_NO_ACCELERATION_ARB* = 0x00002025
  WGL_GENERIC_ACCELERATION_ARB* = 0x00002026
  WGL_FULL_ACCELERATION_ARB* = 0x00002027
  WGL_SWAP_EXCHANGE_ARB* = 0x00002028
  WGL_SWAP_COPY_ARB* = 0x00002029
  WGL_SWAP_UNDEFINED_ARB* = 0x0000202A
  WGL_TYPE_RGBA_ARB* = 0x0000202B
  WGL_TYPE_COLORINDEX_ARB* = 0x0000202C

proc wglGetPixelFormatAttribivARB*(hdc: HDC, iPixelFormat: TGLint,
                                   iLayerPlane: TGLint, nAttributes: TGLuint,
                                   piAttributes: PGLint, piValues: PGLint): BOOL{.
    dynlib: dllname, importc: "wglGetPixelFormatAttribivARB".}
proc wglGetPixelFormatAttribfvARB*(hdc: HDC, iPixelFormat: TGLint,
                                   iLayerPlane: TGLint, nAttributes: TGLuint,
                                   piAttributes: PGLint, pfValues: PGLfloat): BOOL{.
    dynlib: dllname, importc: "wglGetPixelFormatAttribfvARB".}
proc wglChoosePixelFormatARB*(hdc: HDC, piAttribIList: PGLint,
                              pfAttribFList: PGLfloat, nMaxFormats: TGLuint,
                              piFormats: PGLint, nNumFormats: PGLuint): BOOL{.
    dynlib: dllname, importc: "wglChoosePixelFormatARB".}
const
  WGL_ERROR_INVALID_PIXEL_TYPE_ARB* = 0x00002043
  WGL_ERROR_INCOMPATIBLE_DEVICE_CONTEXTS_ARB* = 0x00002054

proc wglMakeContextCurrentARB*(hDrawDC: HDC, hReadDC: HDC, hglrc: HGLRC): BOOL{.
    dynlib: dllname, importc: "wglMakeContextCurrentARB".}
proc wglGetCurrentReadDCARB*(): HDC{.dynlib: dllname,
                                     importc: "wglGetCurrentReadDCARB".}
const
  WGL_DRAW_TO_PBUFFER_ARB* = 0x0000202D # WGL_DRAW_TO_PBUFFER_ARB  { already defined }
  WGL_MAX_PBUFFER_PIXELS_ARB* = 0x0000202E
  WGL_MAX_PBUFFER_WIDTH_ARB* = 0x0000202F
  WGL_MAX_PBUFFER_HEIGHT_ARB* = 0x00002030
  WGL_PBUFFER_LARGEST_ARB* = 0x00002033
  WGL_PBUFFER_WIDTH_ARB* = 0x00002034
  WGL_PBUFFER_HEIGHT_ARB* = 0x00002035
  WGL_PBUFFER_LOST_ARB* = 0x00002036

proc wglCreatePbufferARB*(hDC: HDC, iPixelFormat: TGLint, iWidth: TGLint,
                          iHeight: TGLint, piAttribList: PGLint): THandle{.
    dynlib: dllname, importc: "wglCreatePbufferARB".}
proc wglGetPbufferDCARB*(hPbuffer: THandle): HDC{.dynlib: dllname,
    importc: "wglGetPbufferDCARB".}
proc wglReleasePbufferDCARB*(hPbuffer: THandle, hDC: HDC): TGLint{.
    dynlib: dllname, importc: "wglReleasePbufferDCARB".}
proc wglDestroyPbufferARB*(hPbuffer: THandle): BOOL{.dynlib: dllname,
    importc: "wglDestroyPbufferARB".}
proc wglQueryPbufferARB*(hPbuffer: THandle, iAttribute: TGLint, piValue: PGLint): BOOL{.
    dynlib: dllname, importc: "wglQueryPbufferARB".}
proc wglSwapIntervalEXT*(interval: TGLint): BOOL{.dynlib: dllname,
    importc: "wglSwapIntervalEXT".}
proc wglGetSwapIntervalEXT*(): TGLint{.dynlib: dllname,
                                       importc: "wglGetSwapIntervalEXT".}
const
  WGL_BIND_TO_TEXTURE_RGB_ARB* = 0x00002070
  WGL_BIND_TO_TEXTURE_RGBA_ARB* = 0x00002071
  WGL_TEXTURE_FORMAT_ARB* = 0x00002072
  WGL_TEXTURE_TARGET_ARB* = 0x00002073
  WGL_MIPMAP_TEXTURE_ARB* = 0x00002074
  WGL_TEXTURE_RGB_ARB* = 0x00002075
  WGL_TEXTURE_RGBA_ARB* = 0x00002076
  WGL_NO_TEXTURE_ARB* = 0x00002077
  WGL_TEXTURE_CUBE_MAP_ARB* = 0x00002078
  WGL_TEXTURE_1D_ARB* = 0x00002079
  WGL_TEXTURE_2D_ARB* = 0x0000207A # WGL_NO_TEXTURE_ARB  { already defined }
  WGL_MIPMAP_LEVEL_ARB* = 0x0000207B
  WGL_CUBE_MAP_FACE_ARB* = 0x0000207C
  WGL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB* = 0x0000207D
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB* = 0x0000207E
  WGL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB* = 0x0000207F
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB* = 0x00002080
  WGL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB* = 0x00002081
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB* = 0x00002082
  WGL_FRONT_LEFT_ARB* = 0x00002083
  WGL_FRONT_RIGHT_ARB* = 0x00002084
  WGL_BACK_LEFT_ARB* = 0x00002085
  WGL_BACK_RIGHT_ARB* = 0x00002086
  WGL_AUX0_ARB* = 0x00002087
  WGL_AUX1_ARB* = 0x00002088
  WGL_AUX2_ARB* = 0x00002089
  WGL_AUX3_ARB* = 0x0000208A
  WGL_AUX4_ARB* = 0x0000208B
  WGL_AUX5_ARB* = 0x0000208C
  WGL_AUX6_ARB* = 0x0000208D
  WGL_AUX7_ARB* = 0x0000208E
  WGL_AUX8_ARB* = 0x0000208F
  WGL_AUX9_ARB* = 0x00002090

proc wglBindTexImageARB*(hPbuffer: THandle, iBuffer: TGLint): BOOL{.
    dynlib: dllname, importc: "wglBindTexImageARB".}
proc wglReleaseTexImageARB*(hPbuffer: THandle, iBuffer: TGLint): BOOL{.
    dynlib: dllname, importc: "wglReleaseTexImageARB".}
proc wglSetPbufferAttribARB*(hPbuffer: THandle, piAttribList: PGLint): BOOL{.
    dynlib: dllname, importc: "wglSetPbufferAttribARB".}
proc wglGetExtensionsStringEXT*(): cstring{.dynlib: dllname,
    importc: "wglGetExtensionsStringEXT".}
proc wglMakeContextCurrentEXT*(hDrawDC: HDC, hReadDC: HDC, hglrc: HGLRC): BOOL{.
    dynlib: dllname, importc: "wglMakeContextCurrentEXT".}
proc wglGetCurrentReadDCEXT*(): HDC{.dynlib: dllname,
                                     importc: "wglGetCurrentReadDCEXT".}
const
  WGL_DRAW_TO_PBUFFER_EXT* = 0x0000202D
  WGL_MAX_PBUFFER_PIXELS_EXT* = 0x0000202E
  WGL_MAX_PBUFFER_WIDTH_EXT* = 0x0000202F
  WGL_MAX_PBUFFER_HEIGHT_EXT* = 0x00002030
  WGL_OPTIMAL_PBUFFER_WIDTH_EXT* = 0x00002031
  WGL_OPTIMAL_PBUFFER_HEIGHT_EXT* = 0x00002032
  WGL_PBUFFER_LARGEST_EXT* = 0x00002033
  WGL_PBUFFER_WIDTH_EXT* = 0x00002034
  WGL_PBUFFER_HEIGHT_EXT* = 0x00002035

proc wglCreatePbufferEXT*(hDC: HDC, iPixelFormat: TGLint, iWidth: TGLint,
                          iHeight: TGLint, piAttribList: PGLint): THandle{.
    dynlib: dllname, importc: "wglCreatePbufferEXT".}
proc wglGetPbufferDCEXT*(hPbuffer: THandle): HDC{.dynlib: dllname,
    importc: "wglGetPbufferDCEXT".}
proc wglReleasePbufferDCEXT*(hPbuffer: THandle, hDC: HDC): TGLint{.
    dynlib: dllname, importc: "wglReleasePbufferDCEXT".}
proc wglDestroyPbufferEXT*(hPbuffer: THandle): BOOL{.dynlib: dllname,
    importc: "wglDestroyPbufferEXT".}
proc wglQueryPbufferEXT*(hPbuffer: THandle, iAttribute: TGLint, piValue: PGLint): BOOL{.
    dynlib: dllname, importc: "wglQueryPbufferEXT".}
const
  WGL_NUMBER_PIXEL_FORMATS_EXT* = 0x00002000
  WGL_DRAW_TO_WINDOW_EXT* = 0x00002001
  WGL_DRAW_TO_BITMAP_EXT* = 0x00002002
  WGL_ACCELERATION_EXT* = 0x00002003
  WGL_NEED_PALETTE_EXT* = 0x00002004
  WGL_NEED_SYSTEM_PALETTE_EXT* = 0x00002005
  WGL_SWAP_LAYER_BUFFERS_EXT* = 0x00002006
  WGL_SWAP_METHOD_EXT* = 0x00002007
  WGL_NUMBER_OVERLAYS_EXT* = 0x00002008
  WGL_NUMBER_UNDERLAYS_EXT* = 0x00002009
  WGL_TRANSPARENT_EXT* = 0x0000200A
  WGL_TRANSPARENT_VALUE_EXT* = 0x0000200B
  WGL_SHARE_DEPTH_EXT* = 0x0000200C
  WGL_SHARE_STENCIL_EXT* = 0x0000200D
  WGL_SHARE_ACCUM_EXT* = 0x0000200E
  WGL_SUPPORT_GDI_EXT* = 0x0000200F
  WGL_SUPPORT_OPENGL_EXT* = 0x00002010
  WGL_DOUBLE_BUFFER_EXT* = 0x00002011
  WGL_STEREO_EXT* = 0x00002012
  WGL_PIXEL_TYPE_EXT* = 0x00002013
  WGL_COLOR_BITS_EXT* = 0x00002014
  WGL_RED_BITS_EXT* = 0x00002015
  WGL_RED_SHIFT_EXT* = 0x00002016
  WGL_GREEN_BITS_EXT* = 0x00002017
  WGL_GREEN_SHIFT_EXT* = 0x00002018
  WGL_BLUE_BITS_EXT* = 0x00002019
  WGL_BLUE_SHIFT_EXT* = 0x0000201A
  WGL_ALPHA_BITS_EXT* = 0x0000201B
  WGL_ALPHA_SHIFT_EXT* = 0x0000201C
  WGL_ACCUM_BITS_EXT* = 0x0000201D
  WGL_ACCUM_RED_BITS_EXT* = 0x0000201E
  WGL_ACCUM_GREEN_BITS_EXT* = 0x0000201F
  WGL_ACCUM_BLUE_BITS_EXT* = 0x00002020
  WGL_ACCUM_ALPHA_BITS_EXT* = 0x00002021
  WGL_DEPTH_BITS_EXT* = 0x00002022
  WGL_STENCIL_BITS_EXT* = 0x00002023
  WGL_AUX_BUFFERS_EXT* = 0x00002024
  WGL_NO_ACCELERATION_EXT* = 0x00002025
  WGL_GENERIC_ACCELERATION_EXT* = 0x00002026
  WGL_FULL_ACCELERATION_EXT* = 0x00002027
  WGL_SWAP_EXCHANGE_EXT* = 0x00002028
  WGL_SWAP_COPY_EXT* = 0x00002029
  WGL_SWAP_UNDEFINED_EXT* = 0x0000202A
  WGL_TYPE_RGBA_EXT* = 0x0000202B
  WGL_TYPE_COLORINDEX_EXT* = 0x0000202C

proc wglGetPixelFormatAttribivEXT*(hdc: HDC, iPixelFormat: TGLint,
                                   iLayerPlane: TGLint, nAttributes: TGLuint,
                                   piAttributes: PGLint, piValues: PGLint): BOOL{.
    dynlib: dllname, importc: "wglGetPixelFormatAttribivEXT".}
proc wglGetPixelFormatAttribfvEXT*(hdc: HDC, iPixelFormat: TGLint,
                                   iLayerPlane: TGLint, nAttributes: TGLuint,
                                   piAttributes: PGLint, pfValues: PGLfloat): BOOL{.
    dynlib: dllname, importc: "wglGetPixelFormatAttribfvEXT".}
proc wglChoosePixelFormatEXT*(hdc: HDC, piAttribIList: PGLint,
                              pfAttribFList: PGLfloat, nMaxFormats: TGLuint,
                              piFormats: PGLint, nNumFormats: PGLuint): BOOL{.
    dynlib: dllname, importc: "wglChoosePixelFormatEXT".}
const
  WGL_DIGITAL_VIDEO_CURSOR_ALPHA_FRAMEBUFFER_I3D* = 0x00002050
  WGL_DIGITAL_VIDEO_CURSOR_ALPHA_VALUE_I3D* = 0x00002051
  WGL_DIGITAL_VIDEO_CURSOR_INCLUDED_I3D* = 0x00002052
  WGL_DIGITAL_VIDEO_GAMMA_CORRECTED_I3D* = 0x00002053

proc wglGetDigitalVideoParametersI3D*(hDC: HDC, iAttribute: TGLint,
                                      piValue: PGLint): BOOL{.dynlib: dllname,
    importc: "wglGetDigitalVideoParametersI3D".}
proc wglSetDigitalVideoParametersI3D*(hDC: HDC, iAttribute: TGLint,
                                      piValue: PGLint): BOOL{.dynlib: dllname,
    importc: "wglSetDigitalVideoParametersI3D".}
const
  WGL_GAMMA_TABLE_SIZE_I3D* = 0x0000204E
  WGL_GAMMA_EXCLUDE_DESKTOP_I3D* = 0x0000204F

proc wglGetGammaTableParametersI3D*(hDC: HDC, iAttribute: TGLint,
                                    piValue: PGLint): BOOL{.dynlib: dllname,
    importc: "wglGetGammaTableParametersI3D".}
proc wglSetGammaTableParametersI3D*(hDC: HDC, iAttribute: TGLint,
                                    piValue: PGLint): BOOL{.dynlib: dllname,
    importc: "wglSetGammaTableParametersI3D".}
proc wglGetGammaTableI3D*(hDC: HDC, iEntries: TGLint, puRed: PGLUSHORT,
                          puGreen: PGLUSHORT, puBlue: PGLUSHORT): BOOL{.
    dynlib: dllname, importc: "wglGetGammaTableI3D".}
proc wglSetGammaTableI3D*(hDC: HDC, iEntries: TGLint, puRed: PGLUSHORT,
                          puGreen: PGLUSHORT, puBlue: PGLUSHORT): BOOL{.
    dynlib: dllname, importc: "wglSetGammaTableI3D".}
const
  WGL_GENLOCK_SOURCE_MULTIVIEW_I3D* = 0x00002044
  WGL_GENLOCK_SOURCE_EXTERNAL_SYNC_I3D* = 0x00002045
  WGL_GENLOCK_SOURCE_EXTERNAL_FIELD_I3D* = 0x00002046
  WGL_GENLOCK_SOURCE_EXTERNAL_TTL_I3D* = 0x00002047
  WGL_GENLOCK_SOURCE_DIGITAL_SYNC_I3D* = 0x00002048
  WGL_GENLOCK_SOURCE_DIGITAL_FIELD_I3D* = 0x00002049
  WGL_GENLOCK_SOURCE_EDGE_FALLING_I3D* = 0x0000204A
  WGL_GENLOCK_SOURCE_EDGE_RISING_I3D* = 0x0000204B
  WGL_GENLOCK_SOURCE_EDGE_BOTH_I3D* = 0x0000204C
  WGL_FLOAT_COMPONENTS_NV* = 0x000020B0
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_R_NV* = 0x000020B1
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RG_NV* = 0x000020B2
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGB_NV* = 0x000020B3
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGBA_NV* = 0x000020B4
  WGL_TEXTURE_FLOAT_R_NV* = 0x000020B5
  WGL_TEXTURE_FLOAT_RG_NV* = 0x000020B6
  WGL_TEXTURE_FLOAT_RGB_NV* = 0x000020B7
  WGL_TEXTURE_FLOAT_RGBA_NV* = 0x000020B8

proc wglEnableGenlockI3D*(hDC: HDC): BOOL{.dynlib: dllname,
    importc: "wglEnableGenlockI3D".}
proc wglDisableGenlockI3D*(hDC: HDC): BOOL{.dynlib: dllname,
    importc: "wglDisableGenlockI3D".}
proc wglIsEnabledGenlockI3D*(hDC: HDC, pFlag: PBOOL): BOOL{.dynlib: dllname,
    importc: "wglIsEnabledGenlockI3D".}
proc wglGenlockSourceI3D*(hDC: HDC, uSource: TGLuint): BOOL{.dynlib: dllname,
    importc: "wglGenlockSourceI3D".}
proc wglGetGenlockSourceI3D*(hDC: HDC, uSource: PGLUINT): BOOL{.dynlib: dllname,
    importc: "wglGetGenlockSourceI3D".}
proc wglGenlockSourceEdgeI3D*(hDC: HDC, uEdge: TGLuint): BOOL{.dynlib: dllname,
    importc: "wglGenlockSourceEdgeI3D".}
proc wglGetGenlockSourceEdgeI3D*(hDC: HDC, uEdge: PGLUINT): BOOL{.
    dynlib: dllname, importc: "wglGetGenlockSourceEdgeI3D".}
proc wglGenlockSampleRateI3D*(hDC: HDC, uRate: TGLuint): BOOL{.dynlib: dllname,
    importc: "wglGenlockSampleRateI3D".}
proc wglGetGenlockSampleRateI3D*(hDC: HDC, uRate: PGLUINT): BOOL{.
    dynlib: dllname, importc: "wglGetGenlockSampleRateI3D".}
proc wglGenlockSourceDelayI3D*(hDC: HDC, uDelay: TGLuint): BOOL{.
    dynlib: dllname, importc: "wglGenlockSourceDelayI3D".}
proc wglGetGenlockSourceDelayI3D*(hDC: HDC, uDelay: PGLUINT): BOOL{.
    dynlib: dllname, importc: "wglGetGenlockSourceDelayI3D".}
proc wglQueryGenlockMaxSourceDelayI3D*(hDC: HDC, uMaxLineDelay: PGLUINT,
                                       uMaxPixelDelay: PGLUINT): BOOL{.
    dynlib: dllname, importc: "wglQueryGenlockMaxSourceDelayI3D".}
const
  WGL_BIND_TO_TEXTURE_RECTANGLE_RGB_NV* = 0x000020A0
  WGL_BIND_TO_TEXTURE_RECTANGLE_RGBA_NV* = 0x000020A1
  WGL_TEXTURE_RECTANGLE_NV* = 0x000020A2

const
  WGL_RGBA_FLOAT_MODE_ATI* = 0x00008820
  WGL_COLOR_CLEAR_UNCLAMPED_VALUE_ATI* = 0x00008835
  WGL_TYPE_RGBA_FLOAT_ATI* = 0x000021A0

# implementation
