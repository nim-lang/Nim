discard """
  matrix: "--strings:sso --mm:orc"
  targets: "c cpp"
"""

var s = "abc"
discard s.cstring