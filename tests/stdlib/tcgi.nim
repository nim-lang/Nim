discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/unittest
import std/[cgi, strtabs, sugar]
import std/assertions

block: # Test cgi module
  const queryString = "foo=bar&фу=бар&checked=✓&list=1,2,3&with_space=text%20with%20space"

  block: # test query parsing with readData
    let parsedQuery = readData(queryString)

    check parsedQuery["foo"] == "bar"
    check parsedQuery["фу"] == "бар"
    check parsedQuery["checked"] == "✓"
    check parsedQuery["list"] == "1,2,3"
    check parsedQuery["with_space"] == "text with space"

    expect KeyError:
      discard parsedQuery["not_existing_key"]

# bug #15369
let queryString = "a=1&b=0&c=3&d&e&a=5&a=t%20e%20x%20t&e=http%3A%2F%2Fw3schools.com%2Fmy%20test.asp%3Fname%3Dst%C3%A5le%26car%3Dsaab"

doAssert collect(for pair in decodeData(queryString): pair) ==
  @[("a", "1"), ("b", "0"), ("c", "3"),
    ("d", ""),("e", ""), ("a", "5"), ("a", "t e x t"),
  ("e", "http://w3schools.com/my test.asp?name=ståle&car=saab")
]
