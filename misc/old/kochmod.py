# This is kochmod, a simple module for make-like functionality.
# For further documentation see koch.txt or koch.html.
# (c) 2007 Andreas Rumpf

VERSION = "1.0.4"

import os, os.path, re, shutil, glob, cPickle, zlib, string, \
  getopt, sys
from types import *

def Error(msg): sys.exit("[Koch] *** ERROR: " + msg)
def Warn(msg): print "[Koch] *** WARNING: " + msg
def Echo(msg): print "[Koch] " + msg
def _Info(msg): print "[Koch] " + msg

_FINGERPRINTS_FILE = "koch.dat"
  # in this file all the fingerprints are kept to allow recognizing when a file
  # has changed. This works reliably, which cannot be said from just taking
  # filetime-stamps.

# -----------------------------------------------------------------------------

def FileCmp(filenameA, filenameB):
  SIZE = 4096*2
  result = True
  a = file(filenameA, "rb")
  b = file(filenameB, "rb")
  while True:
    x = a.read(SIZE)
    y = b.read(SIZE)
    if x != y:
      result = False
      break
    elif len(x) < SIZE: # EOF?
      break
  a.close()
  b.close()
  return result

# ---------------- C Compilers ------------------------------------------------

# We support the following C compilers:
C_Compilers = ["gcc", "lcc", "bcc", "dmc", "wcc", "tcc", "pcc", "ucc", "llvm"]

