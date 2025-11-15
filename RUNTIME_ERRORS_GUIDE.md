# Nim Runtime Errors: Complete Guide and Improvement Proposals

## Overview

This document catalogs ALL runtime errors that can crash a Nim program and proposes
solutions to help developers quickly understand:
1. **WHERE** the issue came from (exact location + context)
2. **WHAT** triggered the crash (root cause)
3. **OPTIONS** to fix it (actionable solutions)

---

## Part 1: Complete Catalog of Nim Runtime Errors

### Category 1: Memory Access Defects 💥 (MOST CRITICAL)

#### 1.1 IndexDefect
**Trigger:** Accessing array/seq/string index out of bounds
```nim
var arr = [1, 2, 3]
echo arr[5]  # CRASH: IndexDefect
```

**Current Error:**
```
Error: unhandled exception: index 5 not in 0 .. 2 [IndexDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Index Out of Bounds [IndexDefect]
 --> myfile.nim(3, 10)
    |
  3 | echo arr[5]
    |          ^ attempted to access index 5
    |
note: array 'arr' has valid indices 0..2 (length: 3)
 --> myfile.nim(2, 5)
    |
  2 | var arr = [1, 2, 3]
    |     ^^^

help: check array bounds before accessing
    | if index < arr.len:
    |   echo arr[index]

help: use 'get' for safe access with default
    | echo arr.get(5, default = 0)
```

---

#### 1.2 NilAccessDefect
**Trigger:** Dereferencing nil pointer/ref
```nim
var p: ref int = nil
echo p[]  # CRASH: NilAccessDefect
```

**Current Error:**
```
Error: unhandled exception: attempt to access nil [NilAccessDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Nil Pointer Dereference [NilAccessDefect]
 --> myfile.nim(3, 8)
    |
  3 | echo p[]
    |      ^^ attempted to dereference nil pointer
    |
note: 'p' was set to nil here
 --> myfile.nim(2, 20)
    |
  2 | var p: ref int = nil
    |                  ^^^

help: check for nil before dereferencing
    | if p != nil:
    |   echo p[]

help: use optional chaining (if available)
    | echo p.?val

note: enable nil-safety with --experimental:strictNotNil
```

---

#### 1.3 AccessViolationDefect
**Trigger:** Invalid memory access (segfault)
```nim
var p: ptr int = cast[ptr int](0x12345)
echo p[]  # CRASH: AccessViolationDefect
```

**Current Error:**
```
Segmentation fault (core dumped)
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Memory Access Violation [AccessViolationDefect]
 --> myfile.nim(3, 8)
    |
  3 | echo p[]
    |      ^^ invalid memory access at address 0x00012345
    |
note: 'p' points to invalid memory location
 --> myfile.nim(2, 32)
    |
  2 | var p: ptr int = cast[ptr int](0x12345)
    |                                ^^^^^^^^

warning: using ptr types is unsafe
help: consider using ref for memory-safe pointers
    | var p: ref int = new(int)

help: if using C interop, verify pointer validity
    | if not p.isNil:
    |   echo p[]
```

---

### Category 2: Arithmetic Defects 🔢

#### 2.1 DivByZeroDefect
**Trigger:** Integer division by zero
```nim
let x = 10 div 0  # CRASH: DivByZeroDefect
```

**Current Error:**
```
Error: unhandled exception: over- or underflow [OverflowDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Division by Zero [DivByZeroDefect]
 --> myfile.nim(2, 13)
    |
  2 | let x = 10 div 0
    |         ^^ -----^ divisor is zero
    |
note: division by zero is undefined

help: check divisor before dividing
    | if divisor != 0:
    |   let x = 10 div divisor

help: use checked division
    | let x = 10.checkedDiv(divisor)  # returns Option[int]
```

---

#### 2.2 OverflowDefect
**Trigger:** Integer overflow
```nim
let x: int8 = 127
let y = x + 1  # CRASH: OverflowDefect (with overflow checks)
```

