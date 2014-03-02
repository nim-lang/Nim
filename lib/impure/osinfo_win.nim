# XXX clean up this mess!

import winlean

const
  INVALID_HANDLE_VALUE = int(- 1) # GetStockObject

type
  TMEMORYSTATUSEX {.final, pure.} = object
    dwLength: int32
    dwMemoryLoad: int32
    ullTotalPhys: int64
    ullAvailPhys: int64
    ullTotalPageFile: int64
    ullAvailPageFile: int64
    ullTotalVirtual: int64
    ullAvailVirtual: int64
    ullAvailExtendedVirtual: int64
    
  SYSTEM_INFO* {.final, pure.} = object
    wProcessorArchitecture*: int16
    wReserved*: int16
    dwPageSize*: int32
    lpMinimumApplicationAddress*: pointer
    lpMaximumApplicationAddress*: pointer
    dwActiveProcessorMask*: int32
    dwNumberOfProcessors*: int32
    dwProcessorType*: int32
    dwAllocationGranularity*: int32
    wProcessorLevel*: int16
    wProcessorRevision*: int16

  LPSYSTEM_INFO* = ptr SYSTEM_INFO
  TSYSTEMINFO* = SYSTEM_INFO

  TMemoryInfo* = object
    MemoryLoad*: int ## occupied memory, in percent
    TotalPhysMem*: int64 ## Total Physical memory, in bytes
    AvailablePhysMem*: int64 ## Available physical memory, in bytes
    TotalPageFile*: int64 ## The current committed memory limit 
                          ## for the system or the current process, whichever is smaller, in bytes.
    AvailablePageFile*: int64 ## The maximum amount of memory the current process can commit, in bytes.
    TotalVirtualMem*: int64 ## Total virtual memory, in bytes
    AvailableVirtualMem*: int64 ## Available virtual memory, in bytes
    
  TOSVERSIONINFOEX {.final, pure.} = object
    dwOSVersionInfoSize: int32
    dwMajorVersion: int32
    dwMinorVersion: int32
    dwBuildNumber: int32
    dwPlatformId: int32
    szCSDVersion: array[0..127, char]
    wServicePackMajor: int16
    wServicePackMinor: int16
    wSuiteMask: int16
    wProductType: int8
    wReserved: char
    
  TVersionInfo* = object
    majorVersion*: int
    minorVersion*: int
    buildNumber*: int
    platformID*: int
    SPVersion*: string ## Full Service pack version string
    SPMajor*: int ## Major service pack version
    SPMinor*: int ## Minor service pack version
    SuiteMask*: int
    ProductType*: int
    
  TPartitionInfo* = tuple[FreeSpace, TotalSpace: Tfiletime]
  
