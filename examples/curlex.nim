import 
  libcurl

var hCurl = easy_init()
if hCurl != nil: 
  discard easy_setopt(hCurl, OPT_VERBOSE, true)
  discard easy_setopt(hCurl, OPT_URL, "http://nim-lang.org/")
  discard easy_perform(hCurl)
  easy_cleanup(hCurl)

