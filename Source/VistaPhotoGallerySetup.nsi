; ============================================================================
; Windows Photo Gallery Setup - development installer
; Vista Windows Photo Gallery compatibility project
; ============================================================================

Unicode True
SetCompressor /SOLID lzma
XPStyle on

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
!include "Sections.nsh"

!define PRODUCT_NAME        "Windows Photo Gallery"
!define SETUP_NAME          "Photo Gallery Installer"
!define UNINSTALLER_NAME    "Photo Gallery Uninstaller"
!define PRODUCT_VERSION     "0.1.6-dev"
!define PROJECT_REGKEY      "Software\VistaPhotoGallerySetup"
!define UNINSTALL_REGKEY    "Software\Microsoft\Windows\CurrentVersion\Uninstall\VistaPhotoGalleryCommunity"

Name "${PRODUCT_NAME}"
OutFile "PhotoGalleryInstaller.exe"
InstallDir "$LOCALAPPDATA\Programs\Windows Photo Gallery"
InstallDirRegKey HKCU "${PROJECT_REGKEY}" "InstallDir"
RequestExecutionLevel user
ShowInstDetails show
ShowUninstDetails show
Caption "${SETUP_NAME}"
UninstallCaption "${UNINSTALLER_NAME}"
UninstallButtonText "Uninstall"

VIProductVersion "0.1.6.0"
VIAddVersionKey /LANG=1033 "ProductName" "${SETUP_NAME}"
VIAddVersionKey /LANG=1033 "FileDescription" "Photo Gallery Installer"
VIAddVersionKey /LANG=1033 "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=1033 "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=1033 "LegalCopyright" "Copyright (c) 2026 Vista Photo Gallery Setup contributors"

BrandingText "Windows Photo Gallery"

; --- Vista-ish MUI2 artwork --------------------------------------------------
!define MUI_ABORTWARNING
!define MUI_ICON "assets\setup.ico"
!define MUI_UNICON "assets\uninstall.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "assets\header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "assets\unheader.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "assets\wizard.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "assets\unwizard.bmp"

; --- Variables ---------------------------------------------------------------
Var VistaSource
Var SourceOK
Var SourceError

; --- Welcome page ------------------------------------------------------------
!define MUI_WELCOMEPAGE_TITLE "Welcome to the Photo Gallery Installer"
!define MUI_WELCOMEPAGE_TEXT "This installer will help you install Windows Photo Gallery on your computer.$\r$\n$\r$\nWindows Photo Gallery requires original Windows Vista files supplied by you. It is recommended that you close all other applications before continuing.$\r$\n$\r$\nClick Next to continue."
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE WelcomeLeave
!insertmacro MUI_PAGE_WELCOME

; --- License page ------------------------------------------------------------
!define MUI_PAGE_HEADER_TEXT "License Agreement"
!define MUI_PAGE_HEADER_SUBTEXT "Please review the license terms before installing Windows Photo Gallery."
!define MUI_LICENSEPAGE_RADIOBUTTONS
!define MUI_LICENSEPAGE_TEXT_TOP "Press Page Down to see the rest of the agreement."
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"

; --- Components page ---------------------------------------------------------
!define MUI_PAGE_HEADER_TEXT "Choose Components"
!define MUI_PAGE_HEADER_SUBTEXT "Choose which Windows Photo Gallery components you would like to install."
!define MUI_COMPONENTSPAGE_SMALLDESC
!insertmacro MUI_PAGE_COMPONENTS

; --- Installing page ---------------------------------------------------------
!define MUI_PAGE_HEADER_TEXT "Installing Windows Photo Gallery"
!define MUI_PAGE_HEADER_SUBTEXT "Please wait while Photo Gallery Installer installs Windows Photo Gallery on your computer."
!insertmacro MUI_PAGE_INSTFILES

; --- Finish page -------------------------------------------------------------
!define MUI_FINISHPAGE_TITLE "Completing the Photo Gallery Installer"
!define MUI_FINISHPAGE_TEXT "Windows Photo Gallery has been successfully installed on your computer.$\r$\n$\r$\nClick Finish to close the installer."
!define MUI_FINISHPAGE_RUN "$INSTDIR\WindowsPhotoGallery.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch Windows Photo Gallery"
!insertmacro MUI_PAGE_FINISH

; --- Uninstaller pages -------------------------------------------------------
; Use the same Vista-style artwork as the installer, but give the uninstaller
; its own title/text and separate asset filenames so a red-minus icon/artwork
; can be dropped in later without changing the script.
!define MUI_UNABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "Welcome to the Photo Gallery Uninstaller"
!define MUI_WELCOMEPAGE_TEXT "This wizard will remove Windows Photo Gallery from your computer.$\r$\n$\r$\nYour personal pictures, videos, and Photo Gallery library database will not be removed.$\r$\n$\r$\nClick Next to continue."
!insertmacro MUI_UNPAGE_WELCOME

