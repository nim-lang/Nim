#! /usr/bin/env python

##########################################################################
##                                                                      ##
##             Build script of the Nimrod Compiler                      ##
##                      (c) 2008 Andreas Rumpf                          ##
##                                                                      ##
##########################################################################

import os, os.path, sys, re, shutil, cPickle, time, getopt, glob, zlib
from string import split, replace, lower, join, find, strip

if sys.version[0] >= "3": # this script does not work with Python 3.0
  sys.exit("wrong python version: use Python 1.5.2 or higher")

True = 0 == 0 # Python 1.5 does not have True and False :-(
False = 0 == 1

# --------------------- constants  ----------------------------------------

CC_FLAGS = "-w"  # modify to set flags to the first compilation step

NIMROD_VERSION = '0.6.6'
# This string contains Nimrod's version. It is the only place
# where the version needs to be updated. The rest is done by
# the build process automatically. It is replaced **everywhere**
# automatically!
# Format is: Major.Minor.Patch
# Major part: plan is to use number 1 for the first version that is stable;
#             higher versions may be incompatible with previous versions
# Minor part: incremented if new features are added (but is completely
#             backwards-compatible)
# Patch level: is increased for every patch

SUPPORTED_OSES = split("linux macosx freebsd netbsd openbsd solaris aix")
# The list of supported operating systems
SUPPORTED_CPUS = split("i386 amd64 sparc powerpc")
# The list of supported CPUs

SUPPORTED_PLATTFORMS = split("""
linux_i386* linux_amd64* linux_sparc
macosx_i386* macosx_amd64
solaris_i386 solaris_amd64 solaris_sparc
windows_i386* windows_amd64
""")
# a star marks the tested ones

NICE_NAMES = {
  "linux": "Linux",
  "macosx": "Mac OS X",
  "windows": "Windows",
  "solaris": "Solaris",
  "freebsd": "FreeBSD",
  "openbsd": "OpenBSD",
  "netbsd": "NetBSD",
}

EXPLAIN = True
force = False

GENERATE_DIFF = False
# if set, a diff.log file is generated when bootstrapping
# this uses quite a good amount of RAM (ca. 12 MB), so it should not be done
# on underpowered systems.

USE_FPC = True
INNOSETUP = r"c:\programme\innosetup5\iscc.exe /Q "
PYINSTALLER = r"C:\Eigenes\DownLoad\Python\pyinstaller-1.3"

BOOTCMD = "%s cc --compile:build/platdef.c %s rod/nimrod.nim"
# the command used for bootstrapping

# --------------------------------------------------------------------------

DOC = split("""endb intern lib manual nimrodc steps overview""")
SRCDOC = split("""system os strutils base/regexprs math complex times
            parseopt hashes strtabs lexbase parsecfg base/dialogs
            posix/posix
         """)

ADD_SRCDOC = split("""
                base/cairo/cairo  base/cairo/cairoft
                base/cairo/cairowin32  base/cairo/cairoxlib
                base/gtk/atk  base/gtk/gdk2 base/gtk/gdk2pixbuf
                base/gtk/gdkglext base/gtk/glib2  base/gtk/gtk2
                base/gtk/gtkglext base/gtk/gtkhtml base/gtk/libglade2
                base/gtk/pango base/gtk/pangoutils
                windows/windows windows/mmsystem windows/nb30
                windows/ole2 windows/shellapi windows/shfolder
            """)

# --------------------------------------------------------------------------

def Error(msg): sys.exit("[Koch] *** ERROR: " + msg)
def Warn(msg): print "[Koch] *** WARNING: " + msg
def Echo(msg): print "[Koch] " + msg
def _Info(msg): print "[Koch] " + msg

_FINGERPRINTS_FILE = "koch.dat"
  # in this file all the fingerprints are kept to allow recognizing when a file
  # has changed. This works reliably, which cannot be said from just taking
  # filetime-stamps.

def FileCmp(filenameA, filenameB):
  SIZE = 4096*2
  result = True
  a = open(filenameA, "rb")
  b = open(filenameB, "rb")
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

def Subs(frmt, **substitution):
  import string
  chars = string.digits+string.letters+"_"
  d = substitution
  result = []
  i = 0
  while i < len(frmt):
    if frmt[i] == '$':
      i = i+1
      if frmt[i] == '$':
        result.append('$')
        i = i+1
      elif frmt[i] == '{':
        i = i+1
        j = i
        while frmt[i] != '}': i = i+1
        i = i+1 # skip }
        result.append(d[frmt[j:i-1]])
      elif frmt[i] in string.letters+"_":
        j = i
        i = i+1
        while i < len(frmt) and frmt[i] in chars: i = i + 1
        result.append(d[frmt[j:i]])
      else:
        assert(false)
    else:
      result.append(frmt[i])
      i = i+1
  return join(result, "")

def SplitArg(s):
  if ':' in s: c = ':'
  elif '=' in s: c = '='
  else: return (s, '')
  i = s.find(c)
  return (s[:i], s[i+1:])

_baseDir = os.getcwd()
BaseDir = _baseDir

def Path(a):
  # Gets a UNIX like path and converts it to a path on this platform.
  # With UNIX like, I mean: slashes, not backslashes, only relative
  # paths ('../etc' can be used)
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
    Warn("could not remove: %s" % f)

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
  except IOError, OSError:
    Warn("could not move %s to %s" % (s, d))

def Copy(src, dest):
  s = Path(src)
  d = Path(dest)
  try:
    shutil.copyfile(s, d)
  except IOError, OSError:
    Warn("could not copy %s to %s" % (s, d))

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
  def __init__(self, id, files, explain=False,
               fingerprintsfile=_FINGERPRINTS_FILE):
    # load the fingerprints file:
    # fingerprints is a dict[target, files] where files is a dict[filename, hash]
    self.fingers = {} # default value
    if Exists(fingerprintsfile):
      try:
        self.fingers = cPickle.load(open(fingerprintsfile))
      except OSError:
        Error("Cannot read from " + fingerprintsfile)
    self.filename = fingerprintsfile
    self.id = id
    self.files = files
    self._hashStr = zlib.adler32 # our hash function
    self.explain = explain

  def _hashFile(self, f):
    x = open(f)
    result = self._hashStr(x.read())
    x.close() # for other Python implementations
    return result

  def check(self):
    if type(self.files) == type(""):
      self.files = split(self.files)
    result = False
    target = self.id
    if not self.fingers.has_key(target):
      self.fingers[target] = {}
      if self.explain: _Info("no entries for target '%s'" % target)
      result = True
    for d in self.files:
      if Exists(d):
        n = self._hashFile(d)
        if not self.fingers[target].has_key(d) or n != self.fingers[target][d]:
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
    cPickle.dump(self.fingers, open(self.filename, "w+"))


