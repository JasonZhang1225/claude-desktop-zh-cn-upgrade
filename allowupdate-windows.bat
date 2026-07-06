@echo off
setlocal EnableExtensions

echo ============================================
echo   Claude Desktop 补丁 - 允许更新检查
echo ============================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK',$null,'User'); Write-Host '已允许补丁更新检查（恢复默认）。' -ForegroundColor Green"
echo.
echo 注意：新开的窗口才会读到新设置。
pause
exit /b 0
