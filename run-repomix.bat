@echo off

npx repomix "torah_shiurim_transfer\lib" --style markdown --remove-comments -i "assets/**,core/database/database.g.dart,*.pem,keys/**"

pause