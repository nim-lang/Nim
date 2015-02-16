#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Robert Persson
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import math
import strutils
import times


## Basic 3d support with vectors, points, matrices and some basic utilities.
## Vectors are implemented as direction vectors, ie. when transformed with a matrix
## the translation part of matrix is ignored. The coordinate system used is
## right handed, because its compatible with 2d coordinate system (rotation around
## zaxis equals 2d rotation). 
## Operators `+` , `-` , `*` , `/` , `+=` , `-=` , `*=` and `/=` are implemented
## for vectors and scalars.
##
##
## Quick start example:
##   
##   # Create a matrix which first rotates, then scales and at last translates
##   
##   var m:TMatrix3d=rotate(PI,vector3d(1,1,2.5)) & scale(2.0) & move(100.0,200.0,300.0)
##   
##   # Create a 3d point at (100,150,200) and a vector (5,2,3)
##   
##   var pt:TPoint3d=point3d(100.0,150.0,200.0) 
##   
##   var vec:TVector3d=vector3d(5.0,2.0,3.0)
##   
##   
##   pt &= m # transforms pt in place
##   
##   var pt2:TPoint3d=pt & m #concatenates pt with m and returns a new point
##   
##   var vec2:TVector3d=vec & m #concatenates vec with m and returns a new vector



type 
  TMatrix3d* =object
    ## Implements a row major 3d matrix, which means
    ## transformations are applied the order they are concatenated.
    ## This matrix is stored as an 4x4 matrix:
    ## [ ax ay az aw ]
    ## [ bx by bz bw ]
    ## [ cx cy cz cw ]
    ## [ tx ty tz tw ]
    ax*,ay*,az*,aw*,  bx*,by*,bz*,bw*,  cx*,cy*,cz*,cw*,  tx*,ty*,tz*,tw*:float
  TPoint3d* = object
    ## Implements a non-homegeneous 2d point stored as 
    ## an `x` , `y` and `z` coordinate.
    x*,y*,z*:float
  TVector3d* = object 
    ## Implements a 3d **direction vector** stored as 
    ## an `x` , `y` and `z` coordinate. Direction vector means, 
    ## that when transforming a vector with a matrix, the translational
    ## part of the matrix is ignored.
    x*,y*,z*:float



# Some forward declarations
proc matrix3d*(ax,ay,az,aw,bx,by,bz,bw,cx,cy,cz,cw,tx,ty,tz,tw:float):TMatrix3d {.noInit.}
  ## Creates a new 4x4 3d transformation matrix. 
  ## `ax` , `ay` , `az` is the local x axis.
  ## `bx` , `by` , `bz` is the local y axis.
  ## `cx` , `cy` , `cz` is the local z axis.
  ## `tx` , `ty` , `tz` is the translation.
proc vector3d*(x,y,z:float):TVector3d {.noInit,inline.}
  ## Returns a new 3d vector (`x`,`y`,`z`)
proc point3d*(x,y,z:float):TPoint3d {.noInit,inline.}
  ## Returns a new 4d point (`x`,`y`,`z`)
proc tryNormalize*(v:var TVector3d):bool 
  ## Modifies `v` to have a length of 1.0, keeping its angle.
  ## If `v` has zero length (and thus no angle), it is left unmodified and false is
  ## returned, otherwise true is returned.



let
  IDMATRIX*:TMatrix3d=matrix3d(
    1.0,0.0,0.0,0.0, 
    0.0,1.0,0.0,0.0,
    0.0,0.0,1.0,0.0,
    0.0,0.0,0.0,1.0)
    ## Quick access to a 3d identity matrix
  ORIGO*:TPoint3d=point3d(0.0,0.0,0.0)
    ## Quick access to point (0,0)
  XAXIS*:TVector3d=vector3d(1.0,0.0,0.0)
    ## Quick access to an 3d x-axis unit vector
  YAXIS*:TVector3d=vector3d(0.0,1.0,0.0)
    ## Quick access to an 3d y-axis unit vector
  ZAXIS*:TVector3d=vector3d(0.0,0.0,1.0)
    ## Quick access to an 3d z-axis unit vector



# ***************************************
#     Private utils
# ***************************************

proc rtos(val:float):string=
  return formatFloat(val,ffDefault,0)

proc safeArccos(v:float):float=
  ## assumes v is in range 0.0-1.0, but clamps
  ## the value to avoid out of domain errors
  ## due to rounding issues
  return arccos(clamp(v,-1.0,1.0))

template makeBinOpVector(s:expr)= 
  ## implements binary operators + , - , * and / for vectors
  proc s*(a,b:TVector3d):TVector3d {.inline,noInit.} = 
    vector3d(s(a.x,b.x),s(a.y,b.y),s(a.z,b.z))
  proc s*(a:TVector3d,b:float):TVector3d {.inline,noInit.}  = 
    vector3d(s(a.x,b),s(a.y,b),s(a.z,b))
  proc s*(a:float,b:TVector3d):TVector3d {.inline,noInit.}  = 
    vector3d(s(a,b.x),s(a,b.y),s(a,b.z))
  
template makeBinOpAssignVector(s:expr)= 
  ## implements inplace binary operators += , -= , /= and *= for vectors
  proc s*(a:var TVector3d,b:TVector3d) {.inline.} = 
    s(a.x,b.x) ; s(a.y,b.y) ; s(a.z,b.z)
  proc s*(a:var TVector3d,b:float) {.inline.} = 
    s(a.x,b) ; s(a.y,b) ; s(a.z,b)



