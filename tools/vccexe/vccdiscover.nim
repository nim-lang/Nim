import strutils, os, vccenv

type
  VccVersion* = enum
    vccUndefined = (0, ""),
    vcc90  =  vs90, # Visual Studio 2008
    vcc100 = vs100, # Visual Studio 2010
    vcc110 = vs110, # Visual Studio 2012
    vcc120 = vs120, # Visual Studio 2013
    vcc140 = vs140  # Visual Studio 2015

proc discoverVccVcVarsAllPath*(version: VccVersion = vccUndefined): string =
  # TODO: Attempt discovery using vswhere utility.

  # Attempt discovery through VccEnv 
  # (Trying Visual Studio Common Tools Environment Variables)
  result = vccEnvVcVarsAllPath(cast[VccEnvVersion](version))
  if result.len > 0:
    return

  # All attempts to dicover vcc failed

when isMainModule:
  const
    helpText = """
+-----------------------------------------------------------------+
|        Microsoft C/C++ Compiler Discovery Utility               |
|            (c) 2017 Fredrik Hoeisaether Rasch                   |
+-----------------------------------------------------------------+

Discovers the path to the Developer Command Prompt for the 
specified versions, or attempts to discover the latest installed 
version if no specific version is requested.

Usage:
  vccdiscover [<version>...]
Arguments:
  <version>   Optionally specify the version to discover
    Valid values: 0, 90, 100, 110, 120, 140
    A value of 0 will discover the latest installed SDK

For each specified version the utility prints a line with the 
following format:
<version>: <path>
"""
  var quitValue = 0
  let args = commandLineParams()
  if args.len < 1:
    let path = discoverVccVcVarsAllPath()
    if path.len < 1:
      echo "latest: VCC installation discovery failed."
      quitValue = 1
    else:
      echo "latest: " & path

  for argv in args:
    # Strip leading hyphens or slashes, if someone tries -?, /?, --help or /help
    if argv.len < 1:
      continue
    var argvValue = argv
    while argvValue[0] == '-' or argvValue[0] == '/':
      argvValue = argvValue.substr(1)
    if argvValue.len < 1:
      continue

    if cmpIgnoreCase(argvValue, "help") == 0 or cmpIgnoreCase(argvValue, "?") == 0:
      echo helpText
      continue
    
    let version = cast[VccVersion](parseInt(argvValue))
    let path = discoverVccVcVarsAllPath(version)
    var head = $version
    if head.len < 1:
      head = "latest"
    if path.len < 1:
      echo head & ": VCC installation discovery failed."
      inc quitValue
    else:
      echo "$1: $2" % [head, path]
  quit quitValue