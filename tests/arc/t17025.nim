discard """
  cmd: "nim c --gc:arc $file"
  output: '''
{"Package": {"name": "hello"}, "Author": {"name": "name", "qq": "123456789", "email": "email"}}
hello
name
123456789
email
hello
name2
987654321
liame
'''
"""

import parsecfg, streams, tables

const cfg = """[Package]
name=hello
[Author]
name=name
qq=123456789
email="email""""

proc main() =
    let stream = newStringStream(cfg)
    let dict = loadConfig(stream)
    var pname = dict.getSectionValue("Package","name")
    var name = dict.getSectionValue("Author","name")
    var qq = dict.getSectionValue("Author","qq")
    var email = dict.getSectionValue("Author","email")
    echo dict[]
    echo pname & "\n" & name & "\n" & qq & "\n" & email
    stream.close()

main()

proc getDict(): OrderedTableRef[string, OrderedTableRef[string, string]] =
    result = newOrderedTable[string, OrderedTableRef[string, string]]()
    result["Package"] = newOrderedTable[string, string]()
    result["Package"]["name"] = "hello"
    result["Author"] = newOrderedTable[string, string]()
    result["Author"]["name"] = "name2"
    result["Author"]["qq"] = "987654321"
    result["Author"]["email"] = "liame"

proc main2() =
    let dict = getDict()
    var pname = dict.getSectionValue("Package","name")
    var name = dict.getSectionValue("Author","name")
    var qq = dict.getSectionValue("Author","qq")
    var email = dict.getSectionValue("Author","email")
    echo pname & "\n" & name & "\n" & qq & "\n" & email

main2()

