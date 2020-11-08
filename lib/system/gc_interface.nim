# ----------------- GC interface ---------------------------------------------
const
  usesDestructors = defined(gcDestructors) or defined(gcHooks)

when not usesDestructors:
  {.pragma: nodestroy.}

when hasAlloc:
  type
    GC_Strategy* = enum  ## The strategy the GC should use for the application.
      gcThroughput,      ## optimize for throughput
      gcResponsiveness,  ## optimize for responsiveness (default)
      gcOptimizeTime,    ## optimize for speed
      gcOptimizeSpace    ## optimize for memory footprint

when hasAlloc and not defined(js) and not usesDestructors:
  proc GC_disable*() {.rtl, inl, benign, raises: [].}
    ## Disables the GC. If called `n` times, `n` calls to `GC_enable`
    ## are needed to reactivate the GC.
    ##
    ## Note that in most circumstances one should only disable
    ## the mark and sweep phase with
    ## `GC_disableMarkAndSweep <#GC_disableMarkAndSweep>`_.

  proc GC_enable*() {.rtl, inl, benign, raises: [].}
    ## Enables the GC again.

  proc GC_fullCollect*() {.rtl, benign.}
    ## Forces a full garbage collection pass.
    ## Ordinary code does not need to call this (and should not).

  proc GC_enableMarkAndSweep*() {.rtl, benign.}
  proc GC_disableMarkAndSweep*() {.rtl, benign.}
    ## The current implementation uses a reference counting garbage collector
    ## with a seldomly run mark and sweep phase to free cycles. The mark and
    ## sweep phase may take a long time and is not needed if the application
    ## does not create cycles. Thus the mark and sweep phase can be deactivated
    ## and activated separately from the rest of the GC.

  proc GC_getStatistics*(): string {.rtl, benign.}
    ## Returns an informative string about the GC's activity. This may be useful
    ## for tweaking.

  proc GC_ref*[T](x: ref T) {.magic: "GCref", benign.}
  proc GC_ref*[T](x: seq[T]) {.magic: "GCref", benign.}
  proc GC_ref*(x: string) {.magic: "GCref", benign.}
    ## Marks the object `x` as referenced, so that it will not be freed until
    ## it is unmarked via `GC_unref`.
    ## If called n-times for the same object `x`,
    ## n calls to `GC_unref` are needed to unmark `x`.

  proc GC_unref*[T](x: ref T) {.magic: "GCunref", benign.}
  proc GC_unref*[T](x: seq[T]) {.magic: "GCunref", benign.}
  proc GC_unref*(x: string) {.magic: "GCunref", benign.}
    ## See the documentation of `GC_ref <#GC_ref,string>`_.

  proc nimGC_setStackBottom*(theStackBottom: pointer) {.compilerRtl, noinline, benign, raises: [].}
    ## Expands operating GC stack range to `theStackBottom`. Does nothing
      ## if current stack bottom is already lower than `theStackBottom`.

when hasAlloc and defined(js):
  template GC_disable* =
    {.warning: "GC_disable is a no-op in JavaScript".}

  template GC_enable* =
    {.warning: "GC_enable is a no-op in JavaScript".}

  template GC_fullCollect* =
    {.warning: "GC_fullCollect is a no-op in JavaScript".}

  template GC_setStrategy* =
    {.warning: "GC_setStrategy is a no-op in JavaScript".}

  template GC_enableMarkAndSweep* =
    {.warning: "GC_enableMarkAndSweep is a no-op in JavaScript".}

  template GC_disableMarkAndSweep* =
    {.warning: "GC_disableMarkAndSweep is a no-op in JavaScript".}

  template GC_ref*[T](x: ref T) =
    {.warning: "GC_ref is a no-op in JavaScript".}

  template GC_ref*[T](x: seq[T]) =
    {.warning: "GC_ref is a no-op in JavaScript".}

  template GC_ref*(x: string) =
    {.warning: "GC_ref is a no-op in JavaScript".}

  template GC_unref*[T](x: ref T) =
    {.warning: "GC_unref is a no-op in JavaScript".}

  template GC_unref*[T](x: seq[T]) =
    {.warning: "GC_unref is a no-op in JavaScript".}

  template GC_unref*(x: string) =
    {.warning: "GC_unref is a no-op in JavaScript".}

  template GC_getStatistics*(): string =
    {.warning: "GC_getStatistics is a no-op in JavaScript".}
    ""
