discard """
  matrix: "--mm:refc --mm:orc; --mm:arc --mm:orc; --mm:orc --mm:refc; --mm:refc --mm:none; --mm:boehm --mm:refc; --mm:regions --mm:refc; --mm:hooks --mm:refc; --mm:refc --mm:markandsweep"
"""

# bug #26610: a repeated --mm switch must leave only the last memory
# manager's symbols defined; previously the first MM's symbol survived.

var definedMms = 0
when defined(boehmgc): inc definedMms
when defined(gcrefc): inc definedMms
when defined(gcmarkandsweep): inc definedMms
when defined(gchooks): inc definedMms
when defined(gogc): inc definedMms
when defined(nogc): inc definedMms
when defined(gcregions): inc definedMms
when defined(gcarc): inc definedMms
when defined(gcorc): inc definedMms
when defined(gcyrc): inc definedMms
when defined(gcatomicarc): inc definedMms
doAssert definedMms == 1, "expected exactly one memory manager symbol"

when defined(gcarc) or defined(gcorc) or defined(gcyrc) or defined(gcatomicarc):
  doAssert defined(gcdestructors) and defined(nimSeqsV2) and defined(nimV2)
elif defined(gchooks):
  doAssert defined(nimSeqsV2)
else:
  doAssert not defined(gcdestructors) and not defined(nimSeqsV2) and
    not defined(nimV2)
