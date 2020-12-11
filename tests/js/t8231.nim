import strutils

doAssert formatSize(2462056448, '.', bpIEC, false) == "2.293GiB"