# --------------------------------------------------------------------------

def ask():
  return strip(lower(sys.stdin.readline()))

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
FPC_CMD = (r"fpc -Cs16777216  -gl -bl -Crtoi -Sgidh -vw -Se1 -o%s "
           r"-FU%s %s") % (_nim_exe, _output_obj,
           os.path.join(os.getcwd(), "nim", "nimrod.pas"))

def buildRod(options):
  Exec("nim compile --compile:build/platdef.c %s rod/nimrod" % options)
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
    return True
  return False

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

HELP = """\
+-----------------------------------------------------------------+
|         Maintenance script for Nimrod                           |
|             Version %s|
|             (c) 2008 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Your Python version: %s

Usage:
  koch.py [options] command [options for command]
Options:
  --force, -f, -B, -b      forces rebuild
  --diff                   generates a diff.log file when bootstrapping
  --help, -h               shows this help and quits
Possible Commands:
  install [options]        installs the Nimrod Compiler: options
                           are --cc=<compile command>, --ld=<link command>
  nim                      builds the Pascal version of Nimrod
  rod [options]            builds the Nimrod version of Nimrod (with options)
  installer                builds the installer (needs Inno Setup 5 on Windows)
  configure                configures the environment for developing Nimrod
  doc                      builds the documentation in HTML
  clean                    cleans Nimrod project; removes generated files
  srcdist                  produces src download package
  boot [options]           bootstraps with given command line options
  rodsrc                   generates Nimrod version from Pascal version
  web                      generates the website (requires Cheetah)
""" % (NIMROD_VERSION + ' ' * (44-len(NIMROD_VERSION)), sys.version)

def main(args):
  if len(args) == 0:
    print HELP
  else:
    i = 0
    while args[i][:1] == "-":
      a = args[i]
      if a in ("--force", "-f", "-B", "-b"):
        global force
        force = True
      elif a in ("-h", "--help", "-?"):
        print HELP
        return
      elif a == "--diff":
        global GENERATE_DIFF
        GENERATE_DIFF = True
      elif a == "--no_fpc":
        global USE_FPC
        USE_FPC = False
      else:
        Error("illegal option: " + a)
      i = i + 1
    cmd = args[i]
    if cmd == "rod": cmd_rod(join(args[i+1:]))
    elif cmd == "nim": cmd_nim()
    elif cmd == "installer": cmd_installer()
    elif cmd == "configure": cmd_configure()
    elif cmd == "doc": cmd_doc()
    elif cmd == "clean": cmd_clean()
    elif cmd == "dist":
      if i < len(args)-2:
        cmd_dist(args[i+1], args[i+2])
      elif i < len(args)-1:
        cmd_dist(args[i+1])
      else:
        cmd_dist()
    elif cmd == "alldist": cmd_alldist()
    elif cmd == "srcdist": cmd_srcdist()
    elif cmd == "boot": cmd_boot(join(args[i+1:]))
    #elif cmd == "tests": cmd_tests(join(args[i+1:]))
    elif cmd == "install": cmd_install(args[i+1:])
    elif cmd == "rodsrc": cmd_rodsrc()
    elif cmd == "web": cmd_web()
    else: Error("illegal command: " + cmd)

# -------------------------- bootstrap ----------------------------------------

def readCFiles():
  result = {}
  if GENERATE_DIFF:
    for f in Glob("rod/rod_gen/*.c") + Glob("lib/rod_gen/*.c"):
      x = os.path.split(f)[1]
      result[x] = open(f).readlines()[1:]
  return result

def genBootDiff(genA, genB):
  def interestingDiff(a, b):
    #a = re.sub(r"([a-zA-Z_]+)([0-9]+)", r"\1____", a)
    #b = re.sub(r"([a-zA-Z_]+)([0-9]+)", r"\1____", b)
    return a != b

  BOOTLOG = "bootdiff.log"
  result = False
  for f in Glob("diff/*.c"): Remove(f)
  if Exists(BOOTLOG): Remove(BOOTLOG)
  if GENERATE_DIFF:
    lines = [] # lines of the generated logfile
    if len(genA) != len(genB): Warn("number of generated files differ!")
    for filename, acontent in genA.iteritems():
      bcontent = genB[filename]
      #g = difflib.unified_diff(acontent, bcontent, filename + " generation A",
      #                        filename + " generation B", lineterm='')
      #for d in g: lines.append(d)
      if bcontent != acontent:
        lines.append("------------------------------------------------------")
        lines.append(filename + " differs")
        # write the interesting lines to the log file:
        for i in range(min(len(acontent), len(bcontent))):
          la = acontent[i][:-1] # without newline!
          lb = bcontent[i][:-1]
          if interestingDiff(la, lb):
            lines.append("%6d - %s" % (i, la))
            lines.append("%6d + %s" % (i, lb))
        if len(acontent) > len(bcontent):
          cont = acontent
          marker = "-"
        else:
          cont = bcontent
          marker = "+"
        for i in range(min(len(acontent), len(bcontent)), len(cont)):
          lines.append("%6d %s %s" % (i, marker, cont[i]))
        open(os.path.join("diff", "a_"+filename), "w+").write(join(acontent, ""))
        open(os.path.join("diff", "b_"+filename), "w+").write(join(bcontent, ""))
    if lines: result = True
    open(BOOTLOG, "w+").write(join(lines, "\n"))
  return result

def cmd_rodsrc():
  "converts the src/*.pas files into Nimrod syntax"
  PAS_FILES_BLACKLIST = split("""nsystem nmath nos ntime strutils""")
  if USE_FPC and detect("fpc -h"):
    cmd_nim()
    compiler = "nim"
  else:
    compiler = "nimrod"
  CMD = "%s boot --skip_proj_cfg -o:rod/%s.nim nim/%s"
  result = False
  for fi in Glob("nim/*.pas"):
    f = FilenameNoExt(fi)
    if f in PAS_FILES_BLACKLIST: continue
    c = Changed(f+"__rodsrc", fi, EXPLAIN)
    if c.check() or force:
      Exec(CMD % (compiler, f, f+".pas"))
      Exec("%s parse rod/%s.nim" % (compiler, f))
      c.success()
      result = True
  return result