# ***************************************
#     TMatrix3d implementation
# ***************************************

proc setElements*(t:var TMatrix3d,ax,ay,az,aw,bx,by,bz,bw,cx,cy,cz,cw,tx,ty,tz,tw:float) {.inline.}=
  ## Sets arbitrary elements in an exisitng matrix.
  t.ax=ax
  t.ay=ay
  t.az=az
  t.aw=aw
  t.bx=bx
  t.by=by
  t.bz=bz
  t.bw=bw
  t.cx=cx
  t.cy=cy
  t.cz=cz
  t.cw=cw
  t.tx=tx
  t.ty=ty
  t.tz=tz
  t.tw=tw

proc matrix3d*(ax,ay,az,aw,bx,by,bz,bw,cx,cy,cz,cw,tx,ty,tz,tw:float):TMatrix3d =
  result.setElements(ax,ay,az,aw,bx,by,bz,bw,cx,cy,cz,cw,tx,ty,tz,tw)

proc `&`*(a,b:TMatrix3d):TMatrix3d {.noinit.} =
  ## Concatenates matrices returning a new matrix.
  result.setElements(
    a.aw*b.tx+a.az*b.cx+a.ay*b.bx+a.ax*b.ax,
    a.aw*b.ty+a.az*b.cy+a.ay*b.by+a.ax*b.ay,
    a.aw*b.tz+a.az*b.cz+a.ay*b.bz+a.ax*b.az,
    a.aw*b.tw+a.az*b.cw+a.ay*b.bw+a.ax*b.aw,

    a.bw*b.tx+a.bz*b.cx+a.by*b.bx+a.bx*b.ax,
    a.bw*b.ty+a.bz*b.cy+a.by*b.by+a.bx*b.ay,
    a.bw*b.tz+a.bz*b.cz+a.by*b.bz+a.bx*b.az,
    a.bw*b.tw+a.bz*b.cw+a.by*b.bw+a.bx*b.aw,

    a.cw*b.tx+a.cz*b.cx+a.cy*b.bx+a.cx*b.ax,
    a.cw*b.ty+a.cz*b.cy+a.cy*b.by+a.cx*b.ay,
    a.cw*b.tz+a.cz*b.cz+a.cy*b.bz+a.cx*b.az,
    a.cw*b.tw+a.cz*b.cw+a.cy*b.bw+a.cx*b.aw,

    a.tw*b.tx+a.tz*b.cx+a.ty*b.bx+a.tx*b.ax,
    a.tw*b.ty+a.tz*b.cy+a.ty*b.by+a.tx*b.ay,
    a.tw*b.tz+a.tz*b.cz+a.ty*b.bz+a.tx*b.az,
    a.tw*b.tw+a.tz*b.cw+a.ty*b.bw+a.tx*b.aw)


proc scale*(s:float):TMatrix3d {.noInit.} =
  ## Returns a new scaling matrix.
  result.setElements(s,0,0,0, 0,s,0,0, 0,0,s,0, 0,0,0,1)

proc scale*(s:float,org:TPoint3d):TMatrix3d {.noInit.} =
  ## Returns a new scaling matrix using, `org` as scale origin.
  result.setElements(s,0,0,0, 0,s,0,0, 0,0,s,0, 
    org.x-s*org.x,org.y-s*org.y,org.z-s*org.z,1.0)

proc stretch*(sx,sy,sz:float):TMatrix3d {.noInit.} =
  ## Returns new a stretch matrix, which is a
  ## scale matrix with non uniform scale in x,y and z.
  result.setElements(sx,0,0,0, 0,sy,0,0, 0,0,sz,0, 0,0,0,1)
    
proc stretch*(sx,sy,sz:float,org:TPoint3d):TMatrix3d {.noInit.} =
  ## Returns a new stretch matrix, which is a
  ## scale matrix with non uniform scale in x,y and z.
  ## `org` is used as stretch origin.
  result.setElements(sx,0,0,0, 0,sy,0,0, 0,0,sz,0, org.x-sx*org.x,org.y-sy*org.y,org.z-sz*org.z,1)
    
proc move*(dx,dy,dz:float):TMatrix3d {.noInit.} =
  ## Returns a new translation matrix.
  result.setElements(1,0,0,0, 0,1,0,0, 0,0,1,0, dx,dy,dz,1)

proc move*(v:TVector3d):TMatrix3d {.noInit.} =
  ## Returns a new translation matrix from a vector.
  result.setElements(1,0,0,0, 0,1,0,0, 0,0,1,0, v.x,v.y,v.z,1)


proc rotate*(angle:float,axis:TVector3d):TMatrix3d {.noInit.}=
  ## Creates a rotation matrix that rotates `angle` radians over
  ## `axis`, which passes through origo.

  # see PDF document http://inside.mines.edu/~gmurray/ArbitraryAxisRotation/ArbitraryAxisRotation.pdf
  # for how this is computed

  var normax=axis
  if not normax.tryNormalize: #simplifies matrix computation below a lot
    raise newException(DivByZeroError,"Cannot rotate around zero length axis")

  let
    cs=cos(angle)
    si=sin(angle)
    omc=1.0-cs
    usi=normax.x*si
    vsi=normax.y*si
    wsi=normax.z*si
    u2=normax.x*normax.x
    v2=normax.y*normax.y
    w2=normax.z*normax.z
    uvomc=normax.x*normax.y*omc
    uwomc=normax.x*normax.z*omc
    vwomc=normax.y*normax.z*omc
    
  result.setElements(
    u2+(1.0-u2)*cs, uvomc+wsi, uwomc-vsi, 0.0,
    uvomc-wsi, v2+(1.0-v2)*cs, vwomc+usi, 0.0,
    uwomc+vsi, vwomc-usi, w2+(1.0-w2)*cs, 0.0,
    0.0,0.0,0.0,1.0)

