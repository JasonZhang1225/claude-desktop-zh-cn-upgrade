@echo off
setlocal EnableExtensions

echo ============================================
echo   Claude Desktop 汉化补丁 - 更新检查开关
echo ============================================
echo.

echo 当前状态：
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$v=[Environment]::GetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK','User'); if ($v -match '^(1|true|TRUE|yes|YES|y|Y)$') { Write-Host '  更新检查：已禁止' -ForegroundColor Yellow } else { Write-Host '  更新检查：未禁止（默认）' -ForegroundColor Green }"
echo.
echo 是否禁止补丁脚本检查新版本？
echo   按 Y — 禁止更新检查（以后打补丁不再提示有新版）
echo   按 N — 取消禁止，恢复更新检查（默认）
echo.

set /p choice=请输入 [Y/N]:
if /i "%choice%"=="Y" goto disable
if /i "%choice%"=="N" goto allow
echo 输入无效，未做更改。
goto done

:disable
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK','1','User')"
echo.
echo 已禁止更新检查。
goto done

:allow
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK',$null,'User')"
echo.
echo 已取消禁止，恢复更新检查。
goto done

:done
echo.
echo 注意：新打开的窗口才会读到新设置。
pause
exit /b 0