def cmd_boot(args):
  def moveExes():
    Move(ExeExt("rod/nimrod"), ExeExt("bin/nimrod"))

  def myExec(compiler, args=args):
    Exec(BOOTCMD % (compiler, args))
    # some C compilers (PellesC) output the executable to the
    # wrong directory. We work around this bug here:
    if Exists(ExeExt("rod/rod_gen/nimrod")):
      Move(ExeExt("rod/rod_gen/nimrod"), ExeExt("rod/nimrod"))

  writePlatdefC(getNimrodPath())
  d = detect("fpc -h")
  if USE_FPC and d:
    Echo("'%s' detected" % d)
    cmd_nim()
    compiler = "nim"
  else:
    if not detect("nimrod") and not detect("bin/nimrod"): cmd_install(args)
    compiler = "nimrod"

  cmd_rodsrc() # regenerate nimrod version of the files

  # move the new executable to bin directory (is done by cmd_rod())
  # use the new executable to compile the files in the bootstrap directory:
  myExec(compiler)
  genA = readCFiles() # first generation of generated C files
  # move the new executable to bin directory:
  moveExes()
  # compile again and compare:
  myExec("nimrod")
  genB = readCFiles() # second generation of generated C files
  diff = genBootDiff(genA, genB)
  if diff:
    Warn("generated C files are not equal: cycle once again...")
  # check if the executables are the same (they should!):
  if FileCmp(Path(ExeExt("rod/nimrod")),
             Path(ExeExt("bin/nimrod"))):
    Echo("executables are equal: everything seems fine!")
  else:
    Echo("executables are not equal: cycle once again...")
    diff = True
  if diff:
    # move the new executable to bin directory:
    moveExes()
    # use the new executable to compile Nimrod:
    myExec("nimrod")
    if FileCmp(Path(ExeExt("rod/nimrod")),
               Path(ExeExt("bin/nimrod"))):
      Echo("executables are equal: SUCCESS!")
    else:
      Warn("executables are still not equal")

# ------------------ web ------------------------------------------------------

def buildDoc(destPath):
  # call nim for the documentation:
  for d in DOC:
    Exec("nimrod rst2html --putenv:nimrodversion=%s -o:%s/%s.html "
          "--index=%s/theindex doc/%s" %
         (NIMROD_VERSION, destPath, d, destPath, d))
  for d in SRCDOC:
    Exec("nimrod doc --putenv:nimrodversion=%s -o:%s/%s.html "
         "--index=%s/theindex lib/%s" %
         (NIMROD_VERSION, destPath, FilenameNoExt(d), destPath, d))
  Exec("nimrod rst2html -o:%s/theindex.html %s/theindex" % (destPath, destPath))

def buildAddDoc(destPath):
  # build additional documentation (without the index):
  for d in ADD_SRCDOC:
    c = Changed("web__"+d, ["lib/"+d+".nim"], EXPLAIN)
    if c.check() or force:
      Exec("nimrod doc --putenv:nimrodversion=%s -o:%s/%s.html "
           " lib/%s" % (NIMROD_VERSION, destPath, FilenameNoExt(d), d))
      c.success()

def buildDownloadTxt():
  # now unused!
  result = """\
    "There are two major products that come out of Berkeley: LSD and UNIX.
    We don't believe this to be a coincidence." -- Jeremy S. Anderson.

Here you can download the latest version of the Nimrod Compiler.
Please choose your platform:
"""
  for p in SUPPORTED_PLATTFORMS:
    ops, cpu = split(p, "_")
    n = NICE_NAMES[ops]
    if cpu[-1] == '*':
      cpu = cpu[:-1]
      tested = ""
    else:
      tested = ", untested!"
    result = result + Subs("* source for $nice (${cpu}${tested}): `<download/"
                           "nimrod_${ops}_${cpu}_${version}.zip>`_\n",
                           nice=n, ops=ops, cpu=cpu, tested=tested,
                           version=NIMROD_VERSION)
  result = result + Subs("""\
* installer for Windows (i386): `<download/nimrod_windows_${version}.exe>`_
  (includes LLVM and everything else you need)

.. include:: ../install.txt
""", version=NIMROD_VERSION)
  return result


def cmd_web():
  import Cheetah.Template
  # write the web/download.txt file, because maintaining it sucks:
  # - not anymore!
  #f = open("web/download.txt", "w+")
  #f.write(buildDownloadTxt())
  #f.close()

  TABS = [ # Our tabs: (Menu entry, filename)
    ("home", "index"),
    ("news", "news"),
    ("documentation", "documentation"),
    ("download", "download"),
    ("FAQ", "question"),
    ("links", "links")
  ]
  TEMPLATE_FILE = "web/sunset.tmpl"
  CMD = "nimrod rst2html --compileonly " \
        " --putenv:nimrodversion=%s -o:web/%s.temp web/%s.txt"

  buildAddDoc("web/upload")
  c = Changed("web", Glob("web/*.txt") + [TEMPLATE_FILE, "koch.py"] +
                     Glob("doc/*.txt") + Glob("lib/*.txt") + Glob("lib/*.nim")+
                     Glob("config/*.cfg") + ["install.txt"],
              EXPLAIN)
  if c.check() or force:
    cmd_nim() # we need Nimrod for processing the documentation
    Exec(CMD % (NIMROD_VERSION, "ticker","ticker"))
    tickerText = open("web/ticker.temp").read()
    for t in TABS:
      Exec(CMD % (NIMROD_VERSION, t[1],t[1]))

      tmpl = Cheetah.Template.Template(file=TEMPLATE_FILE)
      tmpl.content = open("web/%s.temp" % t[1]).read()
      tmpl.ticker = tickerText
      tmpl.tab = t[1]
      tmpl.tabs = TABS
      tmpl.lastupdate = time.strftime("%Y-%m-%d %X", time.gmtime())
      f = open("web/upload/%s.html" % t[1], "w+")
      f.write(str(tmpl))
      f.close()
    # remove temporaries:
    Remove("web/ticker.temp")
    for t in TABS: Remove("web/%s.temp" % t[1])
    buildDoc("web/upload")
    if Exists("web/upload/index.html"):
      c.success()

# ------------------ doc ------------------------------------------------------

def cmd_doc():
  c = Changed("doc", ["koch.py"] +
                     Glob("doc/*.txt") + Glob("lib/*.txt") + Glob("lib/*.nim")+
                     Glob("config/*.cfg"),
              EXPLAIN)
  if c.check() or force:
    cmd_nim() # we need Nimrod for processing the documentation
    buildDoc("doc")
    if Exists("doc/overview.html"):
      c.success()

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
    if os.path.split(dirname)[1] == "rod_gen":
      shutil.rmtree(path=dirname, ignore_errors=True)
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