proc rotate*(angle:float,org:TPoint3d,axis:TVector3d):TMatrix3d {.noInit.}=
  ## Creates a rotation matrix that rotates `angle` radians over
  ## `axis`, which passes through `org`.

  # see PDF document http://inside.mines.edu/~gmurray/ArbitraryAxisRotation/ArbitraryAxisRotation.pdf
  # for how this is computed
  
  var normax=axis
  if not normax.tryNormalize: #simplifies matrix computation below a lot
    raise newException(DivByZeroError,"Cannot rotate around zero length axis")
  
  let
    u=normax.x
    v=normax.y
    w=normax.z
    u2=u*u
    v2=v*v
    w2=w*w
    cs=cos(angle)
    omc=1.0-cs
    si=sin(angle)
    a=org.x
    b=org.y
    c=org.z
    usi=u*si
    vsi=v*si
    wsi=w*si
    uvomc=normax.x*normax.y*omc
    uwomc=normax.x*normax.z*omc
    vwomc=normax.y*normax.z*omc
    
  result.setElements(
    u2+(v2+w2)*cs, uvomc+wsi, uwomc-vsi, 0.0,
    uvomc-wsi, v2+(u2+w2)*cs, vwomc+usi, 0.0,
    uwomc+vsi, vwomc-usi, w2+(u2+v2)*cs, 0.0,
    (a*(v2+w2)-u*(b*v+c*w))*omc+(b*w-c*v)*si,
    (b*(u2+w2)-v*(a*u+c*w))*omc+(c*u-a*w)*si,
    (c*(u2+v2)-w*(a*u+b*v))*omc+(a*v-b*u)*si,1.0)


proc rotateX*(angle:float):TMatrix3d {.noInit.}=
  ## Creates a matrix that rotates around the x-axis with `angle` radians,
  ## which is also called a 'roll' matrix.
  let
    c=cos(angle)
    s=sin(angle)
  result.setElements(
    1,0,0,0,
    0,c,s,0,
    0,-s,c,0,
    0,0,0,1)

proc rotateY*(angle:float):TMatrix3d {.noInit.}=
  ## Creates a matrix that rotates around the y-axis with `angle` radians,
  ## which is also called a 'pitch' matrix.
  let
    c=cos(angle)
    s=sin(angle)
  result.setElements(
    c,0,-s,0,
    0,1,0,0,
    s,0,c,0,
    0,0,0,1)
    
proc rotateZ*(angle:float):TMatrix3d {.noInit.}=
  ## Creates a matrix that rotates around the z-axis with `angle` radians,
  ## which is also called a 'yaw' matrix.
  let
    c=cos(angle)
    s=sin(angle)
  result.setElements(
    c,s,0,0,
    -s,c,0,0,
    0,0,1,0,
    0,0,0,1)
    
proc isUniform*(m:TMatrix3d,tol=1.0e-6):bool=
  ## Checks if the transform is uniform, that is 
  ## perpendicular axes of equal length, which means (for example)
  ## it cannot transform a sphere into an ellipsoid.
  ## `tol` is used as tolerance for both equal length comparison 
  ## and perpendicular comparison.
  
  #dot product=0 means perpendicular coord. system, check xaxis vs yaxis and  xaxis vs zaxis
  if abs(m.ax*m.bx+m.ay*m.by+m.az*m.bz)<=tol and # x vs y
    abs(m.ax*m.cx+m.ay*m.cy+m.az*m.cz)<=tol and #x vs z
    abs(m.bx*m.cx+m.by*m.cy+m.bz*m.cz)<=tol: #y vs z
    
    #subtract squared lengths of axes to check if uniform scaling:
    let
      sqxlen=(m.ax*m.ax+m.ay*m.ay+m.az*m.az)
      sqylen=(m.bx*m.bx+m.by*m.by+m.bz*m.bz)
      sqzlen=(m.cx*m.cx+m.cy*m.cy+m.cz*m.cz)
    if abs(sqxlen-sqylen)<=tol and abs(sqxlen-sqzlen)<=tol:
      return true
  return false


    
proc mirror*(planeperp:TVector3d):TMatrix3d {.noInit.}=
  ## Creates a matrix that mirrors over the plane that has `planeperp` as normal,
  ## and passes through origo. `planeperp` does not need to be normalized.
  
  # https://en.wikipedia.org/wiki/Transformation_matrix
  var n=planeperp
  if not n.tryNormalize:
    raise newException(DivByZeroError,"Cannot mirror over a plane with a zero length normal")
  
  let
    a=n.x
    b=n.y
    c=n.z
    ab=a*b
    ac=a*c
    bc=b*c
  
  result.setElements(
    1-2*a*a , -2*ab,-2*ac,0,
    -2*ab , 1-2*b*b, -2*bc, 0,
    -2*ac, -2*bc, 1-2*c*c,0,
    0,0,0,1)