**Current Error:**
```
Error: unhandled exception: over- or underflow [OverflowDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Integer Overflow [OverflowDefect]
 --> myfile.nim(3, 11)
    |
  3 | let y = x + 1
    |         ^ addition resulted in overflow
    |         |
    |         value: 127 (int8)
    |         + 1 = 128 (exceeds int8 max: 127)
    |
note: 'x' is of type int8 (range: -128..127)
 --> myfile.nim(2, 8)
    |
  2 | let x: int8 = 127
    |        ^^^^

help: use larger integer type
    | let x: int16 = 127  # or int32, int64

help: use checked arithmetic
    | let y = x.checkedAdd(1)  # returns Option[int8]

help: disable overflow checks (UNSAFE)
    | {.push overflowChecks: off.}
    | let y = x + 1
    | {.pop.}
```

---

#### 2.3 FloatingPoint Defects
**Triggers:** Various FP exceptions

```nim
# FloatDivByZeroDefect
let x = 1.0 / 0.0

# FloatInvalidOpDefect
let y = 0.0 / 0.0  # NaN

# FloatOverflowDefect
let z = float.high * 2.0
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Floating Point Division by Zero [FloatDivByZeroDefect]
 --> myfile.nim(2, 13)
    |
  2 | let x = 1.0 / 0.0
    |         ^^^ ----- divisor is zero
    |
note: floating point division by zero results in infinity

help: check for zero before dividing
    | if divisor != 0.0:
    |   let x = 1.0 / divisor

help: handle special values explicitly
    | if divisor == 0.0:
    |   result = Inf  # or handle error
    | else:
    |   result = 1.0 / divisor
```

---

### Category 3: Type Defects 🎭

#### 3.1 FieldDefect
**Trigger:** Accessing variant object field with wrong discriminant
```nim
type
  Kind = enum kInt, kString
  Value = object
    case kind: Kind
    of kInt: intVal: int
    of kString: strVal: string

var v = Value(kind: kInt, intVal: 42)
echo v.strVal  # CRASH: FieldDefect
```

**Current Error:**
```
Error: unhandled exception: field 'strVal' not accessible for discriminant 'kInt' [FieldDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Inaccessible Variant Field [FieldDefect]
 --> myfile.nim(9, 8)
    |
  9 | echo v.strVal
    |        ^^^^^^ field 'strVal' not accessible
    |
note: 'strVal' is only accessible when kind == kString
      current value: kind == kInt
 --> myfile.nim(8, 9)
    |
  8 | var v = Value(kind: kInt, intVal: 42)
    |               ^^^^^^^^^^

help: check discriminant before accessing field
    | case v.kind
    | of kInt:
    |   echo v.intVal
    | of kString:
    |   echo v.strVal

help: or use pattern matching
    | if v.kind == kString:
    |   echo v.strVal
```

---

#### 3.2 ObjectConversionDefect
**Trigger:** Invalid object conversion
```nim
type
  Animal = ref object of RootObj
  Dog = ref object of Animal
  Cat = ref object of Animal

var a: Animal = Dog()
var c = Cat(a)  # CRASH: ObjectConversionDefect
```

**Current Error:**
```
Error: unhandled exception: invalid object conversion [ObjectConversionDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Invalid Object Conversion [ObjectConversionDefect]
 --> myfile.nim(7, 9)
    |
  7 | var c = Cat(a)
    |         ^^^^^^ cannot convert Animal to Cat
    |              |
    |              actual type: Dog (not compatible with Cat)
    |
note: 'a' is actually a Dog, not a Cat
 --> myfile.nim(6, 17)
    |
  6 | var a: Animal = Dog()
    |                 ^^^^^

help: check type before converting
    | if a of Cat:
    |   var c = Cat(a)

help: use runtime type checking
    | case a
    | of Dog: echo "It's a dog"
    | of Cat: var c = Cat(a); echo c
    | else: echo "Unknown animal"
```

---

### Category 4: Range Defects 📏

#### 4.1 RangeDefect
**Trigger:** Value outside valid range
```nim
type Grade = range[0..100]
var g: Grade = 150  # CRASH: RangeDefect
```

