
# Testing alignment with the new alignment-aware allocation

type Xxx = object
  v {.align: 128.}: byte

# Test 1: Simple aligned type
echo "Test 1: Simple aligned ref object"
for i in 0..<100:
  let x = new Xxx
  if cast[uint](addr x.v) mod 128 != 0:
    echo "FAILED: Simple aligned ref misaligned at ", cast[uint](addr x.v)
    quit(1)
echo "Test 1 passed"

# Test 2: Nested aligned type (original test case)
type Yyy = object
  v: array[0..127, byte]
  v2: Xxx

echo "Test 2: Nested aligned ref object"
for i in 0..<1000:
  let x = new Yyy
  if cast[uint](addr x.v2.v) mod 128 != 0:
    echo "FAILED: Nested aligned ref misaligned at ", cast[uint](addr x.v2.v)
    quit(1)
echo "Test 2 passed"

# Test 3: Verify regular (non-aligned) objects still work
type Regular = object
  a, b, c: int

echo "Test 3: Regular ref objects"
for i in 0..<100:
  let x = new Regular
  x.a = i
  x.b = i * 2
  x.c = i * 3
  if x.a != i or x.b != i * 2 or x.c != i * 3:
    echo "FAILED: Regular ref data corruption"
    quit(1)
echo "Test 3 passed"

echo ""
echo "All tests passed! Alignment works correctly."

