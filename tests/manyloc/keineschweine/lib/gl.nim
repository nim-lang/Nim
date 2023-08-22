#
#
#  Adaption of the delphi3d.net OpenGL units to FreePascal
#  Sebastian Guenther (sg@freepascal.org) in 2002
#  These units are free to use
#
#******************************************************************************
# Converted to Delphi by Tom Nuydens (tom@delphi3d.net)
# For the latest updates, visit Delphi3D: http://www.delphi3d.net
#******************************************************************************

when defined(windows):
  {.push, callconv: stdcall.}
else:
  {.push, callconv: cdecl.}
when defined(windows):
  const
    dllname* = "opengl32.dll"
elif defined(macosx):
  const
    dllname* = "/System/Library/Frameworks/OpenGL.framework/Libraries/libGL.dylib"
else:
  const
    dllname* = "libGL.so.1"
type
  PGLenum* = ptr TGLenum
  PGLboolean* = ptr TGLboolean
  PGLbitfield* = ptr TGLbitfield
  TGLbyte* = int8
  PGLbyte* = ptr TGlbyte
  PGLshort* = ptr TGLshort
  PGLint* = ptr TGLint
  PGLsizei* = ptr TGLsizei
  PGLubyte* = ptr TGLubyte
  PGLushort* = ptr TGLushort
  PGLuint* = ptr TGLuint
  PGLfloat* = ptr TGLfloat
  PGLclampf* = ptr TGLclampf
  PGLdouble* = ptr TGLdouble
  PGLclampd* = ptr TGLclampd
  PGLvoid* = pointer
  PPGLvoid* = ptr PGLvoid
  TGLenum* = cint
  TGLboolean* = bool
  TGLbitfield* = cint
  TGLshort* = int16
  TGLint* = cint
  TGLsizei* = int
  TGLubyte* = int8
  TGLushort* = int16
  TGLuint* = cint
  TGLfloat* = float32
  TGLclampf* = float32
  TGLdouble* = float
  TGLclampd* = float

