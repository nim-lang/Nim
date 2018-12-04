discard """
  nimout: '''61'''
"""

# bug #2297

import tables

proc html5tags*(): TableRef[string, string] =
  var html5tagsCache: Table[string,string]
  if true:
    new(result)
    html5tagsCache = initTable[string, string]()
    html5tagsCache["a"] = "a"
    html5tagsCache["abbr"] = "abbr"
    html5tagsCache["b"] = "b"
    html5tagsCache["element"] = "element"
    html5tagsCache["embed"] = "embed"
    html5tagsCache["fieldset"] = "fieldset"
    html5tagsCache["figcaption"] = "figcaption"
    html5tagsCache["figure"] = "figure"
    html5tagsCache["footer"] = "footer"
    html5tagsCache["header"] = "header"
    html5tagsCache["form"] = "form"
    html5tagsCache["head"] = "head"
    html5tagsCache["hr"] = "hr"
    html5tagsCache["html"] = "html"
    html5tagsCache["iframe"] = "iframe"
    html5tagsCache["img"] = "img"
    html5tagsCache["input"] = "input"
    html5tagsCache["keygen"] = "keygen"
    html5tagsCache["label"] = "label"
    html5tagsCache["legend"] = "legend"
    html5tagsCache["li"] = "li"
    html5tagsCache["link"] = "link"
    html5tagsCache["main"] = "main"
    html5tagsCache["map"] = "map"
    html5tagsCache["menu"] = "menu"
    html5tagsCache["menuitem"] = "menuitem"
    html5tagsCache["meta"] = "meta"
    html5tagsCache["meter"] = "master"
    html5tagsCache["noscript"] = "noscript"
    html5tagsCache["object"] = "object"
    html5tagsCache["ol"] = "ol"
    html5tagsCache["optgroup"] = "optgroup"
    html5tagsCache["option"] = "option"
    html5tagsCache["output"] = "output"
    html5tagsCache["p"] = "p"
    html5tagsCache["pre"] = "pre"
    html5tagsCache["param"] = "param"
    html5tagsCache["progress"] = "progress"
    html5tagsCache["q"] = "q"
    html5tagsCache["rp"] = "rp"
    html5tagsCache["rt"] = "rt"
    html5tagsCache["ruby"] = "ruby"
    html5tagsCache["s"] = "s"
    html5tagsCache["script"] = "script"
    html5tagsCache["select"] = "select"
    html5tagsCache["source"] = "source"
    html5tagsCache["style"] = "style"
    html5tagsCache["summary"] = "summary"
    html5tagsCache["table"] = "table"
    html5tagsCache["tbody"] = "tbody"
    html5tagsCache["thead"] = "thead"
    html5tagsCache["td"] = "td"
    html5tagsCache["th"] = "th"
    html5tagsCache["template"] = "template"
    html5tagsCache["textarea"] = "textarea"
    html5tagsCache["time"] = "time"
    html5tagsCache["title"] = "title"
    html5tagsCache["tr"] = "tr"
    html5tagsCache["track"] = "track"
    html5tagsCache["ul"] = "ul"
    html5tagsCache["video"] = "video"
  result[] = html5tagsCache

static:
  var i = 0
  for key, value in html5tags().pairs():
    inc i
  echo i