!define MUI_PAGE_HEADER_TEXT "Remove Windows Photo Gallery?"
!define MUI_PAGE_HEADER_SUBTEXT "Photo Gallery Uninstaller is ready to remove Windows Photo Gallery from your computer."
!define MUI_UNCONFIRMPAGE_TEXT_TOP "Photo Gallery Uninstaller is ready to remove Windows Photo Gallery and its installed components from your computer.$\r$\n$\r$\nClick Uninstall to continue."
!insertmacro MUI_UNPAGE_CONFIRM

!define MUI_PAGE_HEADER_TEXT "Removing Windows Photo Gallery"
!define MUI_PAGE_HEADER_SUBTEXT "Please wait while Photo Gallery Uninstaller removes Windows Photo Gallery from your computer."
!insertmacro MUI_UNPAGE_INSTFILES

!define MUI_FINISHPAGE_TITLE "Photo Gallery has been removed"
!define MUI_FINISHPAGE_TEXT "Windows Photo Gallery has been successfully removed from your computer.$\r$\n$\r$\nYour personal pictures and videos have not been changed.$\r$\n$\r$\nClick Finish to close the uninstaller."
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; ============================================================================
; Helpers
; ============================================================================

; Patch one byte after verifying the exact original byte.
; Usage: !insertmacro PatchByte "$INSTDIR\file.dll" 0x1234 0x74 0xEB
!macro PatchByte FILE OFFSET EXPECTED REPLACEMENT
    ClearErrors
    FileOpen $9 "${FILE}" a
    ${If} ${Errors}
        MessageBox MB_ICONSTOP|MB_OK "Setup could not open ${FILE} for patching."
        Abort
    ${EndIf}

    FileSeek $9 ${OFFSET} SET
    FileReadByte $9 $8
    ${If} $8 <> ${EXPECTED}
        FileClose $9
        MessageBox MB_ICONSTOP|MB_OK "Compatibility patch signature mismatch in ${FILE} at offset ${OFFSET}.$\r$\n$\r$\nExpected byte: ${EXPECTED}$\r$\nFound byte: $8$\r$\n$\r$\nSetup will stop rather than patch an unknown file."
        Abort
    ${EndIf}

    FileSeek $9 ${OFFSET} SET
    FileWriteByte $9 ${REPLACEMENT}
    FileClose $9
!macroend

; Verify that one file exists. Sets SourceOK=0 and records a readable error.
!macro RequireFile RELATIVE
    ${IfNot} ${FileExists} "$VistaSource\${RELATIVE}"
        StrCpy $SourceOK 0
        StrCpy $SourceError "Missing file: ${RELATIVE}"
    ${EndIf}
!macroend

