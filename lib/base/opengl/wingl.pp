unit wingl;

interface

uses gl;

function wglGetExtensionsStringARB(hdc: HDC): Pchar; external dllname;

function Load_WGL_ARB_extensions_string: Boolean; external dllname;

const
  WGL_FRONT_COLOR_BUFFER_BIT_ARB = $0001;
  WGL_BACK_COLOR_BUFFER_BIT_ARB = $0002;
  WGL_DEPTH_BUFFER_BIT_ARB = $0004;
  WGL_STENCIL_BUFFER_BIT_ARB = $0008;
  
function WinChoosePixelFormat(DC: HDC; p2: PPixelFormatDescriptor): Integer; external dllname; external 'gdi32' name 'ChoosePixelFormat';

function wglCreateBufferRegionARB(hDC: HDC; iLayerPlane: TGLint; uType: TGLuint): THandle; external dllname;
procedure wglDeleteBufferRegionARB(hRegion: THandle); external dllname;
function wglSaveBufferRegionARB(hRegion: THandle; x: TGLint; y: TGLint; width: TGLint; height: TGLint): BOOL; external dllname;
function wglRestoreBufferRegionARB(hRegion: THandle; x: TGLint; y: TGLint; width: TGLint; height: TGLint; xSrc: TGLint; ySrc: TGLint): BOOL; external dllname;

  function wglAllocateMemoryNV(size: TGLsizei; readFrequency: TGLfloat; writeFrequency: TGLfloat; priority: TGLfloat): PGLvoid; external dllname;
  procedure wglFreeMemoryNV(pointer: PGLvoid); external dllname;

const
  WGL_IMAGE_BUFFER_MIN_ACCESS_I3D = $0001;
  WGL_IMAGE_BUFFER_LOCK_I3D = $0002;

  function wglCreateImageBufferI3D(hDC: HDC; dwSize: DWORD; uFlags: UINT): PGLvoid; external dllname;
  function wglDestroyImageBufferI3D(hDC: HDC; pAddress: PGLvoid): BOOL; external dllname;
  function wglAssociateImageBufferEventsI3D(hdc: HDC; pEvent: PHandle; pAddress: PGLvoid; pSize: PDWORD; count: UINT): BOOL; external dllname;
  function wglReleaseImageBufferEventsI3D(hdc: HDC; pAddress: PGLvoid; count: UINT): BOOL; external dllname;

  function wglEnableFrameLockI3D(): BOOL; external dllname;
  function wglDisableFrameLockI3D(): BOOL; external dllname;
  function wglIsEnabledFrameLockI3D(pFlag: PBOOL): BOOL; external dllname;
  function wglQueryFrameLockMasterI3D(pFlag: PBOOL): BOOL; external dllname;

  function wglGetFrameUsageI3D(pUsage: PGLfloat): BOOL; external dllname;
  function wglBeginFrameTrackingI3D(): BOOL; external dllname;
  function wglEndFrameTrackingI3D(): BOOL; external dllname;
  function wglQueryFrameTrackingI3D(pFrameCount: PDWORD; pMissedFrames: PDWORD; pLastMissedUsage: PGLfloat): BOOL; external dllname;