proc mirror*(org:TPoint3d,planeperp:TVector3d):TMatrix3d {.noInit.}=
  ## Creates a matrix that mirrors over the plane that has `planeperp` as normal,
  ## and passes through `org`. `planeperp` does not need to be normalized.

  # constructs a mirror M like the simpler mirror matrix constructor
  # above but premultiplies with the inverse traslation of org
  # and postmultiplies with the translation of org.
  # With some fiddling this becomes reasonably simple:
  var n=planeperp
  if not n.tryNormalize:
    raise newException(DivByZeroError,"Cannot mirror over a plane with a zero length normal")
  
  let
    a=n.x
    b=n.y
    c=n.z
    ab=a*b
    ac=a*c
    bc=b*c
    aa=a*a
    bb=b*b
    cc=c*c
    tx=org.x
    ty=org.y
    tz=org.z
  
  result.setElements(
    1-2*aa , -2*ab,-2*ac,0,
    -2*ab , 1-2*bb, -2*bc, 0,
    -2*ac, -2*bc, 1-2*cc,0,
    2*(ac*tz+ab*ty+aa*tx),
    2*(bc*tz+bb*ty+ab*tx),
    2*(cc*tz+bc*ty+ac*tx) ,1)


proc determinant*(m:TMatrix3d):float=
  ## Computes the determinant of matrix `m`.
  
  # This computation is gotten from ratsimp(optimize(determinant(m))) 
  # in maxima CAS
  let
    O1=m.cx*m.tw-m.cw*m.tx
    O2=m.cy*m.tw-m.cw*m.ty
    O3=m.cx*m.ty-m.cy*m.tx
    O4=m.cz*m.tw-m.cw*m.tz
    O5=m.cx*m.tz-m.cz*m.tx
    O6=m.cy*m.tz-m.cz*m.ty

  return (O1*m.ay-O2*m.ax-O3*m.aw)*m.bz+
    (-O1*m.az+O4*m.ax+O5*m.aw)*m.by+
    (O2*m.az-O4*m.ay-O6*m.aw)*m.bx+
    (O3*m.az-O5*m.ay+O6*m.ax)*m.bw


proc inverse*(m:TMatrix3d):TMatrix3d {.noInit.}=
  ## Computes the inverse of matrix `m`. If the matrix
  ## determinant is zero, thus not invertible, a EDivByZero
  ## will be raised.
  
  # this computation comes from optimize(invert(m)) in maxima CAS
  
  let 
    det=m.determinant
    O2=m.cy*m.tw-m.cw*m.ty
    O3=m.cz*m.tw-m.cw*m.tz
    O4=m.cy*m.tz-m.cz*m.ty
    O5=m.by*m.tw-m.bw*m.ty
    O6=m.bz*m.tw-m.bw*m.tz
    O7=m.by*m.tz-m.bz*m.ty
    O8=m.by*m.cw-m.bw*m.cy
    O9=m.bz*m.cw-m.bw*m.cz
    O10=m.by*m.cz-m.bz*m.cy
    O11=m.cx*m.tw-m.cw*m.tx
    O12=m.cx*m.tz-m.cz*m.tx
    O13=m.bx*m.tw-m.bw*m.tx
    O14=m.bx*m.tz-m.bz*m.tx
    O15=m.bx*m.cw-m.bw*m.cx
    O16=m.bx*m.cz-m.bz*m.cx
    O17=m.cx*m.ty-m.cy*m.tx
    O18=m.bx*m.ty-m.by*m.tx
    O19=m.bx*m.cy-m.by*m.cx

  if det==0.0:
    raise newException(DivByZeroError,"Cannot normalize zero length vector")

  result.setElements(
    (m.bw*O4+m.by*O3-m.bz*O2)/det    , (-m.aw*O4-m.ay*O3+m.az*O2)/det,
    (m.aw*O7+m.ay*O6-m.az*O5)/det    , (-m.aw*O10-m.ay*O9+m.az*O8)/det,
    (-m.bw*O12-m.bx*O3+m.bz*O11)/det , (m.aw*O12+m.ax*O3-m.az*O11)/det,
    (-m.aw*O14-m.ax*O6+m.az*O13)/det , (m.aw*O16+m.ax*O9-m.az*O15)/det,
    (m.bw*O17+m.bx*O2-m.by*O11)/det  , (-m.aw*O17-m.ax*O2+m.ay*O11)/det,
    (m.aw*O18+m.ax*O5-m.ay*O13)/det  , (-m.aw*O19-m.ax*O8+m.ay*O15)/det,
    (-m.bx*O4+m.by*O12-m.bz*O17)/det , (m.ax*O4-m.ay*O12+m.az*O17)/det,
    (-m.ax*O7+m.ay*O14-m.az*O18)/det , (m.ax*O10-m.ay*O16+m.az*O19)/det)


proc equals*(m1:TMatrix3d,m2:TMatrix3d,tol=1.0e-6):bool=
  ## Checks if all elements of `m1`and `m2` is equal within
  ## a given tolerance `tol`.
  return 
    abs(m1.ax-m2.ax)<=tol and
    abs(m1.ay-m2.ay)<=tol and
    abs(m1.az-m2.az)<=tol and
    abs(m1.aw-m2.aw)<=tol and
    abs(m1.bx-m2.bx)<=tol and
    abs(m1.by-m2.by)<=tol and
    abs(m1.bz-m2.bz)<=tol and
    abs(m1.bw-m2.bw)<=tol and
    abs(m1.cx-m2.cx)<=tol and
    abs(m1.cy-m2.cy)<=tol and
    abs(m1.cz-m2.cz)<=tol and
    abs(m1.cw-m2.cw)<=tol and
    abs(m1.tx-m2.tx)<=tol and
    abs(m1.ty-m2.ty)<=tol and
    abs(m1.tz-m2.tz)<=tol and
    abs(m1.tw-m2.tw)<=tol

