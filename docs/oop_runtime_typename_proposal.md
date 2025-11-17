# Proposal: Built-in Runtime Type Names for Nim OOP

## Executive Summary

**Problem**: Developers cannot easily determine the runtime type of polymorphic objects in Nim, making OOP debugging difficult.

**Current State**:
- Old GC (refc): Partial support via `m_type` field (complex to access)
- Modern GC (ARC/ORC): No built-in runtime type information
- Workaround: Our `system/debugging` module using `of` checks

**Proposal**: Add automatic runtime type name field to all inheritable objects in debug builds.

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
  # Compiler automatically adds (in debug builds):
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
  ## Available in debug builds. In release builds, returns compile-time type.
  when not defined(release):
    return $obj.runtimeType_
  else:
    return $typeof(obj)
```

### 3. Compilation Modes

| Mode | Runtime Type Field | Memory Cost | Use Case |
|------|-------------------|-------------|----------|
| Debug (default) | Yes | 8 bytes/object | Development, debugging |
| Release | No | 0 bytes | Production |
| `-d:runtimeTypeNames` | Yes | 8 bytes/object | Production debugging |

## Implementation Details

### Changes Required

#### 1. Compiler (`compiler/sem.nim` or similar)

```nim
proc addRuntimeTypeField(t: PType; info: TLineInfo) =
  ## Adds hidden runtimeType_ field to inheritable objects
  if tfInheritable in t.flags and
     not defined(release) or defined(runtimeTypeNames):
    let field = newSym(skField, getIdent("runtimeType_"), t.owner, info)
    field.typ = getSysType(tyString)  # or cstring
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
| **Nim (proposed)** | `obj.typeName` | **Debug builds (configurable)** |

## Performance Impact

### Memory

- **Debug build**: +8 bytes per object (one pointer)
- **Release build**: 0 bytes (field not added)
- **Per-type**: ~20 bytes for type name string (shared)

### Runtime

- **Field access**: O(1) - simple pointer dereference
- **Initialization**: O(1) - one assignment in constructor
- **No impact** on method dispatch speed

### Example Program

```nim
type
  Animal = ref object of RootObj  # +8 bytes in debug
  Dog = ref object of Animal      # +8 bytes in debug

let zoo = newSeq[Animal](1000)  # +8000 bytes in debug, +0 in release
```

For typical programs: **<1% memory overhead in debug, 0% in release**

## Migration Path

### Phase 1: Experimental (Current)
- ✅ `system/debugging` module available now
- ✅ Works with all memory managers
- ✅ Zero changes to compiler

### Phase 2: Compiler Support (Proposed)
- Add hidden `runtimeType_` field
- Enable by default in debug builds
- Add `typeName` to system module

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

1. **Make Nim's OOP easier to use** - runtime types "just work"
2. **Improve debugging** - clear error messages, better introspection
3. **Match other languages** - developers expect this feature
4. **Zero cost** - completely free in release builds
5. **Simple implementation** - ~200 lines of compiler code

### Recommendation

**Implement this proposal for Nim 2.2 or 2.4**

The combination of:
- Easy developer experience
- Zero production cost
- Simple implementation
- High user demand

Makes this a high-value, low-risk enhancement to Nim's OOP capabilities.

---

## References

- Compiler code: `compiler/types.nim:1501-1504` (lacksMTypeField)
- Compiler code: `compiler/cbuilderdecls.nim:330-350` (struct building)
- System module: `lib/system/hti.nim:89-107` (TNimType definition)
- Our workaround: `lib/system/debugging.nim` (genRuntimeTypeCheck macro)
