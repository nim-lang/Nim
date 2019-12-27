# Copyright (C) 2012 Dominik Picheta
# MIT License - Look at license.txt for details.
import htmlgen
proc error*(err, jesterVer: string): string =
   return html(head(title(err)),
               body(h1(err),
                    "<hr/>",
                    p("Jester " & jesterVer),
                    style = "text-align: center;"
               ),
               xmlns="http://www.w3.org/1999/xhtml")

proc routeException*(error: string, jesterVer: string): string =
  return html(head(title("Jester route exception")),
              body(
                h1("An error has occured in one of your routes."),
                p(b("Detail: "), error)
              ),
             xmlns="http://www.w3.org/1999/xhtml")
