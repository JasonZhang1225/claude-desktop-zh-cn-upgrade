@echo off
setlocal EnableExtensions

echo ============================================
echo   Claude Desktop 补丁 - 更新检查开关
echo ============================================
echo.
echo 当前状态：
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$v=[Environment]::GetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK','User'); if ($v -match '^(1|true|TRUE|yes|YES|y|Y)$') { Write-Host '  补丁更新检查：已禁用' -ForegroundColor Yellow } else { Write-Host '  补丁更新检查：已允许（默认）' -ForegroundColor Green }"
echo.
echo 按 Y 禁用补丁更新检查（以后运行补丁脚本不再提示有新版）
echo 按 N 允许补丁更新检查（恢复默认）
echo.

set /p choice=请输入 [Y/N]:
if /i "%choice%"=="Y" goto disable
if /i "%choice%"=="N" goto allow
echo 输入无效，未做更改。
goto done

:disable
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK','1','User')"
echo.
echo 已禁用补丁更新检查。
goto done

:allow
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK',$null,'User')"
echo.
echo 已允许补丁更新检查。
goto done

:done
echo.
echo 注意：新开的窗口才会读到新设置。
pause
exit /b 0
