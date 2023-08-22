import packageinfotypes, developfile, packageinfo, version, tables, strformat, strutils

type
  DependencyNode = ref object of RootObj
    name*: string
    version*: string
    resolvedTo*: string
    error*: string
    dependencies*: seq[DependencyNode]

proc depsRecursive*(pkgInfo: PackageInfo,
                    dependencies: seq[PackageInfo],
                    errors: ValidationErrors): seq[DependencyNode] =
  result = @[]

  for (name, ver) in pkgInfo.fullRequirements:
    var depPkgInfo = initPackageInfo()
    let
      found = dependencies.findPkg((name, ver), depPkgInfo)
      packageName = if found: depPkgInfo.basicInfo.name else: name

    let node = DependencyNode(name: packageName)

    result.add node
    node.version = if ver.kind == verAny: "@any" else: $ver
    node.resolvedTo = if found: $depPkgInfo.basicInfo.version else: ""
    node.error = if errors.contains(packageName):
      getValidationErrorMessage(packageName, errors.getOrDefault packageName)
    else: ""

    if found:
      node.dependencies = depsRecursive(depPkgInfo, dependencies, errors)

proc printDepsHumanReadable*(pkgInfo: PackageInfo,
                             dependencies: seq[PackageInfo],
                             level: int,
                             errors: ValidationErrors) =
  for (name, ver) in pkgInfo.requires:
    var depPkgInfo = initPackageInfo()
    let
      found = dependencies.findPkg((name, ver), depPkgInfo)
      packageName = if found: depPkgInfo.basicInfo.name else: name

    echo " ".repeat(level * 2),
      packageName,
      if ver.kind == verAny: "@any" else: " " & $ver,
      if found: fmt "(resolved {depPkgInfo.basicInfo.version})" else: "",
      if errors.contains(packageName):
        " - error: " & getValidationErrorMessage(packageName, errors.getOrDefault packageName)
      else:
        ""
    if found: printDepsHumanReadable(depPkgInfo, dependencies, level + 1, errors)
