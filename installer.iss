; ----------------------------------------------
; Script for Kol HaShiurim Installer
; ----------------------------------------------

[Setup]
AppName=קול השיעורים
AppVerName=קול השיעורים 0.1.0
AppVersion=0.1.0
AppPublisher=זה קל
AppPublisherURL=https://nhlocal.github.io
AppSupportURL=https://nhlocal.github.io
AppUpdatesURL=https://nhlocal.github.io
SetupIconFile="src\assets\icons\app_icon.ico"

; מציג את Readme.txt לפני מסך הרישיון/Welcome
InfoBeforeFile=README.md

; אם יש License:
; LicenseFile=License.rtf

DefaultDirName={pf}\Kol HaShiurim
DefaultGroupName=קול השיעורים

OutputBaseFilename=KolHaShiurimSetup
Compression=lzma
SolidCompression=yes

ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Languages]
Name: "he"; MessagesFile: "compiler:Languages\Hebrew.isl"


[Tasks]
Name: "startmenuicon"; Description: "צור קיצור דרך בתפריט ההתחלה"
Name: "desktopicon";   Description: "צור קיצור דרך על שולחן העבודה"

[Files]
; הקובץ שמוצג כ־InfoBefore
Source: "README.md"; DestDir: "{tmp}"; Flags: dontcopy
; קבצי התוכנה
Source: "src\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; Tasks: startmenuicon
Name: "{commondesktop}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; Tasks: desktopicon

Name: "{userstartup}\קול השיעורים"; Filename: "{app}\kol_hashiurim.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\kol_hashiurim.exe"; Description: "הפעל את קול השיעורים עכשיו"; Flags: nowait postinstall skipifsilent

Filename: "{app}\data\flutter_assets\assets\bin\Volumeid.exe"; \
  Flags: shellexec waituntilterminated skipifsilent; \
  StatusMsg: "מפעיל חלון אישור, אנא אשר כדי להשלים את ההתקנה..."

