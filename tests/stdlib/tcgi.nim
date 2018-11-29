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
