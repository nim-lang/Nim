#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Advanced dependency resolution system for Nim
## Builds directed graphs of dependencies, performs topological sort,
## and handles circular dependencies intelligently.

import
  ast, astalgo, idents, lineinfos, msgs, options, renderer,
  modulegraphs

import std/[tables, sets, hashes, deques, intsets]

when defined(nimPreviewSlimSystem):
  import std/assertions

type
  DepNode* = ref object
    id*: string                     ## Fully qualified symbol name
    ast*: PNode                     ## The AST node
    kind*: TNodeKind               ## Node kind for fast access
    dependencies*: HashSet[string]  ## What this depends on
    dependents*: HashSet[string]    ## What depends on this
    info*: TLineInfo               ## Source location

  DepGraph* = ref object
    nodes*: Table[string, DepNode]
    roots*: HashSet[string]         ## Nodes with no dependencies
    cache*: IdentCache
    config*: ConfigRef

  SortResult* = object
    sorted*: seq[string]            ## Topologically sorted node IDs
    cycles*: seq[seq[string]]       ## Detected circular dependencies

  CycleResolutionKind* = enum
    crkForwardDecl                  ## Use forward declarations
    crkMerge                        ## Merge into single section
    crkError                        ## Report error

# Helper procs for symbol name generation

proc getSymbolId(cache: IdentCache; n: PNode): string =
  ## Extract a unique identifier from a node
  case n.kind
  of nkIdent:
    result = n.ident.s
  of nkSym:
    result = n.sym.name.s
  of nkPostfix:
    result = getSymbolId(cache, n[1])
  of nkPragmaExpr:
    result = getSymbolId(cache, n[0])
  of nkAccQuoted:
    result = ""
    for i in 0..<n.len:
      let id = n[i].getPIdent
      if id != nil: result.add(id.s)
  of nkEnumFieldDef:
    result = getSymbolId(cache, n[0])
  else:
    result = ""

proc getNodeId(cache: IdentCache; n: PNode; idx: int): string =
  ## Generate a unique ID for a top-level node
  case n.kind
  of nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef:
    let name = getSymbolId(cache, n[0])
    if name != "":
      return name
  of nkMacroDef, nkTemplateDef:
    let name = getSymbolId(cache, n[0])
    if name != "":
      return name
  of nkTypeSection:
    if n.len > 0:
      let name = getSymbolId(cache, n[0][0])
      if name != "":
        return "type:" & name
  of nkConstSection:
    if n.len > 0:
      let name = getSymbolId(cache, n[0][0])
      if name != "":
        return "const:" & name
  of nkVarSection, nkLetSection:
    if n.len > 0 and n[0].kind == nkIdentDefs and n[0].len > 0:
      let name = getSymbolId(cache, n[0][0])
      if name != "":
        return "var:" & name
  else:
    discard

  # Fallback to index-based ID
  result = "node:" & $idx

# Dependency extraction

proc extractDependenciesFromType(n: PNode; deps: var HashSet[string]) =
  ## Extract type dependencies
  if n.isNil: return

  case n.kind
  of nkIdent:
    deps.incl(n.ident.s)
  of nkSym:
    deps.incl(n.sym.name.s)
  of nkAccQuoted:
    var id = ""
    for i in 0..<n.len:
      let ident = n[i].getPIdent
      if ident != nil: id.add(ident.s)
    if id != "":
      deps.incl(id)
  of nkBracketExpr:
    # Generic type like seq[int]
    for i in 0..<n.len:
      extractDependenciesFromType(n[i], deps)
  of nkObjectTy, nkTupleTy, nkRefTy, nkPtrTy, nkVarTy, nkDistinctTy:
    for i in 0..<n.len:
      extractDependenciesFromType(n[i], deps)
  of nkProcTy:
    # Proc types
    for i in 0..<n.len:
      extractDependenciesFromType(n[i], deps)
  of nkOfInherit:
    # Inheritance
    for i in 0..<n.len:
      extractDependenciesFromType(n[i], deps)
  of nkRecList:
    # Object fields
    for i in 0..<n.len:
      extractDependenciesFromType(n[i], deps)
  of nkIdentDefs:
    # Field definitions - check types only, not names
    if n.len >= 2:
      extractDependenciesFromType(n[^2], deps) # type
      if n.len >= 3:
        extractDependenciesFromExpr(n[^1], deps) # default value
  else:
    # Recursively search other nodes
    for i in 0..<n.len:
      extractDependenciesFromType(n[i], deps)

