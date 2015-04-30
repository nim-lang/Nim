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
import numeric

type 
  Poly* = object
      cofs:seq[float]

{.deprecated: [TPoly: Poly].}

proc degree*(p:Poly):int=
  ## Returns the degree of the polynomial,
  ## that is the number of coefficients-1
  return p.cofs.len-1


proc eval*(p:Poly,x:float):float=
  ## Evaluates a polynomial function value for `x`
  ## quickly using Horners method
  var n=p.degree
  result=p.cofs[n]
  dec n
  while n>=0:
    result = result*x+p.cofs[n]
    dec n

proc `[]` *(p:Poly;idx:int):float=
  ## Gets a coefficient of the polynomial.
  ## p[2] will returns the quadric term, p[3] the cubic etc.
  ## Out of bounds index will return 0.0.
  if idx<0 or idx>p.degree:
      return 0.0
  return p.cofs[idx]
    
proc `[]=` *(p:var Poly;idx:int,v:float)=
  ## Sets an coefficient of the polynomial by index.
  ## p[2] set the quadric term, p[3] the cubic etc.
  ## If index is out of range for the coefficients,
  ## the polynomial grows to the smallest needed degree.
  assert(idx>=0)

  if idx>p.degree:  #polynomial must grow
    var oldlen=p.cofs.len
    p.cofs.setLen(idx+1)
    for q in oldlen.. <high(p.cofs):
      p.cofs[q]=0.0 #new-grown coefficients set to zero

  p.cofs[idx]=v
    
      
iterator items*(p:Poly):float=
  ## Iterates through the coefficients of the polynomial.
  var i=p.degree
  while i>=0:
    yield p[i]
    dec i    
    
proc clean*(p:var Poly;zerotol=0.0)=
  ## Removes leading zero coefficients of the polynomial.
  ## An optional tolerance can be given for what's considered zero.
  var n=p.degree
  var relen=false

  while n>0 and abs(p[n])<=zerotol:    # >0 => keep at least one coefficient
    dec n
    relen=true

  if relen: p.cofs.setLen(n+1)


proc `$` *(p:Poly):string = 
  ## Gets a somewhat reasonable string representation of the polynomial
  ## The format should be compatible with most online function plotters,
  ## for example directly in google search
  result=""
  var first=true #might skip + sign if first coefficient
  
  for idx in countdown(p.degree,0):
    let a=p[idx]
    
    if a==0.0:
      continue
    
    if a>= 0.0 and not first:
      result.add('+')
    first=false

    if a!=1.0 or idx==0:
      result.add(formatFloat(a,ffDefault,0))
    if idx>=2:
      result.add("x^" & $idx)
    elif idx==1:
      result.add("x")

  if result=="":
      result="0"
          

proc derivative*(p: Poly): Poly=
  ## Returns a new polynomial, which is the derivative of `p`
  newSeq[float](result.cofs,p.degree)
  for idx in 0..high(result.cofs):
    result.cofs[idx]=p.cofs[idx+1]*float(idx+1)
    
proc diff*(p:Poly,x:float):float=
  ## Evaluates the differentiation of a polynomial with
  ## respect to `x` quickly using a modifed Horners method
  var n=p.degree
  result=p[n]*float(n)
  dec n
  while n>=1:
    result = result*x+p[n]*float(n)
    dec n

proc integral*(p:Poly):Poly=
  ## Returns a new polynomial which is the indefinite
  ## integral of `p`. The constant term is set to 0.0
  newSeq(result.cofs,p.cofs.len+1)
  result.cofs[0]=0.0  #constant arbitrary term, use 0.0
  for i in 1..high(result.cofs):
    result.cofs[i]=p.cofs[i-1]/float(i)
        

proc integrate*(p:Poly;xmin,xmax:float):float=
  ## Computes the definite integral of `p` between `xmin` and `xmax`
  ## quickly using a modified version of Horners method
  var
    n=p.degree
    s1=p[n]/float(n+1)
    s2=s1
    fac:float

  dec n
  while n>=0:
    fac=p[n]/float(n+1)
    s1 = s1*xmin+fac
    s2 = s2*xmax+fac
    dec n
 
  result=s2*xmax-s1*xmin
  
proc initPoly*(cofs:varargs[float]):Poly=
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


proc divMod*(p,d:Poly;q,r:var Poly)=
  ## Divides `p` with `d`, and stores the quotinent in `q` and
  ## the remainder in `d`
  var 
    pdeg=p.degree
    ddeg=d.degree
    power=p.degree-d.degree
    ratio:float
  
  r.cofs = p.cofs #initial remainder=numerator
  if power<0: #denominator is larger than numerator
    q.cofs= @ [0.0] #quotinent is 0.0
    return # keep remainder as numerator
      
  q.cofs=newSeq[float](power+1)
  
  for i in countdown(pdeg,ddeg):
    ratio=r.cofs[i]/d.cofs[ddeg]
    
    q.cofs[i-ddeg]=ratio
    r.cofs[i]=0.0
    
    for j in countup(0,<ddeg):
        var idx=i-ddeg+j
        r.cofs[idx] = r.cofs[idx] - d.cofs[j]*ratio
     
  r.clean # drop zero coefficients in remainder

proc `+` *(p1:Poly,p2:Poly):Poly=
  ## Adds two polynomials
  var n=max(p1.cofs.len,p2.cofs.len)
  newSeq(result.cofs,n)
  
  for idx in countup(0,n-1):
      result[idx]=p1[idx]+p2[idx]
      
  result.clean # drop zero coefficients in remainder
    
