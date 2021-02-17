discard """
  cmd: "nim c --gc:arc $file"
  output: '''
hello
name
123456789
email
'''
"""

import parsecfg, streams, tables

const cfg = """[Package]
name=hello
[Author]
name=lihf8515
qq=10214028
email="lihaifeng@wxm.com""""

proc getDict(): OrderedTableRef[string, OrderedTableRef[string, string]] =
    result = newOrderedTable[string, OrderedTableRef[string, string]]()
    result["Package"] = newOrderedTable[string, string]()
    result["Package"]["name"] = "hello"
    result["Author"] = newOrderedTable[string, string]()
    result["Author"]["name"] = "name"
    result["Author"]["qq"] = "123456789"
    result["Author"]["email"] = "email"

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

