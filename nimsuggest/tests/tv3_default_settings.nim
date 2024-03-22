when defined(c) and defined(gcOrc):
  var ok = 1

discard o#[!]#k

discard """
$nimsuggest --v3 --tester $file
>def $1
def;;skVar;;tv3_default_settings.ok;;int;;$file;;2;;6;;"";;100
"""
