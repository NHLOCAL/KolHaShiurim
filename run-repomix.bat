@echo off

npx repomix "torah_shiurim_transfer\lib" --style markdown --remove-comments -i "assets/**,core/database/database.g.dart,*.pem,keys/**"

pause

exit

npx repomix "torah_shiurim_transfer" --style markdown --remove-comments -i "assets/**,lib/core/database/database.g.dart,*.pem,keys/**"