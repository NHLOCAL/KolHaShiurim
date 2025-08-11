@echo off

npx repomix "src\lib" --style markdown --remove-comments --remove-empty-lines -i "assets/**,**/core/database/database.g.dart,**/models/app_user.freezed.dart,*.pem,keys/**"

pause

exit

npx repomix "src" --style markdown --remove-comments --remove-empty-lines -i "assets/**,lib/core/database/database.g.dart,*.pem,keys/**"