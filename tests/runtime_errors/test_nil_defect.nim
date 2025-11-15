# Test: NilAccessDefect - Second Most Common Runtime Error
# WHY IT MATTERS: Nil pointer crashes are confusing and hard to track down
# Developers need to see:
# - WHERE the nil value came from
# - WHEN it was set to nil
# - WHAT function returned nil
# - HOW to prevent it

type
  User = ref object
    name: string
    age: int

proc findUser(id: int): User =
  ## Returns a user if found, nil otherwise
  if id == 1:
    result = User(name: "Alice", age: 30)
  elif id == 2:
    result = User(name: "Bob", age: 25)
  # Missing else case - implicitly returns nil!

proc processUser(u: User) =
  echo "User name: ", u.name  # Will crash if u is nil

echo "Finding user 999..."
let user = findUser(999)  # Returns nil
processUser(user)  # CRASH: attempt to access name of nil

# CURRENT ERROR OUTPUT:
# ===================
# Traceback (most recent call last)
# test_nil_defect.nim(24) test_nil_defect
# test_nil_defect.nim(19) processUser
# Error: unhandled exception: could not access field [NilAccessDefect]

# IMPROVED ERROR OUTPUT (Proposed):
# ===================
# Runtime Error: Nil Dereference [NilAccessDefect]
#  --> test_nil_defect.nim(19, 24)
#     |
#  19 |   echo "User name: ", u.name
#     |                       ^^^^^^ attempted to access field 'name' of nil reference
#     |
# note: 'u' is nil (never initialized)
#  --> test_nil_defect.nim(24, 13)
#     |
#  24 | processUser(user)
#     |             ^^^^ passed nil to processUser()
#     |
# note: 'user' was set to nil by findUser()
#  --> test_nil_defect.nim(23, 12)
#     |
#  23 | let user = findUser(999)
#     |            ^^^^^^^^^^^^^ returned nil (id 999 not found)
#     |
# note: findUser() definition
#  --> test_nil_defect.nim(11, 6)
#     |
#  11 | proc findUser(id: int): User =
#     |      ^^^^^^^^ can return nil when id not in [1, 2]
#     |
# pattern detected: missing else branch in find function
#
# help: add nil check before accessing
#     | if user != nil:
#     |   processUser(user)
#     | else:
#     |   echo "User not found"
#
# help: fix findUser to never return nil
#     | proc findUser(id: int): User =
#     |   if id == 1:
#     |     result = User(name: "Alice", age: 30)
#     |   elif id == 2:
#     |     result = User(name: "Bob", age: 25)
#     |   else:
#     |     result = User(name: "Unknown", age: 0)  # Default user
#
# help: use Option type for fallible operations
#     | import std/options
#     | proc findUser(id: int): Option[User] =
#     |   if id == 1:
#     |     result = some(User(name: "Alice", age: 30))
#     |   else:
#     |     result = none(User)
#     |
#     | let userOpt = findUser(999)
#     | if userOpt.isSome:
#     |   processUser(userOpt.get)