proc `=~`*(m1,m2:TMatrix3d):bool=
  ## Checks if `m1` and `m2` is approximately equal, using a
  ## tolerance of 1e-6.
  equals(m1,m2)
  
proc transpose*(m:TMatrix3d):TMatrix3d {.noInit.}=
  ## Returns the transpose of `m`
  result.setElements(m.ax,m.bx,m.cx,m.tx,m.ay,m.by,m.cy,m.ty,m.az,m.bz,m.cz,m.tz,m.aw,m.bw,m.cw,m.tw)
  
proc getXAxis*(m:TMatrix3d):TVector3d {.noInit.}=
  ## Gets the local x axis of `m`
  result.x=m.ax
  result.y=m.ay
  result.z=m.az

proc getYAxis*(m:TMatrix3d):TVector3d {.noInit.}=
  ## Gets the local y axis of `m`
  result.x=m.bx
  result.y=m.by
  result.z=m.bz

proc getZAxis*(m:TMatrix3d):TVector3d {.noInit.}=
  ## Gets the local y axis of `m`
  result.x=m.cx
  result.y=m.cy
  result.z=m.cz

    
proc `$`*(m:TMatrix3d):string=
  ## String representation of `m`
  return rtos(m.ax) & "," & rtos(m.ay) & "," &rtos(m.az) & "," & rtos(m.aw) &
    "\n" & rtos(m.bx) & "," & rtos(m.by) & "," &rtos(m.bz) & "," & rtos(m.bw) &
    "\n" & rtos(m.cx) & "," & rtos(m.cy) & "," &rtos(m.cz) & "," & rtos(m.cw) &
    "\n" & rtos(m.tx) & "," & rtos(m.ty) & "," &rtos(m.tz) & "," & rtos(m.tw)
    
proc apply*(m:TMatrix3d, x,y,z:var float, translate=false)=
  ## Applies transformation `m` onto `x` , `y` , `z` , optionally
  ## using the translation part of the matrix.
  let 
    oldx=x
    oldy=y
    oldz=z
    
  x=m.cx*oldz+m.bx*oldy+m.ax*oldx
  y=m.cy*oldz+m.by*oldy+m.ay*oldx
  z=m.cz*oldz+m.bz*oldy+m.az*oldx
    
  if translate:
    x+=m.tx
    y+=m.ty
    z+=m.tz

# ***************************************
#     TVector3d implementation
# ***************************************
proc vector3d*(x,y,z:float):TVector3d=
  result.x=x
  result.y=y
  result.z=z

proc len*(v:TVector3d):float=
  ## Returns the length of the vector `v`.
  sqrt(v.x*v.x+v.y*v.y+v.z*v.z)

proc `len=`*(v:var TVector3d,newlen:float) {.noInit.} =
  ## Sets the length of the vector, keeping its direction.
  ## If the vector has zero length before changing it's length,
  ## an arbitrary vector of the requested length is returned.

  let fac=newlen/v.len
  
  if newlen==0.0:
    v.x=0.0
    v.y=0.0
    v.z=0.0
    return
  
  if fac==Inf or fac==NegInf:
    #to short for float accuracy
    #do as good as possible:
    v.x=newlen
    v.y=0.0
    v.z=0.0
  else:
    v.x*=fac
    v.y*=fac
    v.z*=fac


proc sqrLen*(v:TVector3d):float {.inline.}=
  ## Computes the squared length of the vector, which is
  ## faster than computing the absolute length.
  return v.x*v.x+v.y*v.y+v.z*v.z

proc `$` *(v:TVector3d):string=
  ## String representation of `v`
  result=rtos(v.x)
  result.add(",")
  result.add(rtos(v.y))
  result.add(",")
  result.add(rtos(v.z))

proc `&` *(v:TVector3d,m:TMatrix3d):TVector3d {.noInit.} =
  ## Concatenate vector `v` with a transformation matrix.
  ## Transforming a vector ignores the translational part
  ## of the matrix.
  
  #               | AX AY AZ AW |
  # | X Y Z 1 | * | BX BY BZ BW |
  #               | CX CY CZ CW |
  #               | 0  0  0  1 |
  let
    newx=m.cx*v.z+m.bx*v.y+m.ax*v.x
    newy=m.cy*v.z+m.by*v.y+m.ay*v.x
  result.z=m.cz*v.z+m.bz*v.y+m.az*v.x
  result.y=newy
  result.x=newx


proc `&=` *(v:var TVector3d,m:TMatrix3d) {.noInit.} =
  ## Applies transformation `m` onto `v` in place.
  ## Transforming a vector ignores the translational part
  ## of the matrix.
  
  #               | AX AY AZ AW |
  # | X Y Z 1 | * | BX BY BZ BW |
  #               | CX CY CZ CW |
  #               | 0  0  0  1  |
  
  let
    newx=m.cx*v.z+m.bx*v.y+m.ax*v.x
    newy=m.cy*v.z+m.by*v.y+m.ay*v.x
  v.z=m.cz*v.z+m.bz*v.y+m.az*v.x
  v.y=newy
  v.x=newx