_CC_Info = [
  dict(
    name = "gcc",
    objExt = "o",
    optSpeed = " -O3 -ffast-math ",
    optSize = " -Os -ffast-math ",
    comp = "gcc -c $options $include -o $objfile $file",
    buildGui = " -mwindows",
    buildDll = " -mdll",
    link = "gcc $options $buildgui $builddll -o $exefile $objfiles",
    includeCmd = " -I",
    debug = "",
    defineValue = " -D$name=$value",
    define = " -D$name",
    undef = " -U$name",
    pic = "-fPIC"
  ), dict(
    name = "lcc",
    objExt = "obj",
    optSpeed = " -O -p6 ",
    optSize = " -O -p6 ",
    comp = "lcc -e1 $options $include -Fo$objfile $file",
    buildGui = " -subsystem windows",
    buildDll = " -dll",
    link = "lcclnk $options $buildgui $builddll -O $exefile $objfiles",
    includeCmd = " -I",
    debug = " -g5 ",
    defineValue = " -D$name=$value",
    define = " -D$name",
    undef = " -U$name",
    pic = ""
  ), dict(
    name = "bcc",
    objExt = "obj",
    optSpeed = " -O2 -6 ",
    optSize = " -O1 -6 ",
    comp = "bcc32 -c -H- -q -RT- -a8 $options $include -o$objfile $file",
    buildGui = " -tW",
    buildDll = " -tWD",
    link = "bcc32 $options $buildgui $builddll -e$exefile $objfiles",
    includeCmd = " -I",
    debug = "",
    defineValue = " -D$name=$value",
    define = " -D$name",
    undef = " -U$name",
    pic = ""
  ), dict(
    name = "dmc",
    objExt = "obj",
    optSpeed = " -ff -o -6 ",
    optSize = " -ff -o -6 ",
    comp = "dmc -c -Jm $options $include -o$objfile $file",
    buildGui = " -L/exet:nt/su:windows",
    buildDll = " -WD",
    link = "dmc $options $buildgui $builddll -o$exefile $objfiles",
    includeCmd = " -I",
    debug = " -g ",
    defineValue = " -D$name=$value",
    define = " -D$name",
    undef = " -U$name", # XXX: dmc does not have -U ?
    pic = ""
  ), dict(
    name = "wcc",
    objExt = "obj",
    optSpeed = " -ox -on -6 -d0 -fp6 -zW ",
    optSize = "",
    comp = "wcl386 -c -6 -zw $options $include -fo=$objfile $file",
    buildGui = " -bw",
    buildDll = " -bd",
    link = "wcl386 $options $buildgui $builddll -fe=$exefile $objfiles ",
    includeCmd = " -i=",
    debug = " -d2 ",
    defineValue = " -d$name=$value",
    define = " -d$name",
    undef = " -u$name",
    pic = ""
  ), dict(
    name = "vcc",
    objExt = "obj",
    optSpeed = " /Ogityb2 /G7 /arch:SSE2 ",
    optSize = " /O1 /G7 ",
    comp = "cl /c $options $include /Fo$objfile $file",
    buildGui = " /link /SUBSYSTEM:WINDOWS ",
    buildDll = " /LD",
    link = "cl $options $builddll /Fe$exefile $objfiles $buildgui",
    includeCmd = " /I",
    debug = " /GZ /Zi ",
    defineValue = " /D$name=$value",
    define = " /D$name",
    undef = " /U$name",
    pic = ""
  ), dict(
    name = "tcc",
    objExt = "o",
    optSpeed = "", # Tiny C has no optimizer
    optSize = "",
    comp = "tcc -c $options $include -o $objfile $file",
    buildGui = "UNAVAILABLE!",
    buildDll = " -shared",
    link = "tcc -o $exefile $options $buildgui $builddll $objfiles",
    includeCmd = " -I",
    debug = " -b ",
    defineValue = " -D$name=$value",
    define = " -D$name",
    undef = " -U$name",
    pic = ""
  ), dict(
    name = "pcc", # Pelles C
    objExt = "obj",
    optSpeed = " -Ox ",
    optSize = " -Os ",
    comp = "cc -c $options $include -Fo$objfile $file",
    buildGui = " -SUBSYSTEM:WINDOWS",
    buildDll = " -DLL",
    link = "cc $options $buildgui $builddll -OUT:$exefile $objfiles",
    includeCmd = " -I",
    debug = " -Zi ",
    defineValue = " -D$name=$value",
    define = " -D$name",
    undef = " -U$name",
    pic = ""
  ), dict(
    name = "ucc",
    objExt = "o",
    optSpeed = " -O3 ",
    optSize = " -O1 ",
    comp = "cc -c $options $include -o $objfile $file",
    buildGui = "",
    buildDll = " -shared ",
    link = "cc -o $exefile $options $buildgui $builddll $objfiles",
    includeCmd = " -I",
    debug = "",
    defineValue = " -D$name=$value",
    define = " -D$name",
    undef = " -U$name",
    pic = ""
  ), dict(
    name = "llvm_gcc", # its options are the same as GCC's
    objExt = "o",
    optSpeed = " -O3 -ffast-math ",
    optSize = " -Os -ffast-math ",
    comp = "llvm-gcc -c $options $include -o $objfile $file",
    buildGui = " -mwindows",
    buildDll = " -mdll",
    link = "llvm-gcc $options $buildgui $builddll -o $exefile $objfiles",
    includeCmd = " -I",
    debug = "",
    defineValue = " -D$name=$value",
    define = " -D$name",
    undef = " -U$name",
    pic = "-fPIC"
  )
]

#  --------------- little helpers ---------------------------------------------

def Subs(frmt, **substitution):
  if isinstance(frmt, basestring):
    return string.Template(frmt).substitute(substitution)
  else:
    return tuple([string.Template(x).substitute(substitution) for x in frmt])

def SafeSubs(frmt, **substitution):
  return string.Template(frmt).safe_substitute(substitution)

_baseDir = os.getcwd()
BaseDir = _baseDir

def Path(a):
  # Gets a UNIX like path and converts it to a path on this platform.
  # With UNIX like, I mean: slashes, not backslashes, only relative
  # paths ('../etc' can be used)
  result = a
  if os.sep != "/": result = result.replace("/", os.sep)
  if os.pardir != "..": result = result.replace("..", os.pardir)
  return result

def Join(*args):
  result = ""
  for a in args[:-1]:
    result += a
    if result[-1] != "/":
      result += "/"
  result += args[-1]
  return result.replace("//", "/")

def Exec(command):
  c = Path(command)
  Echo(c)
  result = os.system(c)
  if result != 0: Error("execution of an external program failed")
  return result

def TryExec(command):
  c = Path(command)
  Echo(c)
  result = os.system(c)
  return result

def RawExec(command):
  Echo(command)
  result = os.system(command)
  if result != 0: Error("execution of an external program failed")
  return result

