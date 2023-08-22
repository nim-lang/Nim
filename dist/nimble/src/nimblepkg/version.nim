# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

## Module for handling versions and version ranges such as ``>= 1.0 & <= 1.5``
import json, sets
import common, strutils, tables, hashes, parseutils

type
  Version* = object
    version: string

  VersionRangeEnum* = enum
    verLater, # > V
    verEarlier, # < V
    verEqLater, # >= V -- Equal or later
    verEqEarlier, # <= V -- Equal or earlier
    verIntersect, # > V & < V
    verTilde, # ~= V
    verCaret, # ^= V
    verEq, # V
    verAny, # *
    verSpecial # #head

  VersionRange* = ref VersionRangeObj
  VersionRangeObj = object
    case kind*: VersionRangeEnum
    of verLater, verEarlier, verEqLater, verEqEarlier, verEq:
      ver*: Version
    of verSpecial:
      spe*: Version
    of verIntersect, verTilde, verCaret:
      verILeft, verIRight: VersionRange
    of verAny:
      nil

  ## Tuple containing package name and version range.
  PkgTuple* = tuple[name: string, ver: VersionRange]

  ParseVersionError* = object of NimbleError

const
  notSetVersion* = Version(version: "-1")

proc parseVersionError*(msg: string): ref ParseVersionError =
  result = newNimbleError[ParseVersionError](msg)

template `$`*(ver: Version): string = ver.version
template hash*(ver: Version): Hash = ver.version.hash
template `%`*(ver: Version): JsonNode = %ver.version

proc newVersion*(ver: string): Version =
  if ver.len != 0 and ver[0] notin {'#', '\0'} + Digits:
    raise parseVersionError("Wrong version: " & ver)
  return Version(version: ver)

proc initFromJson*(dst: var Version, jsonNode: JsonNode, jsonPath: var string) =
  case jsonNode.kind
  of JNull: dst = notSetVersion
  of JObject: dst = newVersion(jsonNode["version"].str)
  of JString: dst = newVersion(jsonNode.str)
  else:
    assert false,
      "The `jsonNode` must have one of {JNull, JObject, JString} kinds."

proc isSpecial*(ver: Version): bool =
  return ($ver).len > 0 and ($ver)[0] == '#'

proc `<`*(ver: Version, ver2: Version): bool =
  # Handling for special versions such as "#head" or "#branch".
  if ver.isSpecial or ver2.isSpecial:
    # TODO: This may need to be reverted. See #311.
    if ver2.isSpecial and ($ver2).normalize == "#head":
      return ($ver).normalize != "#head"

    if not ver2.isSpecial:
      # `#aa111 < 1.1`
      return ($ver).normalize != "#head"

  # Handling for normal versions such as "0.1.0" or "1.0".
  var sVer = ver.version.split('.')
  var sVer2 = ver2.version.split('.')
  for i in 0..max(sVer.len, sVer2.len)-1:
    var sVerI = 0
    if i < sVer.len:
      discard parseInt(sVer[i], sVerI)
    var sVerI2 = 0
    if i < sVer2.len:
      discard parseInt(sVer2[i], sVerI2)
    if sVerI < sVerI2:
      return true
    elif sVerI == sVerI2:
      discard
    else:
      return false

proc `==`*(ver: Version, ver2: Version): bool =
  if ver.isSpecial or ver2.isSpecial:
    return ($ver).toLowerAscii() == ($ver2).toLowerAscii()
  var sVer = ver.version.split('.')
  var sVer2 = ver2.version.split('.')
  for i in 0..max(sVer.len, sVer2.len)-1:
    var sVerI = 0
    if i < sVer.len:
      discard parseInt(sVer[i], sVerI)
    var sVerI2 = 0
    if i < sVer2.len:
      discard parseInt(sVer2[i], sVerI2)
    if sVerI == sVerI2:
      result = true
    else:
      return false

proc cmp*(a, b: Version): int =
  if a < b: -1
  elif a > b: 1
  else: 0

proc `<=`*(ver: Version, ver2: Version): bool =
  return (ver == ver2) or (ver < ver2)