Function ValidateSource
    StrCpy $SourceOK 1
    StrCpy $SourceError ""

    !insertmacro RequireFile "WindowsPhotoGallery.exe"
    !insertmacro RequireFile "ImagingDevices.exe"
    !insertmacro RequireFile "ImagingEngine.dll"
    !insertmacro RequireFile "PhotoAcq.dll"
    !insertmacro RequireFile "PhotoBase.dll"
    !insertmacro RequireFile "PhotoCinematic.dll"
    !insertmacro RequireFile "PhotoClassic.dll"
    !insertmacro RequireFile "PhotoLibraryDatabase.dll"
    !insertmacro RequireFile "PhotoLibraryMain.dll"
    !insertmacro RequireFile "PhotoLibraryResources.dll"
    !insertmacro RequireFile "PhotoViewer.dll"
    !insertmacro RequireFile "PhotoVoyager.dll"
    !insertmacro RequireFile "VideoViewer.dll"
    !insertmacro RequireFile "VideoMediaHandler.dll"
    !insertmacro RequireFile "Pipeline.dll"
    !insertmacro RequireFile "WMM2CLIP.dll"
    !insertmacro RequireFile "ChangeMetadata.wav"
    !insertmacro RequireFile "sqlceoledb30.dll"
    !insertmacro RequireFile "sqlceqp30.dll"
    !insertmacro RequireFile "sqlcese30.dll"
    !insertmacro RequireFile "sqlceer30EN.dll"

    !insertmacro RequireFile "en-US\ImagingDevices.exe.mui"
    !insertmacro RequireFile "en-US\PhotoAcq.dll.mui"
    !insertmacro RequireFile "en-US\PhotoCinematic.dll.mui"
    !insertmacro RequireFile "en-US\PhotoClassic.dll.mui"
    !insertmacro RequireFile "en-US\PhotoLibraryResources.dll.mui"
    !insertmacro RequireFile "en-US\PhotoViewer.dll.mui"
    !insertmacro RequireFile "en-US\PhotoVoyager.dll.mui"
    !insertmacro RequireFile "en-US\VideoViewer.dll.mui"
    !insertmacro RequireFile "en-US\WindowsPhotoGallery.exe.mui"

    ${If} $SourceOK == 0
        Return
    ${EndIf}

    ; IMPORTANT: LogicLib == / != are string comparisons. GetDLLVersion and
    ; FileReadByte return numeric values, so all numeric checks below use
    ; = / <> to correctly compare decimal results against hex constants.
    ; Exact known x64 Vista versions for the three critical patch/launch files.
    ClearErrors
    GetDLLVersion "$VistaSource\WindowsPhotoGallery.exe" $0 $1
    ${If} ${Errors}
        StrCpy $SourceOK 0
        StrCpy $SourceError "Could not read the version of WindowsPhotoGallery.exe"
        Return
    ${EndIf}
    ${If} $0 <> 0x00060000
    ${OrIf} $1 <> 0x17704002
        StrCpy $SourceOK 0
        StrCpy $SourceError "Unsupported WindowsPhotoGallery.exe. Expected version 6.0.6000.16386."
        Return
    ${EndIf}

    ClearErrors
    GetDLLVersion "$VistaSource\PhotoLibraryMain.dll" $0 $1
    ${If} ${Errors}
        StrCpy $SourceOK 0
        StrCpy $SourceError "Could not read the version of PhotoLibraryMain.dll"
        Return
    ${EndIf}
    ${If} $0 <> 0x00060000
    ${OrIf} $1 <> 0x17724655
        StrCpy $SourceOK 0
        StrCpy $SourceError "Unsupported PhotoLibraryMain.dll. Expected version 6.0.6002.18005."
        Return
    ${EndIf}

    ClearErrors
    GetDLLVersion "$VistaSource\PhotoLibraryDatabase.dll" $0 $1
    ${If} ${Errors}
        StrCpy $SourceOK 0
        StrCpy $SourceError "Could not read the version of PhotoLibraryDatabase.dll"
        Return
    ${EndIf}
    ${If} $0 <> 0x00060000
    ${OrIf} $1 <> 0x17714650
        StrCpy $SourceOK 0
        StrCpy $SourceError "Unsupported PhotoLibraryDatabase.dll. Expected version 6.0.6001.18000."
        Return
    ${EndIf}

    ; Exact known x64 sizes of the critical files.
    FileOpen $2 "$VistaSource\WindowsPhotoGallery.exe" r
    FileSeek $2 0 END $3
    FileClose $2
    ${If} $3 <> 139264
        StrCpy $SourceOK 0
        StrCpy $SourceError "WindowsPhotoGallery.exe has an unexpected size. Please use the supported Vista x64 file set."
        Return
    ${EndIf}

    FileOpen $2 "$VistaSource\PhotoLibraryMain.dll" r
    FileSeek $2 0 END $3
    FileClose $2
    ${If} $3 <> 1354240
        StrCpy $SourceOK 0
        StrCpy $SourceError "PhotoLibraryMain.dll has an unexpected size. Please use the supported Vista x64 file set."
        Return
    ${EndIf}

    FileOpen $2 "$VistaSource\PhotoLibraryDatabase.dll" r
    FileSeek $2 0 END $3
    FileClose $2
    ${If} $3 <> 679936
        StrCpy $SourceOK 0
        StrCpy $SourceError "PhotoLibraryDatabase.dll has an unexpected size. Please use the supported Vista x64 file set."
        Return
    ${EndIf}

    ; Verify original patch signatures before we copy anything.
    FileOpen $2 "$VistaSource\PhotoLibraryMain.dll" r
    FileSeek $2 0x84F7A SET
    FileReadByte $2 $3
    ${If} $3 <> 0x79
        FileClose $2
        StrCpy $SourceOK 0
        StrCpy $SourceError "PhotoLibraryMain.dll is not the expected unmodified Vista file (signature 1 mismatch)."
        Return
    ${EndIf}
    FileSeek $2 0x84F8D SET
    FileReadByte $2 $3
    FileClose $2
    ${If} $3 <> 0x74
        StrCpy $SourceOK 0
        StrCpy $SourceError "PhotoLibraryMain.dll is not the expected unmodified Vista file (signature 2 mismatch)."
        Return
    ${EndIf}

    FileOpen $2 "$VistaSource\PhotoLibraryDatabase.dll" r
    FileSeek $2 0x71827 SET
    FileReadByte $2 $3
    FileReadByte $2 $4
    FileReadByte $2 $5
    FileReadByte $2 $6
    FileReadByte $2 $7
    FileReadByte $2 $8
    FileClose $2
    ${If} $3 <> 0x0F
    ${OrIf} $4 <> 0x84
    ${OrIf} $5 <> 0xCF
    ${OrIf} $6 <> 0x00
    ${OrIf} $7 <> 0x00
    ${OrIf} $8 <> 0x00
        StrCpy $SourceOK 0
        StrCpy $SourceError "PhotoLibraryDatabase.dll is not the expected unmodified Vista file (video patch signature mismatch)."
        Return
    ${EndIf}
