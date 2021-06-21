#
#
#        The Nim Installation Generator
#        (c) Copyright 2012 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import osproc, times, os, strutils

# http://www.debian.org/doc/manuals/maint-guide/

# Required files for debhelper.
# -- control
# -- copyright
# -- changelog
# -- rules

type
  TDebOptions* = object
    buildDepends*, pkgDepends*, shortDesc*: string
    licenses*: seq[tuple[files, license: string]]

template addN(r: string) =
  result.add(r)
  result.add("\n")

proc createControl(pkgName, maintainer, shortDesc, desc: string,
                   buildDepends, pkgDepends: string = ""): string =
  ## pkgName: Should be the package name, no spaces.
  ## maintainer: firstName lastName <email>
  ## shortDesc: short description of the application
  ## desc: long description of the application
  ## buildDepends: what the build depends on (compiling from source),
  ##               this needs to be in the format deb accepts. For example,
  ##               for gcc: ``gcc (>= 4:4.3.2)``
  ##               Multiple dependencies should be separated by commas.
  ## pkgDepends: Same as buildDepends except that this specifies the
  ##             dependencies that the compiled application depends on.


  result = ""

  addN("Source: " & pkgName)
  addN("Maintainer: " & maintainer)
  addN("Section: misc")
  addN("Priority: optional")
  addN("Standards-Version: 3.9.2")
  addN("Build-Depends: debhelper (>= 8)" &
        (if buildDepends != "": ", " & buildDepends else: ""))
  addN("\n")
  addN("Package: " & pkgName)
  addN("Architecture: any")
  addN("Depends: ${shlibs:Depends}, ${misc:Depends}" &
        (if pkgDepends != "": ", " & pkgDepends else: ""))

  var formattedDesc = ""
  for line in splitLines(desc):
    if line == "":
      formattedDesc.add(" .\n")
    else:
      formattedDesc.add(" " & line & "\n")

  addN("Description: " & shortDesc & "\n" & formattedDesc)

proc createCopyright(pkgName, mtnName, mtnEmail, version: string,
                     licenses: seq[tuple[files, license: string]]): string =
  ## pkgName: Package name
  ## mtnName: Maintainer name
  ## mtnEmail: Maintainer email
  ## version: package version
  ## licenses: files: This specifies the files that the `license` covers,
  ##           for example, it might be ``lib/*`` to cover the whole ``lib`` dir
  ##           license: This specifies the license, for example gpl2, or lgpl.

  result = ""
  addN("Maintainer name: " & mtnName)
  addN("Email-Address: " & mtnEmail)
  addN("Date: " & $getTime())
  addN("Package Name: " & pkgName)
  addN("Version: " & version)
  for f, license in items(licenses):
    addN("Files: " & f)
    addN("License: " & license)

proc formatDateTime(t: DateTime, timezone: string): string =
  var day = ($t.weekday)[0..2] & ", "

  return "$1$2 $3 $4 $5:$6:$7 $8" % [day, intToStr(t.monthday, 2),
    ($t.month)[0..2], $t.year, intToStr(t.hour, 2), intToStr(t.minute, 2),
    intToStr(t.second, 2), timezone]

proc createChangelog(pkgName, version, maintainer: string): string =
  ## pkgName: package name
  ## version: package version
  ## maintainer: firstName lastName <email>
  result = ""
  addN(pkgName & " (" & version & "-1) unstable; urgency=low")
  addN("")
  addN("  * Initial release.")
  addN("")
  addN(" -- " & maintainer & "  " &
       formatDateTime(utc(getTime()), "+0000"))

proc createRules(): string =
  ## Creates a nim application-agnostic rules file for building deb packages.
  ## Please note: this assumes the c sources have been built and the
  ## ``build.sh`` and ``install.sh`` files are available.
  result = ""
  addN("#!/usr/bin/make -f")
  addN("%:")
  addN("\tdh $@\n")
  addN("dh_install:")
  addN("\tdh_install --sourcedir=debian/tmp")
  addN("override_dh_auto_clean:")
  addN("\tfind . -name *.o -exec rm {} \\;")
  addN("override_dh_auto_build:")
  addN("\t./build.sh")
  addN("override_dh_auto_install:")
  addN("\t./install.sh debian/tmp")

proc createIncludeBinaries(binaries: seq[string]): string =
  return join(binaries, "\n")

