discard """
cmd: "testament/testament --directory:testament --colors:off --backendLogging:off --nim:$nim category shouldfail"
action: compile
nimout: '''
FAIL: tests/shouldfail/tccodecheck.nim c
Failure: reCodegenFailure
Expected:
baz
FAIL: tests/shouldfail/tcolumn.nim c
Failure: reLinesDiffer
FAIL: tests/shouldfail/terrormsg.nim c
Failure: reMsgsDiffer
FAIL: tests/shouldfail/texitcode1.nim c
Failure: reExitcodesDiffer
FAIL: tests/shouldfail/tfile.nim c
Failure: reFilesDiffer
FAIL: tests/shouldfail/tline.nim c
Failure: reLinesDiffer
FAIL: tests/shouldfail/tmaxcodesize.nim c
Failure: reCodegenFailure
max allowed size: 1
FAIL: tests/shouldfail/tnimout.nim c
Failure: reMsgsDiffer
FAIL: tests/shouldfail/toutput.nim c
Failure: reOutputsDiffer
FAIL: tests/shouldfail/toutputsub.nim c
Failure: reOutputsDiffer
FAIL: tests/shouldfail/treject.nim c
Failure: reFilesDiffer
FAIL: tests/shouldfail/tsortoutput.nim c
Failure: reOutputsDiffer
FAIL: tests/shouldfail/ttimeout.nim c
Failure: reTimeout
FAIL: tests/shouldfail/tvalgrind.nim c
Failure: reExitcodesDiffer
'''
"""