proc transformNorm*(v:var TVector3d,m:TMatrix3d)=
  ## Applies a normal direction transformation `m` onto `v` in place.
  ## The resulting vector is *not* normalized.  Transforming a vector ignores the 
  ## translational part of the matrix. If the matrix is not invertible 
  ## (determinant=0), an EDivByZero will be raised.

  # transforming a normal is done by transforming
  # by the transpose of the inverse of the original matrix
  
  # Major reason this simple function is here is that this function can be optimized in the future,
  # (possibly by hardware) as well as having a consistent API with the 2d version.
  v&=transpose(inverse(m))
  
proc transformInv*(v:var TVector3d,m:TMatrix3d)=
  ## Applies the inverse of `m` on vector `v`. Transforming a vector ignores 
  ## the translational part of the matrix.  Transforming a vector ignores the 
  ## translational part of the matrix.
  ## If the matrix is not invertible (determinant=0), an EDivByZero
  ## will be raised.
  
  # Major reason this simple function is here is that this function can be optimized in the future,
  # (possibly by hardware) as well as having a consistent API with the 2d version.
  v&=m.inverse
 
proc transformNormInv*(vec:var TVector3d,m:TMatrix3d)=
  ## Applies an inverse normal direction transformation `m` onto `v` in place.
  ## This is faster than creating an inverse 
  ## matrix and transformNorm(...) it. Transforming a vector ignores the 
  ## translational part of the matrix.
  
  # see vector2d:s equivalent for a deeper look how/why this works
  vec&=m.transpose

proc tryNormalize*(v:var TVector3d):bool= 
  ## Modifies `v` to have a length of 1.0, keeping its angle.
  ## If `v` has zero length (and thus no angle), it is left unmodified and false is
  ## returned, otherwise true is returned.
  let mag=v.len

  if mag==0.0:
    return false

  v.x/=mag
  v.y/=mag
  v.z/=mag
  
  return true

proc normalize*(v:var TVector3d) {.inline.}= 
  ## Modifies `v` to have a length of 1.0, keeping its angle.
  ## If  `v` has zero length, an EDivByZero will be raised.
  if not tryNormalize(v):
    raise newException(DivByZeroError,"Cannot normalize zero length vector")

proc rotate*(vec:var TVector3d,angle:float,axis:TVector3d)=
  ## Rotates `vec` in place, with `angle` radians over `axis`, which passes 
  ## through origo.

  # see PDF document http://inside.mines.edu/~gmurray/ArbitraryAxisRotation/ArbitraryAxisRotation.pdf
  # for how this is computed
  
  var normax=axis
  if not normax.tryNormalize:
    raise newException(DivByZeroError,"Cannot rotate around zero length axis")
  
  let
    cs=cos(angle)
    si=sin(angle)
    omc=1.0-cs
    u=normax.x
    v=normax.y
    w=normax.z
    x=vec.x
    y=vec.y
    z=vec.z
    uxyzomc=(u*x+v*y+w*z)*omc
  
  vec.x=u*uxyzomc+x*cs+(v*z-w*y)*si
  vec.y=v*uxyzomc+y*cs+(w*x-u*z)*si
  vec.z=w*uxyzomc+z*cs+(u*y-v*x)*si
  
proc scale*(v:var TVector3d,s:float)=
  ## Scales the vector in place with factor `s`
  v.x*=s
  v.y*=s
  v.z*=s

proc stretch*(v:var TVector3d,sx,sy,sz:float)=
  ## Scales the vector non uniformly with factors `sx` , `sy` , `sz`
  v.x*=sx
  v.y*=sy
  v.z*=sz

proc mirror*(v:var TVector3d,planeperp:TVector3d)=
  ## Computes the mirrored vector of `v` over the plane
  ## that has `planeperp` as normal direction. 
  ## `planeperp` does not need to be normalized.
  
  var n=planeperp
  n.normalize
  
  let
    x=v.x
    y=v.y
    z=v.z
    a=n.x
    b=n.y
    c=n.z
    ac=a*c
    ab=a*b
    bc=b*c
  
  v.x= -2*(ac*z+ab*y+a*a*x)+x
  v.y= -2*(bc*z+b*b*y+ab*x)+y
  v.z= -2*(c*c*z+bc*y+ac*x)+z


proc `-` *(v:TVector3d):TVector3d=
  ## Negates a vector
  result.x= -v.x
  result.y= -v.y
  result.z= -v.z
    
# declare templated binary operators
makeBinOpVector(`+`)
makeBinOpVector(`-`)
makeBinOpVector(`*`)
makeBinOpVector(`/`)
makeBinOpAssignVector(`+=`)
makeBinOpAssignVector(`-=`)
makeBinOpAssignVector(`*=`)
makeBinOpAssignVector(`/=`)

proc dot*(v1,v2:TVector3d):float {.inline.}=
  ## Computes the dot product of two vectors. 
  ## Returns 0.0 if the vectors are perpendicular.
  return v1.x*v2.x+v1.y*v2.y+v1.z*v2.z

proc cross*(v1,v2:TVector3d):TVector3d {.inline.}=
  ## Computes the cross product of two vectors.
  ## The result is a vector which is perpendicular
  ## to the plane of `v1` and `v2`, which means
  ## cross(xaxis,yaxis)=zaxis. The magnitude of the result is
  ## zero if the vectors are colinear.
  result.x = (v1.y * v2.z) - (v2.y * v1.z)
  result.y = (v1.z * v2.x) - (v2.z * v1.x)
  result.z = (v1.x * v2.y) - (v2.x * v1.y)

