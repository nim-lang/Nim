## Hooks to send to the results channel 
## functions to bind to incoming and outgoing ports
import globals, net 

import compiler/[renderer,options, msgs, lineinfos ]

proc connectToNextFreePort*(server: Socket, host: string): Port =
  server.bindAddr(Port(0), host)
  let (_, port) = server.getLocalAddr
  result = port


proc writelnToChannel*(line: string) =
  results.send(Suggest(section: ideMsg, doc: line))

proc sugResultHook*(s: Suggest) =
  results.send(s)

proc errorHook*(conf: ConfigRef; info: TLineInfo; msg: string; sev: Severity) =
  results.send(Suggest(section: ideChk, filePath: toFullPath(conf, info),
    line: toLinenumber(info), column: toColumn(info), doc: msg,
    forth: $sev))