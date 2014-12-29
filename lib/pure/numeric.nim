#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Robert Persson
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type OneVarFunction* = proc (x: float): float

{.deprecated: [TOneVarFunction: OneVarFunction].}

proc brent*(xmin,xmax:float, function:OneVarFunction, tol:float,maxiter=1000): 
  tuple[rootx, rooty: float, success: bool]=
  ## Searches `function` for a root between `xmin` and `xmax` 
  ## using brents method. If the function value at `xmin`and `xmax` has the
  ## same sign, `rootx`/`rooty` is set too the extrema value closest to x-axis
  ## and succes is set to false.
  ## Otherwise there exists at least one root and success is set to true.
  ## This root is searched for at most `maxiter` iterations.
  ## If `tol` tolerance is reached within `maxiter` iterations 
  ## the root refinement stops and success=true.

  # see http://en.wikipedia.org/wiki/Brent%27s_method
  var 
    a=xmin
    b=xmax
    c=a
    d=1.0e308 
    fa=function(a)
    fb=function(b)
    fc=fa
    s=0.0
    fs=0.0
    mflag:bool
    i=0
    tmp2:float

  if fa*fb>=0:
    if abs(fa)<abs(fb):
      return (a,fa,false)
    else:
      return (b,fb,false)
  
  if abs(fa)<abs(fb):
    swap(fa,fb)
    swap(a,b)
  
  while fb!=0.0 and abs(a-b)>tol:
    if fa!=fc and fb!=fc: # inverse quadratic interpolation
      s = a * fb * fc / (fa - fb) / (fa - fc) + b * fa * fc / (fb - fa) / (fb - fc) + c * fa * fb / (fc - fa) / (fc - fb)
    else: #secant rule
      s = b - fb * (b - a) / (fb - fa)
    tmp2 = (3.0 * a + b) / 4.0
    if not((s > tmp2 and s < b) or (s < tmp2 and s > b)) or 
      (mflag and abs(s - b) >= (abs(b - c) / 2.0)) or 
      (not mflag and abs(s - b) >= abs(c - d) / 2.0):
      s=(a+b)/2.0
      mflag=true
    else:
      if (mflag and (abs(b - c) < tol)) or (not mflag and (abs(c - d) < tol)):
        s=(a+b)/2.0
        mflag=true
      else:
        mflag=false
    fs = function(s)
    d = c
    c = b
    fc = fb
    if fa * fs<0.0:
      b=s
      fb=fs
    else:
      a=s
      fa=fs
    if abs(fa)<abs(fb):
      swap(a,b)
      swap(fa,fb)
    inc i
    if i>maxiter:
      break
  
  return (b,fb,true)
