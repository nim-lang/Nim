#! /bin/sh
# 
# Nimrod deinstallation script
#   (c) 2008 Andreas Rumpf
#

if [ $# -eq 1 ] ; then
  case $1 in
    "/usr/bin")
      rm -rf /usr/lib/nimrod
      rm -rf /usr/share/nimrod/doc
      rm -f /usr/bin/nimrod
      rm -f /etc/nimrod.cfg
      rm -f /etc/nimdoc.cfg || exit 1
      ;;
    "/usr/local/bin") 
      rm -rf /usr/local/lib/nimrod
      rm -rf /usr/local/share/nimrod/doc
      rm -f /usr/local/bin/nimrod
      rm -f /etc/nimrod.cfg
      rm -f /etc/nimdoc.cfg || exit 1
      ;;
    *) 
      rm -rf $1/nimrod || exit 1
      ;;
  esac
  echo "deinstallation successful"
else
  echo "Nimrod deinstallation script"
  echo "Usage: [sudo] sh deinstall.sh DIR"
  echo "Where DIR may be:"
  echo "  /usr/bin"
  echo "  /usr/local/bin"
  echo "  /opt"
  echo "  <some other dir> (treated like '/opt')"
  exit 1
fi

