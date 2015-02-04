#
#
#  Adaption of the delphi3d.net OpenGL units to FreePascal
#  Sebastian Guenther (sg@freepascal.org) in 2002
#  These units are free to use
#******************************************************************************
# Converted to Delphi by Tom Nuydens (tom@delphi3d.net)
# For the latest updates, visit Delphi3D: http://www.delphi3d.net
#******************************************************************************

import
  GL

when defined(windows):
  {.push, callconv: stdcall.}
else:
  {.push, callconv: cdecl.}

when defined(windows):
  const
    dllname = "glu32.dll"
elif defined(macosx):
  const
    dllname = "/System/Library/Frameworks/OpenGL.framework/Libraries/libGLU.dylib"
else:
  const
    dllname = "libGLU.so.1"
type
  TViewPortArray* = array[0..3, TGLint]
  T16dArray* = array[0..15, TGLdouble]
  TCallBack* = proc ()
  T3dArray* = array[0..2, TGLdouble]
  T4pArray* = array[0..3, Pointer]
  T4fArray* = array[0..3, TGLfloat]
  PPointer* = ptr Pointer

type
  GLUnurbs*{.final.} = object
  PGLUnurbs* = ptr GLUnurbs
  GLUquadric*{.final.} = object
  PGLUquadric* = ptr GLUquadric
  GLUtesselator*{.final.} = object
  PGLUtesselator* = ptr GLUtesselator # backwards compatibility:
  GLUnurbsObj* = GLUnurbs
  PGLUnurbsObj* = PGLUnurbs
  GLUquadricObj* = GLUquadric
  PGLUquadricObj* = PGLUquadric
  GLUtesselatorObj* = GLUtesselator
  PGLUtesselatorObj* = PGLUtesselator
  GLUtriangulatorObj* = GLUtesselator
  PGLUtriangulatorObj* = PGLUtesselator
  TGLUnurbs* = GLUnurbs
  TGLUquadric* = GLUquadric
  TGLUtesselator* = GLUtesselator
  TGLUnurbsObj* = GLUnurbsObj
  TGLUquadricObj* = GLUquadricObj
  TGLUtesselatorObj* = GLUtesselatorObj
  TGLUtriangulatorObj* = GLUtriangulatorObj

proc gluErrorString*(errCode: TGLenum): cstring{.dynlib: dllname,
    importc: "gluErrorString".}
proc gluErrorUnicodeStringEXT*(errCode: TGLenum): ptr int16{.dynlib: dllname,
    importc: "gluErrorUnicodeStringEXT".}
proc gluGetString*(name: TGLenum): cstring{.dynlib: dllname,
    importc: "gluGetString".}
proc gluOrtho2D*(left, right, bottom, top: TGLdouble){.dynlib: dllname,
    importc: "gluOrtho2D".}
proc gluPerspective*(fovy, aspect, zNear, zFar: TGLdouble){.dynlib: dllname,
    importc: "gluPerspective".}
proc gluPickMatrix*(x, y, width, height: TGLdouble, viewport: var TViewPortArray){.
    dynlib: dllname, importc: "gluPickMatrix".}
proc gluLookAt*(eyex, eyey, eyez, centerx, centery, centerz, upx, upy, upz: TGLdouble){.
    dynlib: dllname, importc: "gluLookAt".}
proc gluProject*(objx, objy, objz: TGLdouble,
                 modelMatrix, projMatrix: var T16dArray,
                 viewport: var TViewPortArray, winx, winy, winz: PGLdouble): int{.
    dynlib: dllname, importc: "gluProject".}
proc gluUnProject*(winx, winy, winz: TGLdouble,
                   modelMatrix, projMatrix: var T16dArray,
                   viewport: var TViewPortArray, objx, objy, objz: PGLdouble): int{.
    dynlib: dllname, importc: "gluUnProject".}
proc gluScaleImage*(format: TGLenum, widthin, heightin: TGLint, typein: TGLenum,
                    datain: Pointer, widthout, heightout: TGLint,
                    typeout: TGLenum, dataout: Pointer): int{.dynlib: dllname,
    importc: "gluScaleImage".}
