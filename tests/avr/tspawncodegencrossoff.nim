discard """
  cmd: "nim c --spawncodegen:off --os:standalone --exceptions:quirky -d:noSignalHandler -d:danger --threads:off --avr.standalone.gcc.exe:nim_fake_avr_cc $file"
  action: "reject"
  errormsg: "nim_fake_avr_cc"
  file: ""
"""

# Counterpart of tspawncodegencross: without `--spawncodegen` the in-process
# build must pick up the same `cpu.os.cc.*` cross compilation settings.

echo "hi"