const                         # Version
  GL_VERSION_1_1* = 1         # AccumOp
  constGL_ACCUM* = 0x00000100
  GL_LOAD* = 0x00000101
  GL_RETURN* = 0x00000102
  GL_MULT* = 0x00000103
  GL_ADD* = 0x00000104        # AlphaFunction
  GL_NEVER* = 0x00000200
  GL_LESS* = 0x00000201
  GL_EQUAL* = 0x00000202
  GL_LEQUAL* = 0x00000203
  GL_GREATER* = 0x00000204
  GL_NOTEQUAL* = 0x00000205
  GL_GEQUAL* = 0x00000206
  GL_ALWAYS* = 0x00000207     # AttribMask
  GL_CURRENT_BIT* = 0x00000001
  GL_POINT_BIT* = 0x00000002
  GL_LINE_BIT* = 0x00000004
  GL_POLYGON_BIT* = 0x00000008
  GL_POLYGON_STIPPLE_BIT* = 0x00000010
  GL_PIXEL_MODE_BIT* = 0x00000020
  GL_LIGHTING_BIT* = 0x00000040
  GL_FOG_BIT* = 0x00000080
  GL_DEPTH_BUFFER_BIT* = 0x00000100
  GL_ACCUM_BUFFER_BIT* = 0x00000200
  GL_STENCIL_BUFFER_BIT* = 0x00000400
  GL_VIEWPORT_BIT* = 0x00000800
  GL_TRANSFORM_BIT* = 0x00001000
  GL_ENABLE_BIT* = 0x00002000
  GL_COLOR_BUFFER_BIT* = 0x00004000
  GL_HINT_BIT* = 0x00008000
  GL_EVAL_BIT* = 0x00010000
  GL_LIST_BIT* = 0x00020000
  GL_TEXTURE_BIT* = 0x00040000
  GL_SCISSOR_BIT* = 0x00080000
  GL_ALL_ATTRIB_BITS* = 0x000FFFFF # BeginMode
  GL_POINTS* = 0x00000000
  GL_LINES* = 0x00000001
  GL_LINE_LOOP* = 0x00000002
  GL_LINE_STRIP* = 0x00000003
  GL_TRIANGLES* = 0x00000004
  GL_TRIANGLE_STRIP* = 0x00000005
  GL_TRIANGLE_FAN* = 0x00000006
  GL_QUADS* = 0x00000007
  GL_QUAD_STRIP* = 0x00000008
  GL_POLYGON* = 0x00000009    # BlendingFactorDest
  GL_ZERO* = 0
  GL_ONE* = 1
  GL_SRC_COLOR* = 0x00000300
  GL_ONE_MINUS_SRC_COLOR* = 0x00000301
  GL_SRC_ALPHA* = 0x00000302
  GL_ONE_MINUS_SRC_ALPHA* = 0x00000303
  GL_DST_ALPHA* = 0x00000304
  GL_ONE_MINUS_DST_ALPHA* = 0x00000305 # BlendingFactorSrc
                                       #      GL_ZERO
                                       #      GL_ONE
  GL_DST_COLOR* = 0x00000306
  GL_ONE_MINUS_DST_COLOR* = 0x00000307
  GL_SRC_ALPHA_SATURATE* = 0x00000308 #      GL_SRC_ALPHA
                                      #      GL_ONE_MINUS_SRC_ALPHA
                                      #      GL_DST_ALPHA
                                      #      GL_ONE_MINUS_DST_ALPHA
                                      # Boolean
  GL_TRUE* = 1
  GL_FALSE* = 0               # ClearBufferMask
                              #      GL_COLOR_BUFFER_BIT
                              #      GL_ACCUM_BUFFER_BIT
                              #      GL_STENCIL_BUFFER_BIT
                              #      GL_DEPTH_BUFFER_BIT
                              # ClientArrayType
                              #      GL_VERTEX_ARRAY
                              #      GL_NORMAL_ARRAY
                              #      GL_COLOR_ARRAY
                              #      GL_INDEX_ARRAY
                              #      GL_TEXTURE_COORD_ARRAY
                              #      GL_EDGE_FLAG_ARRAY
                              # ClipPlaneName
  GL_CLIP_PLANE0* = 0x00003000
  GL_CLIP_PLANE1* = 0x00003001
  GL_CLIP_PLANE2* = 0x00003002
  GL_CLIP_PLANE3* = 0x00003003
  GL_CLIP_PLANE4* = 0x00003004
  GL_CLIP_PLANE5* = 0x00003005 # ColorMaterialFace
                               #      GL_FRONT
                               #      GL_BACK
                               #      GL_FRONT_AND_BACK
                               # ColorMaterialParameter
                               #      GL_AMBIENT
                               #      GL_DIFFUSE
                               #      GL_SPECULAR
                               #      GL_EMISSION
                               #      GL_AMBIENT_AND_DIFFUSE
                               # ColorPointerType
                               #      GL_BYTE
                               #      GL_UNSIGNED_BYTE
                               #      GL_SHORT
                               #      GL_UNSIGNED_SHORT
                               #      GL_INT
                               #      GL_UNSIGNED_INT
                               #      GL_FLOAT
                               #      GL_DOUBLE
                               # CullFaceMode
                               #      GL_FRONT
                               #      GL_BACK
                               #      GL_FRONT_AND_BACK
                               # DataType
  GL_BYTE* = 0x00001400
  GL_UNSIGNED_BYTE* = 0x00001401
  GL_SHORT* = 0x00001402
  GL_UNSIGNED_SHORT* = 0x00001403
  GL_INT* = 0x00001404
  GL_UNSIGNED_INT* = 0x00001405
  GL_FLOAT* = 0x00001406
  GL_2_BYTES* = 0x00001407
  GL_3_BYTES* = 0x00001408
  GL_4_BYTES* = 0x00001409
  GL_DOUBLE* = 0x0000140A     # DepthFunction
                              #      GL_NEVER
                              #      GL_LESS
                              #      GL_EQUAL
                              #      GL_LEQUAL
                              #      GL_GREATER
                              #      GL_NOTEQUAL
                              #      GL_GEQUAL
                              #      GL_ALWAYS
                              # DrawBufferMode
  GL_NONE* = 0
  GL_FRONT_LEFT* = 0x00000400
  GL_FRONT_RIGHT* = 0x00000401
  GL_BACK_LEFT* = 0x00000402
  GL_BACK_RIGHT* = 0x00000403
  GL_FRONT* = 0x00000404
  GL_BACK* = 0x00000405
  GL_LEFT* = 0x00000406
  GL_RIGHT* = 0x00000407
  GL_FRONT_AND_BACK* = 0x00000408
  GL_AUX0* = 0x00000409
  GL_AUX1* = 0x0000040A
  GL_AUX2* = 0x0000040B
  GL_AUX3* = 0x0000040C       # Enable
                              #      GL_FOG
                              #      GL_LIGHTING
                              #      GL_TEXTURE_1D
                              #      GL_TEXTURE_2D
                              #      GL_LINE_STIPPLE
                              #      GL_POLYGON_STIPPLE
                              #      GL_CULL_FACE
                              #      GL_ALPHA_TEST
                              #      GL_BLEND
                              #      GL_INDEX_LOGIC_OP
                              #      GL_COLOR_LOGIC_OP
                              #      GL_DITHER
                              #      GL_STENCIL_TEST
                              #      GL_DEPTH_TEST
                              #      GL_CLIP_PLANE0
                              #      GL_CLIP_PLANE1
                              #      GL_CLIP_PLANE2
                              #      GL_CLIP_PLANE3
                              #      GL_CLIP_PLANE4
                              #      GL_CLIP_PLANE5
                              #      GL_LIGHT0
                              #      GL_LIGHT1
                              #      GL_LIGHT2
                              #      GL_LIGHT3
                              #      GL_LIGHT4
                              #      GL_LIGHT5
                              #      GL_LIGHT6
                              #      GL_LIGHT7
                              #      GL_TEXTURE_GEN_S
                              #      GL_TEXTURE_GEN_T
                              #      GL_TEXTURE_GEN_R
                              #      GL_TEXTURE_GEN_Q
                              #      GL_MAP1_VERTEX_3
                              #      GL_MAP1_VERTEX_4
                              #      GL_MAP1_COLOR_4
                              #      GL_MAP1_INDEX
                              #      GL_MAP1_NORMAL
                              #      GL_MAP1_TEXTURE_COORD_1
                              #      GL_MAP1_TEXTURE_COORD_2
                              #      GL_MAP1_TEXTURE_COORD_3
                              #      GL_MAP1_TEXTURE_COORD_4
                              #      GL_MAP2_VERTEX_3
                              #      GL_MAP2_VERTEX_4
                              #      GL_MAP2_COLOR_4
                              #      GL_MAP2_INDEX
                              #      GL_MAP2_NORMAL
                              #      GL_MAP2_TEXTURE_COORD_1
                              #      GL_MAP2_TEXTURE_COORD_2
                              #      GL_MAP2_TEXTURE_COORD_3
                              #      GL_MAP2_TEXTURE_COORD_4
                              #      GL_POINT_SMOOTH
                              #      GL_LINE_SMOOTH
                              #      GL_POLYGON_SMOOTH
                              #      GL_SCISSOR_TEST
                              #      GL_COLOR_MATERIAL
                              #      GL_NORMALIZE
                              #      GL_AUTO_NORMAL
                              #      GL_VERTEX_ARRAY
                              #      GL_NORMAL_ARRAY
                              #      GL_COLOR_ARRAY
                              #      GL_INDEX_ARRAY
                              #      GL_TEXTURE_COORD_ARRAY
                              #      GL_EDGE_FLAG_ARRAY
                              #      GL_POLYGON_OFFSET_POINT
                              #      GL_POLYGON_OFFSET_LINE
                              #      GL_POLYGON_OFFSET_FILL
                              # ErrorCode
  GL_NO_ERROR* = 0
  GL_INVALID_ENUM* = 0x00000500
  GL_INVALID_VALUE* = 0x00000501
  GL_INVALID_OPERATION* = 0x00000502
  GL_STACK_OVERFLOW* = 0x00000503
  GL_STACK_UNDERFLOW* = 0x00000504
  GL_OUT_OF_MEMORY* = 0x00000505 # FeedBackMode
  GL_2D* = 0x00000600
  GL_3D* = 0x00000601
  GL_3D_COLOR* = 0x00000602
  GL_3D_COLOR_TEXTURE* = 0x00000603
  GL_4D_COLOR_TEXTURE* = 0x00000604 # FeedBackToken
  GL_PASS_THROUGH_TOKEN* = 0x00000700
  GL_POINT_TOKEN* = 0x00000701
  GL_LINE_TOKEN* = 0x00000702
  GL_POLYGON_TOKEN* = 0x00000703
  GL_BITMAP_TOKEN* = 0x00000704
  GL_DRAW_PIXEL_TOKEN* = 0x00000705
  GL_COPY_PIXEL_TOKEN* = 0x00000706
  GL_LINE_RESET_TOKEN* = 0x00000707 # FogMode
                                    #      GL_LINEAR
  GL_EXP* = 0x00000800
  GL_EXP2* = 0x00000801       # FogParameter
                              #      GL_FOG_COLOR
                              #      GL_FOG_DENSITY
                              #      GL_FOG_END
                              #      GL_FOG_INDEX
                              #      GL_FOG_MODE
                              #      GL_FOG_START
                              # FrontFaceDirection
  GL_CW* = 0x00000900
  GL_CCW* = 0x00000901        # GetMapTarget
  GL_COEFF* = 0x00000A00
  GL_ORDER* = 0x00000A01
  GL_DOMAIN* = 0x00000A02     # GetPixelMap
                              #      GL_PIXEL_MAP_I_TO_I
                              #      GL_PIXEL_MAP_S_TO_S
                              #      GL_PIXEL_MAP_I_TO_R
                              #      GL_PIXEL_MAP_I_TO_G
                              #      GL_PIXEL_MAP_I_TO_B
                              #      GL_PIXEL_MAP_I_TO_A
                              #      GL_PIXEL_MAP_R_TO_R
                              #      GL_PIXEL_MAP_G_TO_G
                              #      GL_PIXEL_MAP_B_TO_B
                              #      GL_PIXEL_MAP_A_TO_A
                              # GetPointerTarget
                              #      GL_VERTEX_ARRAY_POINTER
                              #      GL_NORMAL_ARRAY_POINTER
                              #      GL_COLOR_ARRAY_POINTER
                              #      GL_INDEX_ARRAY_POINTER
                              #      GL_TEXTURE_COORD_ARRAY_POINTER
                              #      GL_EDGE_FLAG_ARRAY_POINTER
                              # GetTarget
  GL_CURRENT_COLOR* = 0x00000B00
  GL_CURRENT_INDEX* = 0x00000B01
  GL_CURRENT_NORMAL* = 0x00000B02
  GL_CURRENT_TEXTURE_COORDS* = 0x00000B03
  GL_CURRENT_RASTER_COLOR* = 0x00000B04
  GL_CURRENT_RASTER_INDEX* = 0x00000B05
  GL_CURRENT_RASTER_TEXTURE_COORDS* = 0x00000B06
  GL_CURRENT_RASTER_POSITION* = 0x00000B07
  GL_CURRENT_RASTER_POSITION_VALID* = 0x00000B08
  GL_CURRENT_RASTER_DISTANCE* = 0x00000B09
  GL_POINT_SMOOTH* = 0x00000B10
  constGL_POINT_SIZE* = 0x00000B11
  GL_POINT_SIZE_RANGE* = 0x00000B12
  GL_POINT_SIZE_GRANULARITY* = 0x00000B13
  GL_LINE_SMOOTH* = 0x00000B20
  constGL_LINE_WIDTH* = 0x00000B21
  GL_LINE_WIDTH_RANGE* = 0x00000B22
  GL_LINE_WIDTH_GRANULARITY* = 0x00000B23
  constGL_LINE_STIPPLE* = 0x00000B24
  GL_LINE_STIPPLE_PATTERN* = 0x00000B25
  GL_LINE_STIPPLE_REPEAT* = 0x00000B26
  GL_LIST_MODE* = 0x00000B30
  GL_MAX_LIST_NESTING* = 0x00000B31
  constGL_LIST_BASE* = 0x00000B32
  GL_LIST_INDEX* = 0x00000B33
  constGL_POLYGON_MODE* = 0x00000B40
  GL_POLYGON_SMOOTH* = 0x00000B41
  constGL_POLYGON_STIPPLE* = 0x00000B42
  constGL_EDGE_FLAG* = 0x00000B43
  constGL_CULL_FACE* = 0x00000B44
  GL_CULL_FACE_MODE* = 0x00000B45
  constGL_FRONT_FACE* = 0x00000B46
  GL_LIGHTING* = 0x00000B50
  GL_LIGHT_MODEL_LOCAL_VIEWER* = 0x00000B51
  GL_LIGHT_MODEL_TWO_SIDE* = 0x00000B52
  GL_LIGHT_MODEL_AMBIENT* = 0x00000B53
  constGL_SHADE_MODEL* = 0x00000B54
  GL_COLOR_MATERIAL_FACE* = 0x00000B55
  GL_COLOR_MATERIAL_PARAMETER* = 0x00000B56
  constGL_COLOR_MATERIAL* = 0x00000B57
  GL_FOG* = 0x00000B60
  GL_FOG_INDEX* = 0x00000B61
  GL_FOG_DENSITY* = 0x00000B62
  GL_FOG_START* = 0x00000B63
  GL_FOG_END* = 0x00000B64
  GL_FOG_MODE* = 0x00000B65
  GL_FOG_COLOR* = 0x00000B66
  constGL_DEPTH_RANGE* = 0x00000B70
  GL_DEPTH_TEST* = 0x00000B71
  GL_DEPTH_WRITEMASK* = 0x00000B72
  GL_DEPTH_CLEAR_VALUE* = 0x00000B73
  constGL_DEPTH_FUNC* = 0x00000B74
  GL_ACCUM_CLEAR_VALUE* = 0x00000B80
  GL_STENCIL_TEST* = 0x00000B90
  GL_STENCIL_CLEAR_VALUE* = 0x00000B91
  constGL_STENCIL_FUNC* = 0x00000B92
  GL_STENCIL_VALUE_MASK* = 0x00000B93
  GL_STENCIL_FAIL* = 0x00000B94
  GL_STENCIL_PASS_DEPTH_FAIL* = 0x00000B95
  GL_STENCIL_PASS_DEPTH_PASS* = 0x00000B96
  GL_STENCIL_REF* = 0x00000B97
  GL_STENCIL_WRITEMASK* = 0x00000B98
  constGL_MATRIX_MODE* = 0x00000BA0
  GL_NORMALIZE* = 0x00000BA1
  constGL_VIEWPORT* = 0x00000BA2
  GL_MODELVIEW_STACK_DEPTH* = 0x00000BA3
  GL_PROJECTION_STACK_DEPTH* = 0x00000BA4
  GL_TEXTURE_STACK_DEPTH* = 0x00000BA5
  GL_MODELVIEW_MATRIX* = 0x00000BA6
  GL_PROJECTION_MATRIX* = 0x00000BA7
  GL_TEXTURE_MATRIX* = 0x00000BA8
  GL_ATTRIB_STACK_DEPTH* = 0x00000BB0
  GL_CLIENT_ATTRIB_STACK_DEPTH* = 0x00000BB1
  GL_ALPHA_TEST* = 0x00000BC0
  GL_ALPHA_TEST_FUNC* = 0x00000BC1
  GL_ALPHA_TEST_REF* = 0x00000BC2
  GL_DITHER* = 0x00000BD0
  GL_BLEND_DST* = 0x00000BE0
  GL_BLEND_SRC* = 0x00000BE1
  GL_BLEND* = 0x00000BE2
  GL_LOGIC_OP_MODE* = 0x00000BF0
  GL_INDEX_LOGIC_OP* = 0x00000BF1
  GL_COLOR_LOGIC_OP* = 0x00000BF2
  GL_AUX_BUFFERS* = 0x00000C00
  constGL_DRAW_BUFFER* = 0x00000C01
  constGL_READ_BUFFER* = 0x00000C02
  GL_SCISSOR_BOX* = 0x00000C10
  GL_SCISSOR_TEST* = 0x00000C11
  GL_INDEX_CLEAR_VALUE* = 0x00000C20
  GL_INDEX_WRITEMASK* = 0x00000C21
  GL_COLOR_CLEAR_VALUE* = 0x00000C22
  GL_COLOR_WRITEMASK* = 0x00000C23
  GL_INDEX_MODE* = 0x00000C30
  GL_RGBA_MODE* = 0x00000C31
  GL_DOUBLEBUFFER* = 0x00000C32
  GL_STEREO* = 0x00000C33
  constGL_RENDER_MODE* = 0x00000C40
  GL_PERSPECTIVE_CORRECTION_HINT* = 0x00000C50
  GL_POINT_SMOOTH_HINT* = 0x00000C51
  GL_LINE_SMOOTH_HINT* = 0x00000C52
  GL_POLYGON_SMOOTH_HINT* = 0x00000C53
  GL_FOG_HINT* = 0x00000C54
  GL_TEXTURE_GEN_S* = 0x00000C60
  GL_TEXTURE_GEN_T* = 0x00000C61
  GL_TEXTURE_GEN_R* = 0x00000C62
  GL_TEXTURE_GEN_Q* = 0x00000C63
  GL_PIXEL_MAP_I_TO_I* = 0x00000C70
  GL_PIXEL_MAP_S_TO_S* = 0x00000C71
  GL_PIXEL_MAP_I_TO_R* = 0x00000C72
  GL_PIXEL_MAP_I_TO_G* = 0x00000C73
  GL_PIXEL_MAP_I_TO_B* = 0x00000C74
  GL_PIXEL_MAP_I_TO_A* = 0x00000C75
  GL_PIXEL_MAP_R_TO_R* = 0x00000C76
  GL_PIXEL_MAP_G_TO_G* = 0x00000C77
  GL_PIXEL_MAP_B_TO_B* = 0x00000C78
  GL_PIXEL_MAP_A_TO_A* = 0x00000C79
  GL_PIXEL_MAP_I_TO_I_SIZE* = 0x00000CB0
  GL_PIXEL_MAP_S_TO_S_SIZE* = 0x00000CB1
  GL_PIXEL_MAP_I_TO_R_SIZE* = 0x00000CB2
  GL_PIXEL_MAP_I_TO_G_SIZE* = 0x00000CB3
  GL_PIXEL_MAP_I_TO_B_SIZE* = 0x00000CB4
  GL_PIXEL_MAP_I_TO_A_SIZE* = 0x00000CB5
  GL_PIXEL_MAP_R_TO_R_SIZE* = 0x00000CB6
  GL_PIXEL_MAP_G_TO_G_SIZE* = 0x00000CB7
  GL_PIXEL_MAP_B_TO_B_SIZE* = 0x00000CB8
  GL_PIXEL_MAP_A_TO_A_SIZE* = 0x00000CB9
  GL_UNPACK_SWAP_BYTES* = 0x00000CF0
  GL_UNPACK_LSB_FIRST* = 0x00000CF1
  GL_UNPACK_ROW_LENGTH* = 0x00000CF2
  GL_UNPACK_SKIP_ROWS* = 0x00000CF3
  GL_UNPACK_SKIP_PIXELS* = 0x00000CF4
  GL_UNPACK_ALIGNMENT* = 0x00000CF5
  GL_PACK_SWAP_BYTES* = 0x00000D00
  GL_PACK_LSB_FIRST* = 0x00000D01
  GL_PACK_ROW_LENGTH* = 0x00000D02
  GL_PACK_SKIP_ROWS* = 0x00000D03
  GL_PACK_SKIP_PIXELS* = 0x00000D04
  GL_PACK_ALIGNMENT* = 0x00000D05
  GL_MAP_COLOR* = 0x00000D10
  GL_MAP_STENCIL* = 0x00000D11
  GL_INDEX_SHIFT* = 0x00000D12
  GL_INDEX_OFFSET* = 0x00000D13
  GL_RED_SCALE* = 0x00000D14
  GL_RED_BIAS* = 0x00000D15
  GL_ZOOM_X* = 0x00000D16
  GL_ZOOM_Y* = 0x00000D17
  GL_GREEN_SCALE* = 0x00000D18
  GL_GREEN_BIAS* = 0x00000D19
  GL_BLUE_SCALE* = 0x00000D1A
  GL_BLUE_BIAS* = 0x00000D1B
  GL_ALPHA_SCALE* = 0x00000D1C
  GL_ALPHA_BIAS* = 0x00000D1D
  GL_DEPTH_SCALE* = 0x00000D1E
  GL_DEPTH_BIAS* = 0x00000D1F
  GL_MAX_EVAL_ORDER* = 0x00000D30
  GL_MAX_LIGHTS* = 0x00000D31
  GL_MAX_CLIP_PLANES* = 0x00000D32
  GL_MAX_TEXTURE_SIZE* = 0x00000D33
  GL_MAX_PIXEL_MAP_TABLE* = 0x00000D34
  GL_MAX_ATTRIB_STACK_DEPTH* = 0x00000D35
  GL_MAX_MODELVIEW_STACK_DEPTH* = 0x00000D36
  GL_MAX_NAME_STACK_DEPTH* = 0x00000D37
  GL_MAX_PROJECTION_STACK_DEPTH* = 0x00000D38
  GL_MAX_TEXTURE_STACK_DEPTH* = 0x00000D39
  GL_MAX_VIEWPORT_DIMS* = 0x00000D3A
  GL_MAX_CLIENT_ATTRIB_STACK_DEPTH* = 0x00000D3B
  GL_SUBPIXEL_BITS* = 0x00000D50
  GL_INDEX_BITS* = 0x00000D51
  GL_RED_BITS* = 0x00000D52
  GL_GREEN_BITS* = 0x00000D53
  GL_BLUE_BITS* = 0x00000D54
  GL_ALPHA_BITS* = 0x00000D55
  GL_DEPTH_BITS* = 0x00000D56
  GL_STENCIL_BITS* = 0x00000D57
  GL_ACCUM_RED_BITS* = 0x00000D58
  GL_ACCUM_GREEN_BITS* = 0x00000D59
  GL_ACCUM_BLUE_BITS* = 0x00000D5A
  GL_ACCUM_ALPHA_BITS* = 0x00000D5B
  GL_NAME_STACK_DEPTH* = 0x00000D70
  GL_AUTO_NORMAL* = 0x00000D80
  GL_MAP1_COLOR_4* = 0x00000D90
  GL_MAP1_INDEX* = 0x00000D91
  GL_MAP1_NORMAL* = 0x00000D92
  GL_MAP1_TEXTURE_COORD_1* = 0x00000D93
  GL_MAP1_TEXTURE_COORD_2* = 0x00000D94
  GL_MAP1_TEXTURE_COORD_3* = 0x00000D95
  GL_MAP1_TEXTURE_COORD_4* = 0x00000D96
  GL_MAP1_VERTEX_3* = 0x00000D97
  GL_MAP1_VERTEX_4* = 0x00000D98
  GL_MAP2_COLOR_4* = 0x00000DB0
  GL_MAP2_INDEX* = 0x00000DB1
  GL_MAP2_NORMAL* = 0x00000DB2
  GL_MAP2_TEXTURE_COORD_1* = 0x00000DB3
  GL_MAP2_TEXTURE_COORD_2* = 0x00000DB4
  GL_MAP2_TEXTURE_COORD_3* = 0x00000DB5
  GL_MAP2_TEXTURE_COORD_4* = 0x00000DB6
  GL_MAP2_VERTEX_3* = 0x00000DB7
  GL_MAP2_VERTEX_4* = 0x00000DB8
  GL_MAP1_GRID_DOMAIN* = 0x00000DD0
  GL_MAP1_GRID_SEGMENTS* = 0x00000DD1
  GL_MAP2_GRID_DOMAIN* = 0x00000DD2
  GL_MAP2_GRID_SEGMENTS* = 0x00000DD3
  GL_TEXTURE_1D* = 0x00000DE0
  GL_TEXTURE_2D* = 0x00000DE1
  GL_FEEDBACK_BUFFER_POINTER* = 0x00000DF0
  GL_FEEDBACK_BUFFER_SIZE* = 0x00000DF1
  GL_FEEDBACK_BUFFER_TYPE* = 0x00000DF2
  GL_SELECTION_BUFFER_POINTER* = 0x00000DF3
  GL_SELECTION_BUFFER_SIZE* = 0x00000DF4 #      GL_TEXTURE_BINDING_1D
                                         #      GL_TEXTURE_BINDING_2D
                                         #      GL_VERTEX_ARRAY
                                         #      GL_NORMAL_ARRAY
                                         #      GL_COLOR_ARRAY
                                         #      GL_INDEX_ARRAY
                                         #      GL_TEXTURE_COORD_ARRAY
                                         #      GL_EDGE_FLAG_ARRAY
                                         #      GL_VERTEX_ARRAY_SIZE
                                         #      GL_VERTEX_ARRAY_TYPE
                                         #      GL_VERTEX_ARRAY_STRIDE
                                         #      GL_NORMAL_ARRAY_TYPE
                                         #      GL_NORMAL_ARRAY_STRIDE
                                         #      GL_COLOR_ARRAY_SIZE
                                         #      GL_COLOR_ARRAY_TYPE
                                         #      GL_COLOR_ARRAY_STRIDE
                                         #      GL_INDEX_ARRAY_TYPE
                                         #      GL_INDEX_ARRAY_STRIDE
                                         #      GL_TEXTURE_COORD_ARRAY_SIZE
                                         #      GL_TEXTURE_COORD_ARRAY_TYPE
                                         #      GL_TEXTURE_COORD_ARRAY_STRIDE
                                         #      GL_EDGE_FLAG_ARRAY_STRIDE
                                         #      GL_POLYGON_OFFSET_FACTOR
                                         #      GL_POLYGON_OFFSET_UNITS
                                         # GetTextureParameter
                                         #      GL_TEXTURE_MAG_FILTER
                                         #      GL_TEXTURE_MIN_FILTER
                                         #      GL_TEXTURE_WRAP_S
                                         #      GL_TEXTURE_WRAP_T
  GL_TEXTURE_WIDTH* = 0x00001000
  GL_TEXTURE_HEIGHT* = 0x00001001
  GL_TEXTURE_INTERNAL_FORMAT* = 0x00001003
  GL_TEXTURE_BORDER_COLOR* = 0x00001004
  GL_TEXTURE_BORDER* = 0x00001005 #      GL_TEXTURE_RED_SIZE
                                  #      GL_TEXTURE_GREEN_SIZE
                                  #      GL_TEXTURE_BLUE_SIZE
                                  #      GL_TEXTURE_ALPHA_SIZE
                                  #      GL_TEXTURE_LUMINANCE_SIZE
                                  #      GL_TEXTURE_INTENSITY_SIZE
                                  #      GL_TEXTURE_PRIORITY
                                  #      GL_TEXTURE_RESIDENT
                                  # HintMode
  GL_DONT_CARE* = 0x00001100
  GL_FASTEST* = 0x00001101
  GL_NICEST* = 0x00001102     # HintTarget
                              #      GL_PERSPECTIVE_CORRECTION_HINT
                              #      GL_POINT_SMOOTH_HINT
                              #      GL_LINE_SMOOTH_HINT
                              #      GL_POLYGON_SMOOTH_HINT
                              #      GL_FOG_HINT
                              # IndexPointerType
                              #      GL_SHORT
                              #      GL_INT
                              #      GL_FLOAT
                              #      GL_DOUBLE
                              # LightModelParameter
                              #      GL_LIGHT_MODEL_AMBIENT
                              #      GL_LIGHT_MODEL_LOCAL_VIEWER
                              #      GL_LIGHT_MODEL_TWO_SIDE
                              # LightName
  GL_LIGHT0* = 0x00004000
  GL_LIGHT1* = 0x00004001
  GL_LIGHT2* = 0x00004002
  GL_LIGHT3* = 0x00004003
  GL_LIGHT4* = 0x00004004
  GL_LIGHT5* = 0x00004005
  GL_LIGHT6* = 0x00004006
  GL_LIGHT7* = 0x00004007     # LightParameter
  GL_AMBIENT* = 0x00001200
  GL_DIFFUSE* = 0x00001201
  GL_SPECULAR* = 0x00001202
  GL_POSITION* = 0x00001203
  GL_SPOT_DIRECTION* = 0x00001204
  GL_SPOT_EXPONENT* = 0x00001205
  GL_SPOT_CUTOFF* = 0x00001206
  GL_CONSTANT_ATTENUATION* = 0x00001207
  GL_LINEAR_ATTENUATION* = 0x00001208
  GL_QUADRATIC_ATTENUATION* = 0x00001209 # InterleavedArrays
                                         #      GL_V2F
                                         #      GL_V3F
                                         #      GL_C4UB_V2F
                                         #      GL_C4UB_V3F
                                         #      GL_C3F_V3F
                                         #      GL_N3F_V3F
                                         #      GL_C4F_N3F_V3F
                                         #      GL_T2F_V3F
                                         #      GL_T4F_V4F
                                         #      GL_T2F_C4UB_V3F
                                         #      GL_T2F_C3F_V3F
                                         #      GL_T2F_N3F_V3F
                                         #      GL_T2F_C4F_N3F_V3F
                                         #      GL_T4F_C4F_N3F_V4F
                                         # ListMode
  GL_COMPILE* = 0x00001300
  GL_COMPILE_AND_EXECUTE* = 0x00001301 # ListNameType
                                       #      GL_BYTE
                                       #      GL_UNSIGNED_BYTE
                                       #      GL_SHORT
                                       #      GL_UNSIGNED_SHORT
                                       #      GL_INT
                                       #      GL_UNSIGNED_INT
                                       #      GL_FLOAT
                                       #      GL_2_BYTES
                                       #      GL_3_BYTES
                                       #      GL_4_BYTES
                                       # LogicOp
  constGL_CLEAR* = 0x00001500
  GL_AND* = 0x00001501
  GL_AND_REVERSE* = 0x00001502
  GL_COPY* = 0x00001503
  GL_AND_INVERTED* = 0x00001504
  GL_NOOP* = 0x00001505
  GL_XOR* = 0x00001506
  GL_OR* = 0x00001507
  GL_NOR* = 0x00001508
  GL_EQUIV* = 0x00001509
  GL_INVERT* = 0x0000150A
  GL_OR_REVERSE* = 0x0000150B
  GL_COPY_INVERTED* = 0x0000150C
  GL_OR_INVERTED* = 0x0000150D
  GL_NAND* = 0x0000150E
  GL_SET* = 0x0000150F        # MapTarget
                              #      GL_MAP1_COLOR_4
                              #      GL_MAP1_INDEX
                              #      GL_MAP1_NORMAL
                              #      GL_MAP1_TEXTURE_COORD_1
                              #      GL_MAP1_TEXTURE_COORD_2
                              #      GL_MAP1_TEXTURE_COORD_3
                              #      GL_MAP1_TEXTURE_COORD_4
                              #      GL_MAP1_VERTEX_3
                              #      GL_MAP1_VERTEX_4
                              #      GL_MAP2_COLOR_4
                              #      GL_MAP2_INDEX
                              #      GL_MAP2_NORMAL
                              #      GL_MAP2_TEXTURE_COORD_1
                              #      GL_MAP2_TEXTURE_COORD_2
                              #      GL_MAP2_TEXTURE_COORD_3
                              #      GL_MAP2_TEXTURE_COORD_4
                              #      GL_MAP2_VERTEX_3
                              #      GL_MAP2_VERTEX_4
                              # MaterialFace
                              #      GL_FRONT
                              #      GL_BACK
                              #      GL_FRONT_AND_BACK
                              # MaterialParameter
  GL_EMISSION* = 0x00001600
  GL_SHININESS* = 0x00001601
  GL_AMBIENT_AND_DIFFUSE* = 0x00001602
  GL_COLOR_INDEXES* = 0x00001603 #      GL_AMBIENT
                                 #      GL_DIFFUSE
                                 #      GL_SPECULAR
                                 # MatrixMode
  GL_MODELVIEW* = 0x00001700
  GL_PROJECTION* = 0x00001701
  GL_TEXTURE* = 0x00001702    # MeshMode1
                              #      GL_POINT
                              #      GL_LINE
                              # MeshMode2
                              #      GL_POINT
                              #      GL_LINE
                              #      GL_FILL
                              # NormalPointerType
                              #      GL_BYTE
                              #      GL_SHORT
                              #      GL_INT
                              #      GL_FLOAT
                              #      GL_DOUBLE
                              # PixelCopyType
  GL_COLOR* = 0x00001800
  GL_DEPTH* = 0x00001801
  GL_STENCIL* = 0x00001802    # PixelFormat
  GL_COLOR_INDEX* = 0x00001900
  GL_STENCIL_INDEX* = 0x00001901
  GL_DEPTH_COMPONENT* = 0x00001902
  GL_RED* = 0x00001903
  GL_GREEN* = 0x00001904
  GL_BLUE* = 0x00001905
  GL_ALPHA* = 0x00001906
  GL_RGB* = 0x00001907
  GL_RGBA* = 0x00001908
  GL_LUMINANCE* = 0x00001909
  GL_LUMINANCE_ALPHA* = 0x0000190A # PixelMap
                                   #      GL_PIXEL_MAP_I_TO_I
                                   #      GL_PIXEL_MAP_S_TO_S
                                   #      GL_PIXEL_MAP_I_TO_R
                                   #      GL_PIXEL_MAP_I_TO_G
                                   #      GL_PIXEL_MAP_I_TO_B
                                   #      GL_PIXEL_MAP_I_TO_A
                                   #      GL_PIXEL_MAP_R_TO_R
                                   #      GL_PIXEL_MAP_G_TO_G
                                   #      GL_PIXEL_MAP_B_TO_B
                                   #      GL_PIXEL_MAP_A_TO_A
                                   # PixelStore
                                   #      GL_UNPACK_SWAP_BYTES
                                   #      GL_UNPACK_LSB_FIRST
                                   #      GL_UNPACK_ROW_LENGTH
                                   #      GL_UNPACK_SKIP_ROWS
                                   #      GL_UNPACK_SKIP_PIXELS
                                   #      GL_UNPACK_ALIGNMENT
                                   #      GL_PACK_SWAP_BYTES
                                   #      GL_PACK_LSB_FIRST
                                   #      GL_PACK_ROW_LENGTH
                                   #      GL_PACK_SKIP_ROWS
                                   #      GL_PACK_SKIP_PIXELS
                                   #      GL_PACK_ALIGNMENT
                                   # PixelTransfer
                                   #      GL_MAP_COLOR
                                   #      GL_MAP_STENCIL
                                   #      GL_INDEX_SHIFT
                                   #      GL_INDEX_OFFSET
                                   #      GL_RED_SCALE
                                   #      GL_RED_BIAS
                                   #      GL_GREEN_SCALE
                                   #      GL_GREEN_BIAS
                                   #      GL_BLUE_SCALE
                                   #      GL_BLUE_BIAS
                                   #      GL_ALPHA_SCALE
                                   #      GL_ALPHA_BIAS
                                   #      GL_DEPTH_SCALE
                                   #      GL_DEPTH_BIAS
                                   # PixelType
  constGL_BITMAP* = 0x00001A00
  GL_POINT* = 0x00001B00
  GL_LINE* = 0x00001B01
  GL_FILL* = 0x00001B02       # ReadBufferMode
                              #      GL_FRONT_LEFT
                              #      GL_FRONT_RIGHT
                              #      GL_BACK_LEFT
                              #      GL_BACK_RIGHT
                              #      GL_FRONT
                              #      GL_BACK
                              #      GL_LEFT
                              #      GL_RIGHT
                              #      GL_AUX0
                              #      GL_AUX1
                              #      GL_AUX2
                              #      GL_AUX3
                              # RenderingMode
  GL_RENDER* = 0x00001C00
  GL_FEEDBACK* = 0x00001C01
  GL_SELECT* = 0x00001C02     # ShadingModel
  GL_FLAT* = 0x00001D00
  GL_SMOOTH* = 0x00001D01     # StencilFunction
                              #      GL_NEVER
                              #      GL_LESS
                              #      GL_EQUAL
                              #      GL_LEQUAL
                              #      GL_GREATER
                              #      GL_NOTEQUAL
                              #      GL_GEQUAL
                              #      GL_ALWAYS
                              # StencilOp
                              #      GL_ZERO
  GL_KEEP* = 0x00001E00
  GL_REPLACE* = 0x00001E01
  GL_INCR* = 0x00001E02
  GL_DECR* = 0x00001E03       #      GL_INVERT
                              # StringName
  GL_VENDOR* = 0x00001F00
  GL_RENDERER* = 0x00001F01
  GL_VERSION* = 0x00001F02
  GL_EXTENSIONS* = 0x00001F03 # TextureCoordName
  GL_S* = 0x00002000
  GL_T* = 0x00002001
  GL_R* = 0x00002002
  GL_Q* = 0x00002003          # TexCoordPointerType
                              #      GL_SHORT
                              #      GL_INT
                              #      GL_FLOAT
                              #      GL_DOUBLE
                              # TextureEnvMode
  GL_MODULATE* = 0x00002100
  GL_DECAL* = 0x00002101      #      GL_BLEND
                              #      GL_REPLACE
                              # TextureEnvParameter
  GL_TEXTURE_ENV_MODE* = 0x00002200
  GL_TEXTURE_ENV_COLOR* = 0x00002201 # TextureEnvTarget
  GL_TEXTURE_ENV* = 0x00002300 # TextureGenMode
  GL_EYE_LINEAR* = 0x00002400
  GL_OBJECT_LINEAR* = 0x00002401
  GL_SPHERE_MAP* = 0x00002402 # TextureGenParameter
  GL_TEXTURE_GEN_MODE* = 0x00002500
  GL_OBJECT_PLANE* = 0x00002501
  GL_EYE_PLANE* = 0x00002502  # TextureMagFilter
  GL_NEAREST* = 0x00002600
  GL_LINEAR* = 0x00002601     # TextureMinFilter
                              #      GL_NEAREST
                              #      GL_LINEAR
  GL_NEAREST_MIPMAP_NEAREST* = 0x00002700
  GL_LINEAR_MIPMAP_NEAREST* = 0x00002701
  GL_NEAREST_MIPMAP_LINEAR* = 0x00002702
  GL_LINEAR_MIPMAP_LINEAR* = 0x00002703 # TextureParameterName
  GL_TEXTURE_MAG_FILTER* = 0x00002800
  GL_TEXTURE_MIN_FILTER* = 0x00002801
  GL_TEXTURE_WRAP_S* = 0x00002802
  GL_TEXTURE_WRAP_T* = 0x00002803 #      GL_TEXTURE_BORDER_COLOR
                                  #      GL_TEXTURE_PRIORITY
                                  # TextureTarget
                                  #      GL_TEXTURE_1D
                                  #      GL_TEXTURE_2D
                                  #      GL_PROXY_TEXTURE_1D
                                  #      GL_PROXY_TEXTURE_2D
                                  # TextureWrapMode
  GL_CLAMP* = 0x00002900
  GL_REPEAT* = 0x00002901     # VertexPointerType
                              #      GL_SHORT
                              #      GL_INT
                              #      GL_FLOAT
                              #      GL_DOUBLE
                              # ClientAttribMask
  GL_CLIENT_PIXEL_STORE_BIT* = 0x00000001
  GL_CLIENT_VERTEX_ARRAY_BIT* = 0x00000002
  GL_CLIENT_ALL_ATTRIB_BITS* = 0xFFFFFFFF # polygon_offset
  GL_POLYGON_OFFSET_FACTOR* = 0x00008038
  GL_POLYGON_OFFSET_UNITS* = 0x00002A00
  GL_POLYGON_OFFSET_POINT* = 0x00002A01
  GL_POLYGON_OFFSET_LINE* = 0x00002A02
  GL_POLYGON_OFFSET_FILL* = 0x00008037 # texture
  GL_ALPHA4* = 0x0000803B
  GL_ALPHA8* = 0x0000803C
  GL_ALPHA12* = 0x0000803D
  GL_ALPHA16* = 0x0000803E
  GL_LUMINANCE4* = 0x0000803F
  GL_LUMINANCE8* = 0x00008040
  GL_LUMINANCE12* = 0x00008041
  GL_LUMINANCE16* = 0x00008042
  GL_LUMINANCE4_ALPHA4* = 0x00008043
  GL_LUMINANCE6_ALPHA2* = 0x00008044
  GL_LUMINANCE8_ALPHA8* = 0x00008045
  GL_LUMINANCE12_ALPHA4* = 0x00008046
  GL_LUMINANCE12_ALPHA12* = 0x00008047
  GL_LUMINANCE16_ALPHA16* = 0x00008048
  GL_INTENSITY* = 0x00008049
  GL_INTENSITY4* = 0x0000804A
  GL_INTENSITY8* = 0x0000804B
  GL_INTENSITY12* = 0x0000804C
  GL_INTENSITY16* = 0x0000804D
  GL_R3_G3_B2* = 0x00002A10
  GL_RGB4* = 0x0000804F
  GL_RGB5* = 0x00008050
  GL_RGB8* = 0x00008051
  GL_RGB10* = 0x00008052
  GL_RGB12* = 0x00008053
  GL_RGB16* = 0x00008054
  GL_RGBA2* = 0x00008055
  GL_RGBA4* = 0x00008056
  GL_RGB5_A1* = 0x00008057
  GL_RGBA8* = 0x00008058
  GL_RGB10_A2* = 0x00008059
  GL_RGBA12* = 0x0000805A
  GL_RGBA16* = 0x0000805B
  GL_TEXTURE_RED_SIZE* = 0x0000805C
  GL_TEXTURE_GREEN_SIZE* = 0x0000805D
  GL_TEXTURE_BLUE_SIZE* = 0x0000805E
  GL_TEXTURE_ALPHA_SIZE* = 0x0000805F
  GL_TEXTURE_LUMINANCE_SIZE* = 0x00008060
  GL_TEXTURE_INTENSITY_SIZE* = 0x00008061
  GL_PROXY_TEXTURE_1D* = 0x00008063
  GL_PROXY_TEXTURE_2D* = 0x00008064 # texture_object
  GL_TEXTURE_PRIORITY* = 0x00008066
  GL_TEXTURE_RESIDENT* = 0x00008067
  GL_TEXTURE_BINDING_1D* = 0x00008068
  GL_TEXTURE_BINDING_2D* = 0x00008069 # vertex_array
  GL_VERTEX_ARRAY* = 0x00008074
  GL_NORMAL_ARRAY* = 0x00008075
  GL_COLOR_ARRAY* = 0x00008076
  GL_INDEX_ARRAY* = 0x00008077
  GL_TEXTURE_COORD_ARRAY* = 0x00008078
  GL_EDGE_FLAG_ARRAY* = 0x00008079
  GL_VERTEX_ARRAY_SIZE* = 0x0000807A
  GL_VERTEX_ARRAY_TYPE* = 0x0000807B
  GL_VERTEX_ARRAY_STRIDE* = 0x0000807C
  GL_NORMAL_ARRAY_TYPE* = 0x0000807E
  GL_NORMAL_ARRAY_STRIDE* = 0x0000807F
  GL_COLOR_ARRAY_SIZE* = 0x00008081
  GL_COLOR_ARRAY_TYPE* = 0x00008082
  GL_COLOR_ARRAY_STRIDE* = 0x00008083
  GL_INDEX_ARRAY_TYPE* = 0x00008085
  GL_INDEX_ARRAY_STRIDE* = 0x00008086
  GL_TEXTURE_COORD_ARRAY_SIZE* = 0x00008088
  GL_TEXTURE_COORD_ARRAY_TYPE* = 0x00008089
  GL_TEXTURE_COORD_ARRAY_STRIDE* = 0x0000808A
  GL_EDGE_FLAG_ARRAY_STRIDE* = 0x0000808C
  GL_VERTEX_ARRAY_POINTER* = 0x0000808E
  GL_NORMAL_ARRAY_POINTER* = 0x0000808F
  GL_COLOR_ARRAY_POINTER* = 0x00008090
  GL_INDEX_ARRAY_POINTER* = 0x00008091
  GL_TEXTURE_COORD_ARRAY_POINTER* = 0x00008092
  GL_EDGE_FLAG_ARRAY_POINTER* = 0x00008093
  GL_V2F* = 0x00002A20
  GL_V3F* = 0x00002A21
  GL_C4UB_V2F* = 0x00002A22
  GL_C4UB_V3F* = 0x00002A23
  GL_C3F_V3F* = 0x00002A24
  GL_N3F_V3F* = 0x00002A25
  GL_C4F_N3F_V3F* = 0x00002A26
  GL_T2F_V3F* = 0x00002A27
  GL_T4F_V4F* = 0x00002A28
  GL_T2F_C4UB_V3F* = 0x00002A29
  GL_T2F_C3F_V3F* = 0x00002A2A
  GL_T2F_N3F_V3F* = 0x00002A2B
  GL_T2F_C4F_N3F_V3F* = 0x00002A2C
  GL_T4F_C4F_N3F_V4F* = 0x00002A2D # Extensions
  GL_EXT_vertex_array* = 1
  GL_WIN_swap_hint* = 1
  GL_EXT_bgra* = 1
  GL_EXT_paletted_texture* = 1 # EXT_vertex_array
  GL_VERTEX_ARRAY_EXT* = 0x00008074
  GL_NORMAL_ARRAY_EXT* = 0x00008075
  GL_COLOR_ARRAY_EXT* = 0x00008076
  GL_INDEX_ARRAY_EXT* = 0x00008077
  GL_TEXTURE_COORD_ARRAY_EXT* = 0x00008078
  GL_EDGE_FLAG_ARRAY_EXT* = 0x00008079
  GL_VERTEX_ARRAY_SIZE_EXT* = 0x0000807A
  GL_VERTEX_ARRAY_TYPE_EXT* = 0x0000807B
  GL_VERTEX_ARRAY_STRIDE_EXT* = 0x0000807C
  GL_VERTEX_ARRAY_COUNT_EXT* = 0x0000807D
  GL_NORMAL_ARRAY_TYPE_EXT* = 0x0000807E
  GL_NORMAL_ARRAY_STRIDE_EXT* = 0x0000807F
  GL_NORMAL_ARRAY_COUNT_EXT* = 0x00008080
  GL_COLOR_ARRAY_SIZE_EXT* = 0x00008081
  GL_COLOR_ARRAY_TYPE_EXT* = 0x00008082
  GL_COLOR_ARRAY_STRIDE_EXT* = 0x00008083
  GL_COLOR_ARRAY_COUNT_EXT* = 0x00008084
  GL_INDEX_ARRAY_TYPE_EXT* = 0x00008085
  GL_INDEX_ARRAY_STRIDE_EXT* = 0x00008086
  GL_INDEX_ARRAY_COUNT_EXT* = 0x00008087
  GL_TEXTURE_COORD_ARRAY_SIZE_EXT* = 0x00008088
  GL_TEXTURE_COORD_ARRAY_TYPE_EXT* = 0x00008089
  GL_TEXTURE_COORD_ARRAY_STRIDE_EXT* = 0x0000808A
  GL_TEXTURE_COORD_ARRAY_COUNT_EXT* = 0x0000808B
  GL_EDGE_FLAG_ARRAY_STRIDE_EXT* = 0x0000808C
  GL_EDGE_FLAG_ARRAY_COUNT_EXT* = 0x0000808D
  GL_VERTEX_ARRAY_POINTER_EXT* = 0x0000808E
  GL_NORMAL_ARRAY_POINTER_EXT* = 0x0000808F
  GL_COLOR_ARRAY_POINTER_EXT* = 0x00008090
  GL_INDEX_ARRAY_POINTER_EXT* = 0x00008091
  GL_TEXTURE_COORD_ARRAY_POINTER_EXT* = 0x00008092
  GL_EDGE_FLAG_ARRAY_POINTER_EXT* = 0x00008093
  GL_DOUBLE_EXT* = GL_DOUBLE  # EXT_bgra
  GL_BGR_EXT* = 0x000080E0
  GL_BGRA_EXT* = 0x000080E1   # EXT_paletted_texture
                              # These must match the GL_COLOR_TABLE_*_SGI enumerants
  GL_COLOR_TABLE_FORMAT_EXT* = 0x000080D8
  GL_COLOR_TABLE_WIDTH_EXT* = 0x000080D9
  GL_COLOR_TABLE_RED_SIZE_EXT* = 0x000080DA
  GL_COLOR_TABLE_GREEN_SIZE_EXT* = 0x000080DB
  GL_COLOR_TABLE_BLUE_SIZE_EXT* = 0x000080DC
  GL_COLOR_TABLE_ALPHA_SIZE_EXT* = 0x000080DD
  GL_COLOR_TABLE_LUMINANCE_SIZE_EXT* = 0x000080DE
  GL_COLOR_TABLE_INTENSITY_SIZE_EXT* = 0x000080DF
  GL_COLOR_INDEX1_EXT* = 0x000080E2
  GL_COLOR_INDEX2_EXT* = 0x000080E3
  GL_COLOR_INDEX4_EXT* = 0x000080E4
  GL_COLOR_INDEX8_EXT* = 0x000080E5
  GL_COLOR_INDEX12_EXT* = 0x000080E6
  GL_COLOR_INDEX16_EXT* = 0x000080E7 # For compatibility with OpenGL v1.0
  constGL_LOGIC_OP* = GL_INDEX_LOGIC_OP
  GL_TEXTURE_COMPONENTS* = GL_TEXTURE_INTERNAL_FORMAT