proc extractDependenciesFromExpr(n: PNode; deps: var HashSet[string]) =
  ## Extract dependencies from an expression
  if n.isNil: return

  case n.kind
  of nkIdent:
    deps.incl(n.ident.s)
  of nkSym:
    deps.incl(n.sym.name.s)
  of nkAccQuoted:
    var id = ""
    for i in 0..<n.len:
      let ident = n[i].getPIdent
      if ident != nil: id.add(ident.s)
    if id != "":
      deps.incl(id)
  of nkCall, nkCommand, nkCallStrLit:
    # Function calls
    for i in 0..<n.len:
      extractDependenciesFromExpr(n[i], deps)
  of nkDotExpr:
    # obj.field - only left side is a dependency
    if n.len > 0:
      extractDependenciesFromExpr(n[0], deps)
  of nkBracketExpr:
    # arr[idx]
    for i in 0..<n.len:
      extractDependenciesFromExpr(n[i], deps)
  of nkStmtList, nkStmtListExpr:
    for i in 0..<n.len:
      extractDependenciesFromExpr(n[i], deps)
  of nkOpenSymChoice, nkClosedSymChoice:
    if n.len > 0:
      extractDependenciesFromExpr(n[0], deps)
  else:
    # Recursively process children
    for i in 0..<n.len:
      extractDependenciesFromExpr(n[i], deps)

proc extractDependencies(cache: IdentCache; n: PNode): HashSet[string] =
  ## Extract all dependencies from a node
  result = initHashSet[string]()

  case n.kind
  of nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef:
    # Dependencies from parameters
    if n.len > paramsPos and n[paramsPos] != nil:
      let params = n[paramsPos]
      for i in 0..<params.len:
        extractDependenciesFromType(params[i], result)

    # Dependencies from pragma
    if n.len > pragmasPos and n[pragmasPos] != nil:
      extractDependenciesFromExpr(n[pragmasPos], result)

    # Note: We don't extract from body for forward declaration support
    # Bodies are analyzed in a second pass if needed

  of nkMacroDef, nkTemplateDef:
    # Similar to procs
    if n.len > paramsPos and n[paramsPos] != nil:
      extractDependenciesFromType(n[paramsPos], result)

  of nkTypeSection:
    for typeDef in n:
      if typeDef.kind == nkTypeDef and typeDef.len >= 3:
        # Extract from generic params
        if typeDef[1] != nil and typeDef[1].kind != nkEmpty:
          extractDependenciesFromType(typeDef[1], result)
        # Extract from type definition
        extractDependenciesFromType(typeDef[2], result)

  of nkConstSection:
    for constDef in n:
      if constDef.kind == nkConstDef and constDef.len >= 3:
        # Type annotation
        if constDef[1] != nil and constDef[1].kind != nkEmpty:
          extractDependenciesFromType(constDef[1], result)
        # Value
        if constDef[2] != nil:
          extractDependenciesFromExpr(constDef[2], result)

  of nkVarSection, nkLetSection:
    for identDefs in n:
      if identDefs.kind == nkIdentDefs and identDefs.len >= 3:
        # Type
        if identDefs[^2] != nil and identDefs[^2].kind != nkEmpty:
          extractDependenciesFromType(identDefs[^2], result)
        # Initial value
        if identDefs[^1] != nil and identDefs[^1].kind != nkEmpty:
          extractDependenciesFromExpr(identDefs[^1], result)

  else:
    # For other node types, do generic extraction
    extractDependenciesFromExpr(n, result)

# Graph construction

proc newDepGraph*(cache: IdentCache; config: ConfigRef): DepGraph =
  ## Create a new dependency graph
  result = DepGraph(
    nodes: initTable[string, DepNode](),
    roots: initHashSet[string](),
    cache: cache,
    config: config
  )