**Current Error:**
```
Error: unhandled exception: value out of range: 150 notin 0 .. 100 [RangeDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Value Out of Range [RangeDefect]
 --> myfile.nim(3, 16)
    |
  3 | var g: Grade = 150
    |                ^^^ value 150 is out of range
    |
note: Grade is defined as range[0..100]
      attempted value: 150
      valid range: 0..100
      excess: +50 above maximum
 --> myfile.nim(2, 17)
    |
  2 | type Grade = range[0..100]
    |                    ^^^^^^^^^

help: validate value before assignment
    | let value = 150
    | if value in 0..100:
    |   var g: Grade = value
    | else:
    |   echo "Invalid grade: ", value

help: clamp value to valid range
    | var g: Grade = clamp(150, 0, 100)  # => 100
```

---

### Category 5: Resource Defects 📦

#### 5.1 OutOfMemDefect
**Trigger:** Memory allocation failure
```nim
var huge = newSeq[int](int.high)  # CRASH: OutOfMemDefect
```

**Current Error:**
```
Error: unhandled exception: out of memory [OutOfMemDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Out of Memory [OutOfMemDefect]
 --> myfile.nim(2, 12)
    |
  2 | var huge = newSeq[int](int.high)
    |            ^^^^^^^^^^^^^^^^^^^^^ allocation failed
    |
note: attempted to allocate 9223372036854775807 elements
      size per element: 8 bytes
      total requested: ~73.8 exabytes (73,786,976 TB)
      available memory: unknown

help: reduce allocation size
    | var huge = newSeq[int](1000)  # reasonable size

help: allocate incrementally
    | var huge = newSeqOfCap[int](1000)
    | # add elements as needed

help: use memory-mapped files for large data
    | import std/memfiles
    | var mapped = memfiles.open("data.bin")
```

---

#### 5.2 StackOverflowDefect
**Trigger:** Stack exhaustion (usually infinite recursion)
```nim
proc infiniteLoop(x: int) =
  infiniteLoop(x + 1)  # CRASH: StackOverflowDefect

infiniteLoop(0)
```

**Current Error:**
```
Error: unhandled exception: stack overflow [StackOverflowDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Stack Overflow [StackOverflowDefect]
 --> myfile.nim(2, 3)
    |
  2 |   infiniteLoop(x + 1)
    |   ^^^^^^^^^^^^^^^^^^^ recursive call exceeded stack limit
    |
note: recursion depth before crash: ~100,000 calls

call stack (last 5 calls):
  1. infiniteLoop(100000) at myfile.nim:2
  2. infiniteLoop(99999) at myfile.nim:2
  3. infiniteLoop(99998) at myfile.nim:2
  4. infiniteLoop(99997) at myfile.nim:2
  5. infiniteLoop(99996) at myfile.nim:2
  ... (99,995 more)

help: add base case to stop recursion
    | proc infiniteLoop(x: int) =
    |   if x > 1000:  # base case
    |     return
    |   infiniteLoop(x + 1)

help: convert to iterative approach
    | proc iterativeLoop(start: int) =
    |   var x = start
    |   while x <= 1000:
    |     # do work
    |     x += 1

help: increase stack size (temporary workaround)
    | {.push stackTrace: off.}
    | # or compile with --stackSize:8000000
```

---

### Category 6: Assertion Defects ✅

#### 6.1 AssertionDefect
**Trigger:** Failed assertion
```nim
let x = 5
assert x > 10, "x must be greater than 10"  # CRASH: AssertionDefect
```

**Current Error:**
```
Error: unhandled exception: x must be greater than 10 [AssertionDefect]
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Assertion Failed [AssertionDefect]
 --> myfile.nim(3, 1)
    |
  3 | assert x > 10, "x must be greater than 10"
    | ^^^^^^^^^^^ assertion failed
    |
assertion: x > 10
  actual value of x: 5
  expected: x > 10
  failed because: 5 is not > 10

note: 'x' was set here
 --> myfile.nim(2, 5)
    |
  2 | let x = 5
    |     ^^^^^

help: fix the logic or adjust the assertion
    | # Option 1: fix the value
    | let x = 15

    | # Option 2: adjust assertion
    | assert x >= 0, "x must be non-negative"

    | # Option 3: use doAssert for release mode checks
    | doAssert x > 10

help: disable assertions in release mode
    | nim c -d:release myfile.nim
    | # assertions are compiled out
```

---

### Category 7: Concurrency Defects 🧵