const
  # SuiteMask - VersionInfo.SuiteMask
  VER_SUITE_BACKOFFICE* = 0x00000004
  VER_SUITE_BLADE* = 0x00000400
  VER_SUITE_COMPUTE_SERVER* = 0x00004000
  VER_SUITE_DATACENTER* = 0x00000080
  VER_SUITE_ENTERPRISE* = 0x00000002
  VER_SUITE_EMBEDDEDNT* = 0x00000040
  VER_SUITE_PERSONAL* = 0x00000200
  VER_SUITE_SINGLEUSERTS* = 0x00000100
  VER_SUITE_SMALLBUSINESS* = 0x00000001
  VER_SUITE_SMALLBUSINESS_RESTRICTED* = 0x00000020
  VER_SUITE_STORAGE_SERVER* = 0x00002000
  VER_SUITE_TERMINAL* = 0x00000010
  VER_SUITE_WH_SERVER* = 0x00008000

  # ProductType - VersionInfo.ProductType
  VER_NT_DOMAIN_CONTROLLER* = 0x0000002
  VER_NT_SERVER* = 0x0000003
  VER_NT_WORKSTATION* = 0x0000001
  
  VER_PLATFORM_WIN32_NT* = 2
  
  # Product Info - getProductInfo() - (Remove unused ones ?)
  PRODUCT_BUSINESS* = 0x00000006
  PRODUCT_BUSINESS_N* = 0x00000010
  PRODUCT_CLUSTER_SERVER* = 0x00000012
  PRODUCT_DATACENTER_SERVER* = 0x00000008
  PRODUCT_DATACENTER_SERVER_CORE* = 0x0000000C
  PRODUCT_DATACENTER_SERVER_CORE_V* = 0x00000027
  PRODUCT_DATACENTER_SERVER_V* = 0x00000025
  PRODUCT_ENTERPRISE* = 0x00000004
  PRODUCT_ENTERPRISE_E* = 0x00000046
  PRODUCT_ENTERPRISE_N* = 0x0000001B
  PRODUCT_ENTERPRISE_SERVER* = 0x0000000A
  PRODUCT_ENTERPRISE_SERVER_CORE* = 0x0000000E
  PRODUCT_ENTERPRISE_SERVER_CORE_V* = 0x00000029
  PRODUCT_ENTERPRISE_SERVER_IA64* = 0x0000000F
  PRODUCT_ENTERPRISE_SERVER_V* = 0x00000026
  PRODUCT_HOME_BASIC* = 0x00000002
  PRODUCT_HOME_BASIC_E* = 0x00000043
  PRODUCT_HOME_BASIC_N* = 0x00000005
  PRODUCT_HOME_PREMIUM* = 0x00000003
  PRODUCT_HOME_PREMIUM_E* = 0x00000044
  PRODUCT_HOME_PREMIUM_N* = 0x0000001A
  PRODUCT_HYPERV* = 0x0000002A
  PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT* = 0x0000001E
  PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING* = 0x00000020
  PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY* = 0x0000001F
  PRODUCT_PROFESSIONAL* = 0x00000030
  PRODUCT_PROFESSIONAL_E* = 0x00000045
  PRODUCT_PROFESSIONAL_N* = 0x00000031
  PRODUCT_SERVER_FOR_SMALLBUSINESS* = 0x00000018
  PRODUCT_SERVER_FOR_SMALLBUSINESS_V* = 0x00000023
  PRODUCT_SERVER_FOUNDATION* = 0x00000021
  PRODUCT_SMALLBUSINESS_SERVER* = 0x00000009
  PRODUCT_STANDARD_SERVER* = 0x00000007
  PRODUCT_STANDARD_SERVER_CORE * = 0x0000000D
  PRODUCT_STANDARD_SERVER_CORE_V* = 0x00000028
  PRODUCT_STANDARD_SERVER_V* = 0x00000024
  PRODUCT_STARTER* = 0x0000000B
  PRODUCT_STARTER_E* = 0x00000042
  PRODUCT_STARTER_N* = 0x0000002F
  PRODUCT_STORAGE_ENTERPRISE_SERVER* = 0x00000017
  PRODUCT_STORAGE_EXPRESS_SERVER* = 0x00000014
  PRODUCT_STORAGE_STANDARD_SERVER* = 0x00000015
  PRODUCT_STORAGE_WORKGROUP_SERVER* = 0x00000016
  PRODUCT_UNDEFINED* = 0x00000000
  PRODUCT_ULTIMATE* = 0x00000001
  PRODUCT_ULTIMATE_E* = 0x00000047
  PRODUCT_ULTIMATE_N* = 0x0000001C
  PRODUCT_WEB_SERVER* = 0x00000011
  PRODUCT_WEB_SERVER_CORE* = 0x0000001D
  
  PROCESSOR_ARCHITECTURE_AMD64* = 9 ## x64 (AMD or Intel)
  PROCESSOR_ARCHITECTURE_IA64* = 6 ## Intel Itanium Processor Family (IPF)
  PROCESSOR_ARCHITECTURE_INTEL* = 0 ## x86
  PROCESSOR_ARCHITECTURE_UNKNOWN* = 0xffff ## Unknown architecture.
  
  # GetSystemMetrics
  SM_SERVERR2 = 89 
  
proc globalMemoryStatusEx*(lpBuffer: var TMEMORYSTATUSEX){.stdcall, dynlib: "kernel32",
    importc: "GlobalMemoryStatusEx".}
    
proc getMemoryInfo*(): TMemoryInfo =
  ## Retrieves memory info
  var statex: TMEMORYSTATUSEX
  statex.dwLength = sizeof(statex).int32

  globalMemoryStatusEx(statex)
  result.MemoryLoad = statex.dwMemoryLoad
  result.TotalPhysMem = statex.ullTotalPhys
  result.AvailablePhysMem = statex.ullAvailPhys
  result.TotalPageFile = statex.ullTotalPageFile
  result.AvailablePageFile = statex.ullAvailPageFile
  result.TotalVirtualMem = statex.ullTotalVirtual
  result.AvailableVirtualMem = statex.ullAvailExtendedVirtual

proc getVersionEx*(lpVersionInformation: var TOSVERSIONINFOEX): WINBOOL{.stdcall,
    dynlib: "kernel32", importc: "GetVersionExA".}

proc getProcAddress*(hModule: int, lpProcName: cstring): pointer{.stdcall,
    dynlib: "kernel32", importc: "GetProcAddress".}

proc getModuleHandleA*(lpModuleName: cstring): int{.stdcall,
     dynlib: "kernel32", importc: "GetModuleHandleA".}