const
  WGL_NUMBER_PIXEL_FORMATS_ARB = $2000;
  WGL_DRAW_TO_WINDOW_ARB = $2001;
  WGL_DRAW_TO_BITMAP_ARB = $2002;
  WGL_ACCELERATION_ARB = $2003;
  WGL_NEED_PALETTE_ARB = $2004;
  WGL_NEED_SYSTEM_PALETTE_ARB = $2005;
  WGL_SWAP_LAYER_BUFFERS_ARB = $2006;
  WGL_SWAP_METHOD_ARB = $2007;
  WGL_NUMBER_OVERLAYS_ARB = $2008;
  WGL_NUMBER_UNDERLAYS_ARB = $2009;
  WGL_TRANSPARENT_ARB = $200A;
  WGL_TRANSPARENT_RED_VALUE_ARB = $2037;
  WGL_TRANSPARENT_GREEN_VALUE_ARB = $2038;
  WGL_TRANSPARENT_BLUE_VALUE_ARB = $2039;
  WGL_TRANSPARENT_ALPHA_VALUE_ARB = $203A;
  WGL_TRANSPARENT_INDEX_VALUE_ARB = $203B;
  WGL_SHARE_DEPTH_ARB = $200C;
  WGL_SHARE_STENCIL_ARB = $200D;
  WGL_SHARE_ACCUM_ARB = $200E;
  WGL_SUPPORT_GDI_ARB = $200F;
  WGL_SUPPORT_OPENGL_ARB = $2010;
  WGL_DOUBLE_BUFFER_ARB = $2011;
  WGL_STEREO_ARB = $2012;
  WGL_PIXEL_TYPE_ARB = $2013;
  WGL_COLOR_BITS_ARB = $2014;
  WGL_RED_BITS_ARB = $2015;
  WGL_RED_SHIFT_ARB = $2016;
  WGL_GREEN_BITS_ARB = $2017;
  WGL_GREEN_SHIFT_ARB = $2018;
  WGL_BLUE_BITS_ARB = $2019;
  WGL_BLUE_SHIFT_ARB = $201A;
  WGL_ALPHA_BITS_ARB = $201B;
  WGL_ALPHA_SHIFT_ARB = $201C;
  WGL_ACCUM_BITS_ARB = $201D;
  WGL_ACCUM_RED_BITS_ARB = $201E;
  WGL_ACCUM_GREEN_BITS_ARB = $201F;
  WGL_ACCUM_BLUE_BITS_ARB = $2020;
  WGL_ACCUM_ALPHA_BITS_ARB = $2021;
  WGL_DEPTH_BITS_ARB = $2022;
  WGL_STENCIL_BITS_ARB = $2023;
  WGL_AUX_BUFFERS_ARB = $2024;
  WGL_NO_ACCELERATION_ARB = $2025;
  WGL_GENERIC_ACCELERATION_ARB = $2026;
  WGL_FULL_ACCELERATION_ARB = $2027;
  WGL_SWAP_EXCHANGE_ARB = $2028;
  WGL_SWAP_COPY_ARB = $2029;
  WGL_SWAP_UNDEFINED_ARB = $202A;
  WGL_TYPE_RGBA_ARB = $202B;
  WGL_TYPE_COLORINDEX_ARB = $202C;

  function wglGetPixelFormatAttribivARB(hdc: HDC; iPixelFormat: TGLint; iLayerPlane: TGLint; nAttributes: TGLuint; const piAttributes: PGLint; piValues: PGLint): BOOL; external dllname;
  function wglGetPixelFormatAttribfvARB(hdc: HDC; iPixelFormat: TGLint; iLayerPlane: TGLint; nAttributes: TGLuint; const piAttributes: PGLint; pfValues: PGLfloat): BOOL; external dllname;
  function wglChoosePixelFormatARB(hdc: HDC; const piAttribIList: PGLint; const pfAttribFList: PGLfloat; nMaxFormats: TGLuint; piFormats: PGLint; nNumFormats: PGLuint): BOOL; external dllname;


const
  WGL_ERROR_INVALID_PIXEL_TYPE_ARB = $2043;
  WGL_ERROR_INCOMPATIBLE_DEVICE_CONTEXTS_ARB = $2054;

  function wglMakeContextCurrentARB(hDrawDC: HDC; hReadDC: HDC; hglrc: HGLRC): BOOL; external dllname;
  function wglGetCurrentReadDCARB(): HDC; external dllname;

function Load_WGL_ARB_make_current_read: Boolean;

const
  WGL_DRAW_TO_PBUFFER_ARB = $202D;
  // WGL_DRAW_TO_PBUFFER_ARB  { already defined }
  WGL_MAX_PBUFFER_PIXELS_ARB = $202E;
  WGL_MAX_PBUFFER_WIDTH_ARB = $202F;
  WGL_MAX_PBUFFER_HEIGHT_ARB = $2030;
  WGL_PBUFFER_LARGEST_ARB = $2033;
  WGL_PBUFFER_WIDTH_ARB = $2034;
  WGL_PBUFFER_HEIGHT_ARB = $2035;
  WGL_PBUFFER_LOST_ARB = $2036;

  function wglCreatePbufferARB(hDC: HDC; iPixelFormat: TGLint; iWidth: TGLint; iHeight: TGLint; const piAttribList: PGLint): THandle; external dllname;
  function wglGetPbufferDCARB(hPbuffer: THandle): HDC; external dllname;
  function wglReleasePbufferDCARB(hPbuffer: THandle; hDC: HDC): TGLint; external dllname;
  function wglDestroyPbufferARB(hPbuffer: THandle): BOOL; external dllname;
  function wglQueryPbufferARB(hPbuffer: THandle; iAttribute: TGLint; piValue: PGLint): BOOL; external dllname;


  function wglSwapIntervalEXT(interval: TGLint): BOOL; external dllname;
  function wglGetSwapIntervalEXT(): TGLint; external dllname;

