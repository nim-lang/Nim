discard """
  cmd: "nim c --os:standalone --exceptions:quirky -d:noSignalHandler -d:danger --threads:off --avr.standalone.gcc.exe:nim_fake_avr_cc --avr.standalone.gcc.linkerexe:nim_fake_avr_cc $file"
  action: "reject"
  errormsg: "nim_fake_avr_cc"
  file: ""
"""

# The `--spawncodegen` child runs with `--compileOnly` but must still pick up
# the `cpu.os.cc.*` cross compilation settings instead of the host compiler.
# The fake compiler cannot run: the build is expected to fail mentioning it.

echo "hi"
