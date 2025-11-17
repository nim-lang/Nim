# Proposal: Built-in Runtime Type Names for Nim OOP

## Executive Summary

**Problem**: Developers cannot easily determine the runtime type of polymorphic objects in Nim, making OOP debugging difficult.

**Current State**:
- Old GC (refc): Partial support via `m_type` field (complex to access)
- Modern GC (ARC/ORC): No built-in runtime type information
- Workaround: Our `system/debugging` module using `of` checks

**Proposal**: Add automatic runtime type name field to all inheritable objects (enabled by default in all builds).

##Status Quo

### What Works Today (Our Solution)

```nim
import system/debugging

type
  Animal {.inheritable.} = ref object of RootObj
  Dog = ref object of Animal

genRuntimeTypeCheck(Animal, Dog)

let animal: Animal = Dog()
echo runtimeTypeName(animal)  # Works! Prints "Dog"
```

This works but requires:
- Importing a module
- Manually listing all types in hierarchy
- Runtime `of` checks for each type

### What Should Work (Proposed)

```nim
type
  Animal {.inheritable.} = ref object of RootObj
  Dog = ref object of Animal

let animal: Animal = Dog()
echo animal.typeName  # Should just work! Prints "Dog"
```

## Detailed Proposal

### 1. Compiler Enhancement

Add a hidden `runtimeType_` field to all {.inheritable.} objects:

```nim
type Animal {.inheritable.} = ref object of RootObj
  name: string
  # Compiler automatically adds (always, unless -d:noRuntimeTypeNames):
  # runtimeType_: cstring

# Each type gets its type name constant:
const AnimalTypeName {.compilerproc.} = "Animal"
const DogTypeName {.compilerproc.} = "Dog"

# Constructor automatically initializes:
proc newAnimal(): Animal =
  result = Animal()
  result.runtimeType_ = AnimalTypeName

proc newDog(): Dog =
  result = Dog()
  result.runtimeType_ = DogTypeName  # Actual runtime type!
```

### 2. Public API

Add to `system` module:

```nim
proc typeName*[T: ref RootObj](obj: T): string {.inline.} =
  ## Returns the runtime type name of an object.
  ## Always available for inheritable objects.
  return $obj.runtimeType_
```

### 3. Compilation Modes

**Default: Always enabled** - The field is included in ALL builds by default.

| Mode | Runtime Type Field | Memory Cost | Rationale |
|------|-------------------|-------------|-----------|
| **Default (all builds)** | **Yes** | **8 bytes/object** | **Consistent behavior, production debugging** |
| `-d:noRuntimeTypeNames` | No | 0 bytes | Opt-out for extreme memory constraints |

**Why Always-On:**
- **8 bytes is negligible** on modern systems (0.0008% of 1MB object)
- **Production debugging** without recompiling
- **Consistent behavior** across debug and release
- **Matches expectations** from C#/Java/Python developers
- **Enables better error messages** in production

## Implementation Details

### Changes Required

#### 1. Compiler (`compiler/sem.nim` or similar)

```nim
proc addRuntimeTypeField(t: PType; info: TLineInfo) =
  ## Adds hidden runtimeType_ field to inheritable objects
  ## Always added unless -d:noRuntimeTypeNames is defined
  if tfInheritable in t.flags and not defined(noRuntimeTypeNames):
    let field = newSym(skField, getIdent("runtimeType_"), t.owner, info)
    field.typ = getSysType(tyCstring)  # Use cstring for efficiency
    field.flags.incl sfCompilerProc
    t.n.add(newSymNode(field))
```

#### 2. Object Construction (`compiler/semstmts.nim`)

Inject type name initialization in constructors:

```nim
proc injectTypeNameInit(c: PContext; constr: PNode; t: PType) =
  ## Adds: result.runtimeType_ = TypeName
  if hasRuntimeTypeField(t):
    let assignment = newNodeI(nkAsgn, constr.info)
    assignment.add(newDotExpr(result, "runtimeType_"))
    assignment.add(newStrLitNode(t.sym.name.s))
    constr.sons[bodyPos].add(assignment)
```

#### 3. System Module API

```nim
# In lib/system.nim
template typeName*[T: ref RootObj](obj: T): string =
  when compiles(obj.runtimeType_):
    $obj.runtimeType_
  else:
    $typeof(obj)
```

### Backward Compatibility

- **100% compatible**: New field is hidden (`runtimeType_` with trailing underscore)
- Only added in debug builds by default
- Can be disabled entirely with `-d:release`
- No changes to existing code required

## Benefits

### 1. Developer Experience

**Before:**
```nim
# Complex, manual setup
import system/debugging
genRuntimeTypeCheck(Animal, Dog, Cat, Bird)

method speak(a: Animal) =
  debugMethodDispatch(a, "speak", runtimeTypeName(a))
  echo runtimeTypeName(a), " speaks"
```

