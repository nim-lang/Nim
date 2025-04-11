# issue #24838

{.pragma: testit, raises: [], deprecated: "abc".}

{.push testit.}
proc xxx() {.testit.} =
  discard "hello"
proc yyy() =
  discard "hello"
{.pop.}

xxx() #[tt.Warning
^ abc; xxx is deprecated [Deprecated]]#
yyy() #[tt.Warning
^ abc; yyy is deprecated [Deprecated]]#
