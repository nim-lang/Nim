# Based on bountysource.cr located at https://github.com/crystal-lang/crystal-website/blob/master/scripts/bountysource.cr
import httpclient, asyncdispatch, json, strutils, os, strtabs, sequtils, future,
  algorithm, times

type
  BountySource = ref object
    client: AsyncHttpClient
    team: string

  Sponsor = object
    name, url, logo: string
    amount, allTime: float
    since: TimeInfo

const
  team = "nim"
  apiUrl = "https://api.bountysource.com"
  githubApiUrl = "https://api.github.com"

proc newBountySource(team, token: string): BountySource =
  result = BountySource(
    client: newAsyncHttpClient(userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.87 Safari/537.36"),
    team: team
  )

  # Set up headers
  result.client.headers["Accept"] = "application/vnd.bountysource+json; version=2"
  result.client.headers["Authorization"] = "token " & token
  result.client.headers["Referer"] = "https://salt.bountysource.com/teams/nim/admin/supporters"
  result.client.headers["Origin"] = "https://salt.bountysource.com/"

proc getSupportLevels(self: BountySource): Future[JsonNode] {.async.} =
  let response = await self.client.get(apiUrl &
    "/support_levels?supporters_for_team=" & self.team)
  doAssert response.status.startsWith($Http200) # TODO: There should be a ==
  return parseJson(response.body)

proc getSupporters(self: BountySource): Future[JsonNode] {.async.} =
  let response = await self.client.get(apiUrl &
    "/supporters?order=monthly&per_page=200&team_slug=" & self.team)
  doAssert response.status.startsWith($Http200)
  return parseJson(response.body)

proc getGithubUser(username: string): Future[JsonNode] {.async.} =
  let client = newAsyncHttpClient()
  let response = await client.get(githubApiUrl & "/users/" & username)
  if response.status.startsWith($Http200):
    return parseJson(response.body)
  else:
    return nil

proc processLevels(supportLevels: JsonNode) =
  var before = supportLevels.elems.len
  supportLevels.elems.keepIf(
    item => item["status"].getStr == "active" and
      item["owner"]["display_name"].getStr != "Anonymous"
  )
  echo("Found ", before - supportLevels.elems.len, " sponsors that cancelled or didn't pay.")
  echo("Found ", supportLevels.elems.len, " active sponsors!")

  supportLevels.elems.sort(
    (x, y) => cmp(y["amount"].getFNum, x["amount"].getFNum)
  )

proc getSupporter(supporters: JsonNode, displayName: string): JsonNode =
  for supporter in supporters:
    if supporter["display_name"].getStr == displayName:
      return supporter
  doAssert false

proc quote(text: string): string =
  if {' ', ','} in text:
    return "\"" & text & "\""
  else:
    return text

proc getLevel(amount: float): int =
  result = 0
  const levels = [250, 150, 75, 25, 10, 5, 1]
  for i in levels:
    if amount.int <= i:
      result = i

proc writeCsv(sponsors: seq[Sponsor]) =
  var csv = ""
  csv.add "logo, name, url, this_month, all_time, since, level\n"
  for sponsor in sponsors:
    csv.add "$#,$#,$#,$#,$#,$#,$#\n" % [
      sponsor.logo.quote, sponsor.name.quote,
      sponsor.url.quote, $sponsor.amount.int,
      $sponsor.allTime.int, sponsor.since.format("MMM d, yyyy").quote,
      $sponsor.amount.getLevel
    ]
  writeFile("sponsors.new.csv", csv)

when isMainModule:
  if paramCount() == 0:
    quit("You need to specify the BountySource access token on the command\n" &
      "line, you can find it by going onto https://www.bountysource.com/people/25278-dom96\n" &
      "and looking at your browser's network inspector tab to see the token being\n" &
      "sent to api.bountysource.com")

  let token = paramStr(1)
  let bountysource = newBountySource(team, token)

  echo("Getting sponsors...")
  let supporters = waitFor bountysource.getSupporters()

  var supportLevels = waitFor bountysource.getSupportLevels()
  processLevels(supportLevels)

  echo("Generating sponsors list... (please be patient)")
  var sponsors: seq[Sponsor] = @[]
  for supportLevel in supportLevels:
    let name = supportLevel["owner"]["display_name"].getStr
    var url = ""
    let ghUser = waitFor getGithubUser(name)
    if not ghUser.isNil:
      if ghUser["blog"].kind != JNull:
        url = ghUser["blog"].getStr
      else:
        url = ghUser["html_url"].getStr

    if url.len > 0 and not url.startsWith("http"):
      url = "http://" & url

    let amount = supportLevel["amount"].getFNum
    # Only show URL when user donated at least $5.
    if amount < 5:
      url = ""

    let supporter = getSupporter(supporters, supportLevel["owner"]["display_name"].getStr)
    var logo = ""
    if amount >= 75:
      discard # TODO

    sponsors.add(Sponsor(name: name, url: url, logo: logo, amount: amount,
      allTime: supporter["alltime_amount"].getFNum(),
      since: parse(supporter["created_at"].getStr, "yyyy-MM-dd'T'hh:mm:ss")
    ))

  echo("Generated ", sponsors.len, " sponsors")
  writeCsv(sponsors)
  echo("Written csv file to sponsors.new.csv")
