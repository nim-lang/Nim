discard """
  output: '''{"foo":{"test":"123"}}'''
"""

import json, options

type
  Foo = ref object
    test: string
  Test = object
    foo: Option[Foo]

let js = """{"foo": {"test": "123"}}"""
let parsed = parseJson(js)
let a = parsed.to(Test)
echo $(%*a)