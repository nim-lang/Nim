discard """
  cmd: "nim c --os:standalone --exceptions:quirky -d:noSignalHandler -d:danger --threads:off --avr.standalone.gcc.exe:nim_fake_avr_cc --avr.standalone.gcc.options.always:-DNIM_CROSS_MARKER $file"
  action: "reject"
  errormsg: "nim_fake_avr_cc -c   -DNIM_CROSS_MARKER"
  file: ""
"""

# Like tspawncodegencross but for the compiler options: the `--spawncodegen`
# child must use `cpu.os.cc.options.always` instead of the host's options.

echo "hi"
