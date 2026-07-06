@echo off
setlocal EnableExtensions
chcp 65001 >nul

echo ============================================
echo   Claude Desktop 中文补丁 - 一键卸载
echo   卸载中文补丁 + 恢复原始设置
echo ============================================
echo.

echo [1/3] 准备卸载文件...
set "CLAUDE_ZH_SOURCE=%~dp0"
set "CLAUDE_ZH_STAGE=%TEMP%\ClaudeDesktopZhCnUninstallAll"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $src=$env:CLAUDE_ZH_SOURCE; $dst=$env:CLAUDE_ZH_STAGE; if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }; New-Item -ItemType Directory -Path $dst -Force | Out-Null; Copy-Item -LiteralPath (Join-Path $src 'scripts') -Destination $dst -Recurse -Force; Copy-Item -LiteralPath (Join-Path $src 'resources') -Destination $dst -Recurse -Force; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo.
    echo 准备卸载文件失败。
    pause
    exit /b 1
)

echo [2/3] 获取管理员权限并卸载补丁...
echo     请在弹窗 UAC 窗口中点击"是"。
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $script=Join-Path $env:CLAUDE_ZH_STAGE 'scripts\install_windows.ps1'; $p = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$script,'-Action','uninstall' -WorkingDirectory $env:CLAUDE_ZH_STAGE -Verb RunAs -PassThru -ErrorAction Stop; $p.WaitForExit(); exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo.
    echo 获取管理员权限失败或被取消。
    pause
    exit /b 1
)

echo [3/3] 恢复原始设置...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CLAUDE_ZH_SKIP_UPDATE_CHECK',$null,'User')"

echo.
echo 卸载完成。Claude Desktop 已关闭，请手动重新打开。将恢复英文界面。
echo.
timeout /t 3 /nobreak >nul
exit /b 0