FunctionEnd

; Welcome remains the first wizard page. If source files are not already in a
; VistaFiles folder beside Setup.exe, clicking Next opens a normal folder picker.
Function WelcomeLeave
    ${If} $VistaSource == ""
        StrCpy $VistaSource "$EXEDIR\VistaFiles"
    ${EndIf}

source_try:
    Call ValidateSource
    ${If} $SourceOK == 1
        Return
    ${EndIf}

    nsDialogs::SelectFolderDialog "Select your Windows Vista x64 Windows Photo Gallery folder" "$EXEDIR"
    Pop $VistaSource
    ${If} $VistaSource == "error"
        StrCpy $VistaSource ""
        Abort
    ${EndIf}

    Call ValidateSource
    ${If} $SourceOK != 1
        MessageBox MB_ICONEXCLAMATION|MB_RETRYCANCEL "$SourceError$\r$\n$\r$\nSelect the folder containing the supported original Vista x64 Photo Gallery files." IDRETRY source_try IDCANCEL source_cancel
    ${EndIf}
    Return

source_cancel:
    StrCpy $VistaSource ""
    Abort
FunctionEnd

Function .onInit
    SetShellVarContext current
    ${IfNot} ${RunningX64}
        MessageBox MB_ICONSTOP|MB_OK "This development build supports 64-bit Windows only."
        Abort
    ${EndIf}

    ; WindowsPhotoGallery.exe and the Vista COM servers are x64. NSIS itself
    ; is a 32-bit process, so explicitly write/read the 64-bit registry view.
    SetRegView 64

    ; Prefer an optional VistaFiles folder beside the installer, but do not
    ; require it. WelcomeLeave will show a folder picker if it is absent.
    ${If} ${FileExists} "$EXEDIR\VistaFiles\WindowsPhotoGallery.exe"
        StrCpy $VistaSource "$EXEDIR\VistaFiles"
    ${Else}
        StrCpy $VistaSource ""
    ${EndIf}
FunctionEnd

; ============================================================================
; Install sections
; ============================================================================

