# Test def with template and boundaries for the cursor

import fixtures/mstrutils

discard """
$nimsuggest --tester $file
>def $path/fixtures/mstrutils.nim:6:4
def;;skTemplate;;mfakeassert.fakeAssert;;template (cond: untyped, msg: string);;*fixtures/mfakeassert.nim;;3;;9;;"template to allow def lookup testing";;100
>def $path/fixtures/mstrutils.nim:12:3
def;;skTemplate;;mfakeassert.fakeAssert;;template (cond: untyped, msg: string);;*fixtures/mfakeassert.nim;;3;;9;;"template to allow def lookup testing";;100
>def $path/fixtures/mstrutils.nim:18:11
def;;skTemplate;;mfakeassert.fakeAssert;;template (cond: untyped, msg: string);;*fixtures/mfakeassert.nim;;3;;9;;"template to allow def lookup testing";;100
"""