def Move(src, dest):
  s = Path(src)
  d = Path(dest)
  try:
    shutil.move(s, d)
  except IOError, OSError:
    Warn("could not move %s to %s" % (s, d))

def Copy(src, dest):
  s = Path(src)
  d = Path(dest)
  try:
    shutil.copyfile(s, d)
  except IOError, OSError:
    Warn("could not copy %s to %s" % (s, d))

def Remove(f):
  try:
    os.remove(Path(f))
  except OSError:
    Warn("could not remove: %s" % f)

def RemoveDir(f):
  try:
    shutil.rmtree(Path(f))
  except OSError:
    Warn("could not remove: %s" % f)

def Exists(f): return os.path.exists(Path(f))

def Chdir(dest):
  d = Path(dest)
  try:
    os.chdir(d)
  except OSError:
    Warn("could not switch to directory: " + d)

def Mkdir(dest):
  d = Path(dest)
  try:
    os.mkdir(d)
  except OSError:
    Warn("could not create directory: " + d)

def Glob(pattern): # needed because glob.glob() is buggy on Windows 95:
  # things like tests/t*.mor won't work
  global _baseDir
  (head, tail) = os.path.split(Path(pattern))
  result = []
  try:
    os.chdir(os.path.join(_baseDir, head))
    try:
      for f in glob.glob(tail): result.append(os.path.join(head, f))
    except OSError:
      result = []
  finally:
    os.chdir(_baseDir)
  return result

def FilenameNoExt(f):
  return os.path.splitext(os.path.basename(f))[0]

def _Ext(trunc, posixFormat, winFormat):
  (head, tail) = os.path.split(Path(trunc))
  if os.name == "posix": frmt = posixFormat
  else:                  frmt = winFormat
  return os.path.join(head, Subs(frmt, trunc=tail))

def DynExt(trunc):
  """Makes a dynamic library out of a trunc. This means it either
     does '${trunc}.dll' or 'lib${trunc}.so'.
  """
  return _Ext(trunc, 'lib${trunc}.so', '${trunc}.dll')

def LibExt(trunc):
  """Makes a static library out of a trunc. This means it either
     does '${trunc}.lib' or '${trunc}.a'.
  """
  return _Ext(trunc, '${trunc}.a', '${trunc}.lib')

def ScriptExt(trunc):
  """Makes a script out of a trunc. This means it either
     does '${trunc}.bat' or '${trunc}.sh'.
  """
  return _Ext(trunc, '${trunc}.sh', '${trunc}.bat')

def ExeExt(trunc):
  """Makes an executable out of a trunc. This means it either
     does '${trunc}.exe' or '${trunc}'.
  """
  return _Ext(trunc, '${trunc}', '${trunc}.exe')

def MakeExecutable(file):
  os.chmod(file, 493)

# ----------------- Dependency Analyser Core ---------------------------------
# We simply store the rules in a list until building the things. Checking is
# also delayed.
_rules = {}
_importantTargets = [] # used for command line switches
_commands = {} # other commands
# a command is a tuple: (name, description, function, number of arguments)

def Command(name, desc, func, args=0):
  """if args == -1, a variable number of arguments is given to the ``func``
     as a list"""
  _commands[name] = (desc, func, args)

def _applyPath(x):
  if type(x) == ListType:
    return map(Path, x)
  else:
    return Path(x)

def Rule(name = None, desc = "", prereqs = [], cmds = None, outputfile = None,
         modifies = []):
  """Defines a rule. Name must be a single word, not a file!"""
  if not name:
    t = "#" + str(len(_rules.keys()))
  else:
    t = name
  if t in _rules: Error("target '%s' already exists!" % t)
  _rules[t] = (_applyPath(prereqs), cmds, outputfile, _applyPath(modifies))
  if desc:
    _importantTargets.append((t, desc))