# ----------------- distributions ---------------------------------------------

# Here are listed all files that should be included in the different
# distributions.

distlist = {
  'common': (
    "readme.txt",
    "todo.txt",
    "install.txt",
    "configure",
    "makefile",
    "*.html",
    "*.py",

    "lib/nimbase.h",
    "lib/cycle.h",
    "lib/tlsf.c",
    "lib/tlsf.h",
    "lib/target.h",
    "lib/dlmalloc.h",
    "lib/dlmalloc.c",
    "lib/*.nim",

    "rod/readme.txt",
    "build/empty.txt",
    "nim/*.*",

    "data/*.yml",
    "data/*.txt",
    "obj/*.txt",
    "diff/*.txt",

    "config/doctempl.cfg",
    # other config file is generated

    # documentation:
    "doc/*.txt",
    "doc/*.html",
    "doc/*.cfg",
    # tests:
    "tests/*.nim",
    "tests/*.html",
    "tests/*.txt",
    "tests/*.cfg",
    "tests/*.tmpl",
    "tests/gtk/*.nim",
    # library:
    "lib/base/*.c",
    "lib/base/*.nim",
    "lib/base/gtk/*.nim",
    "lib/base/cairo/*.nim",
    "lib/base/x11/*.nim",
    "lib/windows/*.nim",
    "lib/posix/*.nim",
    "lib/ecmas/*.nim",
    "lib/base/sdl/*.nim",
    "lib/base/opengl/*.nim",
    "lib/base/lua/*.nim",
  ),
  'windows': (
    "bin/nimrod.exe",
    "dist/llvm-gcc4.2",
  ),
  'unix': (
    "bin/empty.txt",
    "build",
  ),
  'build': (
    "lib/rod_gen/*.c",
    "rod/rod_gen/*.c",
    "lib/dlmalloc.c",
  )
}

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

def iterInstallFiles(target=getHost()):
  result = []
  for section in ['common', target]:
    for rule in distlist[section]:
      if os.path.isdir(Path(rule)):
        L = []
        mydirwalker(Path(rule), L)
        for f in L:
          result.append((f, f))
      else:
        for f in Glob(rule):
          if not os.path.isdir(f):
            result.append((Path(f), Path(f)))
  return result

def cmd_dist(ops="", cpu="i386"):
  import zipfile
  if not ops: ops = getHost()
  Exec("nimrod compile --force_build --compileonly " \
       " --os:%s --cpu:%s rod/nimrod.nim" % (ops, cpu))
  # assure that we transfer the right C files to the archive
  distfile = Path('web/upload/download/nimrod_%s_%s_%s.zip' %
                 (ops, cpu, getVersion()))
  Echo("creating: %s..." % distfile)
  z = zipfile.ZipFile(distfile, 'w', zipfile.ZIP_DEFLATED)
  if ops == "windows": target = "windows"
  else: target = "unix"
  for source, dest in iterInstallFiles(target):
    z.write(source, os.path.join("nimrod", Path(dest)))
  z.close()
  Echo("... done!")

def cmd_alldist():
  cmd_rodsrc()
  cmd_doc() # assure that the docs are packed
  if getHost() == "windows":
    # build the Windows installer too:
    cmd_installer()
  for p in SUPPORTED_PLATTFORMS:
    o, c = split(p, "_")
    c = replace(c, "*", "")
    cmd_dist(o, c)

def cmd_srcdist():
  def oscpu(o, c):
    x = SUPPORTED_OSES.index(o) + 1
    y = SUPPORTED_CPUS.index(c) + 1
    return str(x) + "_" + str(y)

  def buildDir(o, c):
    return "build/" + oscpu(o, c)

  for x in Glob("lib/*.h"): Copy(x, "build/" + os.path.split(x)[1])
  for o in SUPPORTED_OSES:
    for c in SUPPORTED_CPUS:
      p = buildDir(o, c)
      Mkdir(p)
      Exec("nimrod compile --force_build --compileonly " \
           " --os:%s --cpu:%s rod/nimrod.nim" % (o, c))
      for pattern in distlist["build"]:
        for source in Glob(pattern):
          Copy(source, p + "/" + os.path.split(source)[1])
  # second pass: remove duplicate files
  index = {}
  files = {"platdef.c": 1}
  for osys in SUPPORTED_OSES:
    for cpu in SUPPORTED_CPUS:
      p = buildDir(osys, cpu)
      for filename in Glob(p + "/*.*"):
        f = os.path.split(filename)[1]
        if os.path.splitext(f)[1] == ".c":
          files[f] = 1
        key = "%s_%s/%s" % (osys, cpu, f)
        if not index.has_key(key):
          index[key] = oscpu(osys, cpu)
        matches = 0
        total = 0
        for o in SUPPORTED_OSES:
          for c in SUPPORTED_CPUS:
            q = buildDir(o, c)
            if Exists(q + "/" + f) and FileCmp(q + "/" + f, filename):
              # file is identical to some other, so delete duplicates
              if matches > 0:
                Remove(q + "/" + f)
                index["%s_%s/%s" % (o, c, f)] = oscpu(osys, cpu)
              matches = matches + 1
            total = total + 1

  listing = open(Path("build/listing.txt"), "w+")
  for key, val in index.items(): listing.write("%s: %s\n" % (key, val))
  listing.close()
  listing = open(Path("build/files.txt"), "w+")
  for key, val in files.items(): listing.write("%s\n" % key)
  listing.close()

# ------------------ config template -----------------------------------------

