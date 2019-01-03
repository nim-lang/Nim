import dynlib

proc main()=
  var libHandle: LibHandle
  doAssertRaises(LibraryError):
    unloadLib(libHandle)
main()
