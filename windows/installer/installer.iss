; SkwirlsAI Windows Installer — Inno Setup Script
; Download Inno Setup from: https://jrsoftware.org/isdl.php
;
; To build: open this file in Inno Setup Compiler and click Build → Compile
; Or from command line: iscc installer.iss

#define MyAppName "SkwirlsAI"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Skwirls Lab"
#define MyAppURL "https://skwirls.ai"
#define MyAppExeName "skwirlsai.exe"

; Path to the Release build output (relative to this .iss file)
#define BuildDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{B7E3F8A1-4D2C-4F5E-9A1B-6C8D7E0F2A3B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\build\installer
OutputBaseFilename=SkwirlsAI-Setup-{#MyAppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; All DLLs
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion

; Data directory (app.so, icudtl.dat, flutter_assets)
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
