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
