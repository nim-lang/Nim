#! /usr/bin/env python

##########################################################################
##                                                                      ##
##             Build script of the Nimrod Compiler                      ##
##                      (c) 2008 Andreas Rumpf                          ##
##                                                                      ##
##########################################################################

import os, os.path, sys, re, zipfile, filecmp, shutil, cPickle, time
import string, getopt, textwrap, glob, shutil, getopt, string


if sys.version_info[0] >= 3: # this script does not work with Python 3.0
  sys.exit("wrong python version: use Python 2.x")

from kochmod import *

# --------------------- constants  ----------------------------------------

CFLAGS = ""  # modify to set flags to the first compilation step

NIMROD_VERSION = '0.2.1'
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


EXPLAIN = True
force = False

INNOSETUP = r"c:\programme\innosetup5\iscc.exe /Q "
ADV_SETUP = r"C:\Programme\AdvancedInstaller6.1\AdvancedInstaller.com " \
            r"/build %s -force"
PYINSTALLER = r"C:\Eigenes\DownLoad\Python\pyinstaller-1.3"

# --------------------------------------------------------------------------

def ask():
  return sys.stdin.readline().strip("\t \n\r\f").lower()

def CogRule(name, filename, dependson):
  def processCog():
    from cogapp import Cog
    ret = Cog().main([sys.argv[0], "-r", Path(filename)])
    return ret

  c = Changed(name, filename + " " + dependson, EXPLAIN)
  if c or force:
    if processCog() == 0:
      c.update(filename)
      c.success()

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
          "data/basicopt.txt data/advopt.txt data/changes.txt")
  c = Changed("nim", Glob("nim/*.pas"),
              EXPLAIN)
  if c or force:
    Exec(FPC_CMD)
    if Exists(ExeExt("bin/nim")):
      c.success()

def cmd_rod(options):
  cmd_nim()
  prereqs = Glob("lib/*.nim") + Glob("rod/*.nim") + [
    "lib/nimbase.h", "lib/dlmalloc.c", "lib/dlmalloc.h",
    "config/nimrod.cfg"]
  c = Changed("rod", prereqs, EXPLAIN)
  if c or force:
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

Usage:
  koch.py [options] command [options for command]
Options:
  --force, -f, -B, -b      force rebuild
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
  dist                     produces a distribution as
                           nimrod_$target_$version.zip
  boot [options]           bootstraps with given command line options
  tests [options]          runs the complete testsuite (with options)
  rodsrc                   generates Nimrod version from Pascal version
  web                      generates the website (requires Cheetah)
