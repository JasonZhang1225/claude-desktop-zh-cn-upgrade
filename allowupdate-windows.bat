@echo off
setlocal EnableExtensions

echo ============================================
echo   Claude Desktop 汉化补丁 - 恢复更新检查
echo ============================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK',$null,'User'); Write-Host '已恢复更新检查（取消禁止）。' -ForegroundColor Green"
echo.
echo 注意：新打开的窗口才会读到新设置。
pause
exit /b 0
