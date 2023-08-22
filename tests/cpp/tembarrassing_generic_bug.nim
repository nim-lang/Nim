discard """
  targets: "cpp"
  cmd: "nim cpp --threads:on $file"
"""

# bug #5142

var ci: Channel[int]
ci.open
