; Cesium NSIS Installer Script
; Produces a Windows .exe installer from Linux (makensis)
; Replaces the Inno Setup script (cesium.iss) which required Windows/Wine
;
; Usage:
;   makensis -DAPP_VERSION=v1.7.17 -DAPP_SRC_DIR=/path/to/nwjs-dir cesium.nsi

;--- Overridable defines (pass via -D on command line) ---
!ifndef APP_VERSION
  !define APP_VERSION "v0.0.0"
!endif
!ifndef APP_SRC_DIR
  !define APP_SRC_DIR "."
!endif

!define APP_NAME "Cesium"
!define APP_PUBLISHER "Duniter team"
!define APP_URL "https://cesium.duniter.io"
!define APP_EXE "nw.exe"
; Compile-time icon path (forward slashes for Linux build host)
!define APP_ICON_SRC "cesium/img/favicon.ico"
; Runtime icon path (backslashes for Windows target)
!define APP_ICON_WIN "cesium\img\favicon.ico"
; Match the Inno Setup AppId for upgrade cohabitation
!define APP_ID "Cesium"
!define UNINSTALL_REG_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}"

;--- Installer attributes ---
Name "${APP_NAME} ${APP_VERSION}"
OutFile "${APP_NAME}-setup.exe"
InstallDir "$PROGRAMFILES64\${APP_NAME}"
InstallDirRegKey HKLM "${UNINSTALL_REG_KEY}" "InstallLocation"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

;--- Includes ---
!include "MUI2.nsh"
!include "FileFunc.nsh"

;--- MUI settings ---
!define MUI_ABORTWARNING
!define MUI_ICON "${APP_SRC_DIR}/${APP_ICON_SRC}"
!define MUI_UNICON "${APP_SRC_DIR}/${APP_ICON_SRC}"

;--- Pages ---
!insertmacro MUI_PAGE_LICENSE "${APP_SRC_DIR}/LICENSE.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APP_NAME}"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;--- Languages ---
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "Spanish"

;--- Detect and remove previous installation ---
Function .onInit
  ReadRegStr $0 HKLM "${UNINSTALL_REG_KEY}" "UninstallString"
  StrCmp $0 "" done

  MessageBox MB_OKCANCEL|MB_ICONINFORMATION \
    "A previous version of ${APP_NAME} is installed.$\n$\nIt will be removed before installing the new version." \
    IDOK uninst
  Abort

  uninst:
    ; Also check the Inno Setup registry key for old installations
    ReadRegStr $1 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\{DA3E955D-F840-8274-DDD2-D3C099C306D2}_is1" "UninstallString"
    StrCmp $1 "" nsis_uninst
    ; Run Inno Setup uninstaller silently
    ExecWait '"$1" /SILENT /NORESTART /SUPPRESSMSGBOXES'
    Goto done

  nsis_uninst:
    ExecWait '"$0" /S'

  done:
FunctionEnd

;--- Install section ---
Section "Install"
  SetOutPath "$INSTDIR"

  ; Copy all application files recursively (forward slashes for Linux build host)
  File /r "${APP_SRC_DIR}/*"

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_ICON_WIN}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe"

  ; Desktop shortcut
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_ICON_WIN}"

  ; Add/Remove Programs registry entries
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "URLInfoAbout" "${APP_URL}"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayIcon" "$INSTDIR\${APP_ICON_WIN}"
  WriteRegDWORD HKLM "${UNINSTALL_REG_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTALL_REG_KEY}" "NoRepair" 1

  ; Estimate installed size (in KB)
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${UNINSTALL_REG_KEY}" "EstimatedSize" $0
SectionEnd

;--- Uninstall section ---
Section "Uninstall"
  ; Remove application files
  RMDir /r "$INSTDIR"

  ; Remove Start Menu shortcuts
  RMDir /r "$SMPROGRAMS\${APP_NAME}"

  ; Remove Desktop shortcut
  Delete "$DESKTOP\${APP_NAME}.lnk"

  ; Remove registry keys
  DeleteRegKey HKLM "${UNINSTALL_REG_KEY}"
SectionEnd
