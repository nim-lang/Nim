discard """
  action: run
"""
import os, osproc, unittest

when defined(posix):
  let orgPath = getEnv("PATH")
  doAssert execShellCmd("""
set -e
p=/tmp/nim-osproc-test
mkdir $p $p/1 $p/2 $p/3 $p/4
touch $p/1/exe
echo '#!/bin/sh
' > $p/2/exe
echo '#!/bin/sh
' > $p/4/exe
chmod +x $p/2/exe
chmod +x $p/4/exe
""") == 0

  putEnv("PATH", "/tmp/nim-osproc-test/1:/tmp/nim-osproc-test/2")
  doAssert posixFindExe("exe") == "/tmp/nim-osproc-test/2/exe"
  startProcess("exe", options={poUsePath}).close

  putEnv("PATH", "/tmp/nim-osproc-test/3:/tmp/nim-osproc-test/2")
  doAssert posixFindExe("exe") == "/tmp/nim-osproc-test/2/exe"

  putEnv("PATH", "/tmp/nim-osproc-test/2:/tmp/nim-osproc-test/4")
  doAssert posixFindExe("exe") == "/tmp/nim-osproc-test/2/exe"

  putEnv("PATH", "/tmp/nim-osproc-test/4:/tmp/nim-osproc-test/3")
  doAssert posixFindExe("exe") == "/tmp/nim-osproc-test/4/exe"

  putEnv("PATH", "/tmp/nim-osproc-test/3")
  expect(OSError):
    discard posixFindExe("exe")

  expect(OSError):
    startProcess("exe", options={poUsePath}).close

  putEnv("PATH", "/tmp/nim-osproc-test/1")
  expect(OSError):
    discard posixFindExe("exe")

  expect(OSError):
    startProcess("exe", options={poUsePath}).close

  putEnv("PATH", "/tmp/nim-osproc-test/1:/tmp/nim-osproc-test/3")
  expect(OSError):
    discard posixFindExe("exe")

  expect(OSError):
    startProcess("exe", options={poUsePath}).close

  putEnv("PATH", "/tmp/nim-osproc-test/1")
  setCurrentDir("/tmp/nim-osproc-test/2")
  expect(OSError):
    discard posixFindExe("exe")

  expect(OSError):
    startProcess("exe", options={poUsePath}).close

  putEnv("PATH", orgPath)
  doAssert(execShellCmd("rm -r /tmp/nim-osproc-test") == 0)