""" % (NIMROD_VERSION + ' ' * (44-len(NIMROD_VERSION)))

def main(args):
  if len(args) == 0:
    print HELP
  else:
    i = 0
    while args[i].startswith("-"):
      a = args[i]
      if a in ("--force", "-f", "-B", "-b"):
        global force
        force = True
      elif a in ("-h", "--help", "-?"):
        print HELP
        return
      else:
        Error("illegal option: " + a)
      i += 1
    cmd = args[i]
    if cmd == "rod": cmd_rod(" ".join(args[i+1:]))
    elif cmd == "nim": cmd_nim()
    elif cmd == "installer": cmd_installer()
    elif cmd == "configure": cmd_configure()
    elif cmd == "doc": cmd_doc()
    elif cmd == "clean": cmd_clean()
    elif cmd == "dist": cmd_dist()
    elif cmd == "boot": cmd_boot(" ".join(args[i+1:]))
    elif cmd == "tests": cmd_tests(" ".join(args[i+1:]))
    elif cmd == "install": cmd_install(args[i+1:])
    elif cmd == "rodsrc": cmd_rodsrc()
    elif cmd == "web": cmd_web()
    else: Error("illegal command: " + cmd)

# -------------------------- bootstrap ----------------------------------------

def cmd_rodsrc():
  "converts the src/*.pas files into Nimrod syntax"
  PAS_FILES_BLACKLIST = """nsystem nmath nos ntime strutils""".split()
  CMD = "nim boot --skip_proj_cfg -o:rod/%s.nim nim/%s"
  cmd_nim()
  result = False
  for fi in Glob("nim/*.pas"):
    f = FilenameNoExt(fi)
    if f in PAS_FILES_BLACKLIST: continue
    c = Changed(f+"__rodsrc", fi, EXPLAIN)
    if c or force:
      Exec(CMD % (f, f+".pas"))
      Exec("nim parse rod/%s.nim" % f)
      c.success()
      result = True
  return result

def cmd_boot(args):
  writePlatdefC(getNimrodPath())
  d = detect("fpc -h")
  if d:
    Echo("'%s' detected" % d)
    cmd_nim()
    compiler = "nim"
  else:
    Warn("Free Pascal is not installed; skipping Pascal step")
    cmd_install(args)
    compiler = "nimrod"

  cmd_rodsrc() # regenerate nimrod version of the files

  # move the new executable to bin directory (is done by cmd_rod())
  # use the new executable to compile the files in the bootstrap directory:
  Exec("%s compile --compile:build/platdef.c %s rod/nimrod.nim" %
       (compiler, args))
  # move the new executable to bin directory:
  Move(ExeExt("rod/nimrod"), ExeExt("bin/nimrod"))
  # compile again and compare:
  Exec("nimrod compile --compile:build/platdef.c %s rod/nimrod.nim" % args)

  # check if the executables are the same (they should!):
  if filecmp.cmp(Path(ExeExt("rod/nimrod")),
                 Path(ExeExt("bin/nimrod"))):
    Echo("files are equal: everything seems fine!")
  else:
    Warn("files are not equal: cycle once again...")
    # move the new executable to bin directory:
    Move(ExeExt("rod/nimrod"), ExeExt("bin/nimrod"))
    # use the new executable to compile Nimrod:
    Exec("nimrod compile %s rod/nimrod.nim" % args)
    if filecmp.cmp(Path(ExeExt("rod/nimrod")),
                   Path(ExeExt("bin/nimrod"))):
      Echo("files are equal: everything seems fine!")
    else:
      Error("files are still not equal")

# ------------------ web ------------------------------------------------------

def buildDoc(destPath):
  DOC = "endb intern lib manual nimrodc tutorial overview".split()
  SRCDOC = "system os strutils base/regexprs math complex times".split()
  # call nim for the documentation:
  for d in DOC:
    Exec("nim rst2html --putenv:nimrodversion=%s -o:%s/%s.html "
          "--index=%s/theindex doc/%s" %
         (NIMROD_VERSION, destPath, d, destPath, d))
  for d in SRCDOC:
    Exec("nim doc --putenv:nimrodversion=%s -o:%s/%s.html "
         "--index=%s/theindex lib/%s" %
         (NIMROD_VERSION, destPath, FilenameNoExt(d), destPath, d))
  Exec("nim rst2html -o:%s/theindex.html %s/theindex" % (destPath, destPath))


def cmd_web():
  import Cheetah.Template
  TABS = [ # Our tabs: (Menu entry, filename)
    ("home", "index"),
    ("documentation", "documentation"),
    ("download", "download"),
    ("FAQ", "question"),
    ("links", "links")
  ]
  TEMPLATE_FILE = "web/sunset.tmpl"
  #CMD = "rst2html.py --template=web/docutils.tmpl web/%s.txt web/%s.temp "
  CMD = "nim rst2html --compileonly -o:web/%s.temp web/%s.txt"

  c = Changed("web", Glob("web/*.txt") + [TEMPLATE_FILE, "koch.py"] +
                     Glob("doc/*.txt") + Glob("lib/*.txt") + Glob("lib/*.nim")+
                     Glob("config/*.cfg"),
              EXPLAIN)
  if c or force:
    cmd_nim() # we need Nimrod for processing the documentation
    Exec(CMD % ("news","news"))
    newsText = file("web/news.temp").read()
    for t in TABS:
      Exec(CMD % (t[1],t[1]))

      tmpl = Cheetah.Template.Template(file=TEMPLATE_FILE)
      tmpl.content = file("web/%s.temp" % t[1]).read()
      tmpl.news = newsText
      tmpl.tab = t[1]
      tmpl.tabs = TABS
      tmpl.lastupdate = time.strftime("%Y-%m-%d %X", time.gmtime())
      f = file("web/%s.html" % t[1], "w+")
      f.write(str(tmpl))
      f.close()
    # remove temporaries:
    Remove("web/news.temp")
    for t in TABS: Remove("web/%s.temp" % t[1])
    buildDoc("web")
    if Exists("web/index.html"):
      c.success()

# ------------------ doc ------------------------------------------------------

def cmd_doc():
  c = Changed("doc", ["koch.py"] +
                     Glob("doc/*.txt") + Glob("lib/*.txt") + Glob("lib/*.nim")+
                     Glob("config/*.cfg"),
              EXPLAIN)
  if c or force:
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
  extRegEx = re.compile("|".join([r".*\."+ x +"$" for x in CLEAN_EXT.split()]))
  Remove("koch.dat")
  for f in Glob("web/*.html"): Remove(f)
  for f in Glob("doc/html/*.html"): Remove(f)
  for f in Glob("doc/*.html"): Remove(f)
  for f in Glob("rod/*.nim"): Remove(f) # remove generated source code

  for root, dirs, files in os.walk(dir, topdown=False):
    for name in files:
      if (extRegEx.match(name)
      or (root == "tests" and ('.' not in name))):
        Remove(os.path.join(root, name))
    for name in dirs:
      if name == "rod_gen":
        shutil.rmtree(path=os.path.join(root, name), ignore_errors=True)

# ----------------- distributions ---------------------------------------------

# Here are listed all files that should be included in the different
# distributions.

distlist = {
  'common': (
    "copying.txt",
    "gpl.html",
    "koch.py",

    "lib/nimbase.h -> lib/nimbase.h",
    "lib/*.nim -> lib",

    "rod/*.nim -> rod",
    "nim/*.pas -> nim",
    "nim/*.txt -> nim",

    "data/*.yml -> data",
    "data/*.txt -> data",

    "config/nimrod.cfg -> config/nimrod.cfg",
    # documentation:
    "doc/*.txt",      # only include the text documentation; saves bandwidth!
                      # the installation program should generate the HTML
    "readme.txt -> readme.txt",
    "install.txt -> install.txt",

    # library:
    "lib/base/pcre_all.c -> lib/base/pcre_all.c",
    "lib/base/pcre.nim   -> lib/base/pcre.nim",
    "lib/base/regexprs.nim -> lib/base/regexprs.nim",
    #"lib/windows/winapi.nim -> lib/windows/winapi.nim"
      # don't be too clever here; maybe useful on Linux
      # for cross-compiling to Windows?
  ),
  'windows': (
    "bin/nim.exe -> bin/nim.exe",
    "koch.exe -> koch.exe",
    "lib/dlmalloc.h -> lib/dlmalloc.h",
    "lib/dlmalloc.c -> lib/dlmalloc.c",
  ),
  'linux': (
    "lib/rod_gen/*.c -> build",
    "rod/rod_gen/*.c -> build",
  ),
  'macosx': (
    "lib/rod_gen/*.c -> build",
    "rod/rod_gen/*.c -> build",
  )
}

def getHost():
  if os.name == 'nt': return "windows"
  elif "linux" in sys.platform: return "linux"
  elif "darwin" in sys.platform: return "macosx" # probably Mac OS X
  # a heuristic that could work (most likely not :-):
  else: return re.sub(r"[0-9]+$", r"", sys.platform).lower()

def iterInstallFiles(target=getHost()):
  for section in ['common', target]:
    for rule in distlist[section]:
      splittedRule = re.split(r"\s*\-\>\s*", rule)
      if len(splittedRule) == 2:
        source, dest = splittedRule
        if '*' in source:
          for f in Glob(source):
            yield (Path(f), Path(dest + '/' + os.path.split(f)[1]))
        else:
          yield (Path(source), Path(dest))
      else:
        for f in Glob(rule):
          yield (Path(f), Path(f))

def cmd_dist(target=getHost()):
  from zipfile import ZipFile
  distfile = Path('dist/nimrod_%s_%s.zip' % (target, getVersion()))
  Echo("creating: %s..." % distfile)
  z = ZipFile(distfile, 'w', zipfile.ZIP_DEFLATED)
  for source, dest in iterInstallFiles(target):
    z.write(source, Path(dest))
  z.close()
  Echo("... done!")

# ------------------------------ windows installer ----------------------------

WIN_INSTALLER_TEMPLATE = (r"""
; File generated by koch.py
; Template by Andreas Rumpf
[Setup]
AppName=Nimrod Compiler
AppVerName=Nimrod Compiler $version
DefaultDirName={code:GiveMeAPath|nimrod}
DefaultGroupName=Nimrod
AllowNoIcons=yes
LicenseFile=nim\copying.txt
OutputDir=dist
OutputBaseFilename=install_nimrod_$version
Compression=lzma
SolidCompression=yes
PrivilegesRequired=none

