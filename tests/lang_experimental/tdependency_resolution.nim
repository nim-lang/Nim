discard """
  description: "Test dependency resolution feature"
  cmd: "nim c --experimental:dependencyResolution $file"
"""

{.experimental: "dependencyResolution".}

# This would normally fail due to forward references
# but dependency resolution should handle it

const x = calcDefault()      # Depends on calcDefault

type Config = object
  value: int

proc calcDefault(): int = 
  42  # Simplified - no sizeof to avoid circularity

proc process(c: Config) =    # Depends on Config
  echo helper(c.value)       # Depends on helper

proc helper(x: int): int = x * 2

# Test that it works
let cfg = Config(value: 5)
process(cfg)
assert calcDefault() == 42
