; Windows installer for Kol HaShiurim
#ifndef MyAppVersion
  #error Pass /DMyAppVersion with the version from src/pubspec.yaml
#endif

#ifndef MyAppOutputDir
  #define MyAppOutputDir "."
#endif

[Setup]
AppName=קול השיעורים
AppVerName=קול השיעורים {#MyAppVersion}
AppVersion={#MyAppVersion}
AppPublisher=זה קל
AppPublisherURL=https://nhlocal.github.io
AppSupportURL=https://github.com/NHLOCAL/KolHaShiurim/issues
AppUpdatesURL=https://github.com/NHLOCAL/KolHaShiurim/releases
SetupIconFile="..\src\assets\icons\app_icon.ico"
InfoBeforeFile=Readme.txt
LicenseFile=..\LICENSE
DefaultDirName={autopf}\Kol HaShiurim
DefaultGroupName=קול השיעורים
OutputDir={#MyAppOutputDir}
OutputBaseFilename=KolHaShiurimSetup
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

[Languages]
Name: "he"; MessagesFile: "compiler:Languages\Hebrew.isl"

[Tasks]
Name: "startmenuicon"; Description: "צור קיצור דרך בתפריט ההתחלה"
Name: "desktopicon"; Description: "צור קיצור דרך על שולחן העבודה"

[Files]
Source: "..\src\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "LICENSE,THIRD_PARTY_NOTICES.md,README.md,docs\*"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\docs\מדריך שימוש.md"; DestDir: "{app}\docs"; Flags: ignoreversion

[Icons]
Name: "{group}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; Tasks: startmenuicon
Name: "{commondesktop}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; Tasks: desktopicon
Name: "{commonstartup}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; WorkingDir: "{app}"; Parameters: "--silent"

[Run]
Filename: "{app}\kol_hashiurim.exe"; Description: "הפעל את קול השיעורים עכשיו"; Flags: nowait postinstall skipifsilent