[Languages]
Name: english; MessagesFile: compiler:Default.isl

[Files]
$files

[Icons]
Name: {group}\Console for Nimrod; Filename: {cmd}
Name: {group}\Documentation; Filename: {app}\doc\index.html
Name: {group}\{cm:UninstallProgram,Nimrod Compiler}; Filename: {uninstallexe}

[UninstallDelete]
Type: files; Name: "{app}\config\nimrod.cfg"

[Run]
Filename: "{app}\bin\nimconf.exe"; Description: "Launch configuration"; """ +
"""Flags: postinstall nowait skipifsilent

[Code]
function GiveMeAPath(const DefaultPathName: string): string;
begin
  if IsAdminLoggedOn then Result := ExpandConstant('{pf}')
  else Result := ExpandConstant('{userdocs}');
  Result := Result + '\' + DefaultPathName;
end;

function setEnvCmd(const default: string): string;
var
  op, app: string;
begin
  app := ExpandConstant('{app}');
  if IsAdminLoggedOn then op := '' else op := 'u';
  result := '"' + app + '\bin\setenv.exe" -' + op + 'a PATH "%' + app + '\bin"'
end;
""")

def makeKochExe():
  c = Changed("kochexe",
             ("docmacro.py kochmod.py koch.py " +
              "misc/koch.ico").split(), EXPLAIN)
  if c or force:
    Exec("python " + Join(PYINSTALLER, "Makespec.py") +
         " --onefile --ascii --icon=misc/koch.ico koch.py")
    Exec("python " + Join(PYINSTALLER, "Build.py") + " koch.spec")
    Remove("koch.spec")
    Remove("warnkoch.txt")
    RemoveDir("buildkoch")
    c.success()

def cmd_wininstaller():
  FILENAME = "install_nimrod.iss"
  makeKochExe()

  # generate an installer file
  files = ""
  for source, dest in iterInstallFiles("windows"):
    files += ("Source: " + source + "; DestDir: {app}\\" +
              os.path.split(dest)[0] + "; Flags: ignoreversion\n")
  f = file(FILENAME, "w+")
  f.write(Subs(WIN_INSTALLER_TEMPLATE, files=files, version=getVersion()))
  f.close()
  if RawExec(INNOSETUP + FILENAME) == 0:
    # we cannot use ``Exec()`` here as this would
    # mangle the ``/Q`` switch to ``\Q``
    Remove(FILENAME)

# -------------------------- testing the compiler -----------------------------

# This part verifies Nimrod against the testcases.
# The testcases may contain the directives '#ERROR' or '#ERROR_IN'.
# '#ERROR' is used to indicate that the compiler should report
# an error in the marked line (the line that contains the '#ERROR'
# directive.)
# The format for '#ERROR_IN' is:
#      #ERROR_IN filename linenumber
# One can omit the extension of the filename ('.nim' is then assumed).
# Tests which contain none of the two directives should compile. Thus they
# are executed after successful compilation and their output is verified
# against the results specified with the '#OUT' directive.
# (Tests which require user interaction are currently not possible.)
# Tests can have an #ERROR_MSG directive specifiying the error message
# Nimrod shall produce.
# The code here needs reworking or at least documentation, but I don't have
# the time and it has been debugged and optimized.

try:
  import subprocess
  HAS_SUBPROCESS = True
except ImportError:
  HAS_SUBPROCESS = False

def runProg(args, inp=None):
  """Executes the program + args given in args and
     returns the output of the program as a string."""
  if HAS_SUBPROCESS:
    process = subprocess.Popen(args, bufsize=0, shell=True,
      stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=inp,
      universal_newlines=True)
    standardOut, standardErr = process.communicate(inp)
    process.wait() # be on the safe side
    return standardOut
  else:
    if inp:
      standardIn = file('buildin.tmp', 'w')
      standardIn.write(inp)
      standardIn.close()
      b = " <buildin.tmp"
    else:
      b = ""
    os.system(args + b + " >build.tmp")
    result = file('build.tmp').read()
    if not result: result = ""
    return result
    # system() is not optimal, but every Python version should have it

class Spec(object): pass # specification object

def parseTest(filename):
  # spec is a table
  reError = re.compile(r"#ERROR$")
  reErrorIn = re.compile(r"#ERROR_IN\s*(\S*)\s*(\d*)")
  reErrorMsg = re.compile(r"#ERROR_MSG\s*(.*)")
  reOut = re.compile(r"#OUT\s*(.*)")

  i = 0  # the line counter
  spec = Spec()
  spec.line = None # line number where compiler should throw an error
  spec.file = None # file where compiler should throw an error
  spec.err = False # true if the specification says there should be an error
  spec.out = None  # output that should be produced

  for s in file(filename, 'rU'):
    # we have to use this inefficient method for getting the current line
    i += 1 # our line-counter
    obj = reError.search(s)
    if obj:
      spec.line = i
      spec.file = filename
      spec.err = True
      break
    obj = reErrorIn.search(s)
    if obj:
      spec.file = obj.group(1)
      spec.line = int(obj.group(2))
      spec.err = True
      if '.' not in specfile: specfile += ".nim"
      break
    obj = reOut.search(s)
    if obj:
      spec.out = obj.group(1)
      break
    obj = reErrorMsg.search(s)
    if obj:
      spec.out = obj.group(1)
      spec.err = True
      break

  return spec

def doTest(filename, spec, options):
  # call the compiler
  # short filename for messages (better readability):
  shortfile = os.path.split(filename)[1]

  comp = Spec()
  comp.line = 0
  comp.file = None
  comp.out = None
  comp.err = False
  # call the compiler and read the compiler message:
  results = runProg("nim compile --hints:on " + options + " " + filename)
  print results
  # compiled regular expressions:
  reLineInfoError = re.compile(r"^((.*)\((\d+), \d+\)\s*Error\:\s*(.*))",
                               re.MULTILINE)
  reError = re.compile(r"^Error\:\s*(.*)", re.MULTILINE)
  reSuccess = re.compile(r"^Hint\:\s*operation successful", re.MULTILINE)
  obj = reLineInfoError.search(results)
  if obj:
    comp.err = True
    comp.file = obj.group(2)
    comp.line = int(obj.group(3))
    comp.out = obj.group(1)
    comp.puremsg = obj.group(4)
  else:
    comp.puremsg = ''
    obj = reError.search(results)
    if obj:
      comp.err = True
      comp.out = results
      comp.puremsg = obj.group(1)
      comp.line = 1
    else:
      obj = reSuccess.search(results)
      if not obj: comp.err = True

  if comp.err and not comp.out:
  # the compiler did not say "[Error]" nor "Compilation sucessful"
    Echo("[Tester] %s -- FAILED; COMPILER BROKEN" % shortfile)
    return False

  if (spec.err != comp.err
  or (spec.line and (abs(spec.line - comp.line) > 1))
  or (spec.file and (spec.file.lower() != comp.file.lower()))
  or (spec.out and not (spec.out.strip() in comp.puremsg.strip()))):
    if spec.out:
      Echo("[Tester] %s -- FAILED\n"
           "Compiler says: %s\n"
           "But specification says: Error %s"
           % (shortfile, comp.out, spec.out) )
    elif spec.err:
      if spec.file is None: spec.file = filename
      if spec.line is None: spec.line = -1
      Echo("[Tester] %s -- FAILED\n"
           "Compiler says: %s\n"
           "But specification says: Error in %s line %d"
           % (shortfile, comp.out, spec.file, spec.line) )
    else:
      Echo("[Tester] %s -- FAILED\n"
           "Compiler says: %s\n"
           "But specification says: no error"
           % (shortfile, comp.out) )
    return False
  else:
    if spec.err:
      Echo("[Tester] " + shortfile + ' -- OK') # error correctly reported
      return True
    else:
      # run the compiled program and check if it works
      fileNoExt = os.path.splitext(filename)[0]
      if os.path.isfile(ExeExt(fileNoExt)):
        if spec.out:
          buf = runProg(fileNoExt)
          if buf.strip() == spec.out.strip():
            Echo("[Tester] " + shortfile + " -- compiled program OK")
            return True
          else:
            Echo("[Tester] " + shortfile + " -- compiled program FAILED")
            return False
        else:
          Echo("[Tester] " + shortfile + ' -- OK')
          return True
          # we have no output to validate against, but compilation succeeded,
          # so it's okay
      elif '--compile_only' in options:
        Echo("[Tester] " + shortfile + ' -- OK')
        return True
      else:
        Echo("[Tester] " + shortfile + " -- FAILED\n"
             "no compiled program found")
        return False

def cmd_tests(options): # run the testsuite
  """runs the complete testsuite"""
  #clean(True) # first clean before running the testsuite
  total = 0
  passed = 0
  for filename in Glob("tests/t*.nim"):
    spec = parseTest(filename)
    res = doTest(filename, spec, options)
    assert(res is not None)
    if res: passed += 1
    total += 1
    break
  Echo("[Tester] %d/%d tests passed\n" % (passed, total))

# --------------- install target ----------------------------------------------

CONFIG_TEMPLATE = r"""# Configuration file for the Nimrod Compiler.
# Generated by the koch.py script.
# (c) 2008 Andreas Rumpf