proc `==`*(range1: VersionRange, range2: VersionRange): bool =
  if range1.kind != range2.kind : return false
  result = case range1.kind
  of verLater, verEarlier, verEqLater, verEqEarlier, verEq:
    range1.ver == range2.ver
  of verSpecial:
    range1.spe == range2.spe
  of verIntersect, verTilde, verCaret:
    range1.verILeft == range2.verILeft and range1.verIRight == range2.verIRight
  of verAny: true

proc withinRange*(ver: Version, ran: VersionRange): bool =
  case ran.kind
  of verLater:
    return ver > ran.ver
  of verEarlier:
    return ver < ran.ver
  of verEqLater:
    return ver >= ran.ver
  of verEqEarlier:
    return ver <= ran.ver
  of verEq:
    return ver == ran.ver
  of verSpecial:
    return ver == ran.spe
  of verIntersect, verTilde, verCaret:
    return withinRange(ver, ran.verILeft) and withinRange(ver, ran.verIRight)
  of verAny:
    return true

proc withinRange*(versions: HashSet[Version], range: VersionRange): bool =
  ## Checks whether any of the versions from the set `versions` are in the range
  ## `range`.

  for version in versions:
    if withinRange(version, range):
      return true

proc contains*(ran: VersionRange, ver: Version): bool =
  return withinRange(ver, ran)

proc getNextIncompatibleVersion(version: Version, semver: bool): Version = 
  ## try to get next higher version to exclude according to semver semantic
  var numbers = version.version.split('.')
  let originalNumberLen = numbers.len
  while numbers.len < 3:
    numbers.add("0")
  var zeros = 0
  for n in 0 ..< 2:
    if numbers[n] == "0":
      inc(zeros)
    else: break
  var increasePosition = 0
  if (semver):
    if originalNumberLen > 1:
      case zeros
      of 0:
        increasePosition = 0
      of 1:
        increasePosition = 1
      else:
        increasePosition = 2
  else:
    increasePosition = max(0, originalNumberLen - 2)

  numbers[increasePosition] = $(numbers[increasePosition].parseInt() + 1)
  var zeroPosition = increasePosition + 1
  while zeroPosition < numbers.len:
    numbers[zeroPosition] = "0"
    inc(zeroPosition)
  result = newVersion(numbers.join("."))

proc makeRange*(version: Version, op: string): VersionRange =
  if version == notSetVersion:
    raise parseVersionError("A version needs to accompany the operator.")
  
  case op
  of ">":
    result = VersionRange(kind: verLater, ver: version)
  of "<":
    result = VersionRange(kind: verEarlier, ver: version)
  of ">=":
    result = VersionRange(kind: verEqLater, ver: version)
  of "<=":
    result = VersionRange(kind: verEqEarlier, ver: version)
  of "", "==":
    result = VersionRange(kind: verEq, ver: version)
  of "^=", "~=":
    let
      excludedVersion = getNextIncompatibleVersion(
        version, semver = (op == "^="))
      left = makeRange(version, ">=")
      right = makeRange(excludedVersion, "<")

    result =
      if op == "^=":
        VersionRange(kind: verCaret, verILeft: left, verIRight: right)
      else:
        VersionRange(kind: verTilde, verILeft: left, verIRight: right)
  else:
    raise parseVersionError("Invalid operator: " & op)

proc parseVersionRange*(s: string): VersionRange =
  # >= 1.5 & <= 1.8
  if s.len == 0:
    result = VersionRange(kind: verAny)
    return

  if s[0] == '#':
    result = VersionRange(kind: verSpecial, spe: newVersion(s))
    return

  var i = 0
  var op = ""
  var version = ""
  while i < s.len:
    case s[i]
    of '>', '<', '=', '~', '^':
      op.add(s[i])
    of '&':
      result = VersionRange(kind: verIntersect)
      result.verILeft = makeRange(newVersion(version), op)

      # Parse everything after &
      # Recursion <3
      result.verIRight = parseVersionRange(substr(s, i + 1))

      # Disallow more than one verIntersect. It's pointless and could lead to
      # major unpredictable mistakes.
      if result.verIRight.kind == verIntersect:
        raise parseVersionError(
          "Having more than one `&` in a version range is pointless")
      return
    of '0'..'9', '.':
      version.add(s[i])

    of ' ':
      # Make sure '0.9 8.03' is not allowed.
      if version != "" and i < s.len - 1:
        if s[i+1] in {'0'..'9', '.'}:
          raise parseVersionError(
            "Whitespace is not allowed in a version literal.")
    else:
      raise parseVersionError(
        "Unexpected char in version range '" & s & "': " & s[i])
    inc(i)
  result = makeRange(newVersion(version), op)