Section "Windows Photo Gallery (required)" SEC_CORE
    SectionIn RO
    SetRegView 64

    DetailPrint "Creating installation folders..."
    CreateDirectory "$INSTDIR"
    CreateDirectory "$INSTDIR\en-US"

    DetailPrint "Installing Windows Photo Gallery..."
    CopyFiles /SILENT "$VistaSource\WindowsPhotoGallery.exe" "$INSTDIR\WindowsPhotoGallery.exe"
    CopyFiles /SILENT "$VistaSource\ImagingDevices.exe" "$INSTDIR\ImagingDevices.exe"
    CopyFiles /SILENT "$VistaSource\ImagingEngine.dll" "$INSTDIR\ImagingEngine.dll"
    CopyFiles /SILENT "$VistaSource\PhotoAcq.dll" "$INSTDIR\PhotoAcq.dll"
    CopyFiles /SILENT "$VistaSource\PhotoBase.dll" "$INSTDIR\PhotoBase.dll"
    CopyFiles /SILENT "$VistaSource\PhotoCinematic.dll" "$INSTDIR\PhotoCinematic.dll"
    CopyFiles /SILENT "$VistaSource\PhotoClassic.dll" "$INSTDIR\PhotoClassic.dll"
    CopyFiles /SILENT "$VistaSource\PhotoLibraryDatabase.dll" "$INSTDIR\PhotoLibraryDatabase.dll"
    CopyFiles /SILENT "$VistaSource\PhotoLibraryMain.dll" "$INSTDIR\PhotoLibraryMain.dll"
    CopyFiles /SILENT "$VistaSource\PhotoLibraryResources.dll" "$INSTDIR\PhotoLibraryResources.dll"
    CopyFiles /SILENT "$VistaSource\PhotoViewer.dll" "$INSTDIR\PhotoViewer.dll"
    CopyFiles /SILENT "$VistaSource\PhotoVoyager.dll" "$INSTDIR\PhotoVoyager.dll"
    CopyFiles /SILENT "$VistaSource\VideoViewer.dll" "$INSTDIR\VideoViewer.dll"
    CopyFiles /SILENT "$VistaSource\ChangeMetadata.wav" "$INSTDIR\ChangeMetadata.wav"

    DetailPrint "Installing language resources..."
    CopyFiles /SILENT "$VistaSource\en-US\ImagingDevices.exe.mui" "$INSTDIR\en-US\ImagingDevices.exe.mui"
    CopyFiles /SILENT "$VistaSource\en-US\PhotoAcq.dll.mui" "$INSTDIR\en-US\PhotoAcq.dll.mui"
    CopyFiles /SILENT "$VistaSource\en-US\PhotoCinematic.dll.mui" "$INSTDIR\en-US\PhotoCinematic.dll.mui"
    CopyFiles /SILENT "$VistaSource\en-US\PhotoClassic.dll.mui" "$INSTDIR\en-US\PhotoClassic.dll.mui"
    CopyFiles /SILENT "$VistaSource\en-US\PhotoLibraryResources.dll.mui" "$INSTDIR\en-US\PhotoLibraryResources.dll.mui"
    CopyFiles /SILENT "$VistaSource\en-US\PhotoViewer.dll.mui" "$INSTDIR\en-US\PhotoViewer.dll.mui"
    CopyFiles /SILENT "$VistaSource\en-US\PhotoVoyager.dll.mui" "$INSTDIR\en-US\PhotoVoyager.dll.mui"
    CopyFiles /SILENT "$VistaSource\en-US\VideoViewer.dll.mui" "$INSTDIR\en-US\VideoViewer.dll.mui"
    CopyFiles /SILENT "$VistaSource\en-US\WindowsPhotoGallery.exe.mui" "$INSTDIR\en-US\WindowsPhotoGallery.exe.mui"

    DetailPrint "Preparing the Photo Gallery library..."
    CopyFiles /SILENT "$VistaSource\sqlceoledb30.dll" "$INSTDIR\sqlceoledb30.dll"
    CopyFiles /SILENT "$VistaSource\sqlceqp30.dll" "$INSTDIR\sqlceqp30.dll"
    CopyFiles /SILENT "$VistaSource\sqlcese30.dll" "$INSTDIR\sqlcese30.dll"
    CopyFiles /SILENT "$VistaSource\sqlceer30EN.dll" "$INSTDIR\sqlceer30EN.dll"

    DetailPrint "Configuring Windows Photo Gallery..."
    !insertmacro PatchByte "$INSTDIR\PhotoLibraryMain.dll" 0x84F7A 0x79 0xEB
    !insertmacro PatchByte "$INSTDIR\PhotoLibraryMain.dll" 0x84F8D 0x74 0xEB

    DetailPrint "Finishing Photo Gallery library setup..."
    WriteRegStr   HKCU "Software\Classes\CLSID\{FB4CDF30-A741-421D-BCFA-6CC530D053FB}" "" "Microsoft.SQLLITE.MOBILE.OLEDB.3.0"
    WriteRegDWORD HKCU "Software\Classes\CLSID\{FB4CDF30-A741-421D-BCFA-6CC530D053FB}" "OLEDB_SERVICES" 0xFFFFFFFE
    WriteRegStr   HKCU "Software\Classes\CLSID\{FB4CDF30-A741-421D-BCFA-6CC530D053FB}\InprocServer32" "" "$INSTDIR\sqlceoledb30.dll"
    WriteRegStr   HKCU "Software\Classes\CLSID\{FB4CDF30-A741-421D-BCFA-6CC530D053FB}\InprocServer32" "ThreadingModel" "Both"
    WriteRegStr   HKCU "Software\Classes\CLSID\{FB4CDF30-A741-421D-BCFA-6CC530D053FB}\ProgID" "" "Microsoft.SQLLITE.MOBILE.OLEDB.3.0"
    WriteRegStr   HKCU "Software\Classes\Microsoft.SQLLITE.MOBILE.OLEDB.3.0\CLSID" "" "{FB4CDF30-A741-421D-BCFA-6CC530D053FB}"

    ; Verify the x64 COM registration is visible in the same registry view
    ; that the 64-bit Gallery process will use.
    ClearErrors
    ReadRegStr $0 HKCU "Software\Classes\CLSID\{FB4CDF30-A741-421D-BCFA-6CC530D053FB}\InprocServer32" ""
    ${If} ${Errors}
    ${OrIf} $0 != "$INSTDIR\sqlceoledb30.dll"
        MessageBox MB_ICONSTOP|MB_OK "Setup could not verify the 64-bit SQL Server Compact 3.0 registration.$\r$\n$\r$\nWindows Photo Gallery would not be able to create its library database, so Setup will stop."
        Abort
    ${EndIf}

    WriteRegStr HKCU "${PROJECT_REGKEY}" "InstallDir" "$INSTDIR"

    WriteUninstaller "$INSTDIR\PhotoGalleryUninstaller.exe"
    WriteRegStr   HKCU "${UNINSTALL_REGKEY}" "DisplayName" "Windows Photo Gallery"
    WriteRegStr   HKCU "${UNINSTALL_REGKEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr   HKCU "${UNINSTALL_REGKEY}" "DisplayIcon" "$INSTDIR\WindowsPhotoGallery.exe"
    WriteRegStr   HKCU "${UNINSTALL_REGKEY}" "InstallLocation" "$INSTDIR"
    WriteRegStr   HKCU "${UNINSTALL_REGKEY}" "UninstallString" '$\"$INSTDIR\PhotoGalleryUninstaller.exe$\"'
    WriteRegDWORD HKCU "${UNINSTALL_REGKEY}" "NoModify" 1
    WriteRegDWORD HKCU "${UNINSTALL_REGKEY}" "NoRepair" 1
