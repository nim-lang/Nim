{.pragma: myfoo2, exportc.}
{.pragma: myfoo3, exportc: "myfoo3_in_c", discardable.}
{.pragma: myfoo4, discardable, myfoo2.}
{.pragma: myfoo5.}
{.pragma: myfoo0, exportc: "myfoo0_in_c".}
{.pragma: myfoo6, myfoo0, discardable.}

export myfoo0 # needed if appears in an exported pragma; ideally should not be needed
export myfoo2, myfoo3, myfoo4, myfoo5, myfoo6
