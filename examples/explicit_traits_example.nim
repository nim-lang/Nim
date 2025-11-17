## Example: Explicit Trait-like Concepts for Better Code Organization
##
## This shows how explicit trait declarations could improve Nim's OOP
## for waterfall/enterprise development patterns.

# ============================================================================
# CURRENT NIM: Implicit Concepts (Harder to Organize)
# ============================================================================

type
  # Concept definition - duck typing with compile-time checks
  Serializable = concept x
    proc serialize(x): string
    proc deserialize(x: type, s: string): x

  # Types that happen to satisfy the concept
  # NO explicit declaration of intent!
  User = object
    name: string
    age: int

  Product = object
    id: int
    price: float

# These procs make User and Product implicitly Serializable
# But there's no explicit declaration, making it hard to:
# 1. Find all Serializable types
# 2. Know if User is MEANT to be Serializable or it's accidental
# 3. Generate documentation showing User's interfaces

proc serialize(u: User): string =
  $u.name & "," & $u.age

proc deserialize(T: type User, s: string): User =
  # Parse string...
  User(name: "parsed", age: 0)

proc serialize(p: Product): string =
  $p.id & "," & $p.price

proc deserialize(T: type Product, s: string): Product =
  Product(id: 0, price: 0.0)

# Generic proc using concept
proc saveToFile[T: Serializable](obj: T, filename: string) =
  # Works but it's unclear what types can be used here
  echo "Saving: ", serialize(obj)

# ============================================================================
# PROPOSED: Explicit Implementation (Better Organization)
# ============================================================================

# This is how it COULD work with explicit trait-like features:

when false:  # Pseudo-code showing proposed syntax

  # Option 1: Pragma-based
  type
    User {.implements: [Serializable, Comparable].} = object
      name: string
      age: int

  # Now it's EXPLICIT:
  # - User IS Serializable (documented intent)
  # - IDE can show "User implements: Serializable, Comparable"
  # - Can find all Serializable types easily
  # - Compiler verifies all required methods exist

  # Option 2: Rust-style impl blocks
  impl Serializable for User:
    proc serialize(u: User): string =
      $u.name & "," & $u.age

    proc deserialize(T: type User, s: string): User =
      User(name: "parsed", age: 0)

  # Option 3: Lightweight syntax
  type
    User: Serializable = object  # : indicates implements
      name: string
      age: int

# ============================================================================
# REAL EXAMPLE: Design Pattern with Current Nim
# ============================================================================

# Repository pattern - common in enterprise development

type
  # The concept/interface
  Repository[T] = concept repo
    proc save(repo: var Self, entity: T)
    proc findById(repo: Self, id: int): Option[T]
    proc findAll(repo: Self): seq[T]

  # Concrete implementation
  # PROBLEM: No clear declaration that this IS a Repository!
  UserRepository = object
    users: seq[User]

proc save(repo: var UserRepository, entity: User) =
  repo.users.add(entity)

proc findById(repo: UserRepository, id: int): Option[User] =
  # Search logic...
  if repo.users.len > 0: some(repo.users[0]) else: none(User)

proc findAll(repo: UserRepository): seq[User] =
  repo.users

# Using it
proc processEntities[T, R: Repository[T]](repo: R) =
  # Works, but it's not clear from UserRepository's definition
  # that it's meant to be used this way
  let entities = repo.findAll()
  echo "Processing ", entities.len, " entities"

# ============================================================================
# PROPOSED EXPLICIT VERSION: Much Clearer Intent
# ============================================================================

when false:  # Pseudo-code

  # EXPLICIT: UserRepository IS a Repository[User]
  type UserRepository {.implements: [Repository[User]].} = object
    users: seq[User]

  # Or even better, compiler-verified impl block:
  impl Repository[User] for UserRepository:
    proc save(repo: var UserRepository, entity: User) =
      repo.users.add(entity)

    proc findById(repo: UserRepository, id: int): Option[User] =
      # If we forget to implement this, compiler error!
      if repo.users.len > 0: some(repo.users[0]) else: none(User)

    proc findAll(repo: UserRepository): seq[User] =
      repo.users

  # Benefits:
  # 1. IDE shows "UserRepository implements Repository[User]"
  # 2. Can find all Repository implementations
  # 3. Compiler verifies all methods exist
  # 4. Documentation auto-generated
  # 5. Clear architectural layers

# ============================================================================
# WHY THIS MATTERS FOR WATERFALL/ENTERPRISE DEVELOPMENT
# ============================================================================

# In large teams with waterfall methodology:
# 1. Architects define interfaces/concepts upfront
# 2. Different teams implement different parts
# 3. Need clear documentation of what implements what
# 4. Need compile-time verification of completeness
# 5. Need discoverability (find all implementations)

# Current Nim: All implicit, hard to organize
# Proposed Nim: Explicit when you want it, implicit when you don't

# Example scenario:
when false:
  # Architect defines the contract
  type
    PaymentProcessor = concept p
      proc process(p: Self, amount: float): Result[bool, string]
      proc refund(p: Self, transactionId: string): Result[bool, string]

  # Team A implements Stripe
  type StripeProcessor {.implements: [PaymentProcessor].} = object
    apiKey: string

  impl PaymentProcessor for StripeProcessor:
    # Compiler ensures both methods are implemented
    proc process(p: StripeProcessor, amount: float): Result[bool, string] = ...
    proc refund(p: StripeProcessor, id: string): Result[bool, string] = ...

  # Team B implements PayPal
  type PayPalProcessor {.implements: [PaymentProcessor].} = object
    credentials: Credentials

  impl PaymentProcessor for PayPalProcessor:
    # If they forget a method, compile error with helpful message:
    # "PayPalProcessor does not fully implement PaymentProcessor"
    # "Missing: proc refund(p: Self, transactionId: string)"
    proc process(p: PayPalProcessor, amount: float): Result[bool, string] = ...
    proc refund(p: PayPalProcessor, id: string): Result[bool, string] = ...

  # Quality assurance can easily find all implementations:
  # nimgrep --type:nim "{.implements.*PaymentProcessor"
  # IDE command: "Find all implementations of PaymentProcessor"

# ============================================================================
# SUMMARY
# ============================================================================

echo "\n=== Comparison: Implicit vs Explicit ==="
echo "\nCurrent Nim (Implicit):"
echo "  ✓ Flexible, quick prototyping"
echo "  ✓ Duck typing with compile-time safety"
echo "  ✗ Hard to discover implementations"
echo "  ✗ No clear architectural organization"
echo "  ✗ Accidental satisfaction possible"

echo "\nProposed Enhancement (Explicit option):"
echo "  ✓ All benefits of implicit (still available!)"
echo "  ✓ Clear documentation of intent"
echo "  ✓ IDE integration (find implementations)"
echo "  ✓ Compiler-verified completeness"
echo "  ✓ Better for large teams/waterfall"
echo "  ✓ Matches Rust/C#/Java developer expectations"

echo "\nBest of both worlds: Use implicit for flexibility,"
echo "use explicit for structure and documentation."