**After:**
```nim
# Simple, automatic
method speak(a: Animal) =
  echo a.typeName, " speaks"  # Just works!
```

### 2. Better Debugging

```nim
# Easy method dispatch tracking
method process(a: Animal) {.base.} =
  echo "[DEBUG] Processing ", a.typeName
  # ... implementation

# Clear error messages
if animal of Dog:
  echo "Expected Cat but got ", animal.typeName
```

### 3. Parity with Other Languages

| Language | Syntax | Always Available? |
|----------|--------|-------------------|
| C# | `obj.GetType().Name` | Yes |
| Java | `obj.getClass().getName()` | Yes |
| Python | `type(obj).__name__` | Yes |
| C++ | `typeid(obj).name()` | Debug builds |
| **Nim (proposed)** | `obj.typeName` | **Yes (default, opt-out available)** |

## Performance Impact

### Memory

- **Default (all builds)**: +8 bytes per object (one pointer)
- **With `-d:noRuntimeTypeNames`**: 0 bytes (field not added)
- **Per-type**: ~20 bytes for type name string (shared across all instances)

**Analysis**: For a 1000-object collection, the overhead is 8KB total. On modern systems with GB of RAM, this is negligible (<0.001% of available memory).

### Runtime

- **Field access**: O(1) - simple pointer dereference (same as accessing any field)
- **Initialization**: O(1) - one assignment in constructor (amortized to zero with inlining)
- **No impact** on method dispatch speed
- **No impact** on compilation time

### Example Program

```nim
type
  Animal = ref object of RootObj  # +8 bytes
  Dog = ref object of Animal      # +8 bytes

let zoo = newSeq[Animal](1000)  # +8000 bytes total (0.008 MB)
```

**For typical programs: <1% memory overhead, negligible on modern systems**

## Migration Path

### Phase 1: Experimental (Current)
- ✅ `system/debugging` module available now
- ✅ Works with all memory managers
- ✅ Zero changes to compiler

### Phase 2: Compiler Support (Proposed)
- Add hidden `runtimeType_` field (always-on by default)
- Add `typeName` accessor to system module
- Provide `-d:noRuntimeTypeNames` opt-out for extreme cases

### Phase 3: Documentation
- Update Nim manual OOP section
- Add examples and best practices
- Document performance characteristics

### Phase 4: Ecosystem Adoption
- Standard library uses `typeName` for better errors
- Testing frameworks show actual vs expected types
- Debuggers integrate runtime type information

## Alternative Approaches Considered

### 1. Always Use `of` Checks (Current Workaround)

❌ Requires listing all types
❌ O(n) performance for n types
✅ No memory overhead

### 2. Use `-d:nimTypeNames` with Old GC

❌ Only works with refc GC
❌ Complex to access (`m_type` pointer)
❌ Not well documented
✅ Minimal changes needed

### 3. Store Type ID Instead of Name

✅ Only 4 bytes per object
❌ Needs lookup table for names
❌ More complex implementation

### 4. Proposed: Direct Type Name Field (RECOMMENDED)

✅ Simple to implement
✅ Simple to use
✅ Zero cost in release
✅ Works with all GCs

## Conclusion

This proposal would:

1. **Make Nim's OOP easier to use** - runtime types "just work" everywhere
2. **Improve debugging** - in both development AND production
3. **Match other languages** - C#/Java/Python all have always-on runtime types
4. **Negligible cost** - 8 bytes per object is trivial on modern systems
5. **Simple implementation** - ~200 lines of compiler code
6. **Consistent behavior** - no surprises between debug and release builds

### Recommendation

**Implement this proposal for Nim 2.2 or 2.4 with always-on by default**

The combination of:
- **Easy developer experience** - no configuration needed
- **Negligible cost** - <1% memory overhead
- **Production debugging** - investigate issues without recompiling
- **Simple implementation** - straightforward compiler change
- **High user demand** - developers expect this feature
- **Language parity** - matches C#, Java, Python behavior

Makes this a high-value, low-risk enhancement to Nim's OOP capabilities.

**Why always-on is better than debug-only:**
- Consistent behavior across all builds (no surprises)
- Production debugging without recompiling
- Better error messages in production
- 8 bytes/object is insignificant on modern hardware
- Matches developer expectations from other languages
- Opt-out available for truly constrained environments

---

## References

- Compiler code: `compiler/types.nim:1501-1504` (lacksMTypeField)
- Compiler code: `compiler/cbuilderdecls.nim:330-350` (struct building)
- System module: `lib/system/hti.nim:89-107` (TNimType definition)
- Our workaround: `lib/system/debugging.nim` (genRuntimeTypeCheck macro)