CONFIG_TEMPLATE = r"""# Configuration file for the Nimrod Compiler.
# Template from the koch.py script.

# Feel free to edit the default values as you need.

# You may set environment variables with
# @putenv "key" "val"
# Environment variables cannot be used in the options, however!

# Just call the compiler with several options:
cc = $defaultcc
lib="$$nimrod/lib"
path="$$lib/base"
path="$$lib/base/gtk"
path="$$lib/base/cairo"
path="$$lib/base/x11"
path="$$lib/base/sdl"
path="$$lib/base/opengl"
path="$$lib/windows"
path="$$lib/posix"
path="$$lib/ecmas"
path="$$lib/extra"


@if release:
  checks:off
  stacktrace:off
  debugger:off
  line_dir:off
  opt:speed
@end

# additional defines:
#define=""
# additional options always passed to the compiler:
line_dir=off

hint[LineTooLong]=off
hint[XDeclaredButNotUsed]=off

@if unix:
  @if not bsd: passl= "-ldl" @end
@end

@if icc:
  passl = "-cxxlib"
  passc = "-cxxlib"
@end

# Configuration for the LLVM GCC compiler:
@if windows:
  llvm_gcc.path = r"$$nimrod\dist\llvm-gcc4.2\bin"
@end
llvm_gcc.options.debug = "-g"
llvm_gcc.options.always = "-w"
llvm_gcc.options.speed = "-O2 -ffast-math"
llvm_gcc.options.size = "-Os -ffast-math"

# Configuration for the Borland C++ Compiler:
@if windows:
  bcc.path = r"${bcc_path}"
@end
bcc.options.debug = ""
# turn off warnings about unreachable code and inline procs:
bcc.options.always = "-w- -H- -q -RT- -a8 -w-8027 -w-8066"
bcc.options.speed = "-O2 -6"
bcc.options.size = "-O1 -6"

# Configuration for the Visual C/C++ compiler:
@if vcc:
  @prepend_env path r"${vcc_path}\..\..\Common7\IDE;"
  @prepend_env INCLUDE r"${vcc_path}\..\include;$vcc_path\..\ATLMFC\INCLUDE;"
  @prepend_env LIB r"${vcc_path}\..\lib;$vcc_path\..\..\SDK\v2.0\Lib;"
  passl: r"/F33554432" # set the stack size to 32 MB
@end
@if windows:
  vcc.path = r"${vcc_path}"
@end
vcc.options.debug = "/RTC1 /ZI"
vcc.options.always = "/nologo"
vcc.options.speed = "/Ogityb2 /G7 /arch:SSE2"
vcc.options.size = "/O1 /G7"

# Configuration for the Watcom C/C++ compiler:
@if windows:
  wcc.path = r""
@end
wcc.options.debug = "-d2"
wcc.options.always = "-6 -zw -w-"
wcc.options.speed = "-ox -on -6 -d0 -fp6 -zW"
wcc.options.size = "-ox -on -6 -d0 -fp6 -zW"

# Configuration for the GNU C/C++ compiler:
@if windows:
  gcc.path = r"${gcc_path}"
@end
gcc.options.debug = "-g"
@if macosx:
  gcc.options.always = "-w -fasm-blocks"
@else:
  gcc.options.always = "-w"
@end
gcc.options.speed = "-O2 -ffast-math"
gcc.options.size = "-Os -ffast-math"

# Configuration for the Digital Mars C/C++ compiler:
@if windows:
  dmc.path = r"${dmc_path}"
@end
dmc.options.debug = "-g"
dmc.options.always = "-Jm"
dmc.options.speed = "-ff -o -6"
dmc.options.size = "-ff -o -6"

# Configuration for the LCC compiler:
@if windows:
  lcc.path = r"${lcc_path}"
@end
lcc.options.debug = "-g5"
lcc.options.always = "-e1"
lcc.options.speed = "-O -p6"
lcc.options.size = "-O -p6"

# Configuration for the Tiny C Compiler:
@if windows:
  tcc.path = r""
@end
tcc.options.debug = "-b"
tcc.options.always = ""
tcc.options.speed = ""
tcc.options.size = ""

# Configuration for the Pelles C compiler:
@if windows:
  pcc.path = r"${pcc_path}"
@end
pcc.options.debug = "-Zi"
pcc.options.always = "-Ze"
pcc.options.speed = "-Ox"
pcc.options.size = "-Os"

@if windows:
  icc.path = r""
@end
icc.options.debug = "-g"
icc.options.always = "-w"
icc.options.speed = "-O2 -ffast-math"
icc.options.size = "-Os -ffast-math"

@write "used default config file"
"""

# ------------------------------ windows installer ----------------------------

