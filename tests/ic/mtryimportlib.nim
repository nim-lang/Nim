# Verbatim copy of stew/importops `tryImport` (the shape that triggered the IC
# build-order bug in nim-ssz-serialization's digest.nim). The crucial property:
# the `import v` is INSIDE a template, so a syntactic dependency scan of a *user*
# of `tryImport` sees only a `tryImport foo` call — never an `import foo`
# statement — and therefore does NOT pre-schedule `foo` for the IC frontend.

template tryImport*(v: untyped): bool =
  when compiles((; import v)):
    import v
    true
  else:
    false