SectionEnd

Section "Photo Viewer Integration" SEC_VIEWER
    SetRegView 64
    DetailPrint "Configuring Photo Viewer..."
    WriteRegStr HKCU "Software\Classes\CLSID\{32624F4B-F1D5-4877-989E-555640109D2B}" "" "Windows Photo Gallery Viewer Gallery Interface"
    WriteRegStr HKCU "Software\Classes\CLSID\{32624F4B-F1D5-4877-989E-555640109D2B}\InprocServer32" "" "$INSTDIR\PhotoViewer.dll"
    WriteRegStr HKCU "Software\Classes\CLSID\{32624F4B-F1D5-4877-989E-555640109D2B}\InprocServer32" "ThreadingModel" "Apartment"
    WriteRegStr HKCU "Software\Classes\CLSID\{32624F4B-F1D5-4877-989E-555640109D2B}\ProgID" "" "Microsoft.Photos.ViewerGalleryInterface.1"
    WriteRegStr HKCU "Software\Classes\CLSID\{32624F4B-F1D5-4877-989E-555640109D2B}\VersionIndependentProgID" "" "Microsoft.Photos.ViewerGalleryInterface"
    WriteRegStr HKCU "Software\Classes\Microsoft.Photos.ViewerGalleryInterface.1\CLSID" "" "{32624F4B-F1D5-4877-989E-555640109D2B}"
    WriteRegStr HKCU "Software\Classes\Microsoft.Photos.ViewerGalleryInterface\CLSID" "" "{32624F4B-F1D5-4877-989E-555640109D2B}"
    WriteRegStr HKCU "Software\Classes\Microsoft.Photos.ViewerGalleryInterface\CurVer" "" "Microsoft.Photos.ViewerGalleryInterface.1"
    WriteRegDWORD HKCU "${PROJECT_REGKEY}" "ViewerIntegration" 1
SectionEnd