proc `*` *(p1:Poly,p2:Poly):Poly=
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

proc `*` *(p:Poly,f:float):Poly=
  ## Multiplies the polynomial `p` with a real number
  newSeq(result.cofs,p.cofs.len)
  for i in 0..high(p.cofs):
    result[i]=p.cofs[i]*f
  result.clean
  
proc `*` *(f:float,p:Poly):Poly=
  ## Multiplies a real number with a polynomial
  return p*f
    
proc `-`*(p:Poly):Poly=
  ## Negates a polynomial
  result=p
  for i in countup(0,<result.cofs.len):
    result.cofs[i]= -result.cofs[i]
    
proc `-` *(p1:Poly,p2:Poly):Poly=
  ## Subtract `p1` with `p2`
  var n=max(p1.cofs.len,p2.cofs.len)
  newSeq(result.cofs,n)
  
  for idx in countup(0,n-1):
      result[idx]=p1[idx]-p2[idx]
      
  result.clean # drop zero coefficients in remainder
    
proc `/`*(p:Poly,f:float):Poly=
  ## Divides polynomial `p` with a real number `f`
  newSeq(result.cofs,p.cofs.len)
  for i in 0..high(p.cofs):
    result[i]=p.cofs[i]/f
  result.clean
  
proc `/` *(p,q:Poly):Poly=
  ## Divides polynomial `p` with polynomial `q`
  var dummy:Poly
  p.divMod(q,result,dummy)  

proc `mod` *(p,q:Poly):Poly=
  ## Computes the polynomial modulo operation,
  ## that is the remainder of `p`/`q`
  var dummy:Poly
  p.divMod(q,dummy,result)


proc normalize*(p:var Poly)=
  ## Multiplies the polynomial inplace by a term so that
  ## the leading term is 1.0.
  ## This might lead to an unstable polynomial
  ## if the leading term is zero.
  p=p/p[p.degree]


proc solveQuadric*(a,b,c:float;zerotol=0.0):seq[float]=
  ## Solves the quadric equation `ax^2+bx+c`, with a possible
  ## tolerance `zerotol` to find roots of curves just 'touching'
  ## the x axis. Returns sequence with 0,1 or 2 solutions.
  
  var p,q,d:float
  
  p=b/(2.0*a)
  
  if p==Inf or p==NegInf: #linear equation..
    var linrt= -c/b
    if linrt==Inf or linrt==NegInf: #constant only
      return @[]
    return @[linrt]
  
  q=c/a
  d=p*p-q
  
  if d<0.0:
    #check for inside zerotol range for neg. roots
    var err=a*p*p-b*p+c #evaluate error at parabola center axis
    if(err<=zerotol): return @[-p]
    return @[]
  else:
    var sr=sqrt(d)
    result= @[-sr-p,sr-p]

proc getRangeForRoots(p:Poly):tuple[xmin,xmax:float]=
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
  result.xmax=min(bound1,bound2)
  result.xmin= -result.xmax


proc addRoot(p:Poly,res:var seq[float],xp0,xp1,tol,zerotol,mergetol:float,maxiter:int)=
  ## helper function for `roots` function
  ## try to do a numeric search for a single root in range xp0-xp1,
  ## adding it to `res` (allocating `res` if nil)
  var br=brent(xp0,xp1, proc(x:float):float=p.eval(x),tol)
  if br.success:
    if res.len==0 or br.rootx>=res[high(res)]+mergetol: #dont add equal roots.
      res.add(br.rootx) 
  else:
    #this might be a 'touching' case, check function value against
    #zero tolerance
    if abs(br.rooty)<=zerotol:
      if res.len==0 or br.rootx>=res[high(res)]+mergetol: #dont add equal roots.
        res.add(br.rootx) 


proc roots*(p:Poly,tol=1.0e-9,zerotol=1.0e-6,mergetol=1.0e-12,maxiter=1000):seq[float]=
  ## Computes the real roots of the polynomial `p`
  ## `tol` is the tolerance used to break searching for each root when reached.
  ## `zerotol` is the tolerance, which is 'close enough' to zero to be considered a root
  ## and is used to find roots for curves that only 'touch' the x-axis.
  ## `mergetol` is the tolerance, of which two x-values are considered beeing the same root.
  ## `maxiter` can be used to limit the number of iterations for each root.
  ## Returns a (possibly empty) sorted sequence with the solutions.
  var deg=p.degree
  if deg<=0: #constant only => no roots
    return @[]
  elif p.degree==1: #linear
    var linrt= -p.cofs[0]/p.cofs[1]
    if linrt==Inf or linrt==NegInf:
      return @[] #constant only => no roots
    return @[linrt]
  elif p.degree==2:
    return solveQuadric(p.cofs[2],p.cofs[1],p.cofs[0],zerotol)
  else:
    # degree >=3 , find min/max points of polynomial with recursive
    # derivative and do a numerical search for root between each min/max
    var range=p.getRangeForRoots()
    var minmax=p.derivative.roots(tol,zerotol,mergetol)
    result= @[]
    if minmax!=nil: #ie. we have minimas/maximas in this function
      for x in minmax.items:
        addRoot(p,result,range.xmin,x,tol,zerotol,mergetol,maxiter)
        range.xmin=x
    addRoot(p,result,range.xmin,range.xmax,tol,zerotol,mergetol,maxiter)

