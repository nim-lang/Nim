# Dependency Resolution

## Overview

The dependency resolution feature provides advanced automatic reordering of declarations based on their dependencies. It builds a directed graph of dependencies, performs topological sorting, and intelligently handles circular dependencies.

## Enabling the Feature

To enable dependency resolution, use the experimental pragma:

```nim
{.experimental: "dependencyResolution".}
```

Or via command line:

```bash
nim c --experimental:dependencyResolution myfile.nim
```

## How It Works

### 1. Dependency Graph Construction

The compiler analyzes all top-level declarations and builds a dependency graph:

- **Procedures**: Depend on types in their parameters and return type
- **Types**: Depend on other types they reference
- **Constants**: Depend on values and types in their initialization
- **Variables**: Depend on their types and initialization expressions

### 2. Topological Sort

Uses Kahn's algorithm to determine the correct compilation order:

```nim
const x = calcDefault()      # Depends on calcDefault
proc calcDefault(): int = 42 # Will be moved before x
```

Becomes:

```nim
proc calcDefault(): int = 42
const x = calcDefault()
```

### 3. Cycle Detection

Detects circular dependencies and handles them appropriately:

**Type Cycles** - Automatically merged:
```nim
type
  Node = ref object
    next: LinkedList
  LinkedList = ref object
    head: Node
```

**Proc Cycles** - Warning issued (can use forward declarations):
```nim
proc a() = b()
proc b() = a()
# Warning: Circular dependency (can use forward declarations)
```

**Unresolvable Cycles** - Error reported:
```nim
const x = y + 1
const y = x + 1
# Error: Circular dependency detected: x -> y -> x
```

## Features

### Smart Reordering

Automatically reorders declarations to satisfy dependencies:

```nim
{.experimental: "dependencyResolution".}

# These can be in any order:
proc process(c: Config) = 
  echo helper(c.value)

type Config = object
  value: int

proc helper(x: int): int = x * 2
```

### Circular Dependency Resolution

Intelligently handles different types of circular dependencies:

1. **Merge Strategy**: Type and const sections with mutual dependencies are merged
2. **Forward Declaration Strategy**: Proc dependencies can use forward declarations
3. **Error Strategy**: Truly circular logic is reported as an error

### Debug Mode

Enable debug output to visualize the dependency graph:

```bash
nim c --experimental:dependencyResolution -d:debugDependencyGraph myfile.nim
```

This generates a `dependency_graph.dot` file that can be visualized with Graphviz:

```bash
dot -Tpng dependency_graph.dot -o dependency_graph.png
```

## Comparison with Code Reordering

The dependency resolution feature is more advanced than the existing `codeReordering` feature:

| Feature | codeReordering | dependencyResolution |
|---------|----------------|---------------------|
| Algorithm | Basic dependency tracking | Topological sort (Kahn's) |
| Cycle detection | Simple SCC | DFS with path tracking |
| Type cycles | Basic merging | Smart merging |
| Proc cycles | Warning | Forward decl support |
| Debug output | Limited | Graphviz export |

## Implementation Details

### Files Modified

- `compiler/depresolution.nim` - Core dependency resolution logic
- `compiler/options.nim` - Added `dependencyResolution` feature flag
- `compiler/pipelines.nim` - Integration with compilation pipeline
- `compiler/passes.nim` - Integration with multi-pass compilation

### Architecture

```
User Code
    ↓
Parser (AST)
    ↓
Dependency Graph Builder
    ↓
Topological Sort
    ↓
Cycle Detection & Resolution
    ↓
Reordered AST
    ↓
Semantic Analysis
```

## Limitations

1. **Body Analysis**: Currently only analyzes declarations, not full procedure bodies (to support forward declarations)
2. **Macro Dependencies**: May not fully track dependencies introduced by macros
3. **Module-Level Only**: Only reorders top-level declarations within a single module

## Future Enhancements

- Forward declaration insertion for proc cycles
- Cross-module dependency resolution
- Incremental recompilation support
- Better macro dependency tracking
- Integration with IDE tools

## Examples

### Example 1: Type and Proc Dependencies

```nim
{.experimental: "dependencyResolution".}

# Original order doesn't matter:
const DefaultSize = getSize()
proc getSize(): int = 100
type Buffer = array[DefaultSize, byte]
```

Automatically reordered to:
```nim
proc getSize(): int = 100
const DefaultSize = getSize()
type Buffer = array[DefaultSize, byte]
```

### Example 2: Circular Types

```nim
{.experimental: "dependencyResolution".}

type
  Person = ref object
    name: string
    company: Company
  
  Company = ref object
    name: string
    employees: seq[Person]
```

These are automatically merged into a single type section.

### Example 3: Complex Dependencies

```nim
{.experimental: "dependencyResolution".}

proc main() =
  let config = loadConfig()
  processData(config)

type Config = object
  setting: int

proc loadConfig(): Config =
  Config(setting: DefaultSetting)

const DefaultSetting = 42

proc processData(c: Config) =
  echo c.setting
```

Automatically reordered to proper dependency order.

## See Also

- [Code Reordering](https://nim-lang.org/docs/manual_experimental.html#code-reordering)
- [Forward Declarations](https://nim-lang.org/docs/manual.html#procedures-forward-declarations)