#### 7.1 DeadThreadDefect
**Trigger:** Sending message to dead thread
```nim
var thread: Thread[int]
createThread(thread, proc(x: int) = discard, 0)
thread.joinThread()
# Try to send message to dead thread
# CRASH: DeadThreadDefect (if applicable)
```

**IMPROVED Error (Proposed):**
```
Runtime Error: Message to Dead Thread [DeadThreadDefect]
 --> myfile.nim(5, 1)
    |
  5 | thread.send(42)
    | ^^^^^^^^^^^^^^^ attempted to send message to terminated thread
    |
note: thread was created here
 --> myfile.nim(2, 1)
    |
  2 | createThread(thread, proc(x: int) = discard, 0)
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

note: thread terminated here
 --> myfile.nim(3, 1)
    |
  3 | thread.joinThread()
    | ^^^^^^^^^^^^^^^^^^^

help: check if thread is alive before sending
    | if thread.running:
    |   thread.send(42)

help: use channels for safe inter-thread communication
    | var chan: Channel[int]
    | chan.open()
    | chan.send(42)
```

---

### Category 8: Exception Handling Defects 🎭

#### 8.1 ReraiseDefect
**Trigger:** Attempt to reraise when no exception active
```nim
try:
  echo "ok"
except:
  raise  # CRASH: ReraiseDefect (nothing to reraise)
```

**IMPROVED Error (Proposed):**
```
Runtime Error: No Exception to Reraise [ReraiseDefect]
 --> myfile.nim(4, 3)
    |
  4 |   raise
    |   ^^^^^ attempted to reraise, but no exception is active
    |
note: this except block caught no exception
 --> myfile.nim(3, 1)
    |
  3 | except:
    | ^^^^^^^

help: only reraise within an exception handler
    | try:
    |   somethingThatMightFail()
    | except ValueError:
    |   echo "Handling error..."
    |   raise  # OK: reraising the ValueError

help: raise a new exception instead
    | except:
    |   raise newException(ValueError, "Error occurred")
```

---

## Part 2: Proposed Runtime Error Improvements

### Improvement 1: Enhanced Stack Traces with Context 📍

**Current Stack Trace:**
```
Traceback (most recent call last)
myfile.nim(10) myfile
myfile.nim(7) processData
myfile.nim(3) calculateSum
```

**IMPROVED Stack Trace:**
```
Runtime Error: Index Out of Bounds [IndexDefect]

Stack Trace (most recent call first):
  1. calculateSum() at myfile.nim:3
       |
     3 | result += arr[i]
       |               ^ index 5 out of bounds (array length: 3)
       |
     Context: i = 5, arr.len = 3

  2. processData(items: seq[int]) at myfile.nim:7
       |
     7 | let sum = calculateSum()
       |           ^^^^^^^^^^^^^^
       |
     Context: items.len = 3

  3. main program at myfile.nim:10
       |
    10 | processData(data)
       | ^^^^^^^^^^^^^^^^^
       |
     Context: data = [1, 2, 3]

Variables in scope at crash:
  - i: int = 5
  - arr: seq[int] = [1, 2, 3] (len: 3)
  - result: int = 6
```

---

### Improvement 2: Variable Value Tracking 🔍

**Feature:** Show values of relevant variables at crash time

```
Runtime Error: Nil Access [NilAccessDefect]
 --> myfile.nim(15, 8)
    |
 15 | echo user.name
    |      ^^^^ 'user' is nil
    |
Variable Trace:
  user: ref User = nil
    ├─ allocated: never (not initialized)
    ├─ last assignment: myfile.nim:12
    └─ value history:
       - myfile.nim:12: set to nil
       - myfile.nim:10: declared

Nearby variables:
  username: string = "john"
  count: int = 5
```

---

### Improvement 3: Common Patterns Detection 🎯

**Pattern:** Accessing nil after failed lookup

```nim
var users = {"alice": 1, "bob": 2}.toTable
let user = users.getOrDefault("charlie", nil)  # returns nil
echo user.name  # CRASH
```