# Feel free to edit the default values as you need.

# You may set environment variables with
# @putenv "key" "val"
# Environment variables cannot be used in the options, however!

# Just call the compiler with several options:
cc = @if unix: %(cc)s @else: vcc @end
lib="$nimrod/lib"
path="$lib/base"
path="$lib/base/gtk"
path="$lib/base/cairo"
path="$lib/base/x11"
path="$lib/windows"
path="$lib/extra"

# additional defines:
#define=""
# additional options always passed to the compiler:
force_build
line_dir=off

hint[LineTooLong]=off
hint[XDeclaredButNotUsed]=off

@if unix:
  passl= "-ldl"
  path = "$lib/base/gtk"
@end

@if icc:
  passl = "-cxxlib"
  passc = "-cxxlib"
@end

# Configuration for the Borland C++ Compiler:
@if windows:
  bcc.path = r"C:\eigenes\compiler\cbuilder5\bin"
@end
bcc.options.debug = ""
# turn off warnings about unreachable code and inline procs:
bcc.options.always = "-w- -H- -q -RT- -a8 -w-8027 -w-8066"
bcc.options.speed = "-O2 -6"
bcc.options.size = "-O1 -6"

# Configuration for the Visual C/C++ compiler:
@if vcc:
  @prepend_env path r"C:\Eigenes\compiler\vcc2005\Common7\IDE;"
  @prepend_env INCLUDE r"C:\Eigenes\compiler\vcc2005\VC\include;C:\Eigenes\compiler\vcc2005\VC\ATLMFC\INCLUDE;"
  @prepend_env LIB r"C:\Eigenes\compiler\vcc2005\VC\lib;C:\Eigenes\compiler\vcc2005\SDK\v2.0\Lib;"
