# Test unshare by changing hostname in the container

when defined(linux):
  from posix import fork, getgid, getuid, sethostname, waitpid
  from posix_utils import uname
  import linux
  import oids
  import os
  import strformat
  import strutils

  block tunshare:
    proc isSupportedByKernel: bool =
      let kernelConfigFilePath = "/boot/config-" & uname().release
      if kernelConfigFilePath.fileExists:
        let kernelConfig = readFile(kernelConfigFilePath)
        if "CONFIG_USER_NS=y" in kernelConfig and
            "CONFIG_UTS_NS=y" in kernelConfig:
          return true
      return false

    if isSupportedByKernel():
      let nodeName = uname().nodename
      let newNodeName = "tmp" & ($genOid())[0..<5]  # Generate unique name
      let forkResult = fork()
      case forkResult
      of -1: raiseAssert("Failed to fork")
      of 0:
        # Prepare UID and GID map to act as a root
        let uidMap = fmt"0 {getuid()} 1"
        let gidMap = fmt"0 {getgid()} 1"

        # Call unshare as user, create new UTS
        doAssert unshare(CLONE_NEWUSER or CLONE_NEWUTS) == 0,
          "Failed to do unshare"

        # Update UID and GID map files
        writeFile("/proc/self/setgroups", "deny")
        writeFile("/proc/self/uid_map", uidMap)
        writeFile("/proc/self/gid_map", gidMap)

        # Change hostname and check success
        let size = csize_t(newNodeName.len)
        doAssert sethostname(newNodeName.cstring, size) == 0,
          "Failed to change hostname"
        doAssert uname().nodename == newNodeName,
          "Failed to change hostname (current: " & uname().nodename & ")"
      else:
        # Wait child
        var wstatus: cint
        doAssert waitpid(forkResult, wstatus, 0) >= 0,
          "Failed to waitpid"

        # Check that child's hostname didn't propagate
        doAssert uname().nodename == nodeName