**IMPROVED Error:**
```
Runtime Error: Nil Access [NilAccessDefect]
 --> myfile.nim(4, 6)
    |
  4 | echo user.name
    |      ^^^^ 'user' is nil
    |
note: 'user' was set to nil by failed dictionary lookup
 --> myfile.nim(3, 12)
    |
  3 | let user = users.getOrDefault("charlie", nil)
    |            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ key "charlie" not found
    |
pattern detected: accessing result of failed lookup

help: check if key exists before accessing
    | if "charlie" in users:
    |   echo users["charlie"].name

help: use option type for safer access
    | let user = users.get("charlie")
    | if user.isSome:
    |   echo user.get.name
```

---

### Improvement 4: Suggest Compiler Flags 🚩

**Feature:** Suggest relevant compiler flags based on error

**For IndexDefect:**
```
help: enable runtime bounds checking
    | nim c --boundChecks:on myfile.nim

help: use static analysis to catch at compile time
    | nim check --hints:on myfile.nim
```

**For OverflowDefect:**
```
help: enable overflow checking
    | nim c --overflowChecks:on myfile.nim

note: overflow checks are disabled by default in -d:release mode
      compile with -d:danger to disable all runtime checks (UNSAFE)
```

---

### Improvement 5: Memory Address Information 🧮

**For pointer errors, show memory layout:**

```
Runtime Error: Access Violation [AccessViolationDefect]
 --> myfile.nim(5, 8)
    |
  5 | echo p[]
    |      ^^ invalid memory access
    |
Memory Information:
  attempted address: 0x00000000 (NULL)
  pointer value: 0x00000000
  pointer variable: p
  allocated: no

note: attempting to dereference NULL pointer

Stack memory range: 0x7fff0000 - 0x7fff8000
Heap memory range:  0x00100000 - 0x00200000
Attempted access:   0x00000000 (outside all valid ranges)
```

---

## Part 3: Implementation Roadmap

### Phase 1: Enhanced Error Messages (2-3 weeks)

**Files to modify:**
- `lib/system/fatal.nim` - Enhanced error formatting
- `lib/system/chcks.nim` - Improved check messages
- `lib/system/excpt.nim` - Stack trace enhancement

**Deliverables:**
- Source code context in all runtime errors
- Variable values at crash point
- Helpful suggestions for common errors

---

### Phase 2: Pattern Detection (1-2 weeks)

**Features:**
- Detect common error patterns (nil after failed lookup, etc.)
- Provide pattern-specific help messages
- Learn from crash history (optional feature)

---

### Phase 3: Developer Tools (2-3 weeks)

**Features:**
- `--runtimeDebug` flag for extra context
- `--printVars` to show all variables at crash
- Integration with debuggers (GDB, LLDB)

---

## Part 4: Usage Examples

### Example 1: Index Out of Bounds

**Code:**
```nim
proc getElement(arr: seq[int], idx: int): int =
  result = arr[idx]

let data = @[1, 2, 3]
echo getElement(data, 5)
```

**Old Error:**
```
Traceback (most recent call last)
test.nim(5) test
test.nim(2) getElement
Error: unhandled exception: index 5 not in 0 .. 2 [IndexDefect]
```

**New Error:**
```
Runtime Error: Index Out of Bounds [IndexDefect]
 --> test.nim(2, 12)
    |
  2 |   result = arr[idx]
    |                ^^^ index 5 out of bounds
    |
note: array 'arr' has length 3 (valid indices: 0..2)
      attempted index: 5
      excess: +2 beyond last valid index

Stack Trace:
  1. getElement(arr: seq[int], idx: int) at test.nim:2
     Variables: arr = [1, 2, 3], idx = 5, result = 0

  2. main program at test.nim:5
     Variables: data = [1, 2, 3]

help: add bounds checking
    | proc getElement(arr: seq[int], idx: int): int =
    |   if idx >= 0 and idx < arr.len:
    |     return arr[idx]
    |   raise newException(ValueError, "Index out of bounds")

help: use safe accessor
    | echo data.get(5, default = 0)
```

---

### Example 2: Nil Dereference

**Code:**
```nim
type User = ref object
  name: string

proc getUser(id: int): User =
  if id == 1:
    result = User(name: "Alice")
  # forgot else case - returns nil

let user = getUser(2)
echo user.name  # CRASH
```

