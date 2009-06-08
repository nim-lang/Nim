{

  Adaption of the delphi3d.net OpenGL units to FreePascal
  Sebastian Guenther (sg@freepascal.org) in 2002
  These units are free to use
}

{*++ BUILD Version: 0004    // Increment this if a change has global effects

Copyright (c) 1985-95, Microsoft Corporation

Module Name:

    glu.h

Abstract:

    Procedure declarations, constant definitions and macros for the OpenGL
    Utility Library.

--*}

{*
** Copyright 1991-1993, Silicon Graphics, Inc.
** All Rights Reserved.
**
** This is UNPUBLISHED PROPRIETARY SOURCE CODE of Silicon Graphics, Inc.;
** the contents of this file may not be disclosed to third parties, copied or
** duplicated in any form, in whole or in part, without the prior written
** permission of Silicon Graphics, Inc.
**
** RESTRICTED RIGHTS LEGEND:
** Use, duplication or disclosure by the Government is subject to restrictions
** as set forth in subdivision (c)(1)(ii) of the Rights in Technical Data
** and Computer Software clause at DFARS 252.227-7013, and/or in similar or
** successor clauses in the FAR, DOD or NASA FAR Supplement. Unpublished -
** rights reserved under the Copyright Laws of the United States.
*}

{*
** Return the error string associated with a particular error code.
** This will return 0 for an invalid error code.
**
** The generic function prototype that can be compiled for ANSI or Unicode
** is defined as follows:
**
** LPCTSTR APIENTRY gluErrorStringWIN (GLenum errCode);
*}

