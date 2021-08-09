
import std / [json, os, sets, strutils]

type
  Package* = ref object
    # Required fields in a package.
    name*: string
    url*: string # Download location.
    license*: string
    downloadMethod*: string
    description*: string
    tags*: seq[string] # \
    # From here on, optional fields set to the empty string if not available.
    version*: string
    dvcsTag*: string
    web*: string # Info url for humans.

proc optionalField(obj: JsonNode, name: string, default = ""): string =
  if hasKey(obj, name) and obj[name].kind == JString:
    result = obj[name].str
  else:
    result = default

proc requiredField(obj: JsonNode, name: string): string =
  result = optionalField(obj, name, "")

proc fromJson*(obj: JSonNode): Package =
  result = Package()
  result.name = obj.requiredField("name")
  if result.name.len == 0: return nil
  result.version = obj.optionalField("version")
  result.url = obj.requiredField("url")
  if result.url.len == 0: return nil
  result.downloadMethod = obj.requiredField("method")
  if result.downloadMethod.len == 0: return nil
  result.dvcsTag = obj.optionalField("dvcs-tag")
  result.license = obj.optionalField("license")
  result.tags = @[]
  for t in obj["tags"]:
    result.tags.add(t.str)
  result.description = obj.requiredField("description")
  result.web = obj.optionalField("web")

const PackagesDir* = "packages"

proc getPackages*(workspaceDir: string): seq[Package] =
  result = @[]
  var uniqueNames = initHashSet[string]()
  var jsonFiles = 0
  for kind, path in walkDir(workspaceDir / PackagesDir):
    if kind == pcFile and path.endsWith(".json"):
      inc jsonFiles
      let packages = json.parseFile(path)
      for p in packages:
        let pkg = p.fromJson()
        if pkg != nil and not uniqueNames.containsOrIncl(pkg.name):
          result.add(pkg)

proc `$`*(pkg: Package): string =
  result = pkg.name & ":\n"
  result &= "  url:         " & pkg.url & " (" & pkg.downloadMethod & ")\n"
  result &= "  tags:        " & pkg.tags.join(", ") & "\n"
  result &= "  description: " & pkg.description & "\n"
  result &= "  license:     " & pkg.license & "\n"
  if pkg.web.len > 0:
    result &= "  website:     " & pkg.web & "\n"

proc search*(pkgList: seq[Package]; terms: seq[string]) =
  var found = false
  template onFound =
    echo pkg
    found = true
    break forPackage

  for pkg in pkgList:
    if terms.len > 0:
      block forPackage:
        for term in terms:
          let word = term.toLower
          # Search by name.
          if word in pkg.name.toLower:
            onFound()
          # Search by tag.
          for tag in pkg.tags:
            if word in tag.toLower:
              onFound()
    else:
      echo(pkg)

  if not found and terms.len > 0:
    echo("No package found.")

type PkgCandidates* = array[3, seq[Package]]

proc determineCandidates*(pkgList: seq[Package];
                         terms: seq[string]): PkgCandidates =
  result[0] = @[]
  result[1] = @[]
  result[2] = @[]
  for pkg in pkgList:
    block termLoop:
      for term in terms:
        let word = term.toLower
        if word == pkg.name.toLower:
          result[0].add pkg
          break termLoop
        elif word in pkg.name.toLower:
          result[1].add pkg
          break termLoop
        else:
          for tag in pkg.tags:
            if word in tag.toLower:
              result[2].add pkg
              break termLoop
