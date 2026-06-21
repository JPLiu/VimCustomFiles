chcp 65001 >nul
@echo off

set HTTP_PROXY=http://127.0.0.1:7890
set HTTPS_PROXY=http://127.0.0.1:7890

:Clone
git clone git@github.com:JPLiu/VimCustomFiles.git
pause
exit

:: vim: set expandtab foldmethod=marker softtabstop=4 shiftwidth=4:
