## stdx: standard library extension
This is the monorepo alternative to fusion, which aims to address some shortcomings with fusion.

Unlike fusion, `stdx` and `std` modules can mutually import each other, and, because they're in a monorepo,
are kept in sync, which avoids issues when a change in stdlib requires a corresponding change in fusion.

`stdx` is typically used for modules that are not considered core functionality, yet are useful enough for inclusion in the monorepo.

## `stdx` means `extensions`, not `experimental`
`lib/experimental` (currently only containing `lib/experimental/diff.nim`) is now deprecated.
One issue with this design is that when a module `foo` is migrated from `experimental/foo` to `std/foo` (say with import + re-export or include), third party clients of `foo` have a decision to make:
* use `std/foo` (breaks for users of nim prior to the migration to `std/foo`)
* keep using `experimental/foo` (and silence the deprecation warning)

A bigger issue with `lib/experimental` is the all-or-nothing aspect, which goes against gradual API evolution.

Instead, for experiemntal modules and APIs, place the module in the intended destination and use `when defined(nimExperimentalFoo)` as appropriate, either at module scope or for an individual API that is expected to change:
```nim
# in lib/std/foo.nim
when defined(nimExperimentalFoo):
  proc fn1*() = discard
  proc fn2*() = discard
```

or, after some time passed and `foo` module itself became non-experimental:

```nim
# in lib/std/foo.nim
proc fn1*() = discard
when defined(nimExperimentalFoo):
  proc fn2*() = discard # still experimental
  proc fn3*() = discard # new experimental API
```
