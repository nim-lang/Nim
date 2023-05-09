discard """
matrix: "--hints:off"
nimout: '''
Found 2 tests to run.
Found 3 benches to compile.
 
  --passC:-Wno-stringop-overflow --passL:-Wno-stringop-overflow 
 
  --passC:-Wno-stringop-overflow --passL:-Wno-stringop-overflow 
 
  --passC:-Wno-stringop-overflow --passL:-Wno-stringop-overflow
'''
"""
# bug #21704
import std/strformat

const testDesc: seq[string] = @[
  "tests/t_hash_sha256_vs_openssl.nim",
  "tests/t_cipher_chacha20.nim"
]
const benchDesc = [
  "bench_sha256",
  "bench_hash_to_curve",
  "bench_ethereum_bls_signatures"
]

proc setupTestCommand(flags, path: string): string =
  return "nim c -r " &
    flags &
    &" --nimcache:nimcache/{path} " & # Commenting this out also solves the issue
    path

proc testBatch(commands: var string, flags, path: string) =
  commands &= setupTestCommand(flags, path) & '\n'

proc setupBench(benchName: string): string =
  var runFlags = if false: " -r "
                 else: " " # taking this branch is needed to trigger the bug

  echo runFlags # Somehow runflags isn't reset in corner cases
  runFlags &= " --passC:-Wno-stringop-overflow --passL:-Wno-stringop-overflow "
  echo runFlags

  return "nim c " &
       runFlags &
       &" benchmarks/{benchName}.nim"

proc buildBenchBatch(commands: var string, benchName: string) =
  let command = setupBench(benchName)
  commands &= command & '\n'

proc addTestSet(cmdFile: var string) =
  echo "Found " & $testDesc.len & " tests to run."

  for path in testDesc:
    var flags = "" # This is important
    cmdFile.testBatch(flags, path)

proc addBenchSet(cmdFile: var string) =
  echo "Found " & $benchDesc.len & " benches to compile."
  for bd in benchDesc:
    cmdFile.buildBenchBatch(bd)

proc task_bug() =
  var cmdFile: string
  cmdFile.addTestSet() # Comment this out and there is no bug
  cmdFile.addBenchSet()

static: task_bug()