proc gluBuild1DMipmaps*(target: TGLenum, components, width: TGLint,
                        format, atype: TGLenum, data: Pointer): int{.
    dynlib: dllname, importc: "gluBuild1DMipmaps".}
proc gluBuild2DMipmaps*(target: TGLenum, components, width, height: TGLint,
                        format, atype: TGLenum, data: Pointer): int{.
    dynlib: dllname, importc: "gluBuild2DMipmaps".}
proc gluNewQuadric*(): PGLUquadric{.dynlib: dllname, importc: "gluNewQuadric".}
proc gluDeleteQuadric*(state: PGLUquadric){.dynlib: dllname,
    importc: "gluDeleteQuadric".}
proc gluQuadricNormals*(quadObject: PGLUquadric, normals: TGLenum){.
    dynlib: dllname, importc: "gluQuadricNormals".}
proc gluQuadricTexture*(quadObject: PGLUquadric, textureCoords: TGLboolean){.
    dynlib: dllname, importc: "gluQuadricTexture".}
proc gluQuadricOrientation*(quadObject: PGLUquadric, orientation: TGLenum){.
    dynlib: dllname, importc: "gluQuadricOrientation".}
proc gluQuadricDrawStyle*(quadObject: PGLUquadric, drawStyle: TGLenum){.
    dynlib: dllname, importc: "gluQuadricDrawStyle".}
proc gluCylinder*(qobj: PGLUquadric, baseRadius, topRadius, height: TGLdouble,
                  slices, stacks: TGLint){.dynlib: dllname,
    importc: "gluCylinder".}
proc gluDisk*(qobj: PGLUquadric, innerRadius, outerRadius: TGLdouble,
              slices, loops: TGLint){.dynlib: dllname, importc: "gluDisk".}
proc gluPartialDisk*(qobj: PGLUquadric, innerRadius, outerRadius: TGLdouble,
                     slices, loops: TGLint, startAngle, sweepAngle: TGLdouble){.
    dynlib: dllname, importc: "gluPartialDisk".}
proc gluSphere*(qobj: PGLuquadric, radius: TGLdouble, slices, stacks: TGLint){.
    dynlib: dllname, importc: "gluSphere".}
proc gluQuadricCallback*(qobj: PGLUquadric, which: TGLenum, fn: TCallBack){.
    dynlib: dllname, importc: "gluQuadricCallback".}
proc gluNewTess*(): PGLUtesselator{.dynlib: dllname, importc: "gluNewTess".}
proc gluDeleteTess*(tess: PGLUtesselator){.dynlib: dllname,
    importc: "gluDeleteTess".}
proc gluTessBeginPolygon*(tess: PGLUtesselator, polygon_data: Pointer){.
    dynlib: dllname, importc: "gluTessBeginPolygon".}
proc gluTessBeginContour*(tess: PGLUtesselator){.dynlib: dllname,
    importc: "gluTessBeginContour".}
proc gluTessVertex*(tess: PGLUtesselator, coords: var T3dArray, data: Pointer){.
    dynlib: dllname, importc: "gluTessVertex".}
proc gluTessEndContour*(tess: PGLUtesselator){.dynlib: dllname,
    importc: "gluTessEndContour".}
proc gluTessEndPolygon*(tess: PGLUtesselator){.dynlib: dllname,
    importc: "gluTessEndPolygon".}
proc gluTessProperty*(tess: PGLUtesselator, which: TGLenum, value: TGLdouble){.
    dynlib: dllname, importc: "gluTessProperty".}
proc gluTessNormal*(tess: PGLUtesselator, x, y, z: TGLdouble){.dynlib: dllname,
    importc: "gluTessNormal".}
proc gluTessCallback*(tess: PGLUtesselator, which: TGLenum, fn: TCallBack){.
    dynlib: dllname, importc: "gluTessCallback".}
proc gluGetTessProperty*(tess: PGLUtesselator, which: TGLenum, value: PGLdouble){.
    dynlib: dllname, importc: "gluGetTessProperty".}
proc gluNewNurbsRenderer*(): PGLUnurbs{.dynlib: dllname,
                                        importc: "gluNewNurbsRenderer".}
proc gluDeleteNurbsRenderer*(nobj: PGLUnurbs){.dynlib: dllname,
    importc: "gluDeleteNurbsRenderer".}