proc equals*(v1,v2:TVector3d,tol=1.0e-6):bool=
  ## Checks if two vectors approximately equals with a tolerance.
  return abs(v2.x-v1.x)<=tol and abs(v2.y-v1.y)<=tol and abs(v2.z-v1.z)<=tol
  
proc `=~` *(v1,v2:TVector3d):bool=
  ## Checks if two vectors approximately equals with a 
  ## hardcoded tolerance 1e-6
  equals(v1,v2)
  
proc angleTo*(v1,v2:TVector3d):float=
  ## Returns the smallest angle between v1 and v2,
  ## which is in range 0-PI
  var
    nv1=v1
    nv2=v2
  if not nv1.tryNormalize or not nv2.tryNormalize:
    return 0.0 # zero length vector has zero angle to any other vector
  return safeArccos(dot(nv1,nv2))

proc arbitraryAxis*(norm:TVector3d):TMatrix3d {.noInit.}=
  ## Computes the rotation matrix that would transform
  ## world z vector into `norm`. The inverse of this matrix
  ## is useful to transform a planar 3d object to 2d space.
  ## This is the same algorithm used to interpret DXF and DWG files.
  const lim=1.0/64.0
  var ax,ay,az:TVector3d
  if abs(norm.x)<lim and abs(norm.y)<lim:
    ax=cross(YAXIS,norm)
  else:
    ax=cross(ZAXIS,norm)

  ax.normalize()
  ay=cross(norm,ax)
  ay.normalize()
  az=cross(ax,ay)
  
  result.setElements(
    ax.x,ax.y,ax.z,0.0,
    ay.x,ay.y,ay.z,0.0,
    az.x,az.y,az.z,0.0,
    0.0,0.0,0.0,1.0)

proc bisect*(v1,v2:TVector3d):TVector3d {.noInit.}=
  ## Computes the bisector between v1 and v2 as a normalized vector.
  ## If one of the input vectors has zero length, a normalized version
  ## of the other is returned. If both input vectors has zero length, 
  ## an arbitrary normalized vector `v1` is returned.
  var
    vmag1=v1.len
    vmag2=v2.len
    
  # zero length vector equals arbitrary vector, just change 
  # magnitude to one to avoid zero division
  if vmag1==0.0: 
    if vmag2==0: #both are zero length return any normalized vector
      return XAXIS
    vmag1=1.0
  if vmag2==0.0: vmag2=1.0    
    
  let
    x1=v1.x/vmag1
    y1=v1.y/vmag1
    z1=v1.z/vmag1
    x2=v2.x/vmag2
    y2=v2.y/vmag2
    z2=v2.z/vmag2
    
  result.x=(x1 + x2) * 0.5
  result.y=(y1 + y2) * 0.5
  result.z=(z1 + z2) * 0.5
  
  if not result.tryNormalize():
    # This can happen if vectors are colinear. In this special case
    # there are actually inifinitely many bisectors, we select just 
    # one of them.
    result=v1.cross(XAXIS)
    if result.sqrLen<1.0e-9:
      result=v1.cross(YAXIS)
      if result.sqrLen<1.0e-9:
        result=v1.cross(ZAXIS) # now we should be guaranteed to have succeeded
    result.normalize



# ***************************************
#     TPoint3d implementation
# ***************************************
proc point3d*(x,y,z:float):TPoint3d=
  result.x=x
  result.y=y
  result.z=z
 
proc sqrDist*(a,b:TPoint3d):float=
  ## Computes the squared distance between `a`and `b`
  let dx=b.x-a.x
  let dy=b.y-a.y
  let dz=b.z-a.z
  result=dx*dx+dy*dy+dz*dz
  
proc dist*(a,b:TPoint3d):float {.inline.}=
  ## Computes the absolute distance between `a`and `b`
  result=sqrt(sqrDist(a,b))

proc `$` *(p:TPoint3d):string=
  ## String representation of `p`
  result=rtos(p.x)
  result.add(",")
  result.add(rtos(p.y))
  result.add(",")
  result.add(rtos(p.z))
  
proc `&`*(p:TPoint3d,m:TMatrix3d):TPoint3d=
  ## Concatenates a point `p` with a transform `m`,
  ## resulting in a new, transformed point.
  result.z=m.cz*p.z+m.bz*p.y+m.az*p.x+m.tz
  result.y=m.cy*p.z+m.by*p.y+m.ay*p.x+m.ty
  result.x=m.cx*p.z+m.bx*p.y+m.ax*p.x+m.tx

proc `&=` *(p:var TPoint3d,m:TMatrix3d)=
  ## Applies transformation `m` onto `p` in place.
  let
    x=p.x
    y=p.y
    z=p.z
  p.x=m.cx*z+m.bx*y+m.ax*x+m.tx
  p.y=m.cy*z+m.by*y+m.ay*x+m.ty
  p.z=m.cz*z+m.bz*y+m.az*x+m.tz
    
proc transformInv*(p:var TPoint3d,m:TMatrix3d)=
  ## Applies the inverse of transformation `m` onto `p` in place.
  ## If the matrix is not invertable (determinant=0) , EDivByZero will
  ## be raised.
  
  # can possibly be more optimized in the future so use this function when possible
  p&=inverse(m)