WIN_INSTALLER_TEMPLATE = (r"""; File generated by koch.py
; Template by Andreas Rumpf
[Setup]
AppName=Nimrod Compiler
AppVerName=Nimrod Compiler $version
DefaultDirName={code:GiveMeAPath|nimrod}
DefaultGroupName=Nimrod
AllowNoIcons=yes
LicenseFile=nim\copying.txt
OutputDir=web\upload\download
OutputBaseFilename=nimrod_windows_$version
Compression=lzma
SolidCompression=yes
PrivilegesRequired=none
ChangesEnvironment=yes

[Languages]
Name: english; MessagesFile: compiler:Default.isl

[Files]
$files

[Icons]
Name: {group}\Console for Nimrod; Filename: {cmd}
Name: {group}\Documentation; Filename: {app}\doc\overview.html
Name: {group}\{cm:UninstallProgram,Nimrod Compiler}; Filename: {uninstallexe}

[UninstallDelete]
Type: files; Name: "{app}\config\nimrod.cfg"

;[Run]
;Filename: "{app}\bin\nimconf.exe"; Description: "Launch configuration"; """ +
r"""Flags: postinstall nowait skipifsilent

[Tasks]
Name: generateconfigfile; """ +
r"""Description: &Generate configuration file;
Name: modifypath; Description: """ +
r"""&Add Nimrod your system path (if not in path already);

[Code]
function GiveMeAPath(const DefaultPathName: string): string;
begin
  if IsAdminLoggedOn then Result := ExpandConstant('{pf}')
  else Result := ExpandConstant('{userdocs}');
  Result := Result + '\' + DefaultPathName;
end;

// ----------------------------------------------------------------------------
//
// Inno Setup Ver:  5.2.1
// Script Version:  1.3.1
// Author:          Jared Breland <jbreland@legroom.net>
// Homepage:    http://www.legroom.net/software
//
// Script Function:
//  Enable modification of system path directly from Inno Setup installers
//
// Instructions:
//  Copy modpath.iss to the same directory as your setup script
//
//  Add this statement to your [Setup] section
//    ChangesEnvironment=yes
//
//  Add this statement to your [Tasks] section
//  You can change the Description or Flags, but the Name must be modifypath
//    Name: modifypath; Description: &Add application directory to your
//    system path; Flags: unchecked
//
//  Add the following to the end of your [Code] section
//  setArrayLength must specify the total number of dirs to be added
//  Dir[0] contains first directory, Dir[1] contains second, etc.

function ModPathDir(): TArrayOfString;
begin
  setArrayLength(result, 2);
  result[0] := ExpandConstant('{app}') + '\bin';
  result[1] := ExpandConstant('{app}') + '\dist\llvm-gcc4.2\bin';
end;

// ----------------------------------------------------------------------------

procedure ModPath();
var
  oldpath, newpath, aExecFile: String;
  pathArr, aExecArr, pathdir: TArrayOfString;
  i, d: Integer;
begin
  // Get array of new directories and act on each individually
  pathdir := ModPathDir();
  for d := 0 to GetArrayLength(pathdir)-1 do begin
    // Modify WinNT path
    if UsingWinNT() then begin
      // Get current path, split into an array
      RegQueryStringValue(HKEY_LOCAL_MACHINE,
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        'Path', oldpath);
      oldpath := oldpath + ';';
      i := 0;
      while (Pos(';', oldpath) > 0) do begin
        SetArrayLength(pathArr, i+1);
        pathArr[i] := Copy(oldpath, 0, Pos(';', oldpath)-1);
        oldpath := Copy(oldpath, Pos(';', oldpath)+1, Length(oldpath));
        i := i + 1;
        // Check if current directory matches app dir
        if pathdir[d] = pathArr[i-1] then begin
          // if uninstalling, remove dir from path
          if IsUninstaller() then continue
          // if installing, abort because dir was already in path
          else abort;
        end;
        // Add current directory to new path
        if i = 1 then newpath := pathArr[i-1]
        else newpath := newpath + ';' + pathArr[i-1];
      end;
      // Append app dir to path if not already included
      if not IsUninstaller() then
        newpath := newpath + ';' + pathdir[d];
      // Write new path
      RegWriteStringValue(HKEY_LOCAL_MACHINE,
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        'Path', newpath);
    end
    else begin
      // Modify Win9x path
      // Convert to shortened dirname
      pathdir[d] := GetShortName(pathdir[d]);
      // If autoexec.bat exists, check if app dir already exists in path
      aExecFile := 'C:\AUTOEXEC.BAT';
      if FileExists(aExecFile) then begin
        LoadStringsFromFile(aExecFile, aExecArr);
        for i := 0 to GetArrayLength(aExecArr)-1 do begin
          if not IsUninstaller() then begin
            // If app dir already exists while installing, abort add
            if (Pos(pathdir[d], aExecArr[i]) > 0) then
              abort;
          end
          else begin
            // If app dir exists and = what we originally set,
            // then delete at uninstall
            if aExecArr[i] = 'SET PATH=%PATH%;' + pathdir[d] then
              aExecArr[i] := '';
          end;
        end;
      end;
      // If app dir not found, or autoexec.bat didn't exist, then
      // (create and) append to current path
      if not IsUninstaller() then begin
        SaveStringToFile(aExecFile, #13#10 + 'SET PATH=%PATH%;' + pathdir[d],
                         True);
      end
      else begin
        // If uninstalling, write the full autoexec out
        SaveStringsToFile(aExecFile, aExecArr, False);
      end;
    end;

    // Write file to flag modifypath was selected
    // Workaround since IsTaskSelected() cannot be called at uninstall and
    // AppName and AppId cannot be "read" in Code section
    if not IsUninstaller() then
      SaveStringToFile(ExpandConstant('{app}') + '\uninsTasks.txt',
                       WizardSelectedTasks(False), False);
  end;
end;

// We check for C compilers in the following order:
//   Visual C++ (via registry), Borland C++ (via registry),
//   Lcc (via registry), Pcc (via registry), DMC (via PATH),
//   LLVM-GCC (via PATH), GCC (via PATH)
// The user is informed which C compilers have been found and whether
// LLVM-GCC should be installed
const
  IdxVisualC = 0;
  IdxBorlandC = 1;
  IdxLcc = 2;
  IdxPcc = 3;
  IdxDMC = 4;
  IdxLLVMGCC = 5;
  IdxGCC = 6;
  NumberCC = 7; // number of C compilers

function idxToLongName(idx: integer): string;
begin
  case idx of
    IdxVisualC: result := 'Microsoft Visual C/C++ Compiler';
    IdxBorlandC: result := 'Borland C/C++ Compiler';
    IdxLcc: result := 'Jacob Navia''s LCC-win32';
    IdxPcc: result := 'Pelles C Compiler';
    IdxDMC: result := 'Digital Mars C/C++ Compiler';
    IdxLLVMGCC: result := 'LLVM GCC Compiler';
    IdxGCC: result := 'GNU C/C++ Compiler';
    else result := '';
  end
end;

function idxToShortName(idx: integer): string;
begin
  case idx of
    IdxVisualC: result := 'vcc';
    IdxBorlandC: result := 'bcc';
    IdxLcc: result := 'lcc';
    IdxPcc: result := 'pcc';
    IdxDMC: result := 'dmc';
    IdxLLVMGCC: result := 'llvm_gcc';
    IdxGCC: result := 'gcc';
    else result := '';
  end
end;

function idxToExe(idx: integer): string;
begin
  case idx of
    IdxVisualC: result := 'cl.exe';
    IdxBorlandC: result := 'bcc32.exe';
    IdxLcc: result := 'lcc.exe';
    IdxPcc: result := 'cc.exe';
    IdxDMC: result := 'dmc.exe';
    IdxLLVMGCC: result := 'llvm-gcc.exe';
    IdxGCC: result := 'gcc.exe';
    else result := '';
  end
end;

function ReadStrFromRegistry(const RootKey: Integer;
                             const SubKeyName, ValueName: String): string;
begin
  result := '';
  RegQueryStringValue(rootKey, removeBackslash(subkeyName),
                      valueName, result);
end;

function detectCCompiler(idx: integer): string;
var
  i: integer;
begin
  result := '';
  case idx of
    IdxVisualC: begin
      for i := 20 downto 6 do begin
        result := ReadStrFromRegistry(HKEY_LOCAL_MACHINE,
          'SOFTWARE\Microsoft\DevStudio\' + IntToStr(i) +
          '.0\Products\Microsoft Visual C++\', 'ProductDir');
        if result <> '' then begin
          result := result + '\bin'; // the path we want needs a \bin
          break
        end;
        result := ReadStrFromRegistry(HKEY_LOCAL_MACHINE,
          'SOFTWARE\Microsoft\VisualStudio\' + IntToStr(i) +
          '.0\Setup', 'Dbghelp_path');
        if result <> '' then
          result := ReadStrFromRegistry(HKEY_LOCAL_MACHINE,
            'SOFTWARE\Microsoft\VCExpress\' + IntToStr(i) +
            '.0\', 'InstallDir');
        if result <> '' then begin
          // something like: 'C:\eigenes\compiler\vcc2005\Common7\IDE\'
          // we need: 'C:\eigenes\compiler\vcc2005\vc\bin'
          result := ExtractFilePath(RemoveBackslash(
                       ExtractFilePath(RemoveBackslash(result))))
            + 'vc\bin'; // the path we want needs a vc\bin
          break
        end
      end
    end;
    IdxBorlandC: begin
      for i := 20 downto 2 do begin
        result := ReadStrFromRegistry(HKEY_LOCAL_MACHINE,
          'SOFTWARE\Borland\C++Builder\' + IntToStr(i) + '.0\', 'RootDir');
        if result <> '' then begin
          result := result + '\bin';
          break
        end
      end
    end;
    IdxLcc: begin
      result := ReadStrFromRegistry(HKEY_CURRENT_USER,
        'Software\lcc\compiler\', 'includepath');
      if result <> '' then begin
        result := RemoveBackslash(ExtractFilePath(result)) + '\bin';
        // because we get something like 'c:\..\lcc\include'
      end
    end;
    IdxPcc: begin
      result := ReadStrFromRegistry(HKEY_LOCAL_MACHINE,
        'SOFTWARE\PellesC', '');
      if result <> '' then
        result := result + '\bin';
    end;
    else begin end
  end;
  if (result <> '') then
    if not FileExists(RemoveBackslash(result) + '\' + idxToExe(idx)) then
      result := '';
end;

function myfind(const x: string; const inArray: array of string): integer;
var
  i: integer;
begin
  i := 0;
  while i < GetArrayLength(inArray)-1 do begin
    if CompareText(x, inArray[i]) = 0 then begin
      result := i; exit
    end;
    i := i + 2;
  end;
  result := -1
end;

function mycopy(const s: string; a, b: integer): string;
begin
  result := copy(s, a, b-a+1);
end;

function isPatternChar(c: Char): boolean;
begin
  result := (c >= 'a') and (c <= 'z') or
            (c >= 'A') and (c <= 'Z') or
            (c >= '0') and (c <= '9') or
            (c = '_');
end;

function myformat(const f: string; const args: array of string): string;
var
  i, j, x: integer;
begin
  result := '';
  i := 1;
  while i <= length(f) do
    if f[i] = '$' then begin
      case f[i+1] of
        '$': begin
          result := result + '$';
          i := i + 2;
        end;
        '1', '2', '3', '4', '5', '6', '7', '8', '9': begin
          result := result + args[ord(f[i+1]) - ord('0') - 1];
          i := i + 2;
        end;
        '{': begin
          j := i+1;
          while (j <= length(f)) and (f[j] <> '}') do j := j+1;
          x := myfind(mycopy(f, i+2, j-1), args);
          if (x >= 0) and (x < GetArrayLength(args)-1) then
            result := result + args[x+1];
          i := j+1
        end;
        else if isPatternChar(f[i+1]) then begin
          j := i+1;
          while (j <= length(f)) and isPatternChar(f[j]) do j := j +1;
          x := myfind(mycopy(f, i+1, j-1), args);
          if (x >= 0) and (x < GetArrayLength(args)-1) then
            result := result + args[x+1];
          i := j
        end
        else i := i + 1;
      end
    end
    else begin
      result := result + f[i];
      i := i + 1;
    end
end;

$config_template

procedure generateconfigfile();
var
  data: TArrayOfString;
  i: integer;
  outfile, d: string;
begin
  // set default compiler:
  setArrayLength(data, (NumberCC+2) * 2); // *2 for key: value pairs
  data[0] := 'defaultcc';
  for i := 0 to NumberCC-1 do begin
    data[4+i*2] := idxToShortName(i) + '_path';
    d := detectCCompiler(i);
    data[5+i*2] := d;
    if d <> '' then begin
      if data[1] = '' then data[1] := idxToShortName(i);
      // first found C compiler is default
    end
  end;
  if data[1] = '' then data[1] := 'llvm_gcc';
  // set the library path:
  data[2] := 'libpath';
  data[3] := ExpandConstant('{app}') + '\lib';
  // write the file:
  outfile := ExpandConstant('{app}') + '\config\nimrod.cfg';
  SaveStringToFile(outfile, myformat(template, data), false);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then begin
    if IsTaskSelected('modifypath') then
      ModPath();
    if IsTaskSelected('generateconfigfile') then
      generateconfigfile();
  end
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  appdir, selectedTasks: String;
begin
  appdir := ExpandConstant('{app}');
  if CurUninstallStep = usUninstall then begin
    if LoadStringFromFile(appdir + '\uninsTasks.txt', selectedTasks) then
      if Pos('modifypath', selectedTasks) > 0 then
        ModPath();
    DeleteFile(appdir + '\uninsTasks.txt')
  end;
end;

function NeedRestart(): Boolean;
begin
  result := IsTaskSelected('modifypath') and not UsingWinNT()
end;
""")