proc createDotInstall(pkgName: string, binaries, config, docs,
    lib: seq[string]): string =
  result = ""
  for b in binaries:
    addN(pkgName / b & " " & "usr/bin/")
  for c in config:
    addN(pkgName / c & " " & "etc/")
  for d in docs:
    addN(pkgName / d & " " & "usr/share/doc/nim/")
  for l1 in lib:
    addN(pkgName / l1 & " " & "usr/lib/nim")

proc makeMtn(name, email: string): string =
  return name & " <" & email & ">"

proc assertSuccess(exitCode: int) =
  doAssert(exitCode == QuitSuccess)

proc prepDeb*(packName, version, mtnName, mtnEmail, shortDesc, desc: string,
              licenses: seq[tuple[files, license: string]], binaries,
              config, docs, lib: seq[string],
              buildDepends, pkgDepends = "") =
  ## binaries/config/docs/lib: files relative to nim's root, that need to
  ##   be installed.

  let pkgName = packName.toLowerAscii()

  var workingDir = getTempDir() / "niminst" / "deb"
  var upstreamSource = (pkgName & "-" & version)

  echo("Making sure build.sh and install.sh are +x")
  assertSuccess execCmd("chmod +x \"" &
    (workingDir / upstreamSource / "build.sh") & "\"")
  assertSuccess execCmd("chmod +x \"" &
    (workingDir / upstreamSource / "install.sh") & "\"")

  var tarCmd = "tar pczf \"" &
      (pkgName & "_" & version & ".orig.tar.gz") &
      "\" \"" & upstreamSource & "\""
  echo(tarCmd)
  assertSuccess execCmd("cd \"" & workingDir & "\" && " & tarCmd)

  echo("Creating necessary files in debian/")
  createDir(workingDir / upstreamSource / "debian")

  template writeDebian(f, s: string) =
    writeFile(workingDir / upstreamSource / "debian" / f, s)

  var controlFile = createControl(pkgName, makeMtn(mtnName, mtnEmail),
      shortDesc, desc, buildDepends, pkgDepends)
  echo("debian/control")
  writeDebian("control", controlFile)

  var copyrightFile = createCopyright(pkgName, mtnName, mtnEmail, version,
      licenses)
  echo("debian/copyright")
  writeDebian("copyright", copyrightFile)

  var changelogFile = createChangelog(pkgName, version,
      makeMtn(mtnName, mtnEmail))
  echo("debian/changelog")
  writeDebian("changelog", changelogFile)

  echo("debian/rules")
  writeDebian("rules", createRules())

  echo("debian/compat")
  writeDebian("compat", "8")

  echo("debian/" & pkgName & ".install")
  writeDebian(pkgName & ".install",
    createDotInstall(pkgName, binaries, config, docs, lib))

  # Other things..
  createDir(workingDir / upstreamSource / "debian" / "source")
  echo("debian/source/format")
  writeDebian("source" / "format",
            "3.0 (quilt)")
  echo("debian/source/include-binaries")
  writeFile(workingDir / upstreamSource / "debian" / "source" / "include-binaries",
            createIncludeBinaries(binaries))

  echo("All done, you can now build.")
  echo("Before you do however, make sure the files in " &
    workingDir / upstreamSource / "debian" & " are correct.")
  echo("Change your directory to: " & workingDir / upstreamSource)
  echo("And execute `debuild -us -uc` to build the .deb")

when isMainModule:
  #var controlFile = createControl("nim", "Dominik Picheta <morfeusz8@gmail.com>",
  # "The Nim compiler", "Compiler for the Nim programming language", "gcc (>= 4:4.3.2)", "gcc (>= 4:4.3.2)")

  #echo(controlFile)

  #var copyrightFile = createCopyright("nim", "Dominik Picheta", "morfeusz8@a.b", "0.8.14",
  #    @[("bin/nim", "gpl2"), ("lib/*", "lgpl")])

  #echo copyrightFile

  #var changelogFile = createChangelog("nim", "0.8.14", "Dom P <m@b.c>")
  #echo(changelogFile)

  #echo(createRules())

  prepDeb("nim", "0.9.2", "Dominik Picheta", "morfeusz8@gmail.com",
    "The Nim compiler", "Compiler for the Nim programming language",
    @[("bin/nim", "MIT"), ("lib/*", "MIT")],
    @["bin/nim"], @["config/*"], @["doc/*"], @["lib/*"],
    "gcc (>= 4:4.3.2)", "gcc (>= 4:4.3.2)")

