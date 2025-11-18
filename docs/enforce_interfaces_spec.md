# Specification: Explicit Interface Implementation with Compiler Enforcement

## Overview

Add a compiler flag that enforces complete implementation of declared interfaces/concepts, enabling organized, structured development.

## Compiler Flag

```bash
nim c --enforceInterfaces myfile.nim
# or short form:
nim c --enforceInterfaces:on myfile.nim
nim c --enforceInterfaces:off myfile.nim  # default
```

## Pragma Syntax

```nim
type TypeName {.implements: ConceptName.} = object
  # fields...
```

## Behavior

| Flag State | Pragma Present | Behavior |
|------------|----------------|----------|
| OFF (default) | No | Normal duck typing |
| OFF | Yes | Pragma is documentation only |
| ON | No | Normal duck typing |
| ON | Yes | **ERROR if incomplete** |

## Workflow: Gradual Implementation

### Step 1: Define Interface

```nim
type
  Repository[T] = concept repo
    proc save(repo: var Self, entity: T): bool
    proc findById(repo: Self, id: int): Option[T]
    proc findAll(repo: Self): seq[T]
    proc delete(repo: var Self, id: int): bool
```

### Step 2: Declare Intent (Flag ON)

```nim
# Compile with: nim c --enforceInterfaces myfile.nim

type UserRepository {.implements: Repository[User].} = object
  db: Database

# IMMEDIATE COMPILER ERROR:
# Error: UserRepository does not fully implement Repository[User]
#   Missing methods:
#     proc save(repo: var UserRepository, entity: User): bool
#     proc findById(repo: UserRepository, id: int): Option[User]
#     proc findAll(repo: UserRepository): seq[User]
#     proc delete(repo: var UserRepository, id: int): bool
```

**Now you have a clear TODO list from the compiler!**

### Step 3: Implement Gradually

```nim
# Still compiling with --enforceInterfaces

proc save(repo: var UserRepository, entity: User): bool =
  repo.db.insert(entity)
  return true

# Now compiler says:
# Error: UserRepository does not fully implement Repository[User]
#   Missing methods:
#     proc findById(repo: UserRepository, id: int): Option[User]
#     proc findAll(repo: UserRepository): seq[User]
#     proc delete(repo: var UserRepository, id: int): bool
```

### Step 4: Test Incomplete Implementation

```nim
# Need to test/run with incomplete implementation?
# Compile WITHOUT the flag:

nim c myfile.nim  # --enforceInterfaces is OFF by default

# Or in config:
# --enforceInterfaces:off
```

### Step 5: Complete & Verify

```nim
# Implement all methods...

proc findById(repo: UserRepository, id: int): Option[User] = ...
proc findAll(repo: UserRepository): seq[User] = ...
proc delete(repo: var UserRepository, id: int): bool = ...

# Compile with --enforceInterfaces
nim c --enforceInterfaces myfile.nim

# Success! No errors = fully implemented
```

### Step 6: Keep Flag ON in Production

```nim
# In nim.cfg or project.nims:
--enforceInterfaces:on

# Now all implementations are verified complete
```

## Comparison with C# Approach

### C# Pattern
```csharp
interface IRepository<T> {
    bool Save(T entity);
    T FindById(int id);
}

class UserRepository : IRepository<User> {
    public bool Save(User entity) {
        throw new NotImplementedException();  // Stub
    }
    public User FindById(int id) {
        throw new NotImplementedException();  // Stub
    }
}
// Compiles but crashes at runtime!
```

### Nim with --enforceInterfaces
```nim
type UserRepository {.implements: Repository[User].} = object

# With flag ON: Compile-time error, can't even build!
# With flag OFF: Compiles, runs (use for testing)
# Much cleaner: toggle flag instead of throwing exceptions
```

## Error Message Format

```
Error: Type 'UserRepository' does not fully implement 'Repository[User]'
  Location: myfile.nim(10, 3)

  Missing methods:
    proc findById(repo: UserRepository, id: int): Option[User]
      Required by: Repository[User] at concepts.nim(5, 5)

    proc delete(repo: var UserRepository, id: int): bool
      Required by: Repository[User] at concepts.nim(7, 5)

  Hint: Compile with --enforceInterfaces:off to allow partial implementations
```

## Real-World Development Workflow

