import posix, strutils, os

when false:
  type
    Tstatfs {.importc: "struct statfs64", 
              header: "<sys/statfs.h>", final, pure.} = object
      f_type: int
      f_bsize: int
      f_blocks: int
      f_bfree: int
      f_bavail: int
      f_files: int
      f_ffree: int
      f_fsid: int
      f_namelen: int

  proc statfs(path: string, buf: var Tstatfs): int {.
    importc, header: "<sys/vfs.h>".}


proc getSystemVersion*(): string =
  result = ""
  
  var unix_info: TUtsname
  
  if uname(unix_info) != 0:
    os.raiseOSError(osLastError())
  
  if $unix_info.sysname == "Linux":
    # Linux
    result.add("Linux ")

    result.add($unix_info.release & " ")
    result.add($unix_info.machine)
  elif $unix_info.sysname == "Darwin":
    # Darwin
    result.add("Mac OS X ")
    if "10" in $unix_info.release:
      result.add("v10.6 Snow Leopard")
    elif "9" in $unix_info.release:
      result.add("v10.5 Leopard")
    elif "8" in $unix_info.release:
      result.add("v10.4 Tiger")
    elif "7" in $unix_info.release:
      result.add("v10.3 Panther")
    elif "6" in $unix_info.release:
      result.add("v10.2 Jaguar")
    elif "1.4" in $unix_info.release:
      result.add("v10.1 Puma")
    elif "1.3" in $unix_info.release:
      result.add("v10.0 Cheetah")
    elif "0" in $unix_info.release:
      result.add("Server 1.0 Hera")
  else:
    result.add($unix_info.sysname & " " & $unix_info.release)
    
    
when false:
  var unix_info: TUtsname
  echo(uname(unix_info))
  echo(unix_info.sysname)
  echo("8" in $unix_info.release)

  echo(getSystemVersion())

  var stfs: TStatfs
  echo(statfs("sysinfo_posix.nim", stfs))
  echo(stfs.f_files)
  