proc gluBeginSurface*(nobj: PGLUnurbs){.dynlib: dllname,
                                        importc: "gluBeginSurface".}
proc gluBeginCurve*(nobj: PGLUnurbs){.dynlib: dllname, importc: "gluBeginCurve".}
proc gluEndCurve*(nobj: PGLUnurbs){.dynlib: dllname, importc: "gluEndCurve".}
proc gluEndSurface*(nobj: PGLUnurbs){.dynlib: dllname, importc: "gluEndSurface".}
proc gluBeginTrim*(nobj: PGLUnurbs){.dynlib: dllname, importc: "gluBeginTrim".}
proc gluEndTrim*(nobj: PGLUnurbs){.dynlib: dllname, importc: "gluEndTrim".}
proc gluPwlCurve*(nobj: PGLUnurbs, count: TGLint, aarray: PGLfloat,
                  stride: TGLint, atype: TGLenum){.dynlib: dllname,
    importc: "gluPwlCurve".}
proc gluNurbsCurve*(nobj: PGLUnurbs, nknots: TGLint, knot: PGLfloat,
                    stride: TGLint, ctlarray: PGLfloat, order: TGLint,
                    atype: TGLenum){.dynlib: dllname, importc: "gluNurbsCurve".}
proc gluNurbsSurface*(nobj: PGLUnurbs, sknot_count: TGLint, sknot: PGLfloat,
                      tknot_count: TGLint, tknot: PGLfloat,
                      s_stride, t_stride: TGLint, ctlarray: PGLfloat,
                      sorder, torder: TGLint, atype: TGLenum){.dynlib: dllname,
    importc: "gluNurbsSurface".}
proc gluLoadSamplingMatrices*(nobj: PGLUnurbs,
                              modelMatrix, projMatrix: var T16dArray,
                              viewport: var TViewPortArray){.dynlib: dllname,
    importc: "gluLoadSamplingMatrices".}
proc gluNurbsProperty*(nobj: PGLUnurbs, aproperty: TGLenum, value: TGLfloat){.
    dynlib: dllname, importc: "gluNurbsProperty".}
proc gluGetNurbsProperty*(nobj: PGLUnurbs, aproperty: TGLenum, value: PGLfloat){.
    dynlib: dllname, importc: "gluGetNurbsProperty".}
proc gluNurbsCallback*(nobj: PGLUnurbs, which: TGLenum, fn: TCallBack){.
    dynlib: dllname, importc: "gluNurbsCallback".}
  #*** Callback function prototypes ***
type                          # gluQuadricCallback
  GLUquadricErrorProc* = proc (p: TGLenum) # gluTessCallback
  GLUtessBeginProc* = proc (p: TGLenum)
  GLUtessEdgeFlagProc* = proc (p: TGLboolean)
  GLUtessVertexProc* = proc (p: Pointer)
  GLUtessEndProc* = proc ()
  GLUtessErrorProc* = proc (p: TGLenum)
  GLUtessCombineProc* = proc (p1: var T3dArray, p2: T4pArray, p3: T4fArray,
                              p4: PPointer)
  GLUtessBeginDataProc* = proc (p1: TGLenum, p2: Pointer)
  GLUtessEdgeFlagDataProc* = proc (p1: TGLboolean, p2: Pointer)
  GLUtessVertexDataProc* = proc (p1, p2: Pointer)
  GLUtessEndDataProc* = proc (p: Pointer)
  GLUtessErrorDataProc* = proc (p1: TGLenum, p2: Pointer)
  GLUtessCombineDataProc* = proc (p1: var T3dArray, p2: var T4pArray,
                                  p3: var T4fArray, p4: PPointer, p5: Pointer) #
                                                                               #
                                                                               # gluNurbsCallback
  GLUnurbsErrorProc* = proc (p: TGLenum) #***           Generic constants               ****/

