discard """
cmd: "testament/tester --directory:testament --colors:off --backendLogging:off --nim:../compiler/nim category shouldfail"
action: compile
nimout: '''
FAIL: tccodecheck.nim C
Failure: reCodegenFailure
Expected:
baz
FAIL: tcolumn.nim C
Failure: reLinesDiffer
FAIL: terrormsg.nim C
Failure: reMsgsDiffer
FAIL: texitcode1.nim C
Failure: reExitcodesDiffer
FAIL: tfile.nim C
Failure: reFilesDiffer
FAIL: tline.nim C
Failure: reLinesDiffer
FAIL: tmaxcodesize.nim C
Failure: reCodegenFailure
max allowed size: 1
FAIL: tnimout.nim C
Failure: reMsgsDiffer
FAIL: toutput.nim C
Failure: reOutputsDiffer
FAIL: toutputsub.nim C
Failure: reOutputsDiffer
FAIL: tsortoutput.nim C
Failure: reOutputsDiffer
'''
"""