proc glAccum*(op: TGLenum, value: TGLfloat){.dynlib: dllname, importc: "glAccum".}
proc glAlphaFunc*(fun: TGLenum, theref: TGLclampf){.dynlib: dllname,
    importc: "glAlphaFunc".}
proc glAreTexturesResident*(n: TGLsizei, textures: PGLuint,
                            residences: PGLboolean): TGLboolean{.
    dynlib: dllname, importc: "glAreTexturesResident".}
proc glArrayElement*(i: TGLint){.dynlib: dllname, importc: "glArrayElement".}
proc glBegin*(mode: TGLenum){.dynlib: dllname, importc: "glBegin".}
proc glBindTexture*(target: TGLenum, texture: TGLuint){.dynlib: dllname,
    importc: "glBindTexture".}
proc glBitmap*(width, height: TGLsizei, xorig, yorig: TGLfloat,
               xmove, ymove: TGLfloat, bitmap: PGLubyte){.dynlib: dllname,
    importc: "glBitmap".}
proc glBlendFunc*(sfactor, dfactor: TGLenum){.dynlib: dllname,
    importc: "glBlendFunc".}
proc glCallList*(list: TGLuint){.dynlib: dllname, importc: "glCallList".}
proc glCallLists*(n: TGLsizei, atype: TGLenum, lists: pointer){.dynlib: dllname,
    importc: "glCallLists".}