@end
@if windows:
  vcc.path = r"C:\Eigenes\compiler\vcc2005\VC\bin"
@end
vcc.options.debug = "/GZ /ZI"
vcc.options.always = "/nologo"
vcc.options.speed = "/Ogityb2 /G7 /arch:SSE2"
vcc.options.size = "/O1 /G7"

# Configuration for the Watcom C/C++ compiler:
@if windows:
  wcc.path = r"C:\eigenes\compiler\watcom\binnt"
@end
wcc.options.debug = "-d2"
wcc.options.always = "-6 -zw -w-"
wcc.options.speed = "-ox -on -6 -d0 -fp6 -zW"
wcc.options.size = "-ox -on -6 -d0 -fp6 -zW"

# Configuration for the GNU C/C++ compiler:
@if windows:
  gcc.path = r"C:\eigenes\compiler\mingw\bin"
@end
gcc.options.debug = "-g"
@if macosx:
  gcc.options.always = "-w -fasm-blocks"
@else:
  gcc.options.always = "-w"
@end
gcc.options.speed = "-O3 -ffast-math"
gcc.options.size = "-Os -ffast-math"

# Configuration for the Digital Mars C/C++ compiler:
@if windows:
  dmc.path = r"C:\eigenes\compiler\d\dm\bin"
