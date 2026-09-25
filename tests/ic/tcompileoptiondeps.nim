discard """
  output: "ok"
"""

# nimprof rejects a program unless profiling is enabled. The dependency scan
# must evaluate this false guard rather than scheduling the unused import.
when compileOption("profiler"):
  import std/nimprof

echo "ok"
