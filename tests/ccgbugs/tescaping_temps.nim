
# bug #4505

proc f(t: tuple[]) = discard
f((block: ()))

# bug #4230
# If we make `test` function return nothing - the bug disappears
proc test(dothejob: proc()): int {.discardable.} =
    dothejob()

test proc() =
    let f = 15
    if f > 10:
        test proc() = discard
    # If we remove elif branch of the condition - the bug disappears
    elif f < 3:
        test proc() = discard
    else:
        test proc() = discard

# ensure 'case' does not trigger the same bug:
test proc() =
    let f = 15
    case f
    of 10:
        test proc() = discard
    of 3:
        test proc() = discard
    else:
        test proc() = discard
