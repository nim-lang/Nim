# Helper for `temptyowned`: exports a concrete proc whose body folds to
# nothing (an `nkEmpty` body, like Nimbus' `extras.incInternalErrors` when the
# metrics counter's `.inc()` expands to a no-op under `-u:metrics`). The proc is
# NOT called within its own module — only `memptycaller` references it — so the
# per-module backend's owned-routine seeding is the ONLY thing that can emit it.

template maybe*(x: untyped) =
  when false:
    x

proc emptyOwned*() =
  maybe(echo "unreachable")
