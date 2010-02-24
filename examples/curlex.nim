import 
  libcurl

var hCurl = curl_easy_init()
if hCurl != nil: 
  discard curl_easy_setopt(hCurl, CURLOPT_VERBOSE, True)
  discard curl_easy_setopt(hCurl, CURLOPT_URL, "http://force7.de/nimrod")
  discard curl_easy_perform(hCurl)
  curl_easy_cleanup(hCurl)

