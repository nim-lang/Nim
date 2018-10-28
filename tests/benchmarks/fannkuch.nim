import os
import strutils

proc fannkuch(n: int): int =
    var
        count: seq[int]
        maxFlips = 0
        m = n-1
        r = n
        check = 0
        perm1: seq[int]
        perm: seq[int]

    newSeq(count, n+1)
    newSeq(perm1, n)
    newSeq(perm, n)
    for i in 0 .. n-1:
        count[i] = i+1
        perm1[i] = i
        perm[i]  = i
    count[n] = n+1

    while true:
        if check < 30:
            for i in items(perm1):
                write(stdout, $(i+1))
            echo("")
            inc(check)

        while r != 1:
            count[r-1] = r
            dec (r)

        if perm1[0] != 0 and perm1[m] != m:
            # perm = perm1
            # The above line is between 3 and 4 times slower than the loop below!
            for i in 0 .. n-1:
                perm[i] = perm1[i]
            var flipsCount = 0
            var k = perm[0]
            while k != 0:
                for i in 0 .. (k div 2):
                    swap(perm[i], perm[k-i])
                inc(flipsCount)
                k = perm[0]

            if flipsCount > maxFlips:
                maxFlips = flipsCount

        block makePerm:
            while r != n:
                var tmp = perm1[0]
                # # perm1.delete (0)
                # # perm1.insert (tmp, r)
                # # The above is about twice as slow as the following:
                # moveMem (addr (perm1[0]), addr (perm1[1]), r * sizeof (int))
                # The call to moveMem is about 50% slower than the loop below!
                for i in 0 .. r-1:
                    perm1[i] = perm1[i+1]
                perm1[r] = tmp

                dec(count[r])
                if count[r] > 0:
                    break makePerm
                inc(r)
            return maxFlips

var n = 10
echo("Pfannkuchen(" & $n & ") = " & $fannkuch(n))