const
  WGL_BIND_TO_TEXTURE_RGB_ARB = $2070;
  WGL_BIND_TO_TEXTURE_RGBA_ARB = $2071;
  WGL_TEXTURE_FORMAT_ARB = $2072;
  WGL_TEXTURE_TARGET_ARB = $2073;
  WGL_MIPMAP_TEXTURE_ARB = $2074;
  WGL_TEXTURE_RGB_ARB = $2075;
  WGL_TEXTURE_RGBA_ARB = $2076;
  WGL_NO_TEXTURE_ARB = $2077;
  WGL_TEXTURE_CUBE_MAP_ARB = $2078;
  WGL_TEXTURE_1D_ARB = $2079;
  WGL_TEXTURE_2D_ARB = $207A;
  // WGL_NO_TEXTURE_ARB  { already defined }
  WGL_MIPMAP_LEVEL_ARB = $207B;
  WGL_CUBE_MAP_FACE_ARB = $207C;
  WGL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB = $207D;
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB = $207E;
  WGL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB = $207F;
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB = $2080;
  WGL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB = $2081;
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB = $2082;
  WGL_FRONT_LEFT_ARB = $2083;
  WGL_FRONT_RIGHT_ARB = $2084;
  WGL_BACK_LEFT_ARB = $2085;
  WGL_BACK_RIGHT_ARB = $2086;
  WGL_AUX0_ARB = $2087;
  WGL_AUX1_ARB = $2088;
  WGL_AUX2_ARB = $2089;
  WGL_AUX3_ARB = $208A;
  WGL_AUX4_ARB = $208B;
  WGL_AUX5_ARB = $208C;
  WGL_AUX6_ARB = $208D;
  WGL_AUX7_ARB = $208E;
  WGL_AUX8_ARB = $208F;
  WGL_AUX9_ARB = $2090;

  function wglBindTexImageARB(hPbuffer: THandle; iBuffer: TGLint): BOOL; external dllname;
  function wglReleaseTexImageARB(hPbuffer: THandle; iBuffer: TGLint): BOOL; external dllname;
  function wglSetPbufferAttribARB(hPbuffer: THandle; const piAttribList: PGLint): BOOL; external dllname;


  function wglGetExtensionsStringEXT(): Pchar; external dllname;

  function wglMakeContextCurrentEXT(hDrawDC: HDC; hReadDC: HDC; hglrc: HGLRC): BOOL; external dllname;
  function wglGetCurrentReadDCEXT(): HDC; external dllname;

const
  WGL_DRAW_TO_PBUFFER_EXT = $202D;
  WGL_MAX_PBUFFER_PIXELS_EXT = $202E;
  WGL_MAX_PBUFFER_WIDTH_EXT = $202F;
  WGL_MAX_PBUFFER_HEIGHT_EXT = $2030;
  WGL_OPTIMAL_PBUFFER_WIDTH_EXT = $2031;
  WGL_OPTIMAL_PBUFFER_HEIGHT_EXT = $2032;
  WGL_PBUFFER_LARGEST_EXT = $2033;
  WGL_PBUFFER_WIDTH_EXT = $2034;
  WGL_PBUFFER_HEIGHT_EXT = $2035;

  function wglCreatePbufferEXT(hDC: HDC; iPixelFormat: TGLint; iWidth: TGLint; iHeight: TGLint; const piAttribList: PGLint): THandle; external dllname;
  function wglGetPbufferDCEXT(hPbuffer: THandle): HDC; external dllname;
  function wglReleasePbufferDCEXT(hPbuffer: THandle; hDC: HDC): TGLint; external dllname;
  function wglDestroyPbufferEXT(hPbuffer: THandle): BOOL; external dllname;
  function wglQueryPbufferEXT(hPbuffer: THandle; iAttribute: TGLint; piValue: PGLint): BOOL; external dllname;