@end
dmc.options.debug = "-g"
dmc.options.always = "-Jm"
dmc.options.speed = "-ff -o -6"
dmc.options.size = "-ff -o -6"

# Configuration for the LCC compiler:
@if windows:
  lcc.path = r"C:\eigenes\compiler\lcc\bin"
@end
lcc.options.debug = "-g5"
lcc.options.always = "-e1"
lcc.options.speed = "-O -p6"
lcc.options.size = "-O -p6"

# Configuration for the Tiny C Compiler:
@if windows:
  tcc.path = r"C:\eigenes\compiler\tcc\bin"
@end
tcc.options.debug = "-b"
tcc.options.always = ""
tcc.options.speed = ""
tcc.options.size = ""

# Configuration for the Pelles C compiler:
@if windows:
  pcc.path = r"C:\eigenes\compiler\pellesc\bin"
@end
pcc.options.debug = "-Zi"
pcc.options.always = "-Ze"
pcc.options.speed = "-Ox"
pcc.options.size = "-Os"

# Configuration for the LLVM GCC compiler:
@if windows:
  llvm_gcc.path = r"c:\eignes\compiler\llvm-gcc\bin"
@end
llvm_gcc.options.debug = "-g"
llvm_gcc.options.always = "-w"
llvm_gcc.options.speed = "-O3 -ffast-math"
llvm_gcc.options.size = "-Os -ffast-math"

