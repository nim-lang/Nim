
import std / [json, os, sets, strutils, httpclient, uri, options]
import context

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
  PackageInfo* = ref object
    # Required fields in a PackageInfo.
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

proc fromJson*(obj: JSonNode): PackageInfo =
  result = PackageInfo()
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

const DefaultPackagesDir* = "packages"

proc getPackageInfos*(workspaceDir: string): seq[PackageInfo] =
  result = @[]
  var uniqueNames = initHashSet[string]()
  var jsonFiles = 0
  for kind, path in walkDir(workspaceDir / DefaultPackagesDir):
    if kind == pcFile and path.endsWith(".json"):
      inc jsonFiles
      let packages = json.parseFile(path)
      for p in packages:
        let pkg = p.fromJson()
        if pkg != nil and not uniqueNames.containsOrIncl(pkg.name):
          result.add(pkg)

proc `$`*(pkg: PackageInfo): string =
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

proc singleGithubSearch(c: var AtlasContext, term: string, fullSearch = false): JsonNode =
  when UnitTests:
    echo "SEARCH: ", term
    let filename = "query_github_" & term & ".json"
    let path = findAtlasDir() / "tests" / "test_data" / filename
    result = json.parseFile(path)
  else:
    # For example:
    # https://api.github.com/search/repositories?q=weave+language:nim
    var client = newHttpClient()
    try:
      var searchUrl = "https://api.github.com/search/repositories?q=" & encodeUrl(term)
      if not fullSearch:
        searchUrl &= "+language:nim"

      let x = client.getContent(searchUrl)
      result = parseJson(x).getOrDefault("items")
      if result.kind != JArray:
        error c, toRepo("github search"), "got bad results from GitHub"
        result = newJArray()
      # do full search and filter for languages
      if fullSearch:
        var filtered = newJArray()
        for item in result.items():
          let queryUrl = item["languages_url"].getStr
          let langs = client.getContent(queryUrl).parseJson()
          if langs.hasKey("Nim"):
            filtered.add item
        result = filtered
      
      if result.len() == 0:
        if not fullSearch:
          trace c, toRepo("github search"), "no results found by Github quick search; doing full search"
          result = c.singleGithubSearch(term, fullSearch=true)
        else:
          trace c, toRepo("github search"), "no results found by Github full search"
      else:
        trace c, toRepo("github search"), "found " & $result.len() & " results on GitHub"
    except CatchableError as exc:
      error c, toRepo("github search"), "error searching github: " & exc.msg
      # result = parseJson("{\"items\": []}")
      result = newJArray()
    finally:
      client.close()

proc githubSearch(c: var AtlasContext, seen: var HashSet[string]; terms: seq[string]) =
  for term in terms:
    for j in items(c.singleGithubSearch(term)):
      let p = PackageInfo(
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

proc getUrlFromGithub*(c: var AtlasContext, term: string): string =
  var matches = 0
  result = ""
  for j in items(c.singleGithubSearch(term)):
    let name = j.getOrDefault("name").getStr
    if cmpIgnoreCase(name, term) == 0:
      result = j.getOrDefault("html_url").getStr
      inc matches
  if matches != 1:
    # ambiguous, not ok!
    result = ""

proc search*(c: var AtlasContext, pkgList: seq[PackageInfo]; terms: seq[string]) =
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
  githubSearch c, seen, terms
  if seen.len == 0 and terms.len > 0:
    echo("No PackageInfo found.")

type PkgCandidates* = array[3, seq[PackageInfo]]

proc determineCandidates*(pkgList: seq[PackageInfo];
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