Section "Video Support" SEC_VIDEO
    SetRegView 64

    DetailPrint "Configuring video support..."
    !insertmacro PatchByte "$INSTDIR\PhotoLibraryDatabase.dll" 0x71827 0x0F 0x90
    !insertmacro PatchByte "$INSTDIR\PhotoLibraryDatabase.dll" 0x71828 0x84 0x90
    !insertmacro PatchByte "$INSTDIR\PhotoLibraryDatabase.dll" 0x71829 0xCF 0x90
    !insertmacro PatchByte "$INSTDIR\PhotoLibraryDatabase.dll" 0x7182A 0x00 0x90
    !insertmacro PatchByte "$INSTDIR\PhotoLibraryDatabase.dll" 0x7182B 0x00 0x90
    !insertmacro PatchByte "$INSTDIR\PhotoLibraryDatabase.dll" 0x7182C 0x00 0x90

    DetailPrint "Installing video playback support..."
    CopyFiles /SILENT "$VistaSource\VideoMediaHandler.dll" "$INSTDIR\VideoMediaHandler.dll"
    CopyFiles /SILENT "$VistaSource\Pipeline.dll" "$INSTDIR\Pipeline.dll"
    CopyFiles /SILENT "$VistaSource\WMM2CLIP.dll" "$INSTDIR\WMM2CLIP.dll"

    ; Windows Photo Gallery asks for this COM class when opening a video.
    ; On Vista / a known-good machine it is implemented by VideoMediaHandler.dll.
    DetailPrint "Configuring video playback..."
    WriteRegStr HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}" "" "VideoMediaHandler Class"
    WriteRegStr HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}\InprocServer32" "" "$INSTDIR\VideoMediaHandler.dll"
    WriteRegStr HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}\InprocServer32" "ThreadingModel" "Apartment"
    WriteRegStr HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}\ProgID" "" "VideoMediaHandler.VideoMediaHandler.1"
    WriteRegStr HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}\TypeLib" "" "{2BAFAA8A-5461-4454-A9FB-088144888F44}"
    WriteRegStr HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}\VersionIndependentProgID" "" "VideoMediaHandler.VideoMediaHandler"

    ; Type library registration copied from the known-good Vista-era registration.
    WriteRegStr HKCU "Software\Classes\TypeLib\{2BAFAA8A-5461-4454-A9FB-088144888F44}\1.0" "" "VideoMediaHandler 1.0 Type Library"
    WriteRegStr HKCU "Software\Classes\TypeLib\{2BAFAA8A-5461-4454-A9FB-088144888F44}\1.0\0\win64" "" "$INSTDIR\VideoMediaHandler.dll"
    WriteRegStr HKCU "Software\Classes\TypeLib\{2BAFAA8A-5461-4454-A9FB-088144888F44}\1.0\FLAGS" "" "0"
    WriteRegStr HKCU "Software\Classes\TypeLib\{2BAFAA8A-5461-4454-A9FB-088144888F44}\1.0\HELPDIR" "" "$INSTDIR"

    ; VideoMediaHandler/Pipeline ask for this Movie Maker clip-support class.
    DetailPrint "Finishing video playback setup..."
    WriteRegStr HKCU "Software\Classes\CLSID\{52FD5C49-A63D-45EC-8687-98DA8B7BFE6A}" "" "Video Clips Pix Command Support"
    WriteRegStr HKCU "Software\Classes\CLSID\{52FD5C49-A63D-45EC-8687-98DA8B7BFE6A}\InprocServer32" "" "$INSTDIR\WMM2CLIP.dll"
    WriteRegStr HKCU "Software\Classes\CLSID\{52FD5C49-A63D-45EC-8687-98DA8B7BFE6A}\InprocServer32" "ThreadingModel" "Apartment"

    ; Verify the two COM servers that matter to the playback chain.
    ClearErrors
    ReadRegStr $0 HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}\InprocServer32" ""
    ${If} ${Errors}
    ${OrIf} $0 != "$INSTDIR\VideoMediaHandler.dll"
        MessageBox MB_ICONSTOP|MB_OK "Setup could not verify the 64-bit Vista Video Media Handler registration.$\r$\n$\r$\nVideo playback would not work, so Setup will stop."
        Abort
    ${EndIf}

    ClearErrors
    ReadRegStr $0 HKCU "Software\Classes\CLSID\{52FD5C49-A63D-45EC-8687-98DA8B7BFE6A}\InprocServer32" ""
    ${If} ${Errors}
    ${OrIf} $0 != "$INSTDIR\WMM2CLIP.dll"
        MessageBox MB_ICONSTOP|MB_OK "Setup could not verify the 64-bit Vista video clip support registration.$\r$\n$\r$\nVideo playback would not work, so Setup will stop."
        Abort
    ${EndIf}

    WriteRegDWORD HKCU "${PROJECT_REGKEY}" "VideoFix" 1
    WriteRegDWORD HKCU "${PROJECT_REGKEY}" "VideoPlaybackSupport" 1
SectionEnd

Section "Start Menu Shortcut" SEC_STARTMENU
    DetailPrint "Creating Start Menu shortcut..."
    CreateShortCut "$SMPROGRAMS\Windows Photo Gallery.lnk" "$INSTDIR\WindowsPhotoGallery.exe" "" "$INSTDIR\WindowsPhotoGallery.exe" 0
SectionEnd

Section /o "Desktop Shortcut" SEC_DESKTOP
    DetailPrint "Creating Desktop shortcut..."
    CreateShortCut "$DESKTOP\Windows Photo Gallery.lnk" "$INSTDIR\WindowsPhotoGallery.exe" "" "$INSTDIR\WindowsPhotoGallery.exe" 0
SectionEnd

; Component descriptions shown in the MUI2 description box.
LangString DESC_SEC_CORE      ${LANG_ENGLISH} "Installs Windows Photo Gallery and the compatibility components required to run it on supported versions of Windows."
LangString DESC_SEC_VIEWER    ${LANG_ENGLISH} "Enables Windows Photo Gallery to open pictures with its original Photo Viewer."
LangString DESC_SEC_VIDEO     ${LANG_ENGLISH} "Enables video discovery and playback in Windows Photo Gallery."
LangString DESC_SEC_STARTMENU ${LANG_ENGLISH} "Creates a Windows Photo Gallery shortcut in the Start Menu."
LangString DESC_SEC_DESKTOP   ${LANG_ENGLISH} "Creates a Windows Photo Gallery shortcut on your Desktop."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CORE} $(DESC_SEC_CORE)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_VIEWER} $(DESC_SEC_VIEWER)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_VIDEO} $(DESC_SEC_VIDEO)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_STARTMENU} $(DESC_SEC_STARTMENU)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DESKTOP} $(DESC_SEC_DESKTOP)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ============================================================================
; Uninstaller
; ============================================================================