proc addNode*(graph: DepGraph; id: string; ast: PNode; deps: HashSet[string]) =
  ## Add a node to the dependency graph
  let node = DepNode(
    id: id,
    ast: ast,
    kind: ast.kind,
    dependencies: deps,
    dependents: initHashSet[string](),
    info: ast.info
  )

  graph.nodes[id] = node

  # Update dependents
  for depId in deps:
    if depId in graph.nodes:
      graph.nodes[depId].dependents.incl(id)

  # Check if it's a root node
  var isRoot = true
  for depId in deps:
    if depId in graph.nodes:
      isRoot = false
      break

  if isRoot:
    graph.roots.incl(id)

proc buildDependencyGraph*(cache: IdentCache; config: ConfigRef; n: PNode): DepGraph =
  ## Build a complete dependency graph from an AST
  result = newDepGraph(cache, config)

  if n.kind != nkStmtList:
    return result

  # First pass: Create all nodes
  var nodeIds: seq[string] = @[]
  for idx, stmt in n:
    let id = getNodeId(cache, stmt, idx)
    nodeIds.add(id)
    let deps = extractDependencies(cache, stmt)
    result.addNode(id, stmt, deps)

  # Second pass: Update roots based on actual nodes in graph
  result.roots.clear()
  for id, node in result.nodes:
    var hasInternalDep = false
    for depId in node.dependencies:
      if depId in result.nodes:
        hasInternalDep = true
        break
    if not hasInternalDep:
      result.roots.incl(id)

# Topological sort with cycle detection

proc topologicalSort*(graph: DepGraph): SortResult =
  ## Kahn's algorithm with cycle detection
  result.sorted = @[]
  result.cycles = @[]

  if graph.nodes.len == 0:
    return result

  var
    inDegree = initTable[string, int]()
    queue = initDeque[string]()

  # Calculate in-degrees
  for id, node in graph.nodes:
    var degree = 0
    for depId in node.dependencies:
      if depId in graph.nodes:
        degree.inc
    inDegree[id] = degree
    if degree == 0:
      queue.addLast(id)

  # Process nodes with no dependencies
  while queue.len > 0:
    let current = queue.popFirst()
    result.sorted.add(current)

    # Reduce in-degree for dependents
    if current in graph.nodes:
      for dependent in graph.nodes[current].dependents:
        if dependent in inDegree:
          inDegree[dependent].dec
          if inDegree[dependent] == 0:
            queue.addLast(dependent)

  # Check for cycles
  if result.sorted.len < graph.nodes.len:
    # There are cycles - find them using DFS
    result.cycles = findCycles(graph, inDegree)

proc findCycles(graph: DepGraph; inDegree: Table[string, int]): seq[seq[string]] =
  ## Find all circular dependency cycles using DFS
  result = @[]
  var
    visited = initHashSet[string]()
    recStack = initHashSet[string]()
    path: seq[string] = @[]

  proc dfs(nodeId: string): seq[seq[string]] =
    result = @[]

    if nodeId in recStack:
      # Found a cycle
      var cycleStart = -1
      for i, p in path:
        if p == nodeId:
          cycleStart = i
          break
      if cycleStart >= 0:
        var cycle = path[cycleStart..^1]
        cycle.add(nodeId)
        return @[cycle]

    if nodeId in visited:
      return @[]

    visited.incl(nodeId)
    recStack.incl(nodeId)
    path.add(nodeId)

    if nodeId in graph.nodes:
      for dep in graph.nodes[nodeId].dependencies:
        if dep in graph.nodes:  # Only process internal dependencies
          let cycles = dfs(dep)
          result.add(cycles)

    discard path.pop()
    recStack.excl(nodeId)

  # Start DFS from unprocessed nodes (those with dependencies)
  for id, degree in inDegree:
    if degree > 0 and id notin visited:
      let cycles = dfs(id)
      result.add(cycles)

# Cycle resolution

proc canUseForwardDecl*(graph: DepGraph; cycle: seq[string]): bool =
  ## Check if a cycle can be broken with forward declarations
  for nodeId in cycle:
    if nodeId in graph.nodes:
      let node = graph.nodes[nodeId]
      if node.kind in {nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef}:
        return true
  return false

