# tests for rst module

import ../../lib/packages/docutils/rstgen
import ../../lib/packages/docutils/rst
import unittest
import os

suite "RST include directive":
  test "Include whole":
    "other.rst".writeFile("**test1**")
    let input = ".. include:: other.rst"
    assert "<strong>test1</strong>" == rstTohtml(input, {}, defaultConfig())
    removeFile("other.rst")

  test "Include starting from":
    "other.rst".writeFile("""
And this should **NOT** be visible in `docs.html`
OtherStart
*Visible*
""")

    let input = """
.. include:: other.rst
             :start-after: OtherStart
"""
    assert "<em>Visible</em>" == rstTohtml(input, {}, defaultConfig())
    removeFile("other.rst")

  test "Include everything before":
    "other.rst".writeFile("""
*Visible*
OtherEnd
And this should **NOT** be visible in `docs.html`
""")

    let input = """
.. include:: other.rst
             :end-before: OtherEnd
"""
    assert "<em>Visible</em>" == rstTohtml(input, {}, defaultConfig())
    removeFile("other.rst")


  test "Include everything between":
    "other.rst".writeFile("""
And this should **NOT** be visible in `docs.html`
OtherStart
*Visible*
OtherEnd
And this should **NOT** be visible in `docs.html`
""")

    let input = """
.. include:: other.rst
             :start-after: OtherStart
             :end-before: OtherEnd
"""
    assert "<em>Visible</em>" == rstTohtml(input, {}, defaultConfig())
    removeFile("other.rst")


  test "Ignore premature ending string":
    "other.rst".writeFile("""

OtherEnd
And this should **NOT** be visible in `docs.html`
OtherStart
*Visible*
OtherEnd
And this should **NOT** be visible in `docs.html`
""")

    let input = """
.. include:: other.rst
             :start-after: OtherStart
             :end-before: OtherEnd
"""
    assert "<em>Visible</em>" == rstTohtml(input, {}, defaultConfig())
    removeFile("other.rst")
