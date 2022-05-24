import packageinfotypes
import options

proc a(nnnnnnnnn: Option[PackageInfo]) =
  echo nnnnnnnnn.get.isMinimal
  let b = nnnnnnnnn.get.isMinimal
  echo b
