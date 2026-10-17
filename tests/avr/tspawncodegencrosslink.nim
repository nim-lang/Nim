discard """
  cmd: "nim c --os:standalone --exceptions:quirky -d:noSignalHandler -d:danger --threads:off --avr.standalone.gcc.exe:true --avr.standalone.gcc.linkerexe:nim_fake_avr_ld $file"
  action: "reject"
  errormsg: "nim_fake_avr_ld"
  file: ""
  disabled: "windows"
"""

# Like tspawncodegencross but for the linker: the `--spawncodegen` child must
# also emit the `cpu.os.cc.linkerexe` cross setting into the build
# instructions. `true` stands in for the C compiler so that the build gets as
# far as linking, where the fake linker cannot run.

echo "hi"
