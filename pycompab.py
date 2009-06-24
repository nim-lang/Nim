""" Python compability library
    
    With careful and painful coding, compability from Python 1.5.2 up to 3.0
    is achieved. Don't try this at home.

    Copyright 2009, Andreas Rumpf
"""

import sys

python3 = sys.version[0] >= "3"
python26 = sys.version[:3] == "2.6"

true, false = 0==0, 0==1

if python3:
  sys.exit("This script does not yet work with Python 3.0")

try:
  from cStringIO import StringIO
except ImportError:
  from io import StringIO

if python3:
  def replace(s, a, b): return s.replace(a, b)
  def lower(s): return s.lower()
  def join(a, s=""): return s.join(a)
  def find(s, a): return s.find(a)
  def split(s, a=None): return s.split(a)
  def strip(s): return s.strip()

  def has_key(dic, key): return key in dic
else:
  from string import replace, lower, join, find, split, strip

  def has_key(dic, key): return dic.has_key(key)

if not python3 and not python26:
  import md5
  def newMD5(): return md5.new()
  def MD5update(obj, x):
    return obj.update(x)
else:
  import hashlib
  def newMD5(): return hashlib.md5()
  def MD5update(obj, x):
    if python26:
      return obj.update(x)
    else:
      return obj.update(bytes(x, "utf-8"))

def mydigest(hasher):
  result = ""
  for c in hasher.digest():
    if python3:
      x = hex(c)[2:]
    else:
      x = hex(ord(c))[2:]
    if len(x) == 1: x = "0" + x
    result = result + x
  return result

def Subs(frmt, *args, **substitution):
  DIGITS = "0123456789"
  LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  chars = DIGITS+LETTERS+"_"
  d = substitution
  a = args
  result = []
  i = 0
  num = 0
  L = len(frmt)
  while i < L:
    if frmt[i] == '$':
      i = i+1
      if frmt[i] == '#':
        result.append(a[num])
        num = num+1
        i = i+1
      elif frmt[i] == '$':
        result.append('$')
        i = i+1
      elif frmt[i] == '{':
        i = i+1
        j = i
        while frmt[i] != '}': i = i+1
        i = i+1 # skip }
        x = frmt[j:i-1]
        if x[0] in DIGITS:
          result.append(str(a[int(x)-1]))
        else:
          result.append(str(d[x]))
      elif frmt[i] in chars:
        j = i
        i = i+1
        while i < len(frmt) and frmt[i] in chars: i = i + 1
        x = frmt[j:i]
        if x[0] in DIGITS:
          num = int(x)
          result.append(str(a[num-1]))
        else:
          result.append(str(d[x]))
      else:
        assert(false)
    else:
      result.append(frmt[i])
      i = i+1
  return join(result, "")

