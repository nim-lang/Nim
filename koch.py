#! /usr/bin/env python

##########################################################################
##                                                                      ##
##             Build script of the Nimrod Compiler                      ##
##                      (c) 2009 Andreas Rumpf                          ##
##                                                                      ##
##########################################################################

import sys, os, os.path, re, shutil, time, getopt, glob, zlib, pickle
from pycompab import *

# --------------------- constants  ----------------------------------------

NIMROD_VERSION = '0.7.8'
# This string contains Nimrod's version. It is the only place
# where the version needs to be updated. The rest is done by
# the build process automatically. It is replaced **everywhere**!
# Format is: Major.Minor.Patch
# Major part: plan is to use number 1 for the first version that is stable;
#             higher versions may be incompatible with previous versions
# Minor part: incremented if new features are added (but is completely
#             backwards-compatible)
# Patch level: is increased for every patch

EXPLAIN = true
force = false

GENERATE_DIFF = false
# if set, a diff.log file is generated when bootstrapping

USE_FPC = true

BOOTCMD = "$1 cc --compile:build/platdef.c $2 rod/nimrod.nim"
# the command used for bootstrapping

# ---------------------- compiler detection --------------------------------

def detect(cmd, lookFor="version"):
  try:
    pipe = os.popen4(cmd)[1]
  except AttributeError:
    pipe = os.popen(cmd)
  result = None
  for line in pipe.readlines():
    if find(lower(line), lookFor) >= 0:
      result = line[:-1]
      break
  pipe.close()
  if not result:
    # don't give up yet; it may have written to stderr
    if os.system(cmd) == 0:
      result = cmd
  return result

def detectNimrod():
  if detect("nimrod"): 
    return "nimrod"
  elif detect("bin/nimrod"):
    return "bin/nimrod"
  else:
    Error("could not find a working nimrod executable")

def detectNim():
  if USE_FPC and detect("fpc -h"):
    # workaround a bug in the macosx version of nim:
    if getHost() == "macosx": return "nim" 
    else: return "bin/nim"
  return detectNimrod()

def detectAndCompileNim():
  result = detectNim()
  if result == "bin/nim" or result == "nim":
    cmd_nim()
  return result

# --------------------------------------------------------------------------

def Error(msg): sys.exit("[Koch] *** ERROR: " + msg)
def Warn(msg): print("[Koch] *** WARNING: " + msg)
def Echo(msg): print("[Koch] " + msg)
def _Info(msg): print("[Koch] " + msg)

_FINGERPRINTS_FILE = "koch.dat"
  # in this file all the fingerprints are kept to allow recognizing when a file
  # has changed. This works reliably, which cannot be said from just taking
  # filetime-stamps.

def SameFileContent(filenameA, filenameB):
  SIZE = 4096*2
  result = true
  a = open(filenameA, "rb")
  b = open(filenameB, "rb")
  while true:
    x = a.read(SIZE)
    y = b.read(SIZE)
    if x != y:
      result = false
      break
    elif len(x) < SIZE: # EOF?
      break
  a.close()
  b.close()
  return result

def SplitArg(s):
  if ':' in s: c = ':'
  elif '=' in s: c = '='
  else: return (s, '')
  i = find(s, c)
  return (s[:i], s[i+1:])

_baseDir = os.getcwd()
BaseDir = _baseDir

def Path(a):
  # Gets a UNIX like path and converts it to a path on this platform.
  # With UNIX like, I mean: slashes, not backslashes, only relative
  # paths ('../etc') can be used
  result = a
  if os.sep != "/": result = replace(result, "/", os.sep)
  if os.pardir != "..": result = replace(result, "..", os.pardir)
  return result

def Join(*args):
  result = []
  for a in args[:-1]:
    result.append(a)
    if result[-1] != "/": result.append("/")
  result.append(args[-1])
  return replace(join(result, ""), "//", "/")

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

def Remove(f):
  try:
    os.remove(Path(f))
  except OSError:
    Warn("could not remove: " + f)

def Move(src, dest):
  try:
    m = shutil.move
  except AttributeError:
    def f(src, dest):
      shutil.copy(src, dest)
      Remove(src)
    m = f
  s = Path(src)
  d = Path(dest)
  try:
    m(s, d)
  except IOError:
    Warn(Subs("could not move $1 to $2", s, d))
  except OSError:
    Warn(Subs("could not move $1 to $2", s, d))

