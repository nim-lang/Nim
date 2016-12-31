#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the basics for Linux distribution ("distro")
## detection and the OS's native package manager. Its primary purpose is in
## producing output for Nimble packages like::
##
##  To complete the installation, run:
##
##  sudo apt-get libblas-dev
##  sudo apt-get libvoodoo
##

from strutils import contains, toLowerAscii

when not defined(nimscript):
  from osproc import execProcess

type
  Distribution* {.pure.} = enum ## an enum so that the poor programmer
                                ## cannot introduce typos
    Windows ## some version of Windows
    Posix   ## some Posix system
    MacOSX  ## some version of OSX
    Linux   ## some version of Linux
    Ubuntu
    Debian
    Gentoo
    Fedora
    RedHat

    OpenSUSE
    Manjaro
    Elementary
    Zorin
    CentOS
    Deepin
    ArchLinux
    Antergos
    PCLinuxOS
    Mageia
    LXLE
    Solus
    Lite
    Slackware
    Androidx86
    Puppy
    Peppermint
    Tails
    AntiX
    Kali
    SparkyLinux
    Apricity
    BlackLab
    Bodhi
    TrueOS
    ArchBang
    KaOS
    WattOS
    Korora
    Simplicity
    RemixOS
    OpenMandriva
    Netrunner
    Alpine
    BlackArch
    Ultimate
    Gecko
    Parrot
    KNOPPIX
    GhostBSD
    Sabayon
    Salix
    Q4OS
    ClearOS
    Container
    ROSA
    Zenwalk
    Parabola
    ChaletOS
    BackBox
    MXLinux
    Vector
    Maui
    Qubes
    RancherOS
    Oracle
    TinyCore
    Robolinux
    Trisquel
    Voyager
    Clonezilla
    SteamOS
    Absolute
    NixOS
    AUSTRUMI
    Arya
    Porteus
    AVLinux
    Elive
    Bluestar
    SliTaz
    Solaris
    Chakra
    Wifislax
    Scientific
    ExTiX
    Rockstor
    GoboLinux

    BSD
    FreeBSD
    OpenBSD
    DragonFlyBSD


const
  LacksDevPackages* = {Distribution.Gentoo, Distribution.Slackware,
    Distribution.ArchLinux}

var unameRes: string ## we cache the result of the 'uname -a' execution for
                     ## faster platform detections.

template uname(): untyped =
  const cmd = "uname -a"
  if unameRes.len == 0:
    unameRes = (when defined(nimscript): gorge(cmd) else: execProcess(cmd))
  unameRes

proc detectOsImpl(d: Distribution): bool =
  case d
  of Distribution.Windows: ## some version of Windows
    result = defined(windows)
  of Distribution.Posix: result = defined(posix)
  of Distribution.MacOSX: result = defined(macosx)
  of Distribution.Linux: result = defined(linux)
  of Distribution.Ubuntu, Distribution.Gentoo, Distribution.FreeBSD,
     Distribution.OpenBSD, Distribution.Fedora:
    result = ("-" & $d & " ") in uname()
  of Distribution.RedHat:
    result = "Red Hat" in uname()
  of Distribution.BSD: result = defined(bsd)
  of Distribution.ArchLinux:
    result = "arch" in toLowerAscii(uname())
  of Distribution.OpenSUSE:
    result = "suse" in toLowerAscii(uname())
  of Distribution.GoboLinux:
    result = "-Gobo " in uname()
  of Distribution.OpenMandriva:
    result = "mandriva" in toLowerAscii(uname())
  of Distribution.Solaris:
    let uname = toLowerAscii(uname())
    result = ("sun" in uname) or ("solaris" in uname)
  else:
    result = toLowerAscii($d) in toLowerAscii(uname())

template detectOs*(d: untyped): bool =
  detectOsImpl(Distribution.d)

when not defined(nimble):
  var foreignDeps: seq[string] = @[]

proc foreignCmd*(cmd: string; requiresSudo=false) =
  let c = (if requiresSudo: "sudo " else: "") & cmd
  when defined(nimble):
    nimscriptapi.foreignDeps.add(c)
  else:
    foreignDeps.add(c)

proc foreignDepInstallCmd*(foreignPackageName: string): (string, bool) =
  ## returns the distro's native command line to install 'foreignPackageName'
  ## and whether it requires root/admin rights.
  let p = foreignPackageName
  when defined(windows):
    result = ("Chocolatey install " & p, false)
  elif defined(bsd):
    result = ("ports install " & p, true)
  elif defined(linux):
    if detectOs(Ubuntu) or detectOs(Elementary) or detectOs(Debian) or
        detectOs(KNOPPIX) or detectOs(SteamOS):
      result = ("apt-get install " & p, true)
    elif detectOs(Gentoo):
      result = ("emerge install " & p, true)
    elif detectOs(Fedora):
      result = ("yum install " & p, true)
    elif detectOs(RedHat):
      result = ("rpm install " & p, true)
    elif detectOs(OpenSUSE):
      result = ("yast -i " & p, true)
    elif detectOs(Slackware):
      result = ("installpkg " & p, true)
    elif detectOs(OpenMandriva):
      result = ("urpmi " & p, true)
    elif detectOs(ZenWalk):
      result = ("netpkg install " & p, true)
    elif detectOs(NixOS):
      result = ("nix-env -i " & p, false)
    elif detectOs(Solaris):
      result = ("pkg install " & p, true)
    elif detectOs(PCLinuxOS):
      result = ("rpm -ivh " & p, true)
    elif detectOs(ArchLinux):
      result = ("pacman -S " & p, true)
  else:
    result = ("brew install " & p, true)

proc foreignDep*(foreignPackageName: string) =
  let (installCmd, sudo) = foreignDepInstallCmd(foreignPackageName)
  foreignCmd installCmd, sudo

proc echoForeignDeps*() =
  ## Writes the list of registered foreign deps to stdout.
  echo "To finish the installation, run:"
  for d in foreignDeps:
    echo d

when isMainModule:
  foreignDep("libblas-dev")
  foreignDep "libfoo"
  echoForeignDeps()
