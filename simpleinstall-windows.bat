@echo off
setlocal EnableExtensions

echo ============================================
echo   Claude Desktop 汉化补丁 - 一键安装
echo   简体中文 / Cowork 兼容模式
echo   装完自动禁止 Claude 自动更新（护汉化）
echo ============================================
echo.

echo [1/4] 准备安装文件...
set "CLAUDE_ZH_SOURCE=%~dp0"
set "CLAUDE_ZH_STAGE=%TEMP%\ClaudeDesktopZhCnSimpleInstall"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $src=$env:CLAUDE_ZH_SOURCE; $dst=$env:CLAUDE_ZH_STAGE; if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }; New-Item -ItemType Directory -Path $dst -Force | Out-Null; Copy-Item -LiteralPath (Join-Path $src 'scripts') -Destination $dst -Recurse -Force; Copy-Item -LiteralPath (Join-Path $src 'resources') -Destination $dst -Recurse -Force; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo.
    echo 准备安装文件失败。请把整个 claude-desktop-zh-cn 文件夹复制到本地磁盘后再运行。
    pause
    exit /b 1
)

echo [2/4] 请求管理员权限并安装补丁...
echo      （请在弹出的 UAC 窗口点"是"）
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $script=Join-Path $env:CLAUDE_ZH_STAGE 'scripts\install_windows.ps1'; $p = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$script,'-Action','install','-PatchMode','safe','-Language','zh-CN','-DisableUpdateCheck','-NoPause' -WorkingDirectory $env:CLAUDE_ZH_STAGE -Verb RunAs -PassThru -ErrorAction Stop; $p.WaitForExit(); exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo.
    echo 获取管理员权限失败或已取消。请重新运行本脚本并同意管理员授权。
    pause
    exit /b 1
)

echo [3/4] 禁止 Claude 自动更新（写注册表，CC Switch 切 3P 也冲不掉）...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $script=Join-Path $env:CLAUDE_ZH_STAGE 'scripts\install_windows.ps1'; $p = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$script,'-Action','disable-updates','-Language','zh-CN','-NoPause' -WorkingDirectory $env:CLAUDE_ZH_STAGE -Verb RunAs -PassThru -ErrorAction Stop; $p.WaitForExit(); exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"

echo [4/4] 完成。
echo.
echo Claude Desktop 应已自动重启并显示中文界面。
echo 如果没有自动切换，请在 Claude 左下角账号菜单选 Language -^> 简体中文。
echo Claude 自动更新已禁止，汉化不会被官方更新冲掉。
echo.
timeout /t 3 /nobreak >nul
exit /b 0