def Copy(src, dest):
  s = Path(src)
  d = Path(dest)
  try:
    shutil.copyfile(s, d)
  except IOError:
    Warn(Subs("could not copy $1 to $2", s, d))
  except OSError:
    Warn(Subs("could not copy $1 to $2", s, d))

def RemoveDir(f):
  try:
    shutil.rmtree(Path(f))
  except OSError:
    Warn("could not remove: " + f)

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
  # things like tests/t*.nim won't work
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
  return _Ext(trunc, 'lib${trunc}.so', '${trunc}.dll')

def LibExt(trunc):
  return _Ext(trunc, '${trunc}.a', '${trunc}.lib')

def ScriptExt(trunc):
  return _Ext(trunc, '${trunc}.sh', '${trunc}.bat')

def ExeExt(trunc):
  return _Ext(trunc, '${trunc}', '${trunc}.exe')

def MakeExecutable(file):
  os.chmod(file, 493)

class Changed:
  """ Returns a Changed object. This object evals to true if one of the
      given files has changed, false otherwise in a boolean context. You have
      to call the object's success() method if the building has been a success.

      Example:

      c = Changed("unique_name", "file1.pas file2.pas file3.pas")
      if c.check():
        Exec("fpc file1.pas")
        # Exec raises an exception if it fails, thus if we get to here, it was
        # a success:
        c.success()
  """
  def __init__(self, id, files, explain=false,
               fingerprintsfile=_FINGERPRINTS_FILE):
    # load the fingerprints file:
    # fingerprints is a dict[target, files] where files is a dict[filename, hash]
    self.fingers = {} # default value
    if Exists(fingerprintsfile):
      try:
        self.fingers = pickle.load(open(fingerprintsfile, "rb"))
      except OSError:
        Error("Cannot read from " + fingerprintsfile)
    self.filename = fingerprintsfile
    self.id = id
    self.files = files
    self._hashStr = zlib.adler32 # our hash function
    self.explain = explain

  def _hashFile(self, f):
    x = open(f, "rb")
    result = self._hashStr(x.read())
    x.close() # for other Python implementations
    return result

  def check(self):
    if type(self.files) == type(""):
      self.files = split(self.files)
    result = false
    target = self.id
    if not has_key(self.fingers, target):
      self.fingers[target] = {}
      if self.explain: _Info(Subs("no entries for target '$1'", target))
      result = true
    for d in self.files:
      if Exists(d):
        n = self._hashFile(d)
        if not has_key(self.fingers[target], d) or n != self.fingers[target][d]:
          result = true
          if self.explain: _Info(Subs("'$1' modified since last build", d))
          self.fingers[target][d] = n
      else:
        Warn(Subs("'$1' does not exist!", d))
        result = true
    return result

  def update(self, filename):
    self.fingers[self.id][filename] = self._hashFile(filename)

  def success(self):
    pickle.dump(self.fingers, open(self.filename, "wb+"))


# --------------------------------------------------------------------------

def CogRule(name, filename, dependson):
  def processCog(filename):
    from cogapp import Cog
    ret = Cog().main([sys.argv[0], "-r", Path(filename)])
    return ret

  c = Changed(name, filename + " " + dependson, EXPLAIN)
  if c.check() or force:
    if processCog(filename) == 0:
      c.update(filename)
      c.success()
    else:
      Error("Cog failed")

_nim_exe = os.path.join(os.getcwd(), "bin", ExeExt("nim"))
_output_obj = os.path.join(os.getcwd(), "obj")
FPC_CMD = Subs(r"fpc -Cs16777216  -gl -bl -Crtoi -Sgidh -vw -Se1 -o$1 "
               r"-FU$2 $3", _nim_exe, _output_obj,
               os.path.join(os.getcwd(), "nim", "nimrod.pas"))

def buildRod(options):
  Exec(Subs("nim compile --compile:build/platdef.c $1 rod/nimrod", options))
  Move(ExeExt("rod/nimrod"), ExeExt("bin/nimrod"))

