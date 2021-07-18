## An replacement for `std/winlean` with precise and stable types definitions.

type
  DWORD* = culong  ## https://docs.microsoft.com/en-us/windows/win32/winprog/windows-data-types#ulong
  ULONGLONG* = int64 ## https://docs.microsoft.com/en-us/windows/win32/winprog/windows-data-types#ulonglong
  PULONGLONG* = ptr ULONGLONG ## https://docs.microsoft.com/en-us/windows/win32/winprog/windows-data-types#pulong


proc getTempPath*(
    nBufferLength: DWORD, lpBuffer: WideCString
  ): DWORD {.stdcall, dynlib: "kernel32.dll", importc: "GetTempPathW".} =
  ## Retrieves the path of the directory designated for temporary files.
  ## See https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw
