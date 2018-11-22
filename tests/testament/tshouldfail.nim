discard """
cmd: "testament/tester --directory:testament --nim:../compiler/nim category shouldfail"
nimout: '''
FAIL: tccodecheck.nim C
FAIL: tcolumn.nim C
FAIL: terrormsg.nim C
FAIL: texitcode1.nim C
FAIL: tfile.nim C
FAIL: tline.nim C
FAIL: tmaxcodesize.nim C
FAIL: tnimout.nim C
Test "tests/shouldfail/tnimout.nim" in category "shouldfail"
Failure: reMsgsDiffer
Expected:
Hello World!

Gotten:
Hint: used config file '/home/arne/proj/nim/Nim/config/nim.cfg' [Conf]
Hint: used config file '/home/arne/.config/nim/nim.cfg' [Conf]
something else
Hint:  [Link]
Hint: operation successful (12382 lines compiled; 0.885 sec total; 16.34MiB peakmem; Debug Build) [SuccessX]

TESTING tests/shouldfail/toutput.nim
FAIL: toutput.nim C
Test "tests/shouldfail/toutput.nim" in category "shouldfail"
Failure: reOutputsDiffer
Expected:
done


Gotten:
broken

TESTING tests/shouldfail/toutputsub.nim
FAIL: toutputsub.nim C
Test "tests/shouldfail/toutputsub.nim" in category "shouldfail"
Failure: reOutputsDiffer
Expected:
something else

Gotten:
Hello World!

TESTING tests/shouldfail/tsortoutput.nim
FAIL: tsortoutput.nim C
Test "tests/shouldfail/tsortoutput.nim" in category "shouldfail"
Failure: reOutputsDiffer
Expected:
2
1


Gotten:
1
2

'''
"""