proc parseVersionRange*(version: Version): VersionRange =
  result = version.version.parseVersionRange

proc toVersionRange*(ver: Version): VersionRange =
  ## Converts a version to either a verEq or verSpecial VersionRange.
  result = 
    if ver.isSpecial:
      VersionRange(kind: verSpecial, spe: ver)
    else:
      VersionRange(kind: verEq, ver: ver)

proc parseRequires*(req: string): PkgTuple =
  try:
    if ' ' in req:
      var i = skipUntil(req, Whitespace)
      result.name = req[0 .. i].strip
      result.ver = parseVersionRange(req[i .. req.len-1])
    elif '#' in req:
      var i = skipUntil(req, {'#'})
      result.name = req[0 .. i-1]
      result.ver = parseVersionRange(req[i .. req.len-1])
    else:
      result.name = req.strip
      result.ver = VersionRange(kind: verAny)
  except ParseVersionError:
    raise nimbleError(
        "Unable to parse dependency version range: " & getCurrentExceptionMsg())

proc `$`*(verRange: VersionRange): string =
  case verRange.kind
  of verLater:
    result = "> "
  of verEarlier:
    result = "< "
  of verEqLater:
    result = ">= "
  of verEqEarlier:
    result = "<= "
  of verEq:
    result = ""
  of verSpecial:
    return $verRange.spe
  of verIntersect:
    return $verRange.verILeft & " & " & $verRange.verIRight
  of verTilde:
    return " ~= " & $verRange.verILeft
  of verCaret:
    return " ^= " & $verRange.verILeft
  of verAny:
    return "any version"

  result.add($verRange.ver)

proc getSimpleString*(verRange: VersionRange): string =
  ## Gets a string with no special symbols and spaces. Used for dir name
  ## creation in tools.nim
  case verRange.kind
  of verSpecial:
    result = $verRange.spe
  of verLater, verEarlier, verEqLater, verEqEarlier, verEq:
    result = $verRange.ver
  of verIntersect, verTilde, verCaret:
    result = getSimpleString(verRange.verILeft) & "_" &
        getSimpleString(verRange.verIRight)
  of verAny:
    result = ""

proc newVRAny*(): VersionRange =
  result = VersionRange(kind: verAny)

proc newVREarlier*(ver: Version): VersionRange =
  result = VersionRange(kind: verEarlier, ver: ver)

proc newVREq*(ver: Version): VersionRange =
  result = VersionRange(kind: verEq, ver: ver)

proc findLatest*(verRange: VersionRange,
        versions: OrderedTable[Version, string]): tuple[ver: Version, tag: string] =
  result = (newVersion(""), "")
  for ver, tag in versions:
    if not withinRange(ver, verRange): continue
    if ver > result.ver:
      result = (ver, tag)

proc `$`*(dep: PkgTuple): string =
  return dep.name & "@" & $dep.ver