def cmd_nim():
  CogRule("nversion", "nim/nversion.pas", "koch.py")
  CogRule("msgs", "nim/msgs.pas", "data/messages.yml")
  CogRule("ast", "nim/ast.pas", "koch.py data/magic.yml data/ast.yml")
  CogRule("scanner", "nim/scanner.pas", "data/keywords.txt")
  CogRule("paslex", "nim/paslex.pas", "data/pas_keyw.yml")
  CogRule("wordrecg", "nim/wordrecg.pas", "data/keywords.txt")
  CogRule("commands", "nim/commands.pas",
          "data/basicopt.txt data/advopt.txt")
  CogRule("macros", "lib/macros.nim", "koch.py data/ast.yml")
  c = Changed("nim", Glob("nim/*.pas"), EXPLAIN)
  if c.check() or force:
    Exec(FPC_CMD)
    if Exists(ExeExt("bin/nim")):
      c.success()
    return true
  return false

def cmd_rod(options):
  prereqs = Glob("lib/*.nim") + Glob("rod/*.nim") + [
    "lib/nimbase.h", "lib/dlmalloc.c", "lib/dlmalloc.h",
    "config/nimrod.cfg"]
  c = Changed("rod", prereqs, EXPLAIN)
  if c.check() or cmd_nim() or force:
    buildRod(options)
    if Exists(ExeExt("bin/nimrod")):
      c.success()

# ------------------- constants -----------------------------------------------

HELP = Subs("""\
+-----------------------------------------------------------------+
|         Maintenance script for Nimrod                           |
|             Version $1|
|             (c) 2009 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Your Python version: $2

Usage:
  koch.py [options] command [options for command]
Options:
  --force, -f, -B, -b      forces rebuild
  --diff                   generates a diff.log file when bootstrapping
  --help, -h               shows this help and quits
  --no_fpc                 bootstrap without FPC
Possible Commands:
  nim                      builds the Pascal version of Nimrod
  rod [options]            builds the Nimrod version of Nimrod (with options)
  clean                    cleans Nimrod project; removes generated files
  boot [options]           bootstraps with given command line options
  rodsrc                   generates Nimrod version from Pascal version
  web                      generates the website
  profile                  profile the Nimrod compiler
  csource                  build the C sources for installation
  zip                      build the installation ZIP package
  inno                     build the Inno Setup installer
""", NIMROD_VERSION + ' ' * (44-len(NIMROD_VERSION)), sys.version)

def main(args):
  if len(args) == 0:
    print(HELP)
  else:
    i = 0
    while args[i][:1] == "-":
      a = args[i]
      if a in ("--force", "-f", "-B", "-b"):
        global force
        force = true
      elif a in ("-h", "--help", "-?"):
        print(HELP)
        return
      elif a == "--diff":
        global GENERATE_DIFF
        GENERATE_DIFF = true
      elif a == "--no_fpc":
        global USE_FPC
        USE_FPC = false
      else:
        Error("illegal option: " + a)
      i = i + 1
    cmd = args[i]
    if cmd == "rod": cmd_rod(join(args[i+1:]))
    elif cmd == "nim": cmd_nim()
    elif cmd == "clean": cmd_clean()
    elif cmd == "boot": cmd_boot(join(args[i+1:]))
    elif cmd == "rodsrc": cmd_rodsrc()
    elif cmd == "web": cmd_web()
    elif cmd == "profile": cmd_profile()
    elif cmd == "zip": cmd_zip()
    elif cmd == "inno": cmd_inno()
    elif cmd == "csource": cmd_csource()
    elif cmd == "install": cmd_install() # for backwards compability
    else: Error("illegal command: " + cmd)
    
def cmd_csource():
  Exec(Subs("nimrod cc -r tools/niminst --var:version=$1 csource rod/nimrod",
       NIMROD_VERSION))

def cmd_zip():
  Exec(Subs("nimrod cc -r tools/niminst --var:version=$1 zip rod/nimrod",
       NIMROD_VERSION))
  
def cmd_inno():
  Exec(Subs("nimrod cc -r tools/niminst --var:version=$1 inno rod/nimrod",
       NIMROD_VERSION))

def cmd_install():
  Exec("sh ./build.sh")

# -------------------------- bootstrap ----------------------------------------