def makeKochExe():
  c = Changed("kochexe",
             split("koch.py misc/koch.ico"), EXPLAIN)
  if c.check() or force:
    Exec("python " + Join(PYINSTALLER, "Makespec.py") +
         " --onefile --ascii --icon=misc/koch.ico koch.py")
    Exec("python " + Join(PYINSTALLER, "Build.py") + " koch.spec")
    Remove("koch.spec")
    Remove("warnkoch.txt")
    RemoveDir("buildkoch")
    c.success()

def cmd_wininstaller():
  FILENAME = "install_nimrod.iss"
  cmd_doc()
  # generate an installer file
  files = []
  for source, dest in iterInstallFiles("windows"):
    files.append("Source: " + source + "; DestDir: {app}\\" +
              os.path.split(dest)[0] + "; Flags: ignoreversion\n")
  f = open(FILENAME, "w+")
  pasconfig = ["const template = ''"]
  for line in split(CONFIG_TEMPLATE, '\n'):
    pasconfig.append("  + '%s'+#13#10\n" % line)
  pasconfig.append(";\n")
  f.write(Subs(WIN_INSTALLER_TEMPLATE, files=join(files, ""),
               version=getVersion(),
               config_template=join(pasconfig, "")))
  f.close()
  if RawExec(INNOSETUP + FILENAME) == 0:
    # we cannot use ``Exec()`` here as this would
    # mangle the ``/Q`` switch to ``\Q``
    Remove(FILENAME)

