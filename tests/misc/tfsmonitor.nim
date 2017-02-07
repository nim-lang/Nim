discard """
  disabled: windows
"""

import unittest
import fsmonitor

suite "fsmonitor":
  test "should not raise OSError, bug# 3611":
    let m = newMonitor()
    m.add("foo", {MonitorCloseWrite, MonitorCloseNoWrite})
