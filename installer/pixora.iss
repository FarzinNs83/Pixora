; Pixora for Windows - Inno Setup installer script.
; Build the release first (flutter build windows --release), then from the repo root:
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\pixora.iss
; Override the version with /DAppVersion=x.y.z.

#define AppName "Pixora"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#define AppPublisher "Farzin Nasiri"
#define AppURL "https://github.com/FarzinNs83/Pixora-Tool"
#define AppExeName "pixora.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{E05D2B22-C60A-471A-BC98-1B4DDBD7F6A8}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL=https://t.me/feri_ns83
AppUpdatesURL={#AppURL}/releases
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\artifacts\installer
OutputBaseFilename=Pixora-Setup-{#AppVersion}-x64
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\{#AppExeName}
VersionInfoVersion={#AppVersion}
VersionInfoProductName={#AppName}
VersionInfoDescription=Pixora Installer

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "{#BuildDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Optional: place ffmpeg.exe next to the release build to ship native video conversion.
Source: "{#BuildDir}\ffmpeg.exe"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[Code]
// Pixora keeps running in the system tray after its window is closed,
// so stop it before files are replaced or removed.
procedure StopPixora();
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM {#AppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  StopPixora();
  Result := '';
end;

function InitializeUninstall(): Boolean;
begin
  StopPixora();
  Result := True;
end;
