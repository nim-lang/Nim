# horrible example of how to interface with GNUStep ...

{.passL: "-lobjc".}
{.emit: """

#include <objc/Object.h>

@interface Greeter:Object
{
}

- (void)greet:(long)x y:(long)dummy;

@end

#include <stdio.h>

@implementation Greeter

- (void)greet:(long)x y:(long)dummy
{
	printf("Hello, World!\n");
}

@end

#include <stdlib.h>
""".}

type
  TId {.importc: "id", header: "<objc/Object.h>", final.} = distinct int

proc newGreeter: TId {.importobjc: "Greeter new", nodecl.}
proc greet(self: TId, x, y: int) {.importobjc: "greet", nodecl.}
proc free(self: TId) {.importobjc: "free", nodecl.}

var g = newGreeter()
g.greet(12, 34)
g.free()