def readCFiles():
  result = {}
  if GENERATE_DIFF:
    for f in Glob("rod/nimcache/rod/*.c") + Glob("rod/nimcache/lib/*.c"):
      x = os.path.split(f)[1]
      result[x] = open(f).readlines()[1:]
  return result

def genBootDiff(genA, genB):
  def interestingDiff(a, b):
    #a = re.sub(r"([a-zA-Z_]+)([0-9]+)", r"\1____", a)
    #b = re.sub(r"([a-zA-Z_]+)([0-9]+)", r"\1____", b)
    return a != b

  BOOTLOG = "bootdiff.log"
  result = false
  for f in Glob("diff/*.c"): Remove(f)
  if Exists(BOOTLOG): Remove(BOOTLOG)
  if GENERATE_DIFF:
    lines = [] # lines of the generated logfile
    if len(genA) != len(genB): Warn("number of generated files differ!")
    for filename, acontent in genA.items():
      bcontent = genB[filename]
      if bcontent != acontent:
        lines.append("------------------------------------------------------")
        lines.append(filename + " differs")
        # write the interesting lines to the log file:
        for i in range(min(len(acontent), len(bcontent))):
          la = acontent[i][:-1] # without newline!
          lb = bcontent[i][:-1]
          if interestingDiff(la, lb):
            lines.append(Subs("$1 - $2", i, la))
            lines.append(Subs("$1 + $2", i, lb))
        if len(acontent) > len(bcontent):
          cont = acontent
          marker = "-"
        else:
          cont = bcontent
          marker = "+"
        for i in range(min(len(acontent), len(bcontent)), len(cont)):
          lines.append(Subs("$1 $2 $3", i, marker, cont[i]))
        open(os.path.join("diff", "a_"+filename), "w+").write(join(acontent, ""))
        open(os.path.join("diff", "b_"+filename), "w+").write(join(bcontent, ""))
    if lines: result = true
    open(BOOTLOG, "w+").write(join(lines, "\n"))
  return result

def cmd_rodsrc():
  "converts the src/*.pas files into Nimrod syntax"
  PAS_FILES_BLACKLIST = split("""nsystem nmath nos osproc ntime strutils""")
  compiler = detectAndCompileNim()
  CMD = "$1 boot --skip_proj_cfg -o:rod/$2.nim nim/$3"
  result = false
  for fi in Glob("nim/*.pas"):
    f = FilenameNoExt(fi)
    if f in PAS_FILES_BLACKLIST: continue
    c = Changed(f+"__rodsrc", fi, EXPLAIN)
    if c.check() or force:
      Exec(Subs(CMD, compiler, f, f+".pas"))
      Exec(Subs("$1 parse rod/$2.nim", compiler, f))
      c.success()
      result = true
  return result

def moveExes():
  Move(ExeExt("rod/nimrod"), ExeExt("bin/nimrod"))

def cmd_boot(args):
  def myExec(compiler, args=args):
    Exec(Subs(BOOTCMD, compiler, args))
    # some C compilers (PellesC) output the executable to the
    # wrong directory. We work around this bug here:
    if Exists(ExeExt("rod/nimcache/nimrod")):
      Move(ExeExt("rod/nimcache/nimrod"), ExeExt("rod/nimrod"))

  writePlatdefC(getNimrodPath())
  compiler = detectAndCompileNim()
  cmd_rodsrc() # regenerate nimrod version of the files

  # move the new executable to bin directory (is done by cmd_rod())
  # use the new executable to compile the files in the bootstrap directory:
  myExec(compiler)
  genA = readCFiles() # first generation of generated C files
  # move the new executable to bin directory:
  moveExes()
  # compile again and compare:
  myExec("bin/nimrod") # here we always use the new executable
  genB = readCFiles() # second generation of generated C files
  diff = genBootDiff(genA, genB)
  if diff:
    Warn("generated C files are not equal: cycle once again...")
  # check if the executables are the same (they should!):
  if SameFileContent(Path(ExeExt("rod/nimrod")),
                     Path(ExeExt("bin/nimrod"))):
    Echo("executables are equal: SUCCESS!")
  else:
    Echo("executables are not equal: cycle once again...")
    diff = true
  if diff:
    # move the new executable to bin directory:
    moveExes()
    # use the new executable to compile Nimrod:
    myExec("bin/nimrod")
    if SameFileContent(Path(ExeExt("rod/nimrod")),
                       Path(ExeExt("bin/nimrod"))):
      Echo("executables are equal: SUCCESS!")
    else:
      Warn("executables are still not equal")