when isMainModule:
  import unittest

  suite "version":
    setup:
      let versionRange1 {.used.} = parseVersionRange(">= 1.0 & <= 1.5")
      let versionRange2 {.used.} = parseVersionRange("1.0")

    test "versions comparison":
      check newVersion("1.0") < newVersion("1.4")
      check newVersion("1.0.1") > newVersion("1.0")
      check newVersion("1.0.6") <= newVersion("1.0.6")
      check not (newVersion("0.1.0") < newVersion("0.1"))
      check not (newVersion("0.1.0") > newVersion("0.1"))
      check newVersion("0.1.0") < newVersion("0.1.0.0.1")
      check newVersion("0.1.0") <= newVersion("0.1")
      check newVersion("1") == newVersion("1")
      check newVersion("1.0.2.4.6.1.2.123") == newVersion("1.0.2.4.6.1.2.123")
      check newVersion("1.0.2") != newVersion("1.0.2.4.6.1.2.123")
      check newVersion("1.0.3") != newVersion("1.0.2")
      check newVersion("1") == newVersion("1.0")

    test "version comparison with empty version":
      check not (newVersion("") < newVersion("0.0.0"))
      check newVersion("") < newVersion("1.0.0")
      check newVersion("") < newVersion("0.1.0")

    test "comparison of Nimble special versions":
      check newVersion("#ab26sgdt362") != newVersion("#qwersaggdt362")
      check newVersion("#ab26saggdt362") == newVersion("#ab26saggdt362")
      check newVersion("#head") == newVersion("#HEAD")
      check newVersion("#head") == newVersion("#head")

    test "#head is bigger than any other version":
      check newVersion("#head") > newVersion("0.1.0")
      check not (newVersion("#head") > newVersion("#head"))
      check withinRange(newVersion("#head"), parseVersionRange(">= 0.5.0"))
      check newVersion("#a111") < newVersion("#head")

    test "all special versions except #head are smaller than normal versions":
      doAssert newVersion("#a111") < newVersion("1.1")

    # TODO: Allow these in later versions?
    test "comparison of semantic versions with release candidate tags in them":
      skip()
      # check newVersion("0.1-rc1") < newVersion("0.2")
      # check newVersion("0.1-rc1") < newVersion("0.1")

    test "parse version range":
      check parseVersionRange("== 3.4.2") == parseVersionRange("3.4.2")

    test "correct version range kinds":
      check versionRange1.kind == verIntersect
      check versionRange2.kind == verEq
      # An empty version range should give verAny
      doAssert parseVersionRange("").kind == verAny

    test "version is within range":
      let version1 = newVersion("0.1.0")
      let version2 = newVersion("1.5.1")
      let version3 = newVersion("1.0.2.3.4.5.6.7.8.9.10.11.12")
      let versionRange = parseVersionRange("> 0.1")
      check not withinRange(version1, versionRange)
      check not withinRange(version2, versionRange1)
      check withinRange(version3, versionRange1)

    test "in and notin operators":
      let versionRange = parseVersionRange("#ab26sgdt362")
      check newVersion("#ab26sgdt362") in versionRange
      check newVersion("#ab26saggdt362") notin versionRange
      check newVersion("#head") in parseVersionRange("#head")

    test "find latest version":
      let versions = toOrderedTable[Version, string]({
        newVersion("0.0.1"): "v0.0.1",
        newVersion("0.0.2"): "v0.0.2",
        newVersion("0.1.1"): "v0.1.1",
        newVersion("0.2.2"): "v0.2.2",
        newVersion("0.2.3"): "v0.2.3",
        newVersion("0.5"): "v0.5",
        newVersion("1.2"): "v1.2",
        newVersion("2.2.2"): "v2.2.2",
        newVersion("2.2.3"): "v2.2.3",
        newVersion("2.3.2"): "v2.3.2",
        newVersion("3.2"): "v3.2",
        newVersion("3.3.2"): "v3.3.2"
      })
      check findLatest(parseVersionRange(">= 0.1 & <= 0.4"), versions) ==
          (newVersion("0.2.3"), "v0.2.3")
      check findLatest(parseVersionRange("^= 0.1"), versions) ==
          (newVersion("0.1.1"), "v0.1.1")
      check findLatest(parseVersionRange("^= 0"), versions) ==
          (newVersion("0.5"), "v0.5")
      check findLatest(parseVersionRange("~= 2"), versions) ==
          (newVersion("2.3.2"), "v2.3.2")
      check findLatest(parseVersionRange("^= 0.0.1"), versions) ==
          (newVersion("0.0.1"), "v0.0.1")
      check findLatest(parseVersionRange("^= 2.2.2"), versions) ==
          (newVersion("2.3.2"), "v2.3.2")
      check findLatest(parseVersionRange("^= 2.1.1.1"), versions) ==
          (newVersion("2.3.2"), "v2.3.2")
      check findLatest(parseVersionRange("~= 2.2"), versions) ==
          (newVersion("2.3.2"), "v2.3.2")
      check findLatest(parseVersionRange("~= 0.2.2"), versions) ==
          (newVersion("0.2.3"), "v0.2.3")

    test "convert version to version range":
      check toVersionRange(newVersion("#head")).kind == verSpecial
      check toVersionRange(newVersion("0.2.0")).kind == verEq
