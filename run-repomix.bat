@echo off

npx repomix "src\lib" --style markdown --remove-comments -i "assets/**,core/database/database.g.dart,*.pem,keys/**"

pause

exit

npx repomix "src" --style markdown --remove-comments -i "assets/**,lib/core/database/database.g.dart,*.pem,keys/**"