# ------------------ profile --------------------------------------------------
def cmd_profile():
  Exec(Subs(BOOTCMD, "nimrod", "-d:release --profiler:on"))
  moveExes()
  Exec(Subs(BOOTCMD, "nimrod", "--compile_only"))

# ------------------ web ------------------------------------------------------

def cmd_web():
  Exec(Subs("nimrod cc -r tools/nimweb.nim web/nimrod "
            "--putenv:nimrodversion=$1", NIMROD_VERSION))
       
# -----------------------------------------------------------------------------

def getVersion():
  return NIMROD_VERSION

# ------------------------------ clean ----------------------------------------

CLEAN_EXT = "ppu o obj dcu ~pas ~inc ~dsk ~dpr map tds err bak pyc exe rod"

def cmd_clean(dir = "."):
  L = []
  for x in split(CLEAN_EXT):
    L.append(r".*\."+ x +"$")
  extRegEx = re.compile(join(L, "|"))
  if Exists("koch.dat"): Remove("koch.dat")
  for f in Glob("*.pdb"): Remove(f)
  for f in Glob("*.idb"): Remove(f)
  for f in Glob("web/*.html"): Remove(f)
  for f in Glob("doc/*.html"): Remove(f)
  for f in Glob("rod/*.nim"): Remove(f) # remove generated source code
  def visit(extRegEx, dirname, names):
    if os.path.split(dirname)[1] == "nimcache":
      shutil.rmtree(path=dirname, ignore_errors=true)
      del names
    else:
      for name in names:
        x = os.path.join(dirname, name)
        if os.path.isdir(x): continue
        if (extRegEx.match(name)
        or (os.path.split(dirname)[1] == "tests" and ('.' not in name))):
          if find(x, "/dist/") < 0 and find(x, "\\dist\\") < 0:
            Echo("removing: " + x)
            Remove(x)
  os.path.walk(dir, visit, extRegEx)

def getHost():
  # incomplete list that sys.platform may return:
  # win32 aix3 aix4 atheos beos5 darwin freebsd2 freebsd3 freebsd4 freebsd5
  # freebsd6 freebsd7 generic irix5 irix6 linux2 mac netbsd1 next3 os2emx
  # riscos sunos5 unixware7
  x = replace(lower(re.sub(r"[0-9]+$", r"", sys.platform)), "-", "")
  if x == "win": return "windows"
  elif x == "darwin": return "macosx" # probably Mac OS X
  elif x == "sunos": return "solaris"
  else: return x

def mydirwalker(dir, L):
  for name in os.listdir(dir):
    path = os.path.join(dir, name)
    if os.path.isdir(path):
      mydirwalker(path, L)
    else:
      L.append(path)

# --------------- install target ----------------------------------------------

def getOSandProcessor():
  host = getHost()
  if host == "windows": processor = "i386" # BUGFIX
  else: processor = os.uname()[4]
  if lower(processor) in ("i686", "i586", "i468", "i386"):
    processor = "i386"
  if lower(processor) in ("x86_64", "x86-64", "amd64"):
    processor = "amd64" 
  if find(lower(processor), "sparc") >= 0:
    processor = "sparc"
  return (host, processor)

def writePlatdefC(nimrodpath):
  import os
  host, processor = getOSandProcessor()
  f = open(os.path.join(nimrodpath, "build/platdef.c"), "w+")
  f.write(Subs('/* Generated by koch.py */\n'
               'char* nimOS(void) { return "$1"; }\n'
               'char* nimCPU(void) { return "$2"; }\n'
               '\n', host, processor))
  f.close()

def getNimrodPath():
  if os.name == "posix":
    # Does not work 100% reliably. It is the best solution though.
    p = replace(sys.argv[0], "./", "")
    return os.path.split(os.path.join(os.getcwd(), p))[0]
  else: # Windows
    return os.path.split(sys.argv[0])[0]

# ------------------- main ----------------------------------------------------

if __name__ == "__main__":
  main(sys.argv[1:])