def cmd_posixinstaller():
  try:
    import zipfile
  except ImportError:
    Error("try a more decent Python version for this functionality")
  # assure that we transfer the right C files to the archive
  distfile = Path('web/upload/download/nimrod_src_%s.zip' % NIMROD_VERSION)
  Echo("creating: %s..." % distfile)
  z = zipfile.ZipFile(distfile, 'w', zipfile.ZIP_DEFLATED)
  for source, dest in iterInstallFiles("unix"):
    z.write(source, os.path.join("nimrod", Path(dest)))
  z.close()
  Echo("... done!")

# --------------- install target ----------------------------------------------

def getOSandProcessor():
  host = getHost()
  if host == "windows": processor = "i386" # BUGFIX
  else: processor = os.uname()[4]
  if lower(processor) in ("i686", "i586", "i468", "i386"):
    processor = "i386"
  if find(lower(processor), "sparc") >= 0:
    processor = "sparc"
  return (host, processor)

def writePlatdefC(nimrodpath):
  import os
  host, processor = getOSandProcessor()
  f = open(os.path.join(nimrodpath, "build/platdef.c"), "w+")
  f.write('/* Generated by koch.py */\n'
          'char* nimOS(void) { return "%s"; }\n'
          'char* nimCPU(void) { return "%s"; }\n'
          '\n' % (host, processor))
  f.close()

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

def lookForCC():
  if os.environ.has_key("CC"):
    Echo("using $CC environment variable (%s)" % os.environ["CC"])
    return os.environ["CC"]
  d = detect("gcc -v")
  if d:
    Echo("'%s' detected" % d)
    return "gcc"
  Echo("GCC not found. Testing for generic CC...")
  d = detect("cc -v")
  if d:
    Echo("'%s' detected" % d)
    return "ucc"
  Echo("...not found!")
  Error("No C compiler could be found!")
  return ""

def getNimrodPath():
  if os.name == "posix":
    # Does not work 100% reliably. It is the best solution though.
    p = replace(sys.argv[0], "./", "")
    return os.path.split(os.path.join(os.getcwd(), p))[0]
  else: # Windows
    return os.path.split(sys.argv[0])[0]

def writeCfg(nimrodpath, ccSymbol=None):
  if not ccSymbol:
    ccSymbol = lookForCC()
  configFile = os.path.join(nimrodpath, os.path.join("config", "nimrod.cfg"))
  script = Subs(CONFIG_TEMPLATE, defaultcc=ccSymbol,
                gcc_path="", lcc_path="", llvm_gcc_path="",
                pcc_path="", bcc_path="", dmc_path="",
                vcc_path="", wcc_path="")
  try:
    config = open(configFile)
  except IOError:
    config = None
  if config:
    if strip(config.read()) != strip(script):
      config.close()
      Echo("Configuration file already exists and "
           "seems to have been modified.\n"
           "Do you want to override it? (y/n) ")
      while True:
        a = ask()
        if a in ("y", "yes"):
          f = open(configFile, "w+")
          f.write(script)
          f.close()
          break
        elif a in ("n", "no"):
          break
        else:
          Echo("What do you mean? (y/n) ")
    else:
      config.close()
  else:
    open(configFile, "w+").write(script)
  return ccSymbol

def cmd_install(args):
  o, c = getOSandProcessor()
  if o in ("freebsd", "openbsd", "netbsd"):
    # BUGFIX: BSD does not need nor support '-ldl'
    LINK_OPTIONS = " -lm -o bin/nimrod "
  else:
    LINK_OPTIONS = " -ldl -lm -o bin/nimrod "
  nimrodpath = getNimrodPath()
  Echo("Nimrod should be in '%s'" % nimrodpath)
  # We know that the user has already unzipped this archive into the
  # final directory. So we just create the config file and build Nimrod.

  Echo("Operating system: " + o)
  Echo("Processor: " + c)
  if o not in SUPPORTED_OSES:
    Error("This installer does not support your operating system")
  if c not in SUPPORTED_CPUS:
    Error("This installer does not support your processor")
  try:
    opts, args = getopt.getopt(args, "", ["cc=", "ld="])
  except getopt.GetoptError:
    # print help information and exit:
    Error("Command line contains errors")
  ccSymbol = None
  ldSymbol = None
  for a, b in opts:
    if a == "--cc":   ccSymbol = b
    elif a == "--ld": ldSymbol = b

  # write the configuration file, but check if one exists!
  ccSymbol = writeCfg(nimrodpath, ccSymbol)
  if not ldSymbol:
    ldSymbol = split(ccSymbol)[0] + LINK_OPTIONS

  writePlatdefC(nimrodpath)

  # build Nimrod
  link = [] # store the .o files in here for final linking step
  listing = {}
  files = []
  try:
    filesf = open("build/files.txt")
    files = map(lambda x: x[:-1], filesf.readlines())
    filesf.close()
    listingf = open("build/listing.txt")
    for L in listingf.readlines():
      kv = split(L[:-1], ':', 1)
      listing[kv[0]] = kv[1][1:]
    listingf.close()
  except IOError:
    Error("installation needs ``build/files.txt`` " +
          "and ``build/listing.txt`` files")
  for filename in files:
    f = "build/" + filename
    if not Exists(f):
      f = "build/" + listing[o + "_" + c + "/" + filename] + "/" + filename
    objfile = os.path.splitext(f)[0] + ".o"
    link.append(objfile)
    # compile only:
    if Exec(ccSymbol + " " + CC_FLAGS +
            " -Ibuild -c -o " + objfile + " " + f) != 0:
      Error("the C compiler did not like: " + f)

  if not link:
    Error("could not find Nimrod's sources\n"
          "    (they should be in the build subdirectory)")
  # now link the stuff together:
  if Exec(ldSymbol + join(link)) != 0:
    Error("the linking step failed!")
  # now we have a Nimrod executable :-)
  # remove the generated .o files as they take 1 MB easily:
  for f in link: Remove(f)
  Echo("SUCCESS!")

def cmd_installer():
  if os.name == "posix":
    cmd_posixinstaller()
  else: # Windows
    cmd_wininstaller()


# ------------------ configure ------------------------------------------------

def cmd_configure():
  d = detect("fpc -h")
  if d:
    Echo("'%s' detected" % d)
  else:
    Warn("Free Pascal is not installed, bootstrapping may not work properly.")
  writeCfg(getNimrodPath())
  Echo("Configuration sucessful!")

# ------------------- main ----------------------------------------------------

if __name__ == "__main__":
  main(sys.argv[1:])
