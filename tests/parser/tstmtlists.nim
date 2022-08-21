discard """
  output: '''
2
2
2
2
2
2
2
2
2
2
hello
1
hello
2
hello
3
hello
4
hello
5
hello
6
hello
7
hello
8
hello
9
hello
10
hello
1
hello
2
hello
3
hello
4
hello
5
hello
6
hello
7
hello
8
hello
9
hello
10
lucky
lucky
'''
"""

block: (
  discard;
  echo 1 + 1;
  )

block: (
  discard; #Haha
    #haha
  echo 1 + 1;
)

block: (
  discard;
  #Hmm
  echo 1 +
    1;
)

block: (
  discard
  echo "2"
)

block: (
  discard;
  echo 1 +
    1
)

block: (
  discard
  echo 1 +
    1
)

block: (
  discard;
  discard
)

block: (
  discard
  echo 1 + 1;
  )

block: (
  discard
  echo 1 + 1;
)

block: (
  discard
  echo 1 +
    1;
)

block: (
  discard;
    )

block: ( discard; echo 1 + #heh
                         1;
)

for i in 1..10:
    echo "hello"
    echo i

for i in 1..10: (
    echo "hello";
    echo i;
)

proc square(inSeq: seq[float]): seq[float] = (
  result = newSeq[float](len(inSeq));
  for i, v in inSeq: (
    result[i] = v * v;
  )
)

proc square2(inSeq: seq[float]): seq[float] =
  result = newSeq[float](len(inSeq));
  for i, v in inSeq: (
    result[i] = v * v;
  )

proc cstringCheck(tracked: int; n: int) =
  if true == false and (let a = high(int); let b = high(int);
      a.int8 == 8 and a.int8 notin {3..9}):
    echo(tracked, n)

template dim: int =
  (if int.high == 0:
    int.high
  else:
    int.high)

template dim2: int =
  (if int.high == 0:
    int.high
   else:
    int.high)

template dim: int =
  (
   if int.high == 0:
     int.high
   else:
     int.high)

# lenient indentation:

echo (if 0 == 1:
  "0 == 1"
else:
  "lucky")

# bug #16426
echo (when 0 == 1:
  "0 == 1"
else:
  "lucky")

