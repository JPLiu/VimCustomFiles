chcp 65001 >nul
@echo off

set UpdateTime=%date% %time%

:Push
git add *
git commit -m "%UpdateTime%"
git push origin main
git repack -a -d --depth=250 --window=250
exit

:: vim: set expandtab foldmethod=marker softtabstop=4 shiftwidth=4:
