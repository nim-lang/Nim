#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Robert Persson
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import math
import strutils
import numeric


type 
    TPoly* = object
        cofs:seq[float]

  
proc initPolyFromDegree(n:int):TPoly=
  ## internal usage only
  ## caller must initialize coefficients of poly
  ## and possibly  `clean` away zero exponents
  var numcof=n+1   #num. coefficients is one more than degree
  result.cofs=newSeq[float](numcof)
  
proc degree*(p:TPoly):int=
  ## Returns the degree of the polynomial,
  ## that is the number of coefficients-1
  return p.cofs.len-1


proc eval*(p:TPoly,x:float):float=
  ## Evaluates a polynomial function value for `x`
  ## quickly using Horners method
  var n=p.degree
  result=p.cofs[n]
  dec n
  while n>=0:
    result = result*x+p.cofs[n]
    dec n

proc `[]` *(p:TPoly;idx:int):float=
  ## Gets a coefficient of the polynomial.
  ## p[2] will returns the quadric term, p[3] the cubic etc.
  ## Out of bounds index will return 0.0.
  if idx<0 or idx>p.degree:
      return 0.0
  return p.cofs[idx]
    
proc `[]=` *(p:var TPoly;idx:int,v:float)=
  ## Sets an coefficient of the polynomial by index.
  ## p[2] set the quadric term, p[3] the cubic etc.
  ## If index is out of range for the coefficients,
  ## the polynomial grows to the smallest needed degree.
  if idx<0: 
    return

  if idx>p.degree:  #polynomial must grow
    echo("GROW!")
    var oldlen=p.cofs.len
    p.cofs.setLen(idx+1)
    for q in oldlen.. <high(p.cofs):
      p.cofs[q]=0.0 #new-grown coefficients set to zero

  p.cofs[idx]=v
    
      
iterator coefficients*(p:TPoly):float=
  ## Iterates through the corfficients of the polynomial.
  var i=p.degree
  while i>=0:
    yield p[i]
    dec i    
    
proc clean*(p:var TPoly;zerotol=0.0)=
  ## Removes leading zero coefficients of the polynomial.
  ## An optional tolerance can be given for what's considered zero.
  var n=p.degree
  var relen=false

  while n>0 and abs(p[n])<=zerotol:    # >0 => keep at least one coefficient
    dec n
    relen=true

  if relen: p.cofs.setLen(n+1)


proc `$` *(p:TPoly):string = 
  ## Gets a somewhat reasonable string representation of the polynomial
  ## The format should be compatible with most online function plotters,
  ## for example directly in google search
  result=""
  var first=true #might skip + sign if first coefficient
  
  for idx in countdown(p.degree,0):
    var a=p[idx]
    
    if a==0.0:
      continue
    
    if a>= 0.0 and not first:
      result.add('+')
    first=false

    if a!=1.0 or idx==0:
      result=result & formatFloat(a,ffDefault,0)
    if idx>=2:
      result.add("x^" & $idx)
    elif idx==1:
      result.add("x")

  if result=="":
      result="0"
          

proc derivative*(p:TPoly):TPoly=
  ## Returns a new polynomial, which is the derivative of `p`
  newSeq[float](result.cofs,p.degree)
  for idx in 0..high(result.cofs):
    result.cofs[idx]=p.cofs[idx+1]*float(idx+1)
    
proc diff*(p:TPoly,x:float):float=
  ## Evaluates the differentiation of a polynomial with
  ## respect to `x` quickly using a modifed Horners method
  var n=p.degree
  result=p[n]*float(n)
  dec n
  while n>=1:
    result = result*x+p[n]*float(n)
    dec n

proc integral*(p:TPoly):TPoly=
  ## Returns a new polynomial which is the indefinite
  ## integral of `p`. The constant term is set to 0.0
  result=initPolyFromDegree(p.degree+1)
  result.cofs[0]=0.0  #constant arbitrary term, use 0.0
  for i in 1..high(result.cofs):
    result.cofs[i]=p.cofs[i-1]/float(i)
        

proc integrate*(p:TPoly;xmin,xmax:float):float=
  ## Computes the definite integral of `p` between `xmin` and `xmax`
  # TODO: this can be done faster using a modified horners method,
  # see 'diff' function above.
  var igr=p.integral
  result=igr.eval(xmax)-igr.eval(xmin)

