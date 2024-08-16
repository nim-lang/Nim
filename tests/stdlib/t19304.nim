import times

type DjangoDateTime* = distinct DateTime

# proc toTime*(x: DjangoDateTime): Time  {.borrow.} # <-- works
proc format*(x: DjangoDateTime, f: TimeFormat,
    loc: DateTimeLocale = DefaultLocale): string {.borrow.}