class Changed(object):
  """ Returns a Changed object. This object evals to true if one of the
      given files has changed, false otherwise in a boolean context. You have
      to call the object's success() method if the building has been a success.

      Example:

      c = Changed("unique_name", "file1.pas file2.pas file3.pas")
      if c:
        Exec("fpc file1.pas")
        # Exec raises an exception if it fails, thus if we get to here, it was
        # a success:
        c.success()
  """
  def __init__(self, id, files, explain=False,
              fingerprintsfile=_FINGERPRINTS_FILE):
    # load the fingerprints file:
    # fingerprints is a dict[target, files] where files is a dict[filename, hash]
    self.fingers = {} # default value
    if Exists(fingerprintsfile):
      try:
        self.fingers = cPickle.load(file(fingerprintsfile))
      except OSError:
        Error("Cannot read from " + fingerprintsfile)
    self.filename = fingerprintsfile
    self.id = id
    self.files = files
    self._hashStr = zlib.adler32 # our hash function
    self.explain = explain

  def _hashFile(self, f):
    x = file(f)
    result = self._hashStr(x.read())
    x.close() # for other Python implementations
    return result

  def __nonzero__(self):
    if type(self.files) == type(""):
      self.files = self.files.split()
    result = False
    target = self.id
    if not (target in self.fingers):
      self.fingers[target] = {}
      if self.explain: _Info("no entries for target '%s'" % target)
      result = True
    for d in self.files:
      if Exists(d):
        n = self._hashFile(d)
        if d not in self.fingers[target] or n != self.fingers[target][d]:
          result = True
          if self.explain: _Info("'%s' modified since last build" % d)
          self.fingers[target][d] = n
      else:
        Warn("'%s' does not exist!" % d)
        result = True
    return result

  def update(self, filename):
    self.fingers[self.id][filename] = self._hashFile(filename)

  def success(self):
    cPickle.dump(self.fingers, file(self.filename, "w+"))


class _Koch(object):
  def _loadFingerprints(self, filename):
  # fingerprints is a dict[target, files] where files is a dict[filename, hash]
    if Exists(filename):
      try:
        self.fingers = cPickle.load(file(filename))
      except OSError:
        Error("Cannot read from " + filename)
    else:
      self.fingers = {} # we have no fingerprints :-(

  def _saveFingerprints(self, filename):
    cPickle.dump(self.fingers, file(filename, "w+"))

  def __init__(self, options):
    self._loadFingerprints(_FINGERPRINTS_FILE)
    self.newfingers = {}
    self.rules = _rules
    self._hashStr = zlib.adler32 # our hash function
    self.options = options

  def _doRebuild(self, cmd):
    if cmd is None: return 0
    if type(cmd) is StringType:
      if cmd:
        c = Path(cmd)
        _Info(c)
        return os.system(c)
      else:
        return 0
    elif type(cmd) is FunctionType:
      return cmd()
    elif type(cmd) is ListType:
      for c in cmd:
        res = self._doRebuild(c)
        if res != 0: break
      return res
    else:
      Error("invalid rule: command must be a string or a function")

  def _hashFile(self, f):
    x = file(f)
    result = self._hashStr(x.read())
    x.close() # for other Python implementations
    return result

  def _getDeps(self, target):
    depslist = self.rules[target][0]
    if type(depslist) is StringType:
      result = depslist.split()
    elif type(depslist) is FunctionType:
      result = depslist()
    elif type(depslist) is ListType:
      result = []
      for d in depslist:
        if type(d) is StringType:
          result.append(d)
        elif type(d) is FunctionType:
          result.append(d())
        else:
          Error("invalid rule: prereqs must be a string, list, or a function")
    for i in range(0, len(result)):
      result[i] = Path(result[i])
    return result

  def _hasChanged(self, target, d):
    if not (target in self.newfingers):
      self.newfingers[target] = {}
    if Exists(d):
      n = self._hashFile(d)
      self.newfingers[target][d] = n
      if not (target in self.fingers): return True
      if not (d in self.fingers[target]): return True
      return n != self.fingers[target][d]
    else:
      Warn("'%s' does not exist!" % d)
      return True

  def _makeAux(self, target, callstack={}):
    # returns "uptodate", "updated", "failed"
    UPTODATE = 1
    UPDATED = 2
    FAILED = 3

    if target in callstack: return callstack[target]

    def explain(msg):
      if 'explain' in self.options: _Info(msg)

    if not (target in self.rules): return UPTODATE # target is up to date
    callstack[target] = UPTODATE # assume uptodate until proven otherwise
    result = UPTODATE

    # retrieve the dependencies:
    deps = self._getDeps(target)
    for d in deps:
      if d[0] == '#':
        t = d[1:]
        if not (t in self.rules):
          Error("reference to unknown target '%s'" % t)
        # it is a target!
        #callstack[t] = # XXX: prevend endless recursion!
        res = self._makeAux(t, callstack)
        result = max(result, res)
        if res == UPDATED:
          explain("will build '%s' because '%s' modified since last build" %
                  (target, d))
        elif res == FAILED:
          explain("cannot build '%s' because '%s' failed" %
                  (target, d))
      elif self._hasChanged(target, d):
        explain("will build '%s' because '%s' modified since last build" %
                (target, d))
        result = max(result, UPDATED)
    if self.rules[target][2]: # check if output file exists:
      if not Exists(self.rules[target][2]):
        explain("will build '%s' because output file '%s' does not exist" %
               (target, self.rules[target][2]))
        result = max(result, UPDATED)

    if result == UPTODATE and 'force' in self.options:
      explain("will build '%s' because forced" % target)
      result = max(result, UPDATED)

    if result == UPDATED:
      _Info("building target '%s'" % target)
      buildRes = self._doRebuild(self.rules[target][1])
      if buildRes is None:
        Error("builder for target '%s' did not return an int" % target)
        result = FAILED
      elif buildRes != 0:
        result = FAILED
    elif result == UPTODATE:
      _Info("'%s' is up to date" % target)
    callstack[target] = result
    if result == UPDATED: # building was successful, so update fingerprints:
      if not (target in self.newfingers):
      # for phony targets this check is needed
        self.newfingers[target] = {}
      for m in self.rules[target][3]: # look for changed files
        self._hasChanged(target, m) # call for its side-effects
      self.fingers[target] = self.newfingers[target]
    return result

  def make(self, target):
    self._makeAux(target)
    self._saveFingerprints(_FINGERPRINTS_FILE)

