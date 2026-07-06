@echo off
setlocal EnableExtensions
chcp 65001 >nul

echo ============================================
echo   Claude Desktop 中文补丁 - 一键安装
echo   Cowork / 安全模式
echo   装完自动禁止 Claude 自动更新，不影响使用
echo ============================================
echo.

echo [1/4] 准备安装文件...
set "CLAUDE_ZH_SOURCE=%~dp0"
set "CLAUDE_ZH_STAGE=%TEMP%\ClaudeDesktopZhCnSimpleInstall"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $src=$env:CLAUDE_ZH_SOURCE; $dst=$env:CLAUDE_ZH_STAGE; if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }; New-Item -ItemType Directory -Path $dst -Force | Out-Null; Copy-Item -LiteralPath (Join-Path $src 'scripts') -Destination $dst -Recurse -Force; Copy-Item -LiteralPath (Join-Path $src 'resources') -Destination $dst -Recurse -Force; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo.
    echo 准备安装文件失败。请将 claude-desktop-zh-cn 文件夹复制到本地磁盘后再运行。
    pause
    exit /b 1
)

echo [2/4] 获取管理员权限并安装...
echo      请在弹窗 UAC 窗口中点击"是"。
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $script=Join-Path $env:CLAUDE_ZH_STAGE 'scripts\install_windows.ps1'; $p = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$script,'-Action','install','-PatchMode','safe','-Language','zh-CN' -WorkingDirectory $env:CLAUDE_ZH_STAGE -Verb RunAs -PassThru -ErrorAction Stop; $p.WaitForExit(); exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo.
    echo 获取管理员权限失败或被取消。请确保本脚本在本地硬盘运行，并以管理员身份运行。
    pause
    exit /b 1
)

echo [3/4] 禁止 Claude 自动更新（写注册表，CC Switch 和 3P 也改不了）...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $script=Join-Path $env:CLAUDE_ZH_STAGE 'scripts\install_windows.ps1'; $p = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$script,'-Action','disable-updates','-Language','zh-CN' -WorkingDirectory $env:CLAUDE_ZH_STAGE -Verb RunAs -PassThru -ErrorAction Stop; $p.WaitForExit(); exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"

echo [4/4] 完成。
echo.
echo Claude Desktop 应该已显示中文界面。
echo 如果未自动切换，请在右下角用户菜单 Language -^> 选择中文。
echo Claude 自动更新已禁止，不会被官方新版覆盖。
echo.
timeout /t 3 /nobreak >nul
exit /b 0
