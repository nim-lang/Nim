# Test the case statment

type
  tenum = enum eA, eB, eC

var
  x: string
  y: Tenum = eA

case y
of eA: write(stdout, "a\n")
of eB, eC: write(stdout, "b oder c\n")

x = readLine(stdin)
case x
of "Andreas", "Rumpf": write(stdout, "Hallo Meister!\n")
of "aa", "bb": write(stdout, "Du bist nicht mein Meister\n")
of "cc", "hash", "when": nil
of "will", "it", "finally", "be", "generated": nil
else: write(stdout, "das sollte nicht passieren!\N")