const
  WGL_NUMBER_PIXEL_FORMATS_EXT = $2000;
  WGL_DRAW_TO_WINDOW_EXT = $2001;
  WGL_DRAW_TO_BITMAP_EXT = $2002;
  WGL_ACCELERATION_EXT = $2003;
  WGL_NEED_PALETTE_EXT = $2004;
  WGL_NEED_SYSTEM_PALETTE_EXT = $2005;
  WGL_SWAP_LAYER_BUFFERS_EXT = $2006;
  WGL_SWAP_METHOD_EXT = $2007;
  WGL_NUMBER_OVERLAYS_EXT = $2008;
  WGL_NUMBER_UNDERLAYS_EXT = $2009;
  WGL_TRANSPARENT_EXT = $200A;
  WGL_TRANSPARENT_VALUE_EXT = $200B;
  WGL_SHARE_DEPTH_EXT = $200C;
  WGL_SHARE_STENCIL_EXT = $200D;
  WGL_SHARE_ACCUM_EXT = $200E;
  WGL_SUPPORT_GDI_EXT = $200F;
  WGL_SUPPORT_OPENGL_EXT = $2010;
  WGL_DOUBLE_BUFFER_EXT = $2011;
  WGL_STEREO_EXT = $2012;
  WGL_PIXEL_TYPE_EXT = $2013;
  WGL_COLOR_BITS_EXT = $2014;
  WGL_RED_BITS_EXT = $2015;
  WGL_RED_SHIFT_EXT = $2016;
  WGL_GREEN_BITS_EXT = $2017;
  WGL_GREEN_SHIFT_EXT = $2018;
  WGL_BLUE_BITS_EXT = $2019;
  WGL_BLUE_SHIFT_EXT = $201A;
  WGL_ALPHA_BITS_EXT = $201B;
  WGL_ALPHA_SHIFT_EXT = $201C;
  WGL_ACCUM_BITS_EXT = $201D;
  WGL_ACCUM_RED_BITS_EXT = $201E;
  WGL_ACCUM_GREEN_BITS_EXT = $201F;
  WGL_ACCUM_BLUE_BITS_EXT = $2020;
  WGL_ACCUM_ALPHA_BITS_EXT = $2021;
  WGL_DEPTH_BITS_EXT = $2022;
  WGL_STENCIL_BITS_EXT = $2023;
  WGL_AUX_BUFFERS_EXT = $2024;
  WGL_NO_ACCELERATION_EXT = $2025;
  WGL_GENERIC_ACCELERATION_EXT = $2026;
  WGL_FULL_ACCELERATION_EXT = $2027;
  WGL_SWAP_EXCHANGE_EXT = $2028;
  WGL_SWAP_COPY_EXT = $2029;
  WGL_SWAP_UNDEFINED_EXT = $202A;
  WGL_TYPE_RGBA_EXT = $202B;
  WGL_TYPE_COLORINDEX_EXT = $202C;

  function wglGetPixelFormatAttribivEXT(hdc: HDC; iPixelFormat: TGLint; iLayerPlane: TGLint; nAttributes: TGLuint; piAttributes: PGLint; piValues: PGLint): BOOL; external dllname;
  function wglGetPixelFormatAttribfvEXT(hdc: HDC; iPixelFormat: TGLint; iLayerPlane: TGLint; nAttributes: TGLuint; piAttributes: PGLint; pfValues: PGLfloat): BOOL; external dllname;
  function wglChoosePixelFormatEXT(hdc: HDC; const piAttribIList: PGLint; const pfAttribFList: PGLfloat; nMaxFormats: TGLuint; piFormats: PGLint; nNumFormats: PGLuint): BOOL; external dllname;


const
  WGL_DIGITAL_VIDEO_CURSOR_ALPHA_FRAMEBUFFER_I3D = $2050;
  WGL_DIGITAL_VIDEO_CURSOR_ALPHA_VALUE_I3D = $2051;
  WGL_DIGITAL_VIDEO_CURSOR_INCLUDED_I3D = $2052;
  WGL_DIGITAL_VIDEO_GAMMA_CORRECTED_I3D = $2053;

  function wglGetDigitalVideoParametersI3D(hDC: HDC; iAttribute: TGLint; piValue: PGLint): BOOL; external dllname;
  function wglSetDigitalVideoParametersI3D(hDC: HDC; iAttribute: TGLint; const piValue: PGLint): BOOL; external dllname;