proc getVersionInfo*(): TVersionInfo =
  ## Retrieves operating system info
  var osvi: TOSVERSIONINFOEX
  osvi.dwOSVersionInfoSize = sizeof(osvi).int32
  discard getVersionEx(osvi)
  result.majorVersion = osvi.dwMajorVersion
  result.minorVersion = osvi.dwMinorVersion
  result.buildNumber = osvi.dwBuildNumber
  result.platformID = osvi.dwPlatformId
  result.SPVersion = $osvi.szCSDVersion
  result.SPMajor = osvi.wServicePackMajor
  result.SPMinor = osvi.wServicePackMinor
  result.SuiteMask = osvi.wSuiteMask
  result.ProductType = osvi.wProductType

proc getProductInfo*(majorVersion, minorVersion, SPMajorVersion, 
                     SPMinorVersion: int): int =
  ## Retrieves Windows' ProductInfo, this function only works in Vista and 7

  var pGPI = cast[proc (dwOSMajorVersion, dwOSMinorVersion, 
              dwSpMajorVersion, dwSpMinorVersion: int32, outValue: Pint32)](getProcAddress(
                getModuleHandleA("kernel32.dll"), "GetProductInfo"))
                
  if pGPI != nil:
    var dwType: int32
    pGPI(int32(majorVersion), int32(minorVersion), int32(SPMajorVersion), int32(SPMinorVersion), addr(dwType))
    result = int(dwType)
  else:
    return PRODUCT_UNDEFINED

proc getSystemInfo*(lpSystemInfo: LPSYSTEM_INFO){.stdcall, dynlib: "kernel32",
    importc: "GetSystemInfo".}
    
proc getSystemInfo*(): TSYSTEM_INFO =
  ## Returns the SystemInfo

  # Use GetNativeSystemInfo if it's available
  var pGNSI = cast[proc (lpSystemInfo: LPSYSTEM_INFO)](getProcAddress(
                getModuleHandleA("kernel32.dll"), "GetNativeSystemInfo"))
                
  var systemi: TSYSTEM_INFO              
  if pGNSI != nil:
    pGNSI(addr(systemi))
  else:
    getSystemInfo(addr(systemi))

  return systemi

proc getSystemMetrics*(nIndex: int32): int32{.stdcall, dynlib: "user32",
    importc: "GetSystemMetrics".}

