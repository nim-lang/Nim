discard """
output: '''
456456
456456
456456
Zugr5nd
egerichtetd
verichtetd
'''
"""

# Test the new slices.

var mystr = "Abgrund"
# mystr[..1] = "Zu" # deprecated
mystr[0..1] = "Zu"

mystr[4..4] = "5"

type
  TEnum = enum e1, e2, e3, e4, e5, e6

var myarr: array[TEnum, int] = [1, 2, 3, 4, 5, 6]
myarr[e1..e3] = myarr[e4..e6]
# myarr[..e3] = myarr[e4..e6] # deprecated
myarr[0..e3] = myarr[e4..e6]

for x in items(myarr): stdout.write(x)
echo()

var myarr2: array[0..5, int] = [1, 2, 3, 4, 5, 6]
myarr2[0..2] = myarr2[3..5]

for x in items(myarr2): stdout.write(x)
echo()


var myseq = @[1, 2, 3, 4, 5, 6]
myseq[0..2] = myseq[^3 .. ^1]

for x in items(myseq): stdout.write(x)
echo()

echo mystr

mystr[4..4] = "u"

# test full replacement
# mystr[.. ^2] = "egerichtet"  # deprecated
mystr[0 .. ^2] = "egerichtet"

echo mystr

mystr[0..2] = "ve"
echo mystr

var s = "abcdef"
s[1 .. ^2] = "xyz"
assert s == "axyzf"