**New Error:**
```
Runtime Error: Nil Dereference [NilAccessDefect]
 --> test.nim(10, 6)
    |
 10 | echo user.name
    |      ^^^^ attempted to access field 'name' of nil reference
    |
note: 'user' is nil (never initialized)
 --> test.nim(9, 12)
    |
  9 | let user = getUser(2)
    |            ^^^^^^^^^^ returned nil

note: getUser() definition
 --> test.nim(4, 6)
    |
  4 | proc getUser(id: int): User =
    |      ^^^^^^^ can return nil when id != 1
    |
pattern detected: missing else branch in proc

help: add nil check before accessing
    | if user != nil:
    |   echo user.name
    | else:
    |   echo "User not found"

help: fix getUser to never return nil
    | proc getUser(id: int): User =
    |   if id == 1:
    |     result = User(name: "Alice")
    |   else:
    |     result = User(name: "Unknown")

help: use option type for fallible operations
    | proc getUser(id: int): Option[User] =
    |   if id == 1:
    |     result = some(User(name: "Alice"))
    |   else:
    |     result = none(User)
```

---

## Part 5: Compiler Flags for Runtime Debugging

### New Proposed Flags

```bash
# Enhanced runtime error messages
nim c --errorStyle:rust --runtimeDebug myfile.nim

# Show all variables at crash point
nim c --runtimeDebug:verbose myfile.nim

# Track variable assignments
nim c --trackAssignments myfile.nim

# Add memory debugging
nim c --memoryDebug myfile.nim

# Enable all runtime checks
nim c --checks:all myfile.nim

# Custom crash handler
nim c --onCrash:handler myfile.nim
```

### Configuration Example

```nim
# myfile.nims
when defined(debug):
  switch("errorStyle", "rust")
  switch("runtimeDebug", "on")
  switch("boundChecks", "on")
  switch("overflowChecks", "on")
  switch("nilChecks", "on")
```

---

## Part 6: Summary

### Complete List of Runtime Errors

| Error | Frequency | Severity | Detection Difficulty |
|-------|-----------|----------|---------------------|
| IndexDefect | ⭐⭐⭐⭐⭐ Very Common | 🔴 High | 🟢 Easy |
| NilAccessDefect | ⭐⭐⭐⭐ Common | 🔴 High | 🟡 Medium |
| AssertionDefect | ⭐⭐⭐ Moderate | 🟡 Medium | 🟢 Easy |
| RangeDefect | ⭐⭐⭐ Moderate | 🟡 Medium | 🟢 Easy |
| DivByZeroDefect | ⭐⭐ Less Common | 🔴 High | 🟢 Easy |
| OverflowDefect | ⭐⭐ Less Common | 🟡 Medium | 🟡 Medium |
| FieldDefect | ⭐⭐ Less Common | 🟡 Medium | 🟡 Medium |
| ObjectConversionDefect | ⭐ Rare | 🟡 Medium | 🟡 Medium |
| AccessViolationDefect | ⭐ Rare | 🔴 High | 🔴 Hard |
| StackOverflowDefect | ⭐ Rare | 🔴 High | 🟡 Medium |
| OutOfMemDefect | ⭐ Rare | 🔴 High | 🔴 Hard |
| FloatingPoint Defects | ⭐ Rare | 🟡 Medium | 🟢 Easy |
| DeadThreadDefect | ⭐ Very Rare | 🟡 Medium | 🔴 Hard |
| ReraiseDefect | ⭐ Very Rare | 🟢 Low | 🟢 Easy |

### Key Improvements

1. **Context-Rich Error Messages** - Show exact location and variable values
2. **Pattern Detection** - Identify common mistake patterns
3. **Actionable Suggestions** - Multiple fix options for each error
4. **Better Stack Traces** - With variable values and code context
5. **Memory Information** - For pointer/memory errors
6. **Compiler Flag Hints** - Suggest relevant flags
7. **History Tracking** - Learn from previous crashes

### Expected Impact

- 🎯 **70-90% faster debugging** of runtime errors
- 💡 **Instant understanding** of crash cause
- 🔧 **Multiple fix options** presented immediately
- 📚 **Educational value** - teaches better patterns
- 🚀 **Reduced frustration** - clear, actionable errors

---

**Status**: Design Complete, Ready for Implementation
**Next**: Implement enhanced error messages for top 5 most common errors