proc `$`*(osvi: TVersionInfo): string =
  ## Turns a VersionInfo object, into a string

  if osvi.platformID == VER_PLATFORM_WIN32_NT and osvi.majorVersion > 4:
    result = "Microsoft "
    
    var si = getSystemInfo()
    # Test for the specific product
    if osvi.majorVersion == 6:
      if osvi.minorVersion == 0:
        if osvi.ProductType == VER_NT_WORKSTATION:
          result.add("Windows Vista ")
        else: result.add("Windows Server 2008 ")
      elif osvi.minorVersion == 1:
        if osvi.ProductType == VER_NT_WORKSTATION:
          result.add("Windows 7 ")
        else: result.add("Windows Server 2008 R2 ")
    
      var dwType = getProductInfo(osvi.majorVersion, osvi.minorVersion, 0, 0)
      case dwType
      of PRODUCT_ULTIMATE:
        result.add("Ultimate Edition")
      of PRODUCT_PROFESSIONAL:
        result.add("Professional")
      of PRODUCT_HOME_PREMIUM:
        result.add("Home Premium Edition")
      of PRODUCT_HOME_BASIC:
        result.add("Home Basic Edition")
      of PRODUCT_ENTERPRISE:
        result.add("Enterprise Edition")
      of PRODUCT_BUSINESS:
        result.add("Business Edition")
      of PRODUCT_STARTER:
        result.add("Starter Edition")
      of PRODUCT_CLUSTER_SERVER:
        result.add("Cluster Server Edition")
      of PRODUCT_DATACENTER_SERVER:
        result.add("Datacenter Edition")
      of PRODUCT_DATACENTER_SERVER_CORE:
        result.add("Datacenter Edition (core installation)")
      of PRODUCT_ENTERPRISE_SERVER:
        result.add("Enterprise Edition")
      of PRODUCT_ENTERPRISE_SERVER_CORE:
        result.add("Enterprise Edition (core installation)")
      of PRODUCT_ENTERPRISE_SERVER_IA64:
        result.add("Enterprise Edition for Itanium-based Systems")
      of PRODUCT_SMALLBUSINESS_SERVER:
        result.add("Small Business Server")
      of PRODUCT_STANDARD_SERVER:
        result.add("Standard Edition")
      of PRODUCT_STANDARD_SERVER_CORE:
        result.add("Standard Edition (core installation)")
      of PRODUCT_WEB_SERVER:
        result.add("Web Server Edition")
      else:
        discard
    # End of Windows 6.*

    if osvi.majorVersion == 5 and osvi.minorVersion == 2:
      if getSystemMetrics(SM_SERVERR2) != 0:
        result.add("Windows Server 2003 R2, ")
      elif (osvi.SuiteMask and VER_SUITE_PERSONAL) != 0: # Not sure if this will work
        result.add("Windows Storage Server 2003")
      elif (osvi.SuiteMask and VER_SUITE_WH_SERVER) != 0:
        result.add("Windows Home Server")
      elif osvi.ProductType == VER_NT_WORKSTATION and 
          si.wProcessorArchitecture==PROCESSOR_ARCHITECTURE_AMD64:
        result.add("Windows XP Professional x64 Edition")
      else:
        result.add("Windows Server 2003, ")
      
      # Test for the specific product
      if osvi.ProductType != VER_NT_WORKSTATION:
        if ze(si.wProcessorArchitecture) == PROCESSOR_ARCHITECTURE_IA64:
          if (osvi.SuiteMask and VER_SUITE_DATACENTER) != 0:
            result.add("Datacenter Edition for Itanium-based Systems")
          elif (osvi.SuiteMask and VER_SUITE_ENTERPRISE) != 0:
            result.add("Enterprise Edition for Itanium-based Systems")
        elif ze(si.wProcessorArchitecture) == PROCESSOR_ARCHITECTURE_AMD64:
          if (osvi.SuiteMask and VER_SUITE_DATACENTER) != 0:
            result.add("Datacenter x64 Edition")
          elif (osvi.SuiteMask and VER_SUITE_ENTERPRISE) != 0:
            result.add("Enterprise x64 Edition")
          else:
            result.add("Standard x64 Edition")
        else:
          if (osvi.SuiteMask and VER_SUITE_COMPUTE_SERVER) != 0:
            result.add("Compute Cluster Edition")
          elif (osvi.SuiteMask and VER_SUITE_DATACENTER) != 0:
            result.add("Datacenter Edition")
          elif (osvi.SuiteMask and VER_SUITE_ENTERPRISE) != 0:
            result.add("Enterprise Edition")
          elif (osvi.SuiteMask and VER_SUITE_BLADE) != 0:
            result.add("Web Edition")
          else:
            result.add("Standard Edition")
    # End of 5.2
    
    if osvi.majorVersion == 5 and osvi.minorVersion == 1:
      result.add("Windows XP ")
      if (osvi.SuiteMask and VER_SUITE_PERSONAL) != 0:
        result.add("Home Edition")
      else:
        result.add("Professional")
    # End of 5.1
    
    if osvi.majorVersion == 5 and osvi.minorVersion == 0:
      result.add("Windows 2000 ")
      if osvi.ProductType == VER_NT_WORKSTATION:
        result.add("Professional")
      else:
        if (osvi.SuiteMask and VER_SUITE_DATACENTER) != 0:
          result.add("Datacenter Server")
        elif (osvi.SuiteMask and VER_SUITE_ENTERPRISE) != 0:
          result.add("Advanced Server")
        else:
          result.add("Server")
    # End of 5.0
    
    # Include service pack (if any) and build number.
    if len(osvi.SPVersion) > 0:
      result.add(" ")
      result.add(osvi.SPVersion)
    
    result.add(" (build " & $osvi.buildNumber & ")")
    
    if osvi.majorVersion >= 6:
      if ze(si.wProcessorArchitecture) == PROCESSOR_ARCHITECTURE_AMD64:
        result.add(", 64-bit")
      elif ze(si.wProcessorArchitecture) == PROCESSOR_ARCHITECTURE_INTEL:
        result.add(", 32-bit")
    
  else:
    # Windows 98 etc...
    result = "Unknown version of windows[Kernel version <= 4]"
    

proc getFileSize*(file: string): BiggestInt =
  var fileData: TWIN32_FIND_DATA
  var hFile = findFirstFile(file, fileData)
  if hFile == INVALID_HANDLE_VALUE:
    raise newException(EIO, $getLastError())
  
  return fileData.nFileSizeLow

proc getDiskFreeSpaceEx*(lpDirectoryName: cstring, lpFreeBytesAvailableToCaller,
                         lpTotalNumberOfBytes,
                         lpTotalNumberOfFreeBytes: var TFiletime): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "GetDiskFreeSpaceExA".}

proc getPartitionInfo*(partition: string): TPartitionInfo =
  ## Retrieves partition info, for example ``partition`` may be ``"C:\"``
  var FreeBytes, TotalBytes, TotalFreeBytes: TFiletime 
  var res = getDiskFreeSpaceEx(r"C:\", FreeBytes, TotalBytes, 
                               TotalFreeBytes)
  return (FreeBytes, TotalBytes)

when isMainModule:
  var r = getMemoryInfo()
  echo("Memory load: ", r.MemoryLoad, "%")
  
  var osvi = getVersionInfo()
  
  echo($osvi)

  echo(getFileSize(r"osinfo_win.nim") div 1024 div 1024)
  
  echo(rdFileTime(getPartitionInfo(r"C:\")[0]))