proc glClear*(mask: TGLbitfield){.dynlib: dllname, importc: "glClear".}
proc glClearAccum*(red, green, blue, alpha: TGLfloat){.dynlib: dllname,
    importc: "glClearAccum".}
proc glClearColor*(red, green, blue, alpha: TGLclampf){.dynlib: dllname,
    importc: "glClearColor".}
proc glClearDepth*(depth: TGLclampd){.dynlib: dllname, importc: "glClearDepth".}
proc glClearIndex*(c: TGLfloat){.dynlib: dllname, importc: "glClearIndex".}
proc glClearStencil*(s: TGLint){.dynlib: dllname, importc: "glClearStencil".}
proc glClipPlane*(plane: TGLenum, equation: PGLdouble){.dynlib: dllname,
    importc: "glClipPlane".}
proc glColor3b*(red, green, blue: TGlbyte){.dynlib: dllname,
    importc: "glColor3b".}
proc glColor3bv*(v: PGLbyte){.dynlib: dllname, importc: "glColor3bv".}
proc glColor3d*(red, green, blue: TGLdouble){.dynlib: dllname,
    importc: "glColor3d".}
proc glColor3dv*(v: PGLdouble){.dynlib: dllname, importc: "glColor3dv".}
proc glColor3f*(red, green, blue: TGLfloat){.dynlib: dllname,
    importc: "glColor3f".}