### Day 1: Architecture
```nim
# Senior dev defines interfaces
type
  PaymentProcessor = concept p
    proc process(p: Self, amount: float): Result[bool, string]
    proc refund(p: Self, txId: string): Result[bool, string]
    proc verify(p: Self, txId: string): bool

  Notifier = concept n
    proc send(n: Self, message: string): bool
```

### Day 2: Team Starts Implementation
```nim
# Team member declares what they'll implement
# Compiles with --enforceInterfaces to see TODO list

type StripeProcessor {.implements: PaymentProcessor.} = object
  apiKey: string

# Compiler shows 3 methods needed
# Developer has clear task list!
```

### Day 3-5: Gradual Implementation
```nim
# Implement one method at a time
# Test with flag OFF: nim c myfile.nim
# Verify with flag ON: nim c --enforceInterfaces myfile.nim

proc process(p: StripeProcessor, amount: float): Result[bool, string] =
  # Full implementation
  ok(true)

# Compiler now shows 2 methods left
```

### Day 6: Testing Incomplete
```nim
# Need to test process() even though verify() not done?
# Just compile without flag:

nim c myfile.nim
nim r myfile.nim  # Test process() method
```

### Day 7: Completion & Integration
```nim
# Finish all methods
proc refund(...) = ...
proc verify(...) = ...

# Verify complete:
nim c --enforceInterfaces myfile.nim
# Success!

# Commit with flag in config:
# nim.cfg:
--enforceInterfaces:on
```

## Benefits

### 1. **Organized Work**
- Compiler gives you exact TODO list
- See progress as methods are completed
- No guessing what's needed

### 2. **Flexible Testing**
- Flag OFF: Test partial implementations
- Flag ON: Verify completeness
- No need for NotImplementedException stubs

### 3. **Team Coordination**
- Everyone sees same requirements (from concept)
- Clear completion status
- Easy code review (check flag is ON in CI)

### 4. **Better Than Exceptions**
- C#: Compiles with stubs, crashes at runtime
- Nim: Toggle flag = compile-time safety when you want it

### 5. **Gradual Refinement**
- Start with flag ON to get TODO list
- Flag OFF while implementing/testing
- Flag ON again to verify
- Leave ON in production config

## CI/CD Integration

```yaml
# .github/workflows/build.yml

test:
  # Test even incomplete implementations
  - nim c myfile.nim
  - nim test myfile.nim

verify:
  # Ensure all declared implementations are complete
  - nim c --enforceInterfaces myfile.nim

release:
  # Production must be complete
  - nim c --enforceInterfaces -d:release myfile.nim
```

## Project Configuration

```nim
# project.nims or nim.cfg

# Development: relaxed
when defined(dev):
  switch("enforceInterfaces", "off")

# CI: strict
when defined(ci):
  switch("enforceInterfaces", "on")

# Production: always strict
when defined(release):
  switch("enforceInterfaces", "on")
```

## Implementation Plan

### Compiler Changes Needed

1. **Add flag**: `compiler/options.nim`
   - `--enforceInterfaces[:on|off]`

2. **Process pragma**: `compiler/pragmas.nim`
   - Recognize `{.implements: ConceptName.}`
   - Store which concepts a type should implement

3. **Verify completeness**: `compiler/concepts.nim`
   - When flag is ON and pragma present
   - Check all concept requirements are satisfied
   - Generate detailed error if not

4. **Error messages**: `compiler/msgs.nim`
   - Clear, actionable error messages
   - List exactly what's missing
   - Point to concept definition

### Files to Modify

- `compiler/options.nim` - Add `--enforceInterfaces` flag
- `compiler/pragmas.nim` - Handle `{.implements.}` pragma
- `compiler/concepts.nim` - Verification logic
- `compiler/msgs.nim` - Error messages
- `compiler/semtypes.nim` - Type checking integration

## Estimated Implementation Size

~300-400 lines of compiler code across 5 files.

## Backward Compatibility

**100% compatible**: Flag is OFF by default, pragma has no effect without flag.

Existing code continues to work exactly as before.

---

## Summary

This proposal adds:
- **One compiler flag**: `--enforceInterfaces`
- **One pragma**: `{.implements: ConceptName.}`
- **Simple workflow**: Flag ON = errors, Flag OFF = warnings/none

Enables:
- Organized development with clear TODO lists
- Flexible testing of partial implementations
- Compile-time verification of completeness
- Better than runtime NotImplementedException

Simpler than C#, more structured than implicit duck typing.
