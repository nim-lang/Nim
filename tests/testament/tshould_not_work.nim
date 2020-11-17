discard """
cmd: "testament/testament --directory:testament --colors:off --backendLogging:off --nim:../compiler/nim category shouldfail"
action: compile
nimout: '''
FAIL: tests/shouldfail/tccodecheck.nim C
Failure: reCodegenFailure
Expected:
baz
FAIL: tests/shouldfail/tcolumn.nim C
Failure: reLinesDiffer
FAIL: tests/shouldfail/terrormsg.nim C
Failure: reMsgsDiffer
FAIL: tests/shouldfail/texitcode1.nim C
Failure: reExitcodesDiffer
FAIL: tests/shouldfail/tfile.nim C
Failure: reFilesDiffer
FAIL: tests/shouldfail/tline.nim C
Failure: reLinesDiffer
FAIL: tests/shouldfail/tmaxcodesize.nim C
Failure: reCodegenFailure
max allowed size: 1
FAIL: tests/shouldfail/tnimout.nim C
Failure: reMsgsDiffer
FAIL: tests/shouldfail/toutput.nim C
Failure: reOutputsDiffer
FAIL: tests/shouldfail/toutputsub.nim C
Failure: reOutputsDiffer
FAIL: tests/shouldfail/tsortoutput.nim C
Failure: reOutputsDiffer
FAIL: tests/shouldfail/ttimeout.nim C
Failure: reTimeout
'''
"""

# xxx `--nim:../compiler/nim`, doesn't seem correct (and should also honor `testament --nim`)