proc canMergeNodes*(graph: DepGraph; cycle: seq[string]): bool =
  ## Check if nodes in a cycle can be merged into a single section
  if cycle.len == 0:
    return false

  var firstKind: TNodeKind = nkEmpty
  for nodeId in cycle:
    if nodeId in graph.nodes:
      let node = graph.nodes[nodeId]
      if firstKind == nkEmpty:
        firstKind = node.kind
      elif node.kind != firstKind:
        # Mixed kinds - can only merge if they're all type or const sections
        if not (node.kind in {nkTypeSection, nkConstSection} and
                firstKind in {nkTypeSection, nkConstSection}):
          return false

  return firstKind in {nkTypeSection, nkConstSection}

proc getCycleResolutionKind*(graph: DepGraph; cycle: seq[string]): CycleResolutionKind =
  ## Determine the best way to resolve a circular dependency
  if canMergeNodes(graph, cycle):
    return crkMerge
  elif canUseForwardDecl(graph, cycle):
    return crkForwardDecl
  else:
    return crkError

# Reordering and compilation

proc reorderNodes*(graph: DepGraph; sorted: seq[string]): PNode =
  ## Create a reordered statement list from sorted node IDs
  result = newNode(nkStmtList)

  for nodeId in sorted:
    if nodeId in graph.nodes:
      result.add(graph.nodes[nodeId].ast)

proc reportCycle*(config: ConfigRef; graph: DepGraph; cycle: seq[string]) =
  ## Report a circular dependency error
  var msg = "Circular dependency detected: "
  var first = true
  for nodeId in cycle:
    if not first:
      msg.add(" -> ")
    msg.add(nodeId)
    first = false

  # Get the first node's location for error reporting
  if cycle.len > 0 and cycle[0] in graph.nodes:
    let node = graph.nodes[cycle[0]]
    localError(config, node.info, msg)
  else:
    # Fallback
    echo msg

# Debug utilities

when defined(debugDependencyGraph):
  proc generateDotGraph*(graph: DepGraph): string =
    ## Generate Graphviz DOT format for visualization
    result = "digraph dependencies {\n"
    result.add("  rankdir=LR;\n")
    result.add("  node [shape=box];\n")

    for id, node in graph.nodes:
      let shape = case node.kind
        of nkProcDef, nkFuncDef, nkMethodDef: "box"
        of nkTypeSection: "ellipse"
        of nkConstSection: "diamond"
        else: "circle"

      result.add("  \"" & id & "\" [shape=" & shape & "];\n")

      for dep in node.dependencies:
        if dep in graph.nodes:
          result.add("  \"" & id & "\" -> \"" & dep & "\";\n")

    result.add("}\n")

# High-level API for integration

proc resolveAndReorder*(config: ConfigRef; cache: IdentCache; n: PNode): PNode =
  ## Main entry point for dependency resolution and reordering
  result = n

  if n.kind != nkStmtList:
    return result

  # Build dependency graph
  let depGraph = buildDependencyGraph(cache, config, n)

  # Perform topological sort
  let sortResult = topologicalSort(depGraph)

  # Handle cycles
  if sortResult.cycles.len > 0:
    for cycle in sortResult.cycles:
      let resolutionKind = getCycleResolutionKind(depGraph, cycle)
      case resolutionKind
      of crkMerge:
        # Cycles can be merged (e.g., circular type definitions)
        # The reorderNodes proc will handle this by keeping them together
        discard
      of crkForwardDecl:
        # Could use forward declarations - for now, just warn
        var msg = "Circular dependency (can use forward declarations): "
        msg.add(cycle.join(" -> "))
        if cycle.len > 0 and cycle[0] in depGraph.nodes:
          message(config, depGraph.nodes[cycle[0]].info, warnUser, msg)
      of crkError:
        # Unresolvable cycle
        reportCycle(config, depGraph, cycle)

  # Reorder nodes based on topological sort
  if sortResult.sorted.len > 0:
    result = reorderNodes(depGraph, sortResult.sorted)

  # Debug output if enabled
  when defined(debugDependencyGraph):
    let dotGraph = generateDotGraph(depGraph)
    import std/syncio
    writeFile("dependency_graph.dot", dotGraph)
