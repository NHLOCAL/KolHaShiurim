; ----------------------------------------------
; Script for Kol HaShiurim Installer
; ----------------------------------------------

[Setup]
AppName=קול השיעורים
AppVerName=קול השיעורים 0.2.0
AppVersion=0.2.0
AppPublisher=זה קל
AppPublisherURL=https://nhlocal.github.io
AppSupportURL=https://nhlocal.github.io
AppUpdatesURL=https://nhlocal.github.io
SetupIconFile="..\src\assets\icons\app_icon.ico"

InfoBeforeFile=Readme.txt

DefaultDirName={autopf}\Kol HaShiurim
DefaultGroupName=קול השיעורים
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
Name: "desktopicon";   Description: "צור קיצור דרך על שולחן העבודה"

[Files]
Source: "Readme.txt"; DestDir: "{tmp}"; Flags: dontcopy
Source: "..\src\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; Tasks: startmenuicon
Name: "{commondesktop}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; Tasks: desktopicon
Name: "{commonstartup}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; WorkingDir: "{app}"; Parameters: "--silent"

[Run]
Filename: "{app}\kol_hashiurim.exe"; Description: "הפעל את קול השיעורים עכשיו"; Flags: nowait postinstall skipifsilent

Filename: "{app}\data\flutter_assets\assets\bin\Volumeid.exe"; \
  Flags: shellexec waituntilterminated skipifsilent; \
  StatusMsg: "מפעיל חלון אישור, אנא אשר כדי להשלים את ההתקנה..."