const
  WGL_GAMMA_TABLE_SIZE_I3D = $204E;
  WGL_GAMMA_EXCLUDE_DESKTOP_I3D = $204F;

  function wglGetGammaTableParametersI3D(hDC: HDC; iAttribute: TGLint; piValue: PGLint): BOOL; external dllname;
  function wglSetGammaTableParametersI3D(hDC: HDC; iAttribute: TGLint; const piValue: PGLint): BOOL; external dllname;
  function wglGetGammaTableI3D(hDC: HDC; iEntries: TGLint; puRed: PGLUSHORT; puGreen: PGLUSHORT; puBlue: PGLUSHORT): BOOL; external dllname;
  function wglSetGammaTableI3D(hDC: HDC; iEntries: TGLint; const puRed: PGLUSHORT; const puGreen: PGLUSHORT; const puBlue: PGLUSHORT): BOOL; external dllname;

const
  WGL_GENLOCK_SOURCE_MULTIVIEW_I3D = $2044;
  WGL_GENLOCK_SOURCE_EXTERNAL_SYNC_I3D = $2045;
  WGL_GENLOCK_SOURCE_EXTERNAL_FIELD_I3D = $2046;
  WGL_GENLOCK_SOURCE_EXTERNAL_TTL_I3D = $2047;
  WGL_GENLOCK_SOURCE_DIGITAL_SYNC_I3D = $2048;
  WGL_GENLOCK_SOURCE_DIGITAL_FIELD_I3D = $2049;
  WGL_GENLOCK_SOURCE_EDGE_FALLING_I3D = $204A;
  WGL_GENLOCK_SOURCE_EDGE_RISING_I3D = $204B;
  WGL_GENLOCK_SOURCE_EDGE_BOTH_I3D = $204C;

  WGL_FLOAT_COMPONENTS_NV = $20B0;
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_R_NV = $20B1;
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RG_NV = $20B2;
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGB_NV = $20B3;
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGBA_NV = $20B4;
  WGL_TEXTURE_FLOAT_R_NV = $20B5;
  WGL_TEXTURE_FLOAT_RG_NV = $20B6;
  WGL_TEXTURE_FLOAT_RGB_NV = $20B7;
  WGL_TEXTURE_FLOAT_RGBA_NV = $20B8;

  function wglEnableGenlockI3D(hDC: HDC): BOOL; external dllname;
  function wglDisableGenlockI3D(hDC: HDC): BOOL; external dllname;
  function wglIsEnabledGenlockI3D(hDC: HDC; pFlag: PBOOL): BOOL; external dllname;
  function wglGenlockSourceI3D(hDC: HDC; uSource: TGLuint): BOOL; external dllname;
  function wglGetGenlockSourceI3D(hDC: HDC; uSource: PGLUINT): BOOL; external dllname;
  function wglGenlockSourceEdgeI3D(hDC: HDC; uEdge: TGLuint): BOOL; external dllname;
  function wglGetGenlockSourceEdgeI3D(hDC: HDC; uEdge: PGLUINT): BOOL; external dllname;
  function wglGenlockSampleRateI3D(hDC: HDC; uRate: TGLuint): BOOL; external dllname;
  function wglGetGenlockSampleRateI3D(hDC: HDC; uRate: PGLUINT): BOOL; external dllname;
  function wglGenlockSourceDelayI3D(hDC: HDC; uDelay: TGLuint): BOOL; external dllname;
  function wglGetGenlockSourceDelayI3D(hDC: HDC; uDelay: PGLUINT): BOOL; external dllname;
  function wglQueryGenlockMaxSourceDelayI3D(hDC: HDC; uMaxLineDelay: PGLUINT; uMaxPixelDelay: PGLUINT): BOOL; external dllname;

const
  WGL_BIND_TO_TEXTURE_RECTANGLE_RGB_NV = $20A0;
  WGL_BIND_TO_TEXTURE_RECTANGLE_RGBA_NV = $20A1;
  WGL_TEXTURE_RECTANGLE_NV = $20A2;


const
  WGL_RGBA_FLOAT_MODE_ATI = $8820;
  WGL_COLOR_CLEAR_UNCLAMPED_VALUE_ATI = $8835;
  WGL_TYPE_RGBA_FLOAT_ATI = $21A0;

implementation

end.
