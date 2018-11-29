discard """
cmd: "testament/tester --directory:testament --colors:off --backendLogging:off --nim:../compiler/nim category shouldfail"
action: compile
nimout: '''
FAIL: tccodecheck.nim C
FAIL: tcolumn.nim C
FAIL: terrormsg.nim C
FAIL: texitcode1.nim C
FAIL: tfile.nim C
FAIL: tline.nim C
FAIL: tmaxcodesize.nim C
FAIL: tnimout.nim C
FAIL: toutput.nim C
FAIL: toutputsub.nim C
FAIL: tsortoutput.nim C
'''
"""