proc glColor3fv*(v: PGLfloat){.dynlib: dllname, importc: "glColor3fv".}
proc glColor3i*(red, green, blue: TGLint){.dynlib: dllname, importc: "glColor3i".}
proc glColor3iv*(v: PGLint){.dynlib: dllname, importc: "glColor3iv".}
proc glColor3s*(red, green, blue: TGLshort){.dynlib: dllname,
    importc: "glColor3s".}
proc glColor3sv*(v: PGLshort){.dynlib: dllname, importc: "glColor3sv".}
proc glColor3ub*(red, green, blue: TGLubyte){.dynlib: dllname,
    importc: "glColor3ub".}
proc glColor3ubv*(v: PGLubyte){.dynlib: dllname, importc: "glColor3ubv".}
proc glColor3ui*(red, green, blue: TGLuint){.dynlib: dllname,
    importc: "glColor3ui".}
proc glColor3uiv*(v: PGLuint){.dynlib: dllname, importc: "glColor3uiv".}
proc glColor3us*(red, green, blue: TGLushort){.dynlib: dllname,
    importc: "glColor3us".}
proc glColor3usv*(v: PGLushort){.dynlib: dllname, importc: "glColor3usv".}
proc glColor4b*(red, green, blue, alpha: TGlbyte){.dynlib: dllname,
    importc: "glColor4b".}
proc glColor4bv*(v: PGLbyte){.dynlib: dllname, importc: "glColor4bv".}
proc glColor4d*(red, green, blue, alpha: TGLdouble){.dynlib: dllname,
    importc: "glColor4d".}
proc glColor4dv*(v: PGLdouble){.dynlib: dllname, importc: "glColor4dv".}
proc glColor4f*(red, green, blue, alpha: TGLfloat){.dynlib: dllname,
    importc: "glColor4f".}
proc glColor4fv*(v: PGLfloat){.dynlib: dllname, importc: "glColor4fv".}
proc glColor4i*(red, green, blue, alpha: TGLint){.dynlib: dllname,
    importc: "glColor4i".}
proc glColor4iv*(v: PGLint){.dynlib: dllname, importc: "glColor4iv".}
proc glColor4s*(red, green, blue, alpha: TGLshort){.dynlib: dllname,
    importc: "glColor4s".}
proc glColor4sv*(v: PGLshort){.dynlib: dllname, importc: "glColor4sv".}
proc glColor4ub*(red, green, blue, alpha: TGLubyte){.dynlib: dllname,
    importc: "glColor4ub".}
proc glColor4ubv*(v: PGLubyte){.dynlib: dllname, importc: "glColor4ubv".}
proc glColor4ui*(red, green, blue, alpha: TGLuint){.dynlib: dllname,
    importc: "glColor4ui".}
proc glColor4uiv*(v: PGLuint){.dynlib: dllname, importc: "glColor4uiv".}
proc glColor4us*(red, green, blue, alpha: TGLushort){.dynlib: dllname,
    importc: "glColor4us".}
proc glColor4usv*(v: PGLushort){.dynlib: dllname, importc: "glColor4usv".}
proc glColorMask*(red, green, blue, alpha: TGLboolean){.dynlib: dllname,
    importc: "glColorMask".}
proc glColorMaterial*(face, mode: TGLenum){.dynlib: dllname,
    importc: "glColorMaterial".}
proc glColorPointer*(size: TGLint, atype: TGLenum, stride: TGLsizei,
                     p: pointer){.dynlib: dllname,
                                        importc: "glColorPointer".}
proc glCopyPixels*(x, y: TGLint, width, height: TGLsizei, atype: TGLenum){.
    dynlib: dllname, importc: "glCopyPixels".}
proc glCopyTexImage1D*(target: TGLenum, level: TGLint, internalFormat: TGLenum,
                       x, y: TGLint, width: TGLsizei, border: TGLint){.
    dynlib: dllname, importc: "glCopyTexImage1D".}
proc glCopyTexImage2D*(target: TGLenum, level: TGLint, internalFormat: TGLenum,
                       x, y: TGLint, width, height: TGLsizei, border: TGLint){.
    dynlib: dllname, importc: "glCopyTexImage2D".}
proc glCopyTexSubImage1D*(target: TGLenum, level, xoffset, x, y: TGLint,
                          width: TGLsizei){.dynlib: dllname,
    importc: "glCopyTexSubImage1D".}
proc glCopyTexSubImage2D*(target: TGLenum,
                          level, xoffset, yoffset, x, y: TGLint,
                          width, height: TGLsizei){.dynlib: dllname,
    importc: "glCopyTexSubImage2D".}