proc initPoly*(cofs:varargs[float]):TPoly=
  ## Initializes a polynomial with given coefficients.
  ## The most significant coefficient is first, so to create x^2-2x+3:
  ## intiPoly(1.0,-2.0,3.0)
  if len(cofs)<=0:
      result.cofs= @[0.0]  #need at least one coefficient
  else:
    # reverse order of coefficients so indexing matches degree of
    # coefficient...
    result.cofs= @[]
    for idx in countdown(cofs.len-1,0):  
      result.cofs.add(cofs[idx])

  result.clean #remove leading zero terms


proc divMod*(p,d:TPoly;q,r:var TPoly)=
  ## Divides `p` with `d`, and stores the quotinent in `q` and
  ## the remainder in `d`
  var 
    pdeg=p.degree
    ddeg=d.degree
    power=p.degree-d.degree
    ratio:float
  
  if power<0: #denominator is larger than numerator
    q=initPoly(0.0) #division result is 0
    r=p #remainder is numerator
    return 
      
  q=initPolyFromDegree(power)
  r=p
  
  for i in countdown(pdeg,ddeg):
    ratio=r[i]/d[ddeg]
    
    q[i-ddeg]=ratio
    r[i]=0.0
    
    for j in countup(0,<ddeg):
        var idx=i-ddeg+j
        r[idx] = r[idx] - d[j]*ratio
     
  r.clean # drop zero coefficients in remainder
 

        
proc `+` *(p1:TPoly,p2:TPoly):TPoly=
  ## Adds two polynomials
  var n=max(p1.cofs.len,p2.cofs.len)
  newSeq(result.cofs,n)
  
  for idx in countup(0,n-1):
      result[idx]=p1[idx]+p2[idx]
      
  result.clean # drop zero coefficients in remainder
    
proc `*` *(p1:TPoly,p2:TPoly):TPoly=
  ## Multiplies the polynomial `p1` with `p2`
  var 
    d1=p1.degree
    d2=p2.degree
    n=d1+d2
    idx:int
      
  newSeq(result.cofs,n)

  for i1 in countup(0,d1):
    for i2 in countup(0,d2):
      idx=i1+i2
      result[idx]=result[idx]+p1[i1]*p2[i2]

  result.clean

proc `*` *(p:TPoly,f:float):TPoly=
  ## Multiplies the polynomial `p` with a real number
  result=initPolyFromDegree(p.degree)
  for i in 0..high(p.cofs):
    result[i]=p.cofs[i]*f
  result.clean
  
proc `*` *(f:float,p:TPoly):TPoly=
  ## Multiplies a real number with a polynomial
  return p*f
    
proc `-`*(p:TPoly):TPoly=
  ## Negates a polynomial
  result=p
  for i in countup(0,<result.cofs.len):
    result.cofs[i]= -result.cofs[i]
    
proc `-` *(p1:TPoly,p2:TPoly):TPoly=
  ## Subtract `p1` with `p2`
  var n=max(p1.cofs.len,p2.cofs.len)
  newSeq(result.cofs,n)
  
  for idx in countup(0,n-1):
      result[idx]=p1[idx]-p2[idx]
      
  result.clean # drop zero coefficients in remainder
    
proc `/`*(p:TPoly,f:float):TPoly=
  ## Divides polynomial `p`with real number `f`
  result=initPolyFromDegree(p.degree)
  for i in 0..high(p.cofs):
    result[i]=p.cofs[i]/f
  result.clean
  
proc `/` *(p,q:TPoly):TPoly=
  ## Divides polynomial `p` with polynomial `q`
  var dummy:TPoly
  p.divMod(q,result,dummy)  

proc `mod` *(p,q:TPoly):TPoly=
  ## computes the polynomial modulo operation,
  ## that is the remainder op `p`/`q`
  var dummy:TPoly
  p.divMod(q,dummy,result)


proc normalize*(p:var TPoly)=
  ## Multiplies the polynomial inplace by a term so that
  ## the leading term is 1.0.
  ## This might lead to an unstable polynomial
  ## if the leading term is zero.
  p=p/p[p.degree]