const                         # Version
  GLU_VERSION_1_1* = 1
  GLU_VERSION_1_2* = 1        # Errors: (return value 0 = no error)
  GLU_INVALID_ENUM* = 100900
  GLU_INVALID_VALUE* = 100901
  GLU_OUT_OF_MEMORY* = 100902
  GLU_INCOMPATIBLE_GL_VERSION* = 100903 # StringName
  GLU_VERSION* = 100800
  GLU_EXTENSIONS* = 100801    # Boolean
  GLU_TRUE* = GL_TRUE
  GLU_FALSE* = GL_FALSE #***           Quadric constants               ****/
                        # QuadricNormal
  GLU_SMOOTH* = 100000
  GLU_FLAT* = 100001
  GLU_NONE* = 100002          # QuadricDrawStyle
  GLU_POINT* = 100010
  GLU_LINE* = 100011
  GLU_FILL* = 100012
  GLU_SILHOUETTE* = 100013    # QuadricOrientation
  GLU_OUTSIDE* = 100020
  GLU_INSIDE* = 100021        # Callback types:
                              #      GLU_ERROR       = 100103;
                              #***           Tesselation constants           ****/
  GLU_TESS_MAX_COORD* = 1.00000e+150 # TessProperty
  GLU_TESS_WINDING_RULE* = 100140
  GLU_TESS_BOUNDARY_ONLY* = 100141
  GLU_TESS_TOLERANCE* = 100142 # TessWinding
  GLU_TESS_WINDING_ODD* = 100130
  GLU_TESS_WINDING_NONZERO* = 100131
  GLU_TESS_WINDING_POSITIVE* = 100132
  GLU_TESS_WINDING_NEGATIVE* = 100133
  GLU_TESS_WINDING_ABS_GEQ_TWO* = 100134 # TessCallback
  GLU_TESS_BEGIN* = 100100    # void (CALLBACK*)(TGLenum    type)
  constGLU_TESS_VERTEX* = 100101 # void (CALLBACK*)(void      *data)
  GLU_TESS_END* = 100102      # void (CALLBACK*)(void)
  GLU_TESS_ERROR* = 100103    # void (CALLBACK*)(TGLenum    errno)
  GLU_TESS_EDGE_FLAG* = 100104 # void (CALLBACK*)(TGLboolean boundaryEdge)
  GLU_TESS_COMBINE* = 100105 # void (CALLBACK*)(TGLdouble  coords[3],
                             #                                                            void      *data[4],
                             #                                                            TGLfloat   weight[4],
                             #                                                            void      **dataOut)
  GLU_TESS_BEGIN_DATA* = 100106 # void (CALLBACK*)(TGLenum    type,
                                #                                                            void      *polygon_data)
  GLU_TESS_VERTEX_DATA* = 100107 # void (CALLBACK*)(void      *data,
                                 #                                                            void      *polygon_data)
  GLU_TESS_END_DATA* = 100108 # void (CALLBACK*)(void      *polygon_data)
  GLU_TESS_ERROR_DATA* = 100109 # void (CALLBACK*)(TGLenum    errno,
                                #                                                            void      *polygon_data)
  GLU_TESS_EDGE_FLAG_DATA* = 100110 # void (CALLBACK*)(TGLboolean boundaryEdge,
                                    #                                                            void      *polygon_data)
  GLU_TESS_COMBINE_DATA* = 100111 # void (CALLBACK*)(TGLdouble  coords[3],
                                  #                                                            void      *data[4],
                                  #                                                            TGLfloat   weight[4],
                                  #                                                            void      **dataOut,
                                  #                                                            void      *polygon_data)
                                  # TessError
  GLU_TESS_ERROR1* = 100151
  GLU_TESS_ERROR2* = 100152
  GLU_TESS_ERROR3* = 100153
  GLU_TESS_ERROR4* = 100154
  GLU_TESS_ERROR5* = 100155
  GLU_TESS_ERROR6* = 100156
  GLU_TESS_ERROR7* = 100157
  GLU_TESS_ERROR8* = 100158
  GLU_TESS_MISSING_BEGIN_POLYGON* = GLU_TESS_ERROR1
  GLU_TESS_MISSING_BEGIN_CONTOUR* = GLU_TESS_ERROR2
  GLU_TESS_MISSING_END_POLYGON* = GLU_TESS_ERROR3
  GLU_TESS_MISSING_END_CONTOUR* = GLU_TESS_ERROR4
  GLU_TESS_COORD_TOO_LARGE* = GLU_TESS_ERROR5
  GLU_TESS_NEED_COMBINE_CALLBACK* = GLU_TESS_ERROR6 #***           NURBS constants                 ****/
                                                    # NurbsProperty
  GLU_AUTO_LOAD_MATRIX* = 100200
  GLU_CULLING* = 100201
  GLU_SAMPLING_TOLERANCE* = 100203
  GLU_DISPLAY_MODE* = 100204
  GLU_PARAMETRIC_TOLERANCE* = 100202
  GLU_SAMPLING_METHOD* = 100205
  GLU_U_STEP* = 100206
  GLU_V_STEP* = 100207        # NurbsSampling
  GLU_PATH_LENGTH* = 100215
  GLU_PARAMETRIC_ERROR* = 100216
  GLU_DOMAIN_DISTANCE* = 100217 # NurbsTrim
  GLU_MAP1_TRIM_2* = 100210
  GLU_MAP1_TRIM_3* = 100211   # NurbsDisplay
                              #      GLU_FILL                = 100012;
  GLU_OUTLINE_POLYGON* = 100240
  GLU_OUTLINE_PATCH* = 100241 # NurbsCallback
                              #      GLU_ERROR               = 100103;
                              # NurbsErrors
  GLU_NURBS_ERROR1* = 100251
  GLU_NURBS_ERROR2* = 100252
  GLU_NURBS_ERROR3* = 100253
  GLU_NURBS_ERROR4* = 100254
  GLU_NURBS_ERROR5* = 100255
  GLU_NURBS_ERROR6* = 100256
  GLU_NURBS_ERROR7* = 100257
  GLU_NURBS_ERROR8* = 100258
  GLU_NURBS_ERROR9* = 100259
  GLU_NURBS_ERROR10* = 100260
  GLU_NURBS_ERROR11* = 100261
  GLU_NURBS_ERROR12* = 100262
  GLU_NURBS_ERROR13* = 100263
  GLU_NURBS_ERROR14* = 100264
  GLU_NURBS_ERROR15* = 100265
  GLU_NURBS_ERROR16* = 100266
  GLU_NURBS_ERROR17* = 100267
  GLU_NURBS_ERROR18* = 100268
  GLU_NURBS_ERROR19* = 100269
  GLU_NURBS_ERROR20* = 100270
  GLU_NURBS_ERROR21* = 100271
  GLU_NURBS_ERROR22* = 100272
  GLU_NURBS_ERROR23* = 100273
  GLU_NURBS_ERROR24* = 100274
  GLU_NURBS_ERROR25* = 100275
  GLU_NURBS_ERROR26* = 100276
  GLU_NURBS_ERROR27* = 100277
  GLU_NURBS_ERROR28* = 100278
  GLU_NURBS_ERROR29* = 100279
  GLU_NURBS_ERROR30* = 100280
  GLU_NURBS_ERROR31* = 100281
  GLU_NURBS_ERROR32* = 100282
  GLU_NURBS_ERROR33* = 100283
  GLU_NURBS_ERROR34* = 100284
  GLU_NURBS_ERROR35* = 100285
  GLU_NURBS_ERROR36* = 100286
  GLU_NURBS_ERROR37* = 100287 #***           Backwards compatibility for old tesselator           ****/

proc gluBeginPolygon*(tess: PGLUtesselator){.dynlib: dllname,
    importc: "gluBeginPolygon".}
proc gluNextContour*(tess: PGLUtesselator, atype: TGLenum){.dynlib: dllname,
    importc: "gluNextContour".}
proc gluEndPolygon*(tess: PGLUtesselator){.dynlib: dllname,
    importc: "gluEndPolygon".}
const                         # Contours types -- obsolete!
  GLU_CW* = 100120
  GLU_CCW* = 100121
  GLU_INTERIOR* = 100122
  GLU_EXTERIOR* = 100123
  GLU_UNKNOWN* = 100124       # Names without "TESS_" prefix
  GLU_BEGIN* = GLU_TESS_BEGIN
  GLU_VERTEX* = constGLU_TESS_VERTEX
  GLU_END* = GLU_TESS_END
  GLU_ERROR* = GLU_TESS_ERROR
  GLU_EDGE_FLAG* = GLU_TESS_EDGE_FLAG

{.pop.}
# implementation
