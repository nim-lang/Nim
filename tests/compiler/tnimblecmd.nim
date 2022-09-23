include compiler/[nimblecmd], sets

proc v(s: string): Version = s.newVersion

proc testVersionsComparison =
  # #head is special in the sense that it's assumed to always be newest.
  doAssert v"1.0" < v"#head"
  doAssert v"1.0" < v"1.1"
  doAssert v"1.0.1" < v"1.1"
  doAssert v"1" < v"1.1"
  doAssert v"#aaaqwe" < v"1.1" # We cannot assume that a branch is newer.
  doAssert v"#a111" < v"#head"

proc testAddPackageWithoutChecksum =
  ## For backward compatibility it is not required all packages to have a
  ## sha1 checksum at the end of the name of the Nimble cache directory.
  ## This way a new compiler will be able to work with an older Nimble.

  let conf = newConfigRef()
  var rr: PackageInfo

  addPackage conf, rr, "irc-#a111", unknownLineInfo
  addPackage conf, rr, "irc-#head", unknownLineInfo
  addPackage conf, rr, "irc-0.1.0", unknownLineInfo

  addPackage conf, rr, "another-0.1", unknownLineInfo

  addPackage conf, rr, "ab-0.1.3", unknownLineInfo
  addPackage conf, rr, "ab-0.1", unknownLineInfo
  addPackage conf, rr, "justone-1.0", unknownLineInfo

  doAssert toSeq(rr.chosen).toHashSet ==
    ["irc-#head", "another-0.1", "ab-0.1.3", "justone-1.0"].toHashSet

proc testAddPackageWithChecksum =
  let conf = newConfigRef()
  var rr: PackageInfo

  # in the case of packages with the same version, but different checksums for
  # now the first one will be chosen

  addPackage conf, rr, "irc-#a111-DBC1F902CB79946E990E38AF51F0BAD36ACFABD9",
             unknownLineInfo
  addPackage conf, rr, "irc-#head-042D4BE2B90ED0672E717D71850ABDB0A2D19CD1",
             unknownLineInfo
  addPackage conf, rr, "irc-#head-042D4BE2B90ED0672E717D71850ABDB0A2D19CD2",
             unknownLineInfo
  addPackage conf, rr, "irc-0.1.0-6EE6DE936B32E82C7DBE526DA3463574F6568FAF",
             unknownLineInfo

  addPackage conf, rr, "another-0.1", unknownLineInfo
  addPackage conf, rr, "another-0.1-F07EE6040579F0590608A8FD34F5F2D91D859340",
             unknownLineInfo

  addPackage conf, rr, "ab-0.1.3-34BC3B72CE46CF5A496D1121CFEA7369385E9EA2",
             unknownLineInfo
  addPackage conf, rr, "ab-0.1.3-24BC3B72CE46CF5A496D1121CFEA7369385E9EA2",
             unknownLineInfo
  addPackage conf, rr, "ab-0.1-A3CFFABDC4759F7779D541F5E031AED17169390A",
             unknownLineInfo

  # lower case hex digits is also a valid sha1 checksum
  addPackage conf, rr, "justone-1.0-f07ee6040579f0590608a8fd34f5f2d91d859340",
             unknownLineInfo

  doAssert toSeq(rr.chosen).toHashSet == [
    "irc-#head-042D4BE2B90ED0672E717D71850ABDB0A2D19CD1",
    "another-0.1",
    "ab-0.1.3-34BC3B72CE46CF5A496D1121CFEA7369385E9EA2",
    "justone-1.0-f07ee6040579f0590608a8fd34f5f2d91d859340"
    ].toHashSet

testVersionsComparison()
testAddPackageWithoutChecksum()
testAddPackageWithChecksum()