proc solveQuadric*(a,b,c:float;zerotol=0.0):seq[float]=
  ## Solves the quadric equation `ax^2+bx+c`, with a possible
  ## tolerance `zerotol` to find roots of curves just 'touching'
  ## the x axis. Returns sequence with 1 or 2 solutions, or nil
  ## in case of no real solution.
  result=nil
  
  var p,q,d:float
  
  p=b/(2.0*a)
  
  if p==inf or p==neginf: #linear equation..
    var linrt= -c/b
    if linrt==inf or linrt==neginf: #constant only
      return nil
    return @[linrt]
  
  q=c/a
  d=p*p-q
  
  if d<0.0:
    #check for inside zerotol range for neg. roots
    var err=a*p*p-b*p+c #evaluate error at parabola center axis
    if(err<=zerotol): return @[-p]
    return nil
  else:
    var sr=sqrt(d)
    result= @[-sr-p,sr-p]

proc getRangeForRoots(p:TPoly;xmin,xmax:var float)=
  ## helper function for `roots` function
  ## quickly computes a range, guaranteed to contain
  ## all the real roots of the polynomial
  # see http://www.mathsisfun.com/algebra/polynomials-bounds-zeros.html

  var deg=p.degree
  var d=p[deg]
  var bound1,bound2:float
  
  for i in countup(0,deg):
      var c=abs(p.cofs[i]/d)
      bound1=max(bound1,c+1.0)
      bound2=bound2+c
      
  bound2=max(1.0,bound2)
  xmax=min(bound1,bound2)
  xmin= -xmax


proc addRoot(p:TPoly,res:var seq[float],xp0,xp1,tol,zerotol,mergetol:float)=
  ## helper function for `roots` function
  ## try to do a numeric search for a single root in range xp0-xp1,
  ## adding it to `res` (allocating `res` if nil)
  var rootx,rooty:float
  
  if brent(xp0,xp1, proc(x:float):float=p.eval(x),rootx,rooty,tol):
    if res==nil: res= @[rootx]
    elif rootx>=res[high(res)]+mergetol: res.add(rootx) #dont add equal roots.
  else:
    #this might be a 'touching' case, check function value against
    #zero tolerance
    if abs(rooty)<=zerotol:
      if res==nil: res= @[rootx]
      elif rootx>=res[high(res)]+mergetol: res.add(rootx) #dont add equal roots.


proc roots*(p:TPoly,tol=1.0e-9,zerotol=1.0e-6,mergetol=1.0e-12):seq[float]=
  ## Computes the real roots of the polynomial `p`
  ## `tol` is the tolerance use to break searching for each root when reached.
  ## `zerotol` is the tolerance, which is 'close enough' to zero to be considered a root
  ## and is used to find roots for curves that only 'touch' the x-axis.
  ## `mergetol` is the tolerance, of which two x-values are considered beeing the same root.
  ## Returns a sequence with the solutions, or nil in case of no solutions.
  var deg=p.degree
  var res:seq[float]=nil
  if deg<=0:
    return nil
  elif p.degree==1:
    var linrt= -p.cofs[0]/p.cofs[1]
    if linrt==inf or linrt==neginf:
      return nil #constant only => no roots
    return @[linrt]
  elif p.degree==2:
    return solveQuadric(p.cofs[2],p.cofs[1],p.cofs[0],zerotol)
  else:
    # degree >=3 , find min/max points of polynomial with recursive
    # derivative and do a numerical search for root between each min/max
    var x0,x1:float
    p.getRangeForRoots(x0,x1)
    var minmax=p.derivative.roots(tol,zerotol,mergetol)
    if minmax!=nil: #ie. we have minimas/maximas in this function
      for x in minmax.items:
        addRoot(p,res,x0,x,tol,zerotol,mergetol)
        x0=x
    addRoot(p,res,x0,x1,tol,zerotol,mergetol)

  return res

when isMainModule:
  var ply=initPoly(1.0,-6.0,5.0,2.0)
  var ply2 =initPoly(4.0,5.0,6.0)
  
  echo ply
  echo ply2 
  echo ply2-ply
  
  
  
  
  var rts=ply.roots
  if rts!=nil:
    for i in rts:
      echo formatFloat(i,ffDefault,0)
  

  discard readLine(stdin) 
  
  
    
  
  
    
    
    
    
    
    
    
    
    
    
        
        
        
    