# -----------------------------------------------------------------------------

def SplitArg(s):
  if ':' in s: c = ':'
  elif '=' in s: c = '='
  else: return (s, '')
  i = s.find(c)
  return (s[:i], s[i+1:])

# -----------------------------------------------------------------------------

def _writeUsage():
  print("Usage: koch.py [options] command/target [command/target...]\n"
        "Options:\n"
        "  --force, -b, -f        forces rebuilding\n"
        "  --help, -h             shows this help\n"
        "  --explain, -e          explain why a target is built\n"
        "Available targets:")
  for t in _importantTargets:
    print("  " + t[0] + " " * (23-len(t[0])) + t[1])
  if len(_commands) > 0:
    print("Available commands:")
    for k, v in _commands.iteritems():
      print("  " + k + " " * (23-len(k)) + v[0])
  sys.exit(2)

def Koch(defaultTarget):
  argv = sys.argv[1:]

  options = {}
  i = 0
  # process general options:
  while i < len(argv):
    if argv[i][0] == '-':
      if argv[i] in ("-h", "--help"): _writeUsage()
      elif argv[i] in ("-b", "-B", "--force", "-f"): options['force'] = True
      elif argv[i] in ("--explain", "-e"): options['explain'] = True
      else: Error("invalid option: '%s'" % argv[i])
    else: break # BUGFIX
    i += 1

  k = _Koch(options)

  # process commands:
  i = 0
  while i < len(argv):
    if argv[i][0] != '-': # process target/command
      if argv[i] in _rules:
        k.make(argv[i])
      elif argv[i] in _commands:
        cmd = argv[i]
        n = _commands[cmd][2]
        args = []
        if n < 0: upperBound = len(argv)-1
        else: upperBound = i+n
        while i+1 <= upperBound:
          if i+1 >= len(argv):
            Error("command '%s' expects %d arguments" % (cmd, n))
          args.append(argv[i+1])
          i += 1
        if n < 0: _commands[cmd][1](args)
        else: _commands[cmd][1](*args)
      else:
        Error("Invalid target/command: " + argv[i])

    i += 1
  if len(argv) == 0:
    k.make(defaultTarget)

if __name__ == "__main__":
  Error("You should execute the file 'koch.py' or consult\n"
        "the documentation to see how to build this software.")


