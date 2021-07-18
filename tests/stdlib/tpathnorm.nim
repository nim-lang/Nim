when defined(windows):
  block: # isWindowsDrive
    assert isWindowsDrive(r"c:\")
    assert isWindowsDrive(r"c:/")
    for a in [r"c:\abc", r"c:abc", r"c:", "abc", r"\", "/", ""]: assert not isWindowsDrive(a)