{******************************************************************************}
{ Converted to Delphi by Tom Nuydens (tom@delphi3d.net)                        }
{ For the latest updates, visit Delphi3D: http://www.delphi3d.net              }
{******************************************************************************}

unit GLu;

interface

uses
  GL;

const
  dllname = 'glu32.dll';
  dylibname = '/System/Library/Frameworks/OpenGL.framework/Libraries/libGLU.dylib';
  libname = 'libGLU.so.1';

type
  TViewPortArray = array [0..3] of GLint;
  T16dArray = array [0..15] of GLdouble;
  TCallBack = procedure;
  T3dArray = array [0..2] of GLdouble;
  T4pArray = array [0..3] of Pointer;
  T4fArray = array [0..3] of GLfloat;
  PPointer = ^Pointer;

type
  GLUnurbs = record end;                PGLUnurbs = ^GLUnurbs;
  GLUquadric = record end;              PGLUquadric = ^GLUquadric;
  GLUtesselator = record end;           PGLUtesselator = ^GLUtesselator;

  // backwards compatibility:
  GLUnurbsObj = GLUnurbs;               PGLUnurbsObj = PGLUnurbs;
  GLUquadricObj = GLUquadric;           PGLUquadricObj = PGLUquadric;
  GLUtesselatorObj = GLUtesselator;     PGLUtesselatorObj = PGLUtesselator;
  GLUtriangulatorObj = GLUtesselator;   PGLUtriangulatorObj = PGLUtesselator;

  TGLUnurbs = GLUnurbs;
  TGLUquadric = GLUquadric;
  TGLUtesselator = GLUtesselator;

  TGLUnurbsObj = GLUnurbsObj;
  TGLUquadricObj = GLUquadricObj;
  TGLUtesselatorObj = GLUtesselatorObj;
  TGLUtriangulatorObj = GLUtriangulatorObj;


  function gluErrorString(errCode: GLenum): PChar; external dllname;
  function gluErrorUnicodeStringEXT(errCode: GLenum): PWideChar; external dllname;
  function gluGetString(name: GLenum): PChar; external dllname;
  procedure gluOrtho2D(left,right, bottom, top: GLdouble); external dllname;
  procedure gluPerspective(fovy, aspect, zNear, zFar: GLdouble); external dllname;
  procedure gluPickMatrix(x, y, width, height: GLdouble; var viewport: TViewPortArray); external dllname;
  procedure gluLookAt(eyex, eyey, eyez, centerx, centery, centerz, upx, upy, upz: GLdouble); external dllname;
  function gluProject(objx, objy, objz: GLdouble; var modelMatrix, projMatrix: T16dArray; var viewport: TViewPortArray; winx, winy, winz: PGLdouble): Integer; external dllname;
  function gluUnProject(winx, winy, winz: GLdouble; var modelMatrix, projMatrix: T16dArray; var viewport: TViewPortArray; objx, objy, objz: PGLdouble): Integer; external dllname;
  function gluScaleImage(format: GLenum; widthin, heightin: GLint; typein: GLenum; const datain: Pointer; widthout, heightout: GLint; typeout: GLenum; dataout: Pointer): Integer; external dllname;
  function gluBuild1DMipmaps(target: GLenum; components, width: GLint; format, atype: GLenum; const data: Pointer): Integer; external dllname;
  function gluBuild2DMipmaps(target: GLenum; components, width, height: GLint; format, atype: GLenum; const data: Pointer): Integer; external dllname;


  function gluNewQuadric: PGLUquadric; external dllname;
  procedure gluDeleteQuadric(state: PGLUquadric); external dllname;
  procedure gluQuadricNormals(quadObject: PGLUquadric; normals: GLenum); external dllname;
  procedure gluQuadricTexture(quadObject: PGLUquadric; textureCoords: GLboolean); external dllname;
  procedure gluQuadricOrientation(quadObject: PGLUquadric; orientation: GLenum); external dllname;
  procedure gluQuadricDrawStyle(quadObject: PGLUquadric; drawStyle: GLenum); external dllname;
  procedure gluCylinder(qobj: PGLUquadric; baseRadius, topRadius, height: GLdouble; slices, stacks: GLint); external dllname;
  procedure gluDisk(qobj: PGLUquadric; innerRadius, outerRadius: GLdouble; slices, loops: GLint); external dllname;
  procedure gluPartialDisk(qobj: PGLUquadric; innerRadius, outerRadius: GLdouble; slices, loops: GLint; startAngle, sweepAngle: GLdouble); external dllname;
  procedure gluSphere(qobj: PGLuquadric; radius: GLdouble; slices, stacks: GLint); external dllname;
  procedure gluQuadricCallback(qobj: PGLUquadric; which: GLenum; fn: TCallBack); external dllname;
  function gluNewTess: PGLUtesselator; external dllname;
  procedure gluDeleteTess(tess: PGLUtesselator); external dllname;
  procedure gluTessBeginPolygon(tess: PGLUtesselator; polygon_data: Pointer); external dllname;
  procedure gluTessBeginContour(tess: PGLUtesselator); external dllname;
  procedure gluTessVertex(tess: PGLUtesselator; var coords: T3dArray; data: Pointer); external dllname;
  procedure gluTessEndContour(tess: PGLUtesselator); external dllname;
  procedure gluTessEndPolygon(tess: PGLUtesselator); external dllname;
  procedure gluTessProperty(tess: PGLUtesselator; which: GLenum; value: GLdouble); external dllname;
  procedure gluTessNormal(tess: PGLUtesselator; x, y, z: GLdouble); external dllname;
  procedure gluTessCallback(tess: PGLUtesselator; which: GLenum;fn: TCallBack); external dllname;
  procedure gluGetTessProperty(tess: PGLUtesselator; which: GLenum; value: PGLdouble); external dllname;
  function gluNewNurbsRenderer: PGLUnurbs; external dllname;
  procedure gluDeleteNurbsRenderer(nobj: PGLUnurbs); external dllname;
  procedure gluBeginSurface(nobj: PGLUnurbs); external dllname;
  procedure gluBeginCurve(nobj: PGLUnurbs); external dllname;
  procedure gluEndCurve(nobj: PGLUnurbs); external dllname;
  procedure gluEndSurface(nobj: PGLUnurbs); external dllname;
  procedure gluBeginTrim(nobj: PGLUnurbs); external dllname;
  procedure gluEndTrim(nobj: PGLUnurbs); external dllname;
  procedure gluPwlCurve(nobj: PGLUnurbs; count: GLint; aarray: PGLfloat; stride: GLint; atype: GLenum); external dllname;
  procedure gluNurbsCurve(nobj: PGLUnurbs; nknots: GLint; knot: PGLfloat; stride: GLint; ctlarray: PGLfloat; order: GLint; atype: GLenum); external dllname;
  procedure gluNurbsSurface(nobj: PGLUnurbs; sknot_count: GLint; sknot: PGLfloat; tknot_count: GLint; tknot: PGLfloat; s_stride, t_stride: GLint; ctlarray: PGLfloat; sorder, torder: GLint; atype: GLenum); external dllname;
  procedure gluLoadSamplingMatrices(nobj: PGLUnurbs; var modelMatrix, projMatrix: T16dArray; var viewport: TViewPortArray); external dllname;
  procedure gluNurbsProperty(nobj: PGLUnurbs; aproperty: GLenum; value: GLfloat); external dllname;
  procedure gluGetNurbsProperty(nobj: PGLUnurbs; aproperty: GLenum; value: PGLfloat); external dllname;
  procedure gluNurbsCallback(nobj: PGLUnurbs; which: GLenum; fn: TCallBack); external dllname;

(**** Callback function prototypes ****)

type
  // gluQuadricCallback
  GLUquadricErrorProc = procedure(p: GLenum); 

  // gluTessCallback
  GLUtessBeginProc = procedure(p: GLenum); 
  GLUtessEdgeFlagProc = procedure(p: GLboolean); 
  GLUtessVertexProc = procedure(p: Pointer); 
  GLUtessEndProc = procedure; 
  GLUtessErrorProc = procedure(p: GLenum); 
  GLUtessCombineProc = procedure(var p1: T3dArray; p2: T4pArray; p3: T4fArray; p4: PPointer); 
  GLUtessBeginDataProc = procedure(p1: GLenum; p2: Pointer); 
  GLUtessEdgeFlagDataProc = procedure(p1: GLboolean; p2: Pointer); 
  GLUtessVertexDataProc = procedure(p1, p2: Pointer); 
  GLUtessEndDataProc = procedure(p: Pointer); 
  GLUtessErrorDataProc = procedure(p1: GLenum; p2: Pointer); 
  GLUtessCombineDataProc = procedure(var p1: T3dArray; var p2: T4pArray; var p3: T4fArray;
                                     p4: PPointer; p5: Pointer); 

  // gluNurbsCallback
  GLUnurbsErrorProc = procedure(p: GLenum); 


//***           Generic constants               ****/

const
  // Version
  GLU_VERSION_1_1                 = 1;
  GLU_VERSION_1_2                 = 1;

  // Errors: (return value 0 = no error)
  GLU_INVALID_ENUM                = 100900;
  GLU_INVALID_VALUE               = 100901;
  GLU_OUT_OF_MEMORY               = 100902;
  GLU_INCOMPATIBLE_GL_VERSION     = 100903;

  // StringName
  GLU_VERSION                     = 100800;
  GLU_EXTENSIONS                  = 100801;

  // Boolean
  GLU_TRUE                        = GL_TRUE;
  GLU_FALSE                       = GL_FALSE;


  //***           Quadric constants               ****/

  // QuadricNormal
  GLU_SMOOTH              = 100000;
  GLU_FLAT                = 100001;
  GLU_NONE                = 100002;

  // QuadricDrawStyle
  GLU_POINT               = 100010;
  GLU_LINE                = 100011;
  GLU_FILL                = 100012;
  GLU_SILHOUETTE          = 100013;

  // QuadricOrientation
  GLU_OUTSIDE             = 100020;
  GLU_INSIDE              = 100021;

  // Callback types:
  //      GLU_ERROR       = 100103;


  //***           Tesselation constants           ****/

  GLU_TESS_MAX_COORD              = 1.0e150;

  // TessProperty
  GLU_TESS_WINDING_RULE           = 100140;
  GLU_TESS_BOUNDARY_ONLY          = 100141;
  GLU_TESS_TOLERANCE              = 100142;

  // TessWinding
  GLU_TESS_WINDING_ODD            = 100130;
  GLU_TESS_WINDING_NONZERO        = 100131;
  GLU_TESS_WINDING_POSITIVE       = 100132;
  GLU_TESS_WINDING_NEGATIVE       = 100133;
  GLU_TESS_WINDING_ABS_GEQ_TWO    = 100134;

  // TessCallback
  GLU_TESS_BEGIN          = 100100;    // void (CALLBACK*)(GLenum    type)
  GLU_TESS_VERTEX         = 100101;    // void (CALLBACK*)(void      *data)
  GLU_TESS_END            = 100102;    // void (CALLBACK*)(void)
  GLU_TESS_ERROR          = 100103;    // void (CALLBACK*)(GLenum    errno)
  GLU_TESS_EDGE_FLAG      = 100104;    // void (CALLBACK*)(GLboolean boundaryEdge)
  GLU_TESS_COMBINE        = 100105;    { void (CALLBACK*)(GLdouble  coords[3],
                                                            void      *data[4],
                                                            GLfloat   weight[4],
                                                            void      **dataOut) }
  GLU_TESS_BEGIN_DATA     = 100106;    { void (CALLBACK*)(GLenum    type,
                                                            void      *polygon_data) }
  GLU_TESS_VERTEX_DATA    = 100107;    { void (CALLBACK*)(void      *data,
                                                            void      *polygon_data) }
  GLU_TESS_END_DATA       = 100108;    // void (CALLBACK*)(void      *polygon_data)
  GLU_TESS_ERROR_DATA     = 100109;    { void (CALLBACK*)(GLenum    errno,
                                                            void      *polygon_data) }
  GLU_TESS_EDGE_FLAG_DATA = 100110;    { void (CALLBACK*)(GLboolean boundaryEdge,
                                                            void      *polygon_data) }
  GLU_TESS_COMBINE_DATA   = 100111;    { void (CALLBACK*)(GLdouble  coords[3],
                                                            void      *data[4],
                                                            GLfloat   weight[4],
                                                            void      **dataOut,
                                                            void      *polygon_data) }

  // TessError
  GLU_TESS_ERROR1     = 100151;
  GLU_TESS_ERROR2     = 100152;
  GLU_TESS_ERROR3     = 100153;
  GLU_TESS_ERROR4     = 100154;
  GLU_TESS_ERROR5     = 100155;
  GLU_TESS_ERROR6     = 100156;
  GLU_TESS_ERROR7     = 100157;
  GLU_TESS_ERROR8     = 100158;

  GLU_TESS_MISSING_BEGIN_POLYGON  = GLU_TESS_ERROR1;
  GLU_TESS_MISSING_BEGIN_CONTOUR  = GLU_TESS_ERROR2;
  GLU_TESS_MISSING_END_POLYGON    = GLU_TESS_ERROR3;
  GLU_TESS_MISSING_END_CONTOUR    = GLU_TESS_ERROR4;
  GLU_TESS_COORD_TOO_LARGE        = GLU_TESS_ERROR5;
  GLU_TESS_NEED_COMBINE_CALLBACK  = GLU_TESS_ERROR6;

  //***           NURBS constants                 ****/

  // NurbsProperty
  GLU_AUTO_LOAD_MATRIX            = 100200;
  GLU_CULLING                     = 100201;
  GLU_SAMPLING_TOLERANCE          = 100203;
  GLU_DISPLAY_MODE                = 100204;
  GLU_PARAMETRIC_TOLERANCE        = 100202;
  GLU_SAMPLING_METHOD             = 100205;
  GLU_U_STEP                      = 100206;
  GLU_V_STEP                      = 100207;

  // NurbsSampling
  GLU_PATH_LENGTH                 = 100215;
  GLU_PARAMETRIC_ERROR            = 100216;
  GLU_DOMAIN_DISTANCE             = 100217;


  // NurbsTrim
  GLU_MAP1_TRIM_2                 = 100210;
  GLU_MAP1_TRIM_3                 = 100211;

  // NurbsDisplay
  //      GLU_FILL                = 100012;
  GLU_OUTLINE_POLYGON             = 100240;
  GLU_OUTLINE_PATCH               = 100241;

  // NurbsCallback
  //      GLU_ERROR               = 100103;

  // NurbsErrors
  GLU_NURBS_ERROR1        = 100251;
  GLU_NURBS_ERROR2        = 100252;
  GLU_NURBS_ERROR3        = 100253;
  GLU_NURBS_ERROR4        = 100254;
  GLU_NURBS_ERROR5        = 100255;
  GLU_NURBS_ERROR6        = 100256;
  GLU_NURBS_ERROR7        = 100257;
  GLU_NURBS_ERROR8        = 100258;
  GLU_NURBS_ERROR9        = 100259;
  GLU_NURBS_ERROR10       = 100260;
  GLU_NURBS_ERROR11       = 100261;
  GLU_NURBS_ERROR12       = 100262;
  GLU_NURBS_ERROR13       = 100263;
  GLU_NURBS_ERROR14       = 100264;
  GLU_NURBS_ERROR15       = 100265;
  GLU_NURBS_ERROR16       = 100266;
  GLU_NURBS_ERROR17       = 100267;
  GLU_NURBS_ERROR18       = 100268;
  GLU_NURBS_ERROR19       = 100269;
  GLU_NURBS_ERROR20       = 100270;
  GLU_NURBS_ERROR21       = 100271;
  GLU_NURBS_ERROR22       = 100272;
  GLU_NURBS_ERROR23       = 100273;
  GLU_NURBS_ERROR24       = 100274;
  GLU_NURBS_ERROR25       = 100275;
  GLU_NURBS_ERROR26       = 100276;
  GLU_NURBS_ERROR27       = 100277;
  GLU_NURBS_ERROR28       = 100278;
  GLU_NURBS_ERROR29       = 100279;
  GLU_NURBS_ERROR30       = 100280;
  GLU_NURBS_ERROR31       = 100281;
  GLU_NURBS_ERROR32       = 100282;
  GLU_NURBS_ERROR33       = 100283;
  GLU_NURBS_ERROR34       = 100284;
  GLU_NURBS_ERROR35       = 100285;
  GLU_NURBS_ERROR36       = 100286;
  GLU_NURBS_ERROR37       = 100287;

//***           Backwards compatibility for old tesselator           ****/


  procedure gluBeginPolygon(tess: PGLUtesselator); external dllname;
  procedure gluNextContour(tess: PGLUtesselator; atype: GLenum); external dllname;
  procedure gluEndPolygon(tess: PGLUtesselator); external dllname;

const
  // Contours types -- obsolete!
  GLU_CW          = 100120;
  GLU_CCW         = 100121;
  GLU_INTERIOR    = 100122;
  GLU_EXTERIOR    = 100123;
  GLU_UNKNOWN     = 100124;

  // Names without "TESS_" prefix
  GLU_BEGIN       = GLU_TESS_BEGIN;
  GLU_VERTEX      = GLU_TESS_VERTEX;
  GLU_END         = GLU_TESS_END;
  GLU_ERROR       = GLU_TESS_ERROR;
  GLU_EDGE_FLAG   = GLU_TESS_EDGE_FLAG;

implementation

end.