Section "Uninstall"
    SetShellVarContext current
    SetRegView 64

    Delete "$SMPROGRAMS\Windows Photo Gallery.lnk"
    Delete "$DESKTOP\Windows Photo Gallery.lnk"

    ; Remove our Photo Viewer override only if it still points to this install.
    ReadRegStr $0 HKCU "Software\Classes\CLSID\{32624F4B-F1D5-4877-989E-555640109D2B}\InprocServer32" ""
    ${If} $0 == "$INSTDIR\PhotoViewer.dll"
        DeleteRegKey HKCU "Software\Classes\CLSID\{32624F4B-F1D5-4877-989E-555640109D2B}"
        DeleteRegKey HKCU "Software\Classes\Microsoft.Photos.ViewerGalleryInterface.1"
        DeleteRegKey HKCU "Software\Classes\Microsoft.Photos.ViewerGalleryInterface"
    ${EndIf}

    ; Remove our SQL CE registration only if it still points to this install.
    ReadRegStr $0 HKCU "Software\Classes\CLSID\{FB4CDF30-A741-421D-BCFA-6CC530D053FB}\InprocServer32" ""
    ${If} $0 == "$INSTDIR\sqlceoledb30.dll"
        DeleteRegKey HKCU "Software\Classes\CLSID\{FB4CDF30-A741-421D-BCFA-6CC530D053FB}"
        DeleteRegKey HKCU "Software\Classes\Microsoft.SQLLITE.MOBILE.OLEDB.3.0"
    ${EndIf}

    ; Remove our video playback COM registrations only if they still point to this install.
    ReadRegStr $0 HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}\InprocServer32" ""
    ${If} $0 == "$INSTDIR\VideoMediaHandler.dll"
        DeleteRegKey HKCU "Software\Classes\CLSID\{AD1A096D-8A20-4316-988D-784A58B2F42A}"
    ${EndIf}

    ReadRegStr $0 HKCU "Software\Classes\TypeLib\{2BAFAA8A-5461-4454-A9FB-088144888F44}\1.0\0\win64" ""
    ${If} $0 == "$INSTDIR\VideoMediaHandler.dll"
        DeleteRegKey HKCU "Software\Classes\TypeLib\{2BAFAA8A-5461-4454-A9FB-088144888F44}"
    ${EndIf}

    ReadRegStr $0 HKCU "Software\Classes\CLSID\{52FD5C49-A63D-45EC-8687-98DA8B7BFE6A}\InprocServer32" ""
    ${If} $0 == "$INSTDIR\WMM2CLIP.dll"
        DeleteRegKey HKCU "Software\Classes\CLSID\{52FD5C49-A63D-45EC-8687-98DA8B7BFE6A}"
    ${EndIf}

    DeleteRegKey HKCU "${PROJECT_REGKEY}"
    DeleteRegKey HKCU "${UNINSTALL_REGKEY}"

    Delete /REBOOTOK "$INSTDIR\en-US\ImagingDevices.exe.mui"
    Delete /REBOOTOK "$INSTDIR\en-US\PhotoAcq.dll.mui"
    Delete /REBOOTOK "$INSTDIR\en-US\PhotoCinematic.dll.mui"
    Delete /REBOOTOK "$INSTDIR\en-US\PhotoClassic.dll.mui"
    Delete /REBOOTOK "$INSTDIR\en-US\PhotoLibraryResources.dll.mui"
    Delete /REBOOTOK "$INSTDIR\en-US\PhotoViewer.dll.mui"
    Delete /REBOOTOK "$INSTDIR\en-US\PhotoVoyager.dll.mui"
    Delete /REBOOTOK "$INSTDIR\en-US\VideoViewer.dll.mui"
    Delete /REBOOTOK "$INSTDIR\en-US\WindowsPhotoGallery.exe.mui"
    RMDir "$INSTDIR\en-US"

    Delete /REBOOTOK "$INSTDIR\WindowsPhotoGallery.exe"
    Delete /REBOOTOK "$INSTDIR\ImagingDevices.exe"
    Delete /REBOOTOK "$INSTDIR\ImagingEngine.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoAcq.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoBase.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoCinematic.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoClassic.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoLibraryDatabase.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoLibraryMain.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoLibraryResources.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoViewer.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoVoyager.dll"
    Delete /REBOOTOK "$INSTDIR\VideoViewer.dll"
    Delete /REBOOTOK "$INSTDIR\VideoMediaHandler.dll"
    Delete /REBOOTOK "$INSTDIR\Pipeline.dll"
    Delete /REBOOTOK "$INSTDIR\WMM2CLIP.dll"
    Delete /REBOOTOK "$INSTDIR\ChangeMetadata.wav"
    Delete /REBOOTOK "$INSTDIR\sqlceoledb30.dll"
    Delete /REBOOTOK "$INSTDIR\sqlceqp30.dll"
    Delete /REBOOTOK "$INSTDIR\sqlcese30.dll"
    Delete /REBOOTOK "$INSTDIR\sqlceer30EN.dll"
    Delete /REBOOTOK "$INSTDIR\PhotoGalleryUninstaller.exe"
    RMDir /REBOOTOK "$INSTDIR"
SectionEnd
