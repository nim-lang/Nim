
import std / [json, os, sets, strutils, httpclient, uri, options]

const
  MockupRun = defined(atlasTests)
  UnitTests = defined(atlasUnitTests)
  TestsDir = "atlas/tests"

when UnitTests:
  proc findAtlasDir*(): string =
    result = currentSourcePath().absolutePath
    while not result.endsWith("atlas"):
      result = result.parentDir
      assert result != "", "atlas dir not found!"

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

proc toTags(j: JsonNode): seq[string] =
  result = @[]
  if j.kind == JArray:
    for elem in items j:
      result.add elem.getStr("")

proc singleGithubSearch(term: string): JsonNode =
  when UnitTests:
    let filename = "query_github_" & term & ".json"
    let path = findAtlasDir() / "tests" / "test_data" / filename
    result = json.parseFile(path)
  else:
    # For example:
    # https://api.github.com/search/repositories?q=weave+language:nim
    var client = newHttpClient()
    try:
      let x = client.getContent("https://api.github.com/search/repositories?q=" & encodeUrl(term) & "+language:nim")
      result = parseJson(x)
    except:
      result = parseJson("{\"items\": []}")
    finally:
      client.close()

proc githubSearch(seen: var HashSet[string]; terms: seq[string]) =
  for term in terms:
    let results = singleGithubSearch(term)
    for j in items(results.getOrDefault("items")):
      let p = Package(
        name: j.getOrDefault("name").getStr,
        url: j.getOrDefault("html_url").getStr,
        downloadMethod: "git",
        tags: toTags(j.getOrDefault("topics")),
        description: j.getOrDefault("description").getStr,
        license: j.getOrDefault("license").getOrDefault("spdx_id").getStr,
        web: j.getOrDefault("html_url").getStr
      )
      if not seen.containsOrIncl(p.url):
        echo p

proc getUrlFromGithub*(term: string): string =
  let results = singleGithubSearch(term)
  var matches = 0
  result = ""
  for j in items(results.getOrDefault("items")):
    let name = j.getOrDefault("name").getStr
    if cmpIgnoreCase(name, term) == 0:
      result = j.getOrDefault("html_url").getStr
      inc matches
  if matches != 1:
    # ambiguous, not ok!
    result = ""

proc search*(pkgList: seq[Package]; terms: seq[string]) =
  var seen = initHashSet[string]()
  template onFound =
    echo pkg
    seen.incl pkg.url
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
  githubSearch seen, terms
  if seen.len == 0 and terms.len > 0:
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
