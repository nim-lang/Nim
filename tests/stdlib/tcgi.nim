discard """
  output: '''
[Suite] Test cgi module
(key: "a", value: "1")
(key: "b", value: "0")
(key: "c", value: "3")
(key: "d", value: "")
(key: "e", value: "")
(key: "a", value: "5")
(key: "a", value: "t e x t")
(key: "e", value: "http://w3schools.com/my test.asp?name=ståle&car=saab")
'''
"""

import unittest
import cgi, strtabs

suite "Test cgi module":
  const queryString = "foo=bar&фу=бар&checked=✓&list=1,2,3&with_space=text%20with%20space"

  test "test query parsing with readData":
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

for pair in decodeData(queryString):
  echo pair
