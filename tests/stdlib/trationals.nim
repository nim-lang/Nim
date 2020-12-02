import rationals, math


var
  z = Rational[int](num: 0, den: 1)
  o = initRational(num = 1, den = 1)
  a = initRational(1, 2)
  b = -1 // -2
  m1 = -1 // 1
  tt = 10 // 2

assert(a == a)
assert( (a-a) == z)
assert( (a+b) == o)
assert( (a/b) == o)
assert( (a*b) == 1 // 4)
assert( (3/a) == 6 // 1)
assert( (a/3) == 1 // 6)
assert(a*b == 1 // 4)
assert(tt*z == z)
assert(10*a == tt)
assert(a*10 == tt)
assert(tt/10 == a)
assert(a-m1 == 3 // 2)
assert(a+m1 == -1 // 2)
assert(m1+tt == 16 // 4)
assert(m1-tt == 6 // -1)

assert(z < o)
assert(z <= o)
assert(z == z)
assert(cmp(z, o) < 0)
assert(cmp(o, z) > 0)

assert(o == o)
assert(o >= o)
assert(not(o > o))
assert(cmp(o, o) == 0)
assert(cmp(z, z) == 0)
assert(hash(o) == hash(o))

assert(a == b)
assert(a >= b)
assert(not(b > a))
assert(cmp(a, b) == 0)
assert(hash(a) == hash(b))

var x = 1//3

x *= 5//1
assert(x == 5//3)
x += 2 // 9
assert(x == 17//9)
x -= 9//18
assert(x == 25//18)
x /= 1//2
assert(x == 50//18)

var y = 1//3

y *= 4
assert(y == 4//3)
y += 5
assert(y == 19//3)
y -= 2
assert(y == 13//3)
y /= 9
assert(y == 13//27)

assert toRational(5) == 5//1
assert abs(toFloat(y) - 0.4814814814814815) < 1.0e-7
assert toInt(z) == 0

when sizeof(int) == 8:
  assert toRational(0.98765432) == 2111111029 // 2137499919
  assert toRational(PI) == 817696623 // 260280919
when sizeof(int) == 4:
  assert toRational(0.98765432) == 80 // 81
  assert toRational(PI) == 355 // 113

assert toRational(0.1) == 1 // 10
assert toRational(0.9) == 9 // 10

assert toRational(0.0) == 0 // 1
assert toRational(-0.25) == 1 // -4
assert toRational(3.2) == 16 // 5
assert toRational(0.33) == 33 // 100
assert toRational(0.22) == 11 // 50
assert toRational(10.0) == 10 // 1

assert (1//1) div (3//10) == 3
assert (-1//1) div (3//10) == -3
assert (3//10) mod (1//1) == 3//10
assert (-3//10) mod (1//1) == -3//10
assert floorDiv(1//1, 3//10) == 3
assert floorDiv(-1//1, 3//10) == -4
assert floorMod(3//10, 1//1) == 3//10
assert floorMod(-3//10, 1//1) == 7//10