proc `+`*(p:TPoint3d,v:TVector3d):TPoint3d {.noInit,inline.} =
  ## Adds a vector `v` to a point `p`, resulting 
  ## in a new point.
  result.x=p.x+v.x
  result.y=p.y+v.y
  result.z=p.z+v.z

proc `+=`*(p:var TPoint3d,v:TVector3d) {.noInit,inline.} =
  ## Adds a vector `v` to a point `p` in place.
  p.x+=v.x
  p.y+=v.y
  p.z+=v.z

proc `-`*(p:TPoint3d,v:TVector3d):TPoint3d {.noInit,inline.} =
  ## Subtracts a vector `v` from a point `p`, resulting 
  ## in a new point.
  result.x=p.x-v.x
  result.y=p.y-v.y
  result.z=p.z-v.z

proc `-`*(p1,p2:TPoint3d):TVector3d {.noInit,inline.} =
  ## Subtracts `p2`from `p1` resulting in a difference vector.
  result.x=p1.x-p2.x
  result.y=p1.y-p2.y
  result.z=p1.z-p2.z

proc `-=`*(p:var TPoint3d,v:TVector3d) {.noInit,inline.} =
  ## Subtracts a vector `v` from a point `p` in place.
  p.x-=v.x
  p.y-=v.y
  p.z-=v.z  

proc equals(p1,p2:TPoint3d,tol=1.0e-6):bool {.inline.}=
  ## Checks if two points approximately equals with a tolerance.
  return abs(p2.x-p1.x)<=tol and abs(p2.y-p1.y)<=tol and abs(p2.z-p1.z)<=tol

proc `=~`*(p1,p2:TPoint3d):bool {.inline.}=
  ## Checks if two vectors approximately equals with a 
  ## hardcoded tolerance 1e-6
  equals(p1,p2)

proc rotate*(p:var TPoint3d,rad:float,axis:TVector3d)=
  ## Rotates point `p` in place `rad` radians about an axis 
  ## passing through origo.
  
  var v=vector3d(p.x,p.y,p.z)
  v.rotate(rad,axis) # reuse this code here since doing the same thing and quite complicated
  p.x=v.x
  p.y=v.y
  p.z=v.z
    
proc rotate*(p:var TPoint3d,angle:float,org:TPoint3d,axis:TVector3d)=
  ## Rotates point `p` in place `rad` radians about an axis 
  ## passing through `org`
  
  # see PDF document http://inside.mines.edu/~gmurray/ArbitraryAxisRotation/ArbitraryAxisRotation.pdf
  # for how this is computed
  
  var normax=axis
  normax.normalize
  
  let
    cs=cos(angle)
    omc=1.0-cs
    si=sin(angle)
    u=normax.x
    v=normax.y
    w=normax.z
    a=org.x
    b=org.y
    c=org.z
    x=p.x
    y=p.y
    z=p.z
    uu=u*u
    vv=v*v
    ww=w*w
    ux=u*p.x
    vy=v*p.y
    wz=w*p.z
    au=a*u
    bv=b*v
    cw=c*w
    uxmvymwz=ux-vy-wz
    
  p.x=(a*(vv+ww)-u*(bv+cw-uxmvymwz))*omc + x*cs + (b*w+v*z-c*v-w*y)*si
  p.y=(b*(uu+ww)-v*(au+cw-uxmvymwz))*omc + y*cs + (c*u-a*w+w*x-u*z)*si
  p.z=(c*(uu+vv)-w*(au+bv-uxmvymwz))*omc + z*cs + (a*v+u*y-b*u-v*x)*si
  
proc scale*(p:var TPoint3d,fac:float) {.inline.}=
  ## Scales a point in place `fac` times with world origo as origin.
  p.x*=fac
  p.y*=fac
  p.z*=fac
  
proc scale*(p:var TPoint3d,fac:float,org:TPoint3d){.inline.}=
  ## Scales the point in place `fac` times with `org` as origin.
  p.x=(p.x - org.x) * fac + org.x
  p.y=(p.y - org.y) * fac + org.y
  p.z=(p.z - org.z) * fac + org.z

proc stretch*(p:var TPoint3d,facx,facy,facz:float){.inline.}=
  ## Scales a point in place non uniformly `facx` , `facy` , `facz` times 
  ## with world origo as origin.
  p.x*=facx
  p.y*=facy
  p.z*=facz

proc stretch*(p:var TPoint3d,facx,facy,facz:float,org:TPoint3d){.inline.}=
  ## Scales the point in place non uniformly `facx` , `facy` , `facz` times
  ## with `org` as origin.
  p.x=(p.x - org.x) * facx + org.x
  p.y=(p.y - org.y) * facy + org.y
  p.z=(p.z - org.z) * facz + org.z
  

proc move*(p:var TPoint3d,dx,dy,dz:float){.inline.}=
  ## Translates a point `dx` , `dy` , `dz` in place.
  p.x+=dx
  p.y+=dy
  p.z+=dz

proc move*(p:var TPoint3d,v:TVector3d){.inline.}=
  ## Translates a point with vector `v` in place.
  p.x+=v.x
  p.y+=v.y
  p.z+=v.z

proc area*(a,b,c:TPoint3d):float {.inline.}=
  ## Computes the area of the triangle thru points `a` , `b` and `c`
  
  # The area of a planar 3d quadliteral is the magnitude of the cross
  # product of two edge vectors. Taking this time 0.5 gives the triangle area.
  return cross(b-a,c-a).len*0.5