@if windows:
  icc.path = r"c:\eignes\compiler\icc\bin"
@end
icc.options.debug = "-g"
icc.options.always = "-w"
icc.options.speed = "-O3 -ffast-math"
icc.options.size = "-Os -ffast-math"

@write "used default config file"
"""

def writePlatdefC(nimrodpath):
  import os
  host = getHost()
  if host == "windows": processor = "i386" # BUGFIX
  else: processor = os.uname()[4]
  if processor.lower() in ("i686", "i586", "i468", "i386"):
    processor = "i386"
  if "sparc" in processor.lower():
    processor = "sparc"
  f = file(os.path.join(nimrodpath, "build/platdef.c"), "w+")
  f.write('/* Generated by koch.py */\n'
          '#include "nimbase.h"\n'
          'N_NIMCALL(char*, nimOS)(void) { return "%s"; }\n'
          'N_NIMCALL(char*, nimCPU)(void) { return "%s"; }\n'
          '\n' % (host, processor))
  f.close()

def detect(cmd, lookFor="version"):
  pipe = os.popen4(cmd)[1]
  result = None
  for line in pipe:
    if lookFor in line:
      result = line[:-1]
      break
  pipe.close()
  return result

def lookForCC():
  if "CC" in os.environ:
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
    p = sys.argv[0].replace("./", "")
    return os.path.split(os.path.join(os.getcwd(), p))[0]
  else: # Windows
    return os.path.split(sys.argv[0])[0]

def writeCfg(nimrodpath, ccSymbol=None):
  if not ccSymbol:
    ccSymbol = lookForCC()
  configFile = os.path.join(nimrodpath, "config/nimrod.cfg")
  script = CONFIG_TEMPLATE % {'cc': ccSymbol, 'nimrodpath': nimrodpath}
  config = file(configFile)
  if config:
    if config.read().strip() != script.strip():
      config.close()
      Echo("Configuration file already exists and "
           "seems to have been modified.\n"
           "Do you want to override it? (y/n) ")
      while True:
        a = ask()
        if a in ("y", "yes"):
          f = file(configFile, "w+")
          f.write(script)
          f.close()
          break
        elif a in ("n", "no"):
          break
        else:
          Echo("What do you mean? (y/n) ")
    else:
      config.close()
  return ccSymbol

def cmd_install(args):
  Echo("Nimrod should be in '%s'" % getNimrodPath())
  # We know that the user has already unzipped this archive into the
  # final directory. So we just create the config file and build Nimrod.

  # write the configuration file, but check if one exists!
  nimrodpath = getNimrodPath()
  try:
    opts, args = getopt.getopt(args, "", ["cc=", "ld="])
  except getopt.GetoptError:
    # print help information and exit:
    Error("Command line contains errors")
  ccSymbol = None
  ldSymbol = None
  for o, a in opts:
    if o == "--cc":   ccSymbol = a
    elif o == "--ld": ldSymbol = a

  ccSymbol = writeCfg(nimrodpath, ccSymbol)
  if not ldSymbol:
    ldSymbol = ccSymbol.split()[0] + " -ldl -o bin/nimrod "

  writePlatdefC(nimrodpath)

  # build Nimrod
  link = "" # store the .o files in here for final linking step
  for f in Glob("build/*.c"):
    objfile = os.path.splitext(f)[0] + ".o"
    link += " " + objfile
    # compile only:
    if Exec(ccSymbol + " " + CFLAGS + " -c -o " + objfile + " " + f) != 0:
      Error("the C compiler did not like: " + f)
  if link == "":
    Error("could not find Nimrod's sources\n"
          "    (they should be in the build subdirectory)")
  # now link the stuff together:
  if Exec(ldSymbol + link) != 0:
    Error("the linking step failed!")
  # now we have a Nimrod executable :-)

  nimrodpath = getNimrodPath()
  writeScript(CONFIG_TEMPLATE % {'cc': ccSymbol, 'nimrodpath': nimrodpath},
              os.path.join(nimrodpath, "config/nimrod.cfg"))

  # remove the generated .o files as they take 1 MB:
  for f in Glob("build/*.o"): Remove(f)
  Echo("SUCCESS!")

def cmd_installer():
  if os.name == "posix":
    Echo("Nothing to do")
  else: # Windows
    cmd_wininstaller()


# ------------------ configure ------------------------------------------------

def writeScript(script, filename):
  if os.name != "posix": filename += ".bat"
  f = file(filename, "w+")
  f.write(script)
  f.close()
  # make the script executable:
  if os.name == "posix":
    os.chmod(filename, 493) # 0o755

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
