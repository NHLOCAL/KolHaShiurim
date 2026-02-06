## Windows: UTF-8 safe reads and writes (Hebrew-safe)

On Windows, always force UTF-8 for both input and console output when reading files, and be explicit about UTF-8 when writing files. This prevents mojibake (broken Hebrew text), especially with Windows PowerShell 5.1 defaults.

### Read files (always use this pattern)

```powershell
powershell.exe -NoProfile -Command "[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new(); Get-Content -LiteralPath 'PATH/TO/FILE' -Raw -Encoding UTF8"
```

Rules:

* Do not use `Get-Content` without `-Encoding UTF8` for project source files.
* Always set `[Console]::OutputEncoding` to UTF-8 before printing file contents.
* Prefer `-Raw` when you need the whole file as one string.