proc glCullFace*(mode: TGLenum){.dynlib: dllname, importc: "glCullFace".}
proc glDeleteLists*(list: TGLuint, range: TGLsizei){.dynlib: dllname,
    importc: "glDeleteLists".}
proc glDeleteTextures*(n: TGLsizei, textures: PGLuint){.dynlib: dllname,
    importc: "glDeleteTextures".}
proc glDepthFunc*(fun: TGLenum){.dynlib: dllname, importc: "glDepthFunc".}
proc glDepthMask*(flag: TGLboolean){.dynlib: dllname, importc: "glDepthMask".}
proc glDepthRange*(zNear, zFar: TGLclampd){.dynlib: dllname,
    importc: "glDepthRange".}
proc glDisable*(cap: TGLenum){.dynlib: dllname, importc: "glDisable".}
proc glDisableClientState*(aarray: TGLenum){.dynlib: dllname,
    importc: "glDisableClientState".}
proc glDrawArrays*(mode: TGLenum, first: TGLint, count: TGLsizei){.
    dynlib: dllname, importc: "glDrawArrays".}
proc glDrawBuffer*(mode: TGLenum){.dynlib: dllname, importc: "glDrawBuffer".}
proc glDrawElements*(mode: TGLenum, count: TGLsizei, atype: TGLenum,
                     indices: pointer){.dynlib: dllname,
                                        importc: "glDrawElements".}
proc glDrawPixels*(width, height: TGLsizei, format, atype: TGLenum,
                   pixels: pointer){.dynlib: dllname, importc: "glDrawPixels".}
proc glEdgeFlag*(flag: TGLboolean){.dynlib: dllname, importc: "glEdgeFlag".}
proc glEdgeFlagPointer*(stride: TGLsizei, p: pointer){.dynlib: dllname,
    importc: "glEdgeFlagPointer".}
proc glEdgeFlagv*(flag: PGLboolean){.dynlib: dllname, importc: "glEdgeFlagv".}
proc glEnable*(cap: TGLenum){.dynlib: dllname, importc: "glEnable".}
proc glEnableClientState*(aarray: TGLenum){.dynlib: dllname,
    importc: "glEnableClientState".}
proc glEnd*(){.dynlib: dllname, importc: "glEnd".}
proc glEndList*(){.dynlib: dllname, importc: "glEndList".}
proc glEvalCoord1d*(u: TGLdouble){.dynlib: dllname, importc: "glEvalCoord1d".}
proc glEvalCoord1dv*(u: PGLdouble){.dynlib: dllname, importc: "glEvalCoord1dv".}
proc glEvalCoord1f*(u: TGLfloat){.dynlib: dllname, importc: "glEvalCoord1f".}
proc glEvalCoord1fv*(u: PGLfloat){.dynlib: dllname, importc: "glEvalCoord1fv".}
proc glEvalCoord2d*(u, v: TGLdouble){.dynlib: dllname, importc: "glEvalCoord2d".}
proc glEvalCoord2dv*(u: PGLdouble){.dynlib: dllname, importc: "glEvalCoord2dv".}
proc glEvalCoord2f*(u, v: TGLfloat){.dynlib: dllname, importc: "glEvalCoord2f".}
proc glEvalCoord2fv*(u: PGLfloat){.dynlib: dllname, importc: "glEvalCoord2fv".}
proc glEvalMesh1*(mode: TGLenum, i1, i2: TGLint){.dynlib: dllname,
    importc: "glEvalMesh1".}
proc glEvalMesh2*(mode: TGLenum, i1, i2, j1, j2: TGLint){.dynlib: dllname,
    importc: "glEvalMesh2".}
proc glEvalPoint1*(i: TGLint){.dynlib: dllname, importc: "glEvalPoint1".}
proc glEvalPoint2*(i, j: TGLint){.dynlib: dllname, importc: "glEvalPoint2".}
proc glFeedbackBuffer*(size: TGLsizei, atype: TGLenum, buffer: PGLfloat){.
    dynlib: dllname, importc: "glFeedbackBuffer".}
proc glFinish*(){.dynlib: dllname, importc: "glFinish".}
proc glFlush*(){.dynlib: dllname, importc: "glFlush".}
proc glFogf*(pname: TGLenum, param: TGLfloat){.dynlib: dllname,
    importc: "glFogf".}
