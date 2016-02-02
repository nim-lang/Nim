# parsing IPv6 addresses in host...

import uri

echo(parseUri("http://[1:2::3:::]/path/:/full/?of/muck#derp").hostname)