proc glFogfv*(pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glFogfv".}
proc glFogi*(pname: TGLenum, param: TGLint){.dynlib: dllname, importc: "glFogi".}
proc glFogiv*(pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glFogiv".}
proc glFrontFace*(mode: TGLenum){.dynlib: dllname, importc: "glFrontFace".}
proc glFrustum*(left, right, bottom, top, zNear, zFar: TGLdouble){.
    dynlib: dllname, importc: "glFrustum".}
proc glGenLists*(range: TGLsizei): TGLuint{.dynlib: dllname,
    importc: "glGenLists".}
proc glGenTextures*(n: TGLsizei, textures: PGLuint){.dynlib: dllname,
    importc: "glGenTextures".}
proc glGetBooleanv*(pname: TGLenum, params: PGLboolean){.dynlib: dllname,
    importc: "glGetBooleanv".}
proc glGetClipPlane*(plane: TGLenum, equation: PGLdouble){.dynlib: dllname,
    importc: "glGetClipPlane".}
proc glGetDoublev*(pname: TGLenum, params: PGLdouble){.dynlib: dllname,
    importc: "glGetDoublev".}
proc glGetError*(): TGLenum{.dynlib: dllname, importc: "glGetError".}
proc glGetFloatv*(pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glGetFloatv".}
proc glGetIntegerv*(pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glGetIntegerv".}
proc glGetLightfv*(light, pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glGetLightfv".}
proc glGetLightiv*(light, pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glGetLightiv".}
proc glGetMapdv*(target, query: TGLenum, v: PGLdouble){.dynlib: dllname,
    importc: "glGetMapdv".}
proc glGetMapfv*(target, query: TGLenum, v: PGLfloat){.dynlib: dllname,
    importc: "glGetMapfv".}
proc glGetMapiv*(target, query: TGLenum, v: PGLint){.dynlib: dllname,
    importc: "glGetMapiv".}
proc glGetMaterialfv*(face, pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glGetMaterialfv".}
proc glGetMaterialiv*(face, pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glGetMaterialiv".}
proc glGetPixelMapfv*(map: TGLenum, values: PGLfloat){.dynlib: dllname,
    importc: "glGetPixelMapfv".}
proc glGetPixelMapuiv*(map: TGLenum, values: PGLuint){.dynlib: dllname,
    importc: "glGetPixelMapuiv".}
proc glGetPixelMapusv*(map: TGLenum, values: PGLushort){.dynlib: dllname,
    importc: "glGetPixelMapusv".}
proc glGetPointerv*(pname: TGLenum, params: pointer){.dynlib: dllname,
    importc: "glGetPointerv".}
proc glGetPolygonStipple*(mask: PGLubyte){.dynlib: dllname,
    importc: "glGetPolygonStipple".}
proc glGetString*(name: TGLenum): cstring{.dynlib: dllname,
    importc: "glGetString".}
proc glGetTexEnvfv*(target, pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glGetTexEnvfv".}
proc glGetTexEnviv*(target, pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glGetTexEnviv".}
proc glGetTexGendv*(coord, pname: TGLenum, params: PGLdouble){.dynlib: dllname,
    importc: "glGetTexGendv".}
proc glGetTexGenfv*(coord, pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glGetTexGenfv".}
proc glGetTexGeniv*(coord, pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glGetTexGeniv".}
proc glGetTexImage*(target: TGLenum, level: TGLint, format: TGLenum,
                    atype: TGLenum, pixels: pointer){.dynlib: dllname,
    importc: "glGetTexImage".}
proc glGetTexLevelParameterfv*(target: TGLenum, level: TGLint, pname: TGLenum,
                               params: pointer){.dynlib: dllname,
    importc: "glGetTexLevelParameterfv".}
proc glGetTexLevelParameteriv*(target: TGLenum, level: TGLint, pname: TGLenum,
                               params: PGLint){.dynlib: dllname,
    importc: "glGetTexLevelParameteriv".}
proc glGetTexParameterfv*(target, pname: TGLenum, params: PGLfloat){.
    dynlib: dllname, importc: "glGetTexParameterfv".}
proc glGetTexParameteriv*(target, pname: TGLenum, params: PGLint){.
    dynlib: dllname, importc: "glGetTexParameteriv".}
proc glHint*(target, mode: TGLenum){.dynlib: dllname, importc: "glHint".}
proc glIndexMask*(mask: TGLuint){.dynlib: dllname, importc: "glIndexMask".}
proc glIndexPointer*(atype: TGLenum, stride: TGLsizei, p: pointer){.
    dynlib: dllname, importc: "glIndexPointer".}
proc glIndexd*(c: TGLdouble){.dynlib: dllname, importc: "glIndexd".}
proc glIndexdv*(c: PGLdouble){.dynlib: dllname, importc: "glIndexdv".}
proc glIndexf*(c: TGLfloat){.dynlib: dllname, importc: "glIndexf".}
proc glIndexfv*(c: PGLfloat){.dynlib: dllname, importc: "glIndexfv".}
proc glIndexi*(c: TGLint){.dynlib: dllname, importc: "glIndexi".}
proc glIndexiv*(c: PGLint){.dynlib: dllname, importc: "glIndexiv".}
proc glIndexs*(c: TGLshort){.dynlib: dllname, importc: "glIndexs".}
proc glIndexsv*(c: PGLshort){.dynlib: dllname, importc: "glIndexsv".}
proc glIndexub*(c: TGLubyte){.dynlib: dllname, importc: "glIndexub".}
proc glIndexubv*(c: PGLubyte){.dynlib: dllname, importc: "glIndexubv".}
proc glInitNames*(){.dynlib: dllname, importc: "glInitNames".}
proc glInterleavedArrays*(format: TGLenum, stride: TGLsizei, p: pointer){.
    dynlib: dllname, importc: "glInterleavedArrays".}
proc glIsEnabled*(cap: TGLenum): TGLboolean{.dynlib: dllname,
    importc: "glIsEnabled".}
proc glIsList*(list: TGLuint): TGLboolean{.dynlib: dllname, importc: "glIsList".}
proc glIsTexture*(texture: TGLuint): TGLboolean{.dynlib: dllname,
    importc: "glIsTexture".}
proc glLightModelf*(pname: TGLenum, param: TGLfloat){.dynlib: dllname,
    importc: "glLightModelf".}
proc glLightModelfv*(pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glLightModelfv".}
proc glLightModeli*(pname: TGLenum, param: TGLint){.dynlib: dllname,
    importc: "glLightModeli".}
proc glLightModeliv*(pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glLightModeliv".}
proc glLightf*(light, pname: TGLenum, param: TGLfloat){.dynlib: dllname,
    importc: "glLightf".}
proc glLightfv*(light, pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glLightfv".}
proc glLighti*(light, pname: TGLenum, param: TGLint){.dynlib: dllname,
    importc: "glLighti".}
proc glLightiv*(light, pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glLightiv".}
proc glLineStipple*(factor: TGLint, pattern: TGLushort){.dynlib: dllname,
    importc: "glLineStipple".}
proc glLineWidth*(width: TGLfloat){.dynlib: dllname, importc: "glLineWidth".}
proc glListBase*(base: TGLuint){.dynlib: dllname, importc: "glListBase".}
proc glLoadIdentity*(){.dynlib: dllname, importc: "glLoadIdentity".}
proc glLoadMatrixd*(m: PGLdouble){.dynlib: dllname, importc: "glLoadMatrixd".}
proc glLoadMatrixf*(m: PGLfloat){.dynlib: dllname, importc: "glLoadMatrixf".}
proc glLoadName*(name: TGLuint){.dynlib: dllname, importc: "glLoadName".}
proc glLogicOp*(opcode: TGLenum){.dynlib: dllname, importc: "glLogicOp".}
proc glMap1d*(target: TGLenum, u1, u2: TGLdouble, stride, order: TGLint,
              points: PGLdouble){.dynlib: dllname, importc: "glMap1d".}
proc glMap1f*(target: TGLenum, u1, u2: TGLfloat, stride, order: TGLint,
              points: PGLfloat){.dynlib: dllname, importc: "glMap1f".}
proc glMap2d*(target: TGLenum, u1, u2: TGLdouble, ustride, uorder: TGLint,
              v1, v2: TGLdouble, vstride, vorder: TGLint, points: PGLdouble){.
    dynlib: dllname, importc: "glMap2d".}
proc glMap2f*(target: TGLenum, u1, u2: TGLfloat, ustride, uorder: TGLint,
              v1, v2: TGLfloat, vstride, vorder: TGLint, points: PGLfloat){.
    dynlib: dllname, importc: "glMap2f".}
proc glMapGrid1d*(un: TGLint, u1, u2: TGLdouble){.dynlib: dllname,
    importc: "glMapGrid1d".}
proc glMapGrid1f*(un: TGLint, u1, u2: TGLfloat){.dynlib: dllname,
    importc: "glMapGrid1f".}
proc glMapGrid2d*(un: TGLint, u1, u2: TGLdouble, vn: TGLint, v1, v2: TGLdouble){.
    dynlib: dllname, importc: "glMapGrid2d".}
proc glMapGrid2f*(un: TGLint, u1, u2: TGLfloat, vn: TGLint, v1, v2: TGLfloat){.
    dynlib: dllname, importc: "glMapGrid2f".}
proc glMaterialf*(face, pname: TGLenum, param: TGLfloat){.dynlib: dllname,
    importc: "glMaterialf".}
proc glMaterialfv*(face, pname: TGLenum, params: PGLfloat){.dynlib: dllname,
    importc: "glMaterialfv".}
proc glMateriali*(face, pname: TGLenum, param: TGLint){.dynlib: dllname,
    importc: "glMateriali".}
proc glMaterialiv*(face, pname: TGLenum, params: PGLint){.dynlib: dllname,
    importc: "glMaterialiv".}
proc glMatrixMode*(mode: TGLenum){.dynlib: dllname, importc: "glMatrixMode".}
proc glMultMatrixd*(m: PGLdouble){.dynlib: dllname, importc: "glMultMatrixd".}
proc glMultMatrixf*(m: PGLfloat){.dynlib: dllname, importc: "glMultMatrixf".}
proc glNewList*(list: TGLuint, mode: TGLenum){.dynlib: dllname,
    importc: "glNewList".}
proc glNormal3b*(nx, ny, nz: TGlbyte){.dynlib: dllname, importc: "glNormal3b".}
proc glNormal3bv*(v: PGLbyte){.dynlib: dllname, importc: "glNormal3bv".}
proc glNormal3d*(nx, ny, nz: TGLdouble){.dynlib: dllname, importc: "glNormal3d".}
proc glNormal3dv*(v: PGLdouble){.dynlib: dllname, importc: "glNormal3dv".}
proc glNormal3f*(nx, ny, nz: TGLfloat){.dynlib: dllname, importc: "glNormal3f".}
proc glNormal3fv*(v: PGLfloat){.dynlib: dllname, importc: "glNormal3fv".}
proc glNormal3i*(nx, ny, nz: TGLint){.dynlib: dllname, importc: "glNormal3i".}
proc glNormal3iv*(v: PGLint){.dynlib: dllname, importc: "glNormal3iv".}
proc glNormal3s*(nx, ny, nz: TGLshort){.dynlib: dllname, importc: "glNormal3s".}
proc glNormal3sv*(v: PGLshort){.dynlib: dllname, importc: "glNormal3sv".}
proc glNormalPointer*(atype: TGLenum, stride: TGLsizei, p: pointer){.
    dynlib: dllname, importc: "glNormalPointer".}
proc glOrtho*(left, right, bottom, top, zNear, zFar: TGLdouble){.
    dynlib: dllname, importc: "glOrtho".}
proc glPassThrough*(token: TGLfloat){.dynlib: dllname, importc: "glPassThrough".}
proc glPixelMapfv*(map: TGLenum, mapsize: TGLsizei, values: PGLfloat){.
    dynlib: dllname, importc: "glPixelMapfv".}
proc glPixelMapuiv*(map: TGLenum, mapsize: TGLsizei, values: PGLuint){.
    dynlib: dllname, importc: "glPixelMapuiv".}
proc glPixelMapusv*(map: TGLenum, mapsize: TGLsizei, values: PGLushort){.
    dynlib: dllname, importc: "glPixelMapusv".}
proc glPixelStoref*(pname: TGLenum, param: TGLfloat){.dynlib: dllname,
    importc: "glPixelStoref".}
proc glPixelStorei*(pname: TGLenum, param: TGLint){.dynlib: dllname,
    importc: "glPixelStorei".}
proc glPixelTransferf*(pname: TGLenum, param: TGLfloat){.dynlib: dllname,
    importc: "glPixelTransferf".}
proc glPixelTransferi*(pname: TGLenum, param: TGLint){.dynlib: dllname,
    importc: "glPixelTransferi".}
proc glPixelZoom*(xfactor, yfactor: TGLfloat){.dynlib: dllname,
    importc: "glPixelZoom".}
proc glPointSize*(size: TGLfloat){.dynlib: dllname, importc: "glPointSize".}
proc glPolygonMode*(face, mode: TGLenum){.dynlib: dllname,
    importc: "glPolygonMode".}
proc glPolygonOffset*(factor, units: TGLfloat){.dynlib: dllname,
    importc: "glPolygonOffset".}
proc glPolygonStipple*(mask: PGLubyte){.dynlib: dllname,
                                        importc: "glPolygonStipple".}
proc glPopAttrib*(){.dynlib: dllname, importc: "glPopAttrib".}
proc glPopClientAttrib*(){.dynlib: dllname, importc: "glPopClientAttrib".}
proc glPopMatrix*(){.dynlib: dllname, importc: "glPopMatrix".}
proc glPopName*(){.dynlib: dllname, importc: "glPopName".}
proc glPrioritizeTextures*(n: TGLsizei, textures: PGLuint, priorities: PGLclampf){.
    dynlib: dllname, importc: "glPrioritizeTextures".}
proc glPushAttrib*(mask: TGLbitfield){.dynlib: dllname, importc: "glPushAttrib".}
proc glPushClientAttrib*(mask: TGLbitfield){.dynlib: dllname,
    importc: "glPushClientAttrib".}
proc glPushMatrix*(){.dynlib: dllname, importc: "glPushMatrix".}
proc glPushName*(name: TGLuint){.dynlib: dllname, importc: "glPushName".}
proc glRasterPos2d*(x, y: TGLdouble){.dynlib: dllname, importc: "glRasterPos2d".}
proc glRasterPos2dv*(v: PGLdouble){.dynlib: dllname, importc: "glRasterPos2dv".}
proc glRasterPos2f*(x, y: TGLfloat){.dynlib: dllname, importc: "glRasterPos2f".}
proc glRasterPos2fv*(v: PGLfloat){.dynlib: dllname, importc: "glRasterPos2fv".}
proc glRasterPos2i*(x, y: TGLint){.dynlib: dllname, importc: "glRasterPos2i".}
proc glRasterPos2iv*(v: PGLint){.dynlib: dllname, importc: "glRasterPos2iv".}
proc glRasterPos2s*(x, y: TGLshort){.dynlib: dllname, importc: "glRasterPos2s".}
proc glRasterPos2sv*(v: PGLshort){.dynlib: dllname, importc: "glRasterPos2sv".}
proc glRasterPos3d*(x, y, z: TGLdouble){.dynlib: dllname,
    importc: "glRasterPos3d".}
proc glRasterPos3dv*(v: PGLdouble){.dynlib: dllname, importc: "glRasterPos3dv".}
proc glRasterPos3f*(x, y, z: TGLfloat){.dynlib: dllname,
                                        importc: "glRasterPos3f".}
proc glRasterPos3fv*(v: PGLfloat){.dynlib: dllname, importc: "glRasterPos3fv".}
proc glRasterPos3i*(x, y, z: TGLint){.dynlib: dllname, importc: "glRasterPos3i".}
proc glRasterPos3iv*(v: PGLint){.dynlib: dllname, importc: "glRasterPos3iv".}
proc glRasterPos3s*(x, y, z: TGLshort){.dynlib: dllname,
                                        importc: "glRasterPos3s".}
proc glRasterPos3sv*(v: PGLshort){.dynlib: dllname, importc: "glRasterPos3sv".}
proc glRasterPos4d*(x, y, z, w: TGLdouble){.dynlib: dllname,
    importc: "glRasterPos4d".}
proc glRasterPos4dv*(v: PGLdouble){.dynlib: dllname, importc: "glRasterPos4dv".}
proc glRasterPos4f*(x, y, z, w: TGLfloat){.dynlib: dllname,
    importc: "glRasterPos4f".}
proc glRasterPos4fv*(v: PGLfloat){.dynlib: dllname, importc: "glRasterPos4fv".}
proc glRasterPos4i*(x, y, z, w: TGLint){.dynlib: dllname,
    importc: "glRasterPos4i".}
proc glRasterPos4iv*(v: PGLint){.dynlib: dllname, importc: "glRasterPos4iv".}
proc glRasterPos4s*(x, y, z, w: TGLshort){.dynlib: dllname,
    importc: "glRasterPos4s".}
proc glRasterPos4sv*(v: PGLshort){.dynlib: dllname, importc: "glRasterPos4sv".}
proc glReadBuffer*(mode: TGLenum){.dynlib: dllname, importc: "glReadBuffer".}
proc glReadPixels*(x, y: TGLint, width, height: TGLsizei,
                   format, atype: TGLenum, pixels: pointer){.dynlib: dllname,
    importc: "glReadPixels".}
proc glRectd*(x1, y1, x2, y2: TGLdouble){.dynlib: dllname, importc: "glRectd".}
proc glRectdv*(v1: PGLdouble, v2: PGLdouble){.dynlib: dllname,
    importc: "glRectdv".}
proc glRectf*(x1, y1, x2, y2: TGLfloat){.dynlib: dllname, importc: "glRectf".}
proc glRectfv*(v1: PGLfloat, v2: PGLfloat){.dynlib: dllname, importc: "glRectfv".}
proc glRecti*(x1, y1, x2, y2: TGLint){.dynlib: dllname, importc: "glRecti".}
proc glRectiv*(v1: PGLint, v2: PGLint){.dynlib: dllname, importc: "glRectiv".}
proc glRects*(x1, y1, x2, y2: TGLshort){.dynlib: dllname, importc: "glRects".}
proc glRectsv*(v1: PGLshort, v2: PGLshort){.dynlib: dllname, importc: "glRectsv".}
proc glRenderMode*(mode: TGLint): TGLint{.dynlib: dllname,
    importc: "glRenderMode".}
proc glRotated*(angle, x, y, z: TGLdouble){.dynlib: dllname,
    importc: "glRotated".}
proc glRotatef*(angle, x, y, z: TGLfloat){.dynlib: dllname, importc: "glRotatef".}
proc glScaled*(x, y, z: TGLdouble){.dynlib: dllname, importc: "glScaled".}
proc glScalef*(x, y, z: TGLfloat){.dynlib: dllname, importc: "glScalef".}
proc glScissor*(x, y: TGLint, width, height: TGLsizei){.dynlib: dllname,
    importc: "glScissor".}
proc glSelectBuffer*(size: TGLsizei, buffer: PGLuint){.dynlib: dllname,
    importc: "glSelectBuffer".}
proc glShadeModel*(mode: TGLenum){.dynlib: dllname, importc: "glShadeModel".}
proc glStencilFunc*(fun: TGLenum, theref: TGLint, mask: TGLuint){.
    dynlib: dllname, importc: "glStencilFunc".}
proc glStencilMask*(mask: TGLuint){.dynlib: dllname, importc: "glStencilMask".}
proc glStencilOp*(fail, zfail, zpass: TGLenum){.dynlib: dllname,
    importc: "glStencilOp".}
proc glTexCoord1d*(s: TGLdouble){.dynlib: dllname, importc: "glTexCoord1d".}
proc glTexCoord1dv*(v: PGLdouble){.dynlib: dllname, importc: "glTexCoord1dv".}
proc glTexCoord1f*(s: TGLfloat){.dynlib: dllname, importc: "glTexCoord1f".}
proc glTexCoord1fv*(v: PGLfloat){.dynlib: dllname, importc: "glTexCoord1fv".}
proc glTexCoord1i*(s: TGLint){.dynlib: dllname, importc: "glTexCoord1i".}
proc glTexCoord1iv*(v: PGLint){.dynlib: dllname, importc: "glTexCoord1iv".}
proc glTexCoord1s*(s: TGLshort){.dynlib: dllname, importc: "glTexCoord1s".}
proc glTexCoord1sv*(v: PGLshort){.dynlib: dllname, importc: "glTexCoord1sv".}
proc glTexCoord2d*(s, t: TGLdouble){.dynlib: dllname, importc: "glTexCoord2d".}
proc glTexCoord2dv*(v: PGLdouble){.dynlib: dllname, importc: "glTexCoord2dv".}
proc glTexCoord2f*(s, t: TGLfloat){.dynlib: dllname, importc: "glTexCoord2f".}
proc glTexCoord2fv*(v: PGLfloat){.dynlib: dllname, importc: "glTexCoord2fv".}
proc glTexCoord2i*(s, t: TGLint){.dynlib: dllname, importc: "glTexCoord2i".}
proc glTexCoord2iv*(v: PGLint){.dynlib: dllname, importc: "glTexCoord2iv".}
proc glTexCoord2s*(s, t: TGLshort){.dynlib: dllname, importc: "glTexCoord2s".}
proc glTexCoord2sv*(v: PGLshort){.dynlib: dllname, importc: "glTexCoord2sv".}
proc glTexCoord3d*(s, t, r: TGLdouble){.dynlib: dllname, importc: "glTexCoord3d".}
proc glTexCoord3dv*(v: PGLdouble){.dynlib: dllname, importc: "glTexCoord3dv".}
proc glTexCoord3f*(s, t, r: TGLfloat){.dynlib: dllname, importc: "glTexCoord3f".}
proc glTexCoord3fv*(v: PGLfloat){.dynlib: dllname, importc: "glTexCoord3fv".}
proc glTexCoord3i*(s, t, r: TGLint){.dynlib: dllname, importc: "glTexCoord3i".}
proc glTexCoord3iv*(v: PGLint){.dynlib: dllname, importc: "glTexCoord3iv".}
proc glTexCoord3s*(s, t, r: TGLshort){.dynlib: dllname, importc: "glTexCoord3s".}
proc glTexCoord3sv*(v: PGLshort){.dynlib: dllname, importc: "glTexCoord3sv".}
proc glTexCoord4d*(s, t, r, q: TGLdouble){.dynlib: dllname,
    importc: "glTexCoord4d".}
proc glTexCoord4dv*(v: PGLdouble){.dynlib: dllname, importc: "glTexCoord4dv".}
proc glTexCoord4f*(s, t, r, q: TGLfloat){.dynlib: dllname,
    importc: "glTexCoord4f".}
proc glTexCoord4fv*(v: PGLfloat){.dynlib: dllname, importc: "glTexCoord4fv".}
proc glTexCoord4i*(s, t, r, q: TGLint){.dynlib: dllname, importc: "glTexCoord4i".}
proc glTexCoord4iv*(v: PGLint){.dynlib: dllname, importc: "glTexCoord4iv".}
proc glTexCoord4s*(s, t, r, q: TGLshort){.dynlib: dllname,
    importc: "glTexCoord4s".}
proc glTexCoord4sv*(v: PGLshort){.dynlib: dllname, importc: "glTexCoord4sv".}
proc glTexCoordPointer*(size: TGLint, atype: TGLenum, stride: TGLsizei,
                        p: pointer){.dynlib: dllname,
    importc: "glTexCoordPointer".}
proc glTexEnvf*(target: TGLenum, pname: TGLenum, param: TGLfloat){.
    dynlib: dllname, importc: "glTexEnvf".}
proc glTexEnvfv*(target: TGLenum, pname: TGLenum, params: PGLfloat){.
    dynlib: dllname, importc: "glTexEnvfv".}
proc glTexEnvi*(target: TGLenum, pname: TGLenum, param: TGLint){.
    dynlib: dllname, importc: "glTexEnvi".}
proc glTexEnviv*(target: TGLenum, pname: TGLenum, params: PGLint){.
    dynlib: dllname, importc: "glTexEnviv".}
proc glTexGend*(coord: TGLenum, pname: TGLenum, param: TGLdouble){.
    dynlib: dllname, importc: "glTexGend".}
proc glTexGendv*(coord: TGLenum, pname: TGLenum, params: PGLdouble){.
    dynlib: dllname, importc: "glTexGendv".}
proc glTexGenf*(coord: TGLenum, pname: TGLenum, param: TGLfloat){.
    dynlib: dllname, importc: "glTexGenf".}
proc glTexGenfv*(coord: TGLenum, pname: TGLenum, params: PGLfloat){.
    dynlib: dllname, importc: "glTexGenfv".}
proc glTexGeni*(coord: TGLenum, pname: TGLenum, param: TGLint){.dynlib: dllname,
    importc: "glTexGeni".}
proc glTexGeniv*(coord: TGLenum, pname: TGLenum, params: PGLint){.
    dynlib: dllname, importc: "glTexGeniv".}
proc glTexImage1D*(target: TGLenum, level, internalformat: TGLint,
                   width: TGLsizei, border: TGLint, format, atype: TGLenum,
                   pixels: pointer){.dynlib: dllname, importc: "glTexImage1D".}
proc glTexImage2D*(target: TGLenum, level, internalformat: TGLint,
                   width, height: TGLsizei, border: TGLint,
                   format, atype: TGLenum, pixels: pointer){.dynlib: dllname,
    importc: "glTexImage2D".}
proc glTexParameterf*(target: TGLenum, pname: TGLenum, param: TGLfloat){.
    dynlib: dllname, importc: "glTexParameterf".}
proc glTexParameterfv*(target: TGLenum, pname: TGLenum, params: PGLfloat){.
    dynlib: dllname, importc: "glTexParameterfv".}
proc glTexParameteri*(target: TGLenum, pname: TGLenum, param: TGLint){.
    dynlib: dllname, importc: "glTexParameteri".}
proc glTexParameteriv*(target: TGLenum, pname: TGLenum, params: PGLint){.
    dynlib: dllname, importc: "glTexParameteriv".}
proc glTexSubImage1D*(target: TGLenum, level, xoffset: TGLint, width: TGLsizei,
                      format, atype: TGLenum, pixels: pointer){.dynlib: dllname,
    importc: "glTexSubImage1D".}
proc glTexSubImage2D*(target: TGLenum, level, xoffset, yoffset: TGLint,
                      width, height: TGLsizei, format, atype: TGLenum,
                      pixels: pointer){.dynlib: dllname,
                                        importc: "glTexSubImage2D".}
proc glTranslated*(x, y, z: TGLdouble){.dynlib: dllname, importc: "glTranslated".}
proc glTranslatef*(x, y, z: TGLfloat){.dynlib: dllname, importc: "glTranslatef".}
proc glVertex2d*(x, y: TGLdouble){.dynlib: dllname, importc: "glVertex2d".}
proc glVertex2dv*(v: PGLdouble){.dynlib: dllname, importc: "glVertex2dv".}
proc glVertex2f*(x, y: TGLfloat){.dynlib: dllname, importc: "glVertex2f".}
proc glVertex2fv*(v: PGLfloat){.dynlib: dllname, importc: "glVertex2fv".}
proc glVertex2i*(x, y: TGLint){.dynlib: dllname, importc: "glVertex2i".}
proc glVertex2iv*(v: PGLint){.dynlib: dllname, importc: "glVertex2iv".}
proc glVertex2s*(x, y: TGLshort){.dynlib: dllname, importc: "glVertex2s".}
proc glVertex2sv*(v: PGLshort){.dynlib: dllname, importc: "glVertex2sv".}
proc glVertex3d*(x, y, z: TGLdouble){.dynlib: dllname, importc: "glVertex3d".}
proc glVertex3dv*(v: PGLdouble){.dynlib: dllname, importc: "glVertex3dv".}
proc glVertex3f*(x, y, z: TGLfloat){.dynlib: dllname, importc: "glVertex3f".}
proc glVertex3fv*(v: PGLfloat){.dynlib: dllname, importc: "glVertex3fv".}
proc glVertex3i*(x, y, z: TGLint){.dynlib: dllname, importc: "glVertex3i".}
proc glVertex3iv*(v: PGLint){.dynlib: dllname, importc: "glVertex3iv".}
proc glVertex3s*(x, y, z: TGLshort){.dynlib: dllname, importc: "glVertex3s".}
proc glVertex3sv*(v: PGLshort){.dynlib: dllname, importc: "glVertex3sv".}
proc glVertex4d*(x, y, z, w: TGLdouble){.dynlib: dllname, importc: "glVertex4d".}
proc glVertex4dv*(v: PGLdouble){.dynlib: dllname, importc: "glVertex4dv".}
proc glVertex4f*(x, y, z, w: TGLfloat){.dynlib: dllname, importc: "glVertex4f".}
proc glVertex4fv*(v: PGLfloat){.dynlib: dllname, importc: "glVertex4fv".}
proc glVertex4i*(x, y, z, w: TGLint){.dynlib: dllname, importc: "glVertex4i".}
proc glVertex4iv*(v: PGLint){.dynlib: dllname, importc: "glVertex4iv".}
proc glVertex4s*(x, y, z, w: TGLshort){.dynlib: dllname, importc: "glVertex4s".}
proc glVertex4sv*(v: PGLshort){.dynlib: dllname, importc: "glVertex4sv".}
proc glVertexPointer*(size: TGLint, atype: TGLenum, stride: TGLsizei,
                      p: pointer){.dynlib: dllname,
    importc: "glVertexPointer".}
proc glViewport*(x, y: TGLint, width, height: TGLsizei){.dynlib: dllname,
    importc: "glViewport".}
type
  PFN_GLARRAY_ELEMENT_EXTPROC* = proc (i: TGLint)
  PFN_GLDRAW_ARRAYS_EXTPROC* = proc (mode: TGLenum, first: TGLint,
                                     count: TGLsizei)
  PFN_GLVERTEX_POINTER_EXTPROC* = proc (size: TGLint, atype: TGLenum,
                                        stride, count: TGLsizei,
                                        p: pointer)
  PFN_GLNORMAL_POINTER_EXTPROC* = proc (atype: TGLenum, stride, count: TGLsizei,
                                        p: pointer)
  PFN_GLCOLOR_POINTER_EXTPROC* = proc (size: TGLint, atype: TGLenum,
                                       stride, count: TGLsizei, p: pointer)
  PFN_GLINDEX_POINTER_EXTPROC* = proc (atype: TGLenum, stride, count: TGLsizei,
                                       p: pointer)
  PFN_GLTEXCOORD_POINTER_EXTPROC* = proc (size: TGLint, atype: TGLenum,
      stride, count: TGLsizei, p: pointer)
  PFN_GLEDGEFLAG_POINTER_EXTPROC* = proc (stride, count: TGLsizei,
      pointer: PGLboolean)
  PFN_GLGET_POINTER_VEXT_PROC* = proc (pname: TGLenum, params: pointer)
  PFN_GLARRAY_ELEMENT_ARRAY_EXTPROC* = proc (mode: TGLenum, count: TGLsizei,
      pi: pointer)            # WIN_swap_hint
  PFN_GLADDSWAPHINT_RECT_WINPROC* = proc (x, y: TGLint, width, height: TGLsizei)
  PFN_GLCOLOR_TABLE_EXTPROC* = proc (target, internalFormat: TGLenum,
                                     width: TGLsizei, format, atype: TGLenum,
                                     data: pointer)
  PFN_GLCOLOR_SUBTABLE_EXTPROC* = proc (target: TGLenum, start, count: TGLsizei,
                                        format, atype: TGLenum, data: pointer)
  PFN_GLGETCOLOR_TABLE_EXTPROC* = proc (target, format, atype: TGLenum,
                                        data: pointer)
  PFN_GLGETCOLOR_TABLE_PARAMETER_IVEXTPROC* = proc (target, pname: TGLenum,
      params: PGLint)
  PFN_GLGETCOLOR_TABLE_PARAMETER_FVEXTPROC* = proc (target, pname: TGLenum,
      params: PGLfloat)

{.pop.}
# implementation
