#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON="/usr/bin/python3"
PATCHER="$DIR/scripts/patch_claude_zh_cn.py"

if [ ! -x "$PYTHON" ]; then
  PYTHON="$(command -v python3)"
fi

echo "Claude Desktop 中文补丁"
echo "目录: $DIR"
echo

ACTION="${CLAUDE_ACTION:-}"
SKIP_ASAR_PATCH="${CLAUDE_SKIP_ASAR_PATCH:-0}"
if [ -z "$ACTION" ]; then
  echo "请选择操作："
  echo "  [1] 安装中文补丁"
  echo "  [2] 安装中文补丁(安全模式，跳过 app.asar 补丁,第三方模型需借助ccswitch映射)"
  echo "  [3] 恢复原样 / 卸载补丁"
  echo
  read -rp "请输入选项 [1/2/3，默认 1]: " action_choice
  case "${action_choice:-1}" in
    2) ACTION="install"; SKIP_ASAR_PATCH="1" ;;
    3) ACTION="restore" ;;
    *) ACTION="install" ;;
  esac
  echo
fi

if [ "$ACTION" = "uninstall" ]; then
  ACTION="restore"
fi

# Language selection
if [ "$ACTION" = "restore" ]; then
  LANG_CODE=""
elif [ -z "${CLAUDE_LANG:-}" ]; then
  echo "请选择要安装的语言："
  echo "  [1] 简体中文"
  echo "  [2] 繁体中文（中国台湾）"
  echo "  [3] 繁体中文（中国香港）"
  echo
  read -rp "请输入选项 [1/2/3，默认 1]: " choice
  case "${choice:-1}" in
    2) LANG_CODE="zh-TW" ;;
    3) LANG_CODE="zh-HK" ;;
    *) LANG_CODE="zh-CN" ;;
  esac
  echo
else
  LANG_CODE="$CLAUDE_LANG"
fi

SKIP_ASAR_ARG=""
case "$SKIP_ASAR_PATCH" in
  1|true|TRUE|yes|YES|y|Y) SKIP_ASAR_ARG="--skip-asar-patch" ;;
esac

if [ "$ACTION" != "restore" ]; then
  echo "选择的语言: $LANG_CODE"
  if [ -n "$SKIP_ASAR_ARG" ]; then
    echo "安全模式: 跳过 app.asar 补丁"
  fi
  echo
fi

NEEDS_SUDO=1
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    NEEDS_SUDO=0
  fi
done

if [ "$(id -u)" -ne 0 ] && [ "$NEEDS_SUDO" -eq 1 ]; then
  echo "需要管理员权限来替换 /Applications/Claude.app。"
  echo "请按提示输入这台 Mac 的登录密码。"
  echo
  if [ "$ACTION" = "restore" ]; then
    sudo "$PYTHON" "$PATCHER" --user-home "$HOME" --restore --launch "$@"
  else
    sudo "$PYTHON" "$PATCHER" --user-home "$HOME" --lang "$LANG_CODE" --launch ${SKIP_ASAR_ARG:+"$SKIP_ASAR_ARG"} "$@"
  fi
  STATUS=$?
  echo
  echo "按回车退出。"
  read -r _
  exit "$STATUS"
fi

USER_HOME="$HOME"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  USER_HOME="$("$PYTHON" -c 'import pwd, sys; print(pwd.getpwnam(sys.argv[1]).pw_dir)' "$SUDO_USER" 2>/dev/null || true)"
  if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
    USER_HOME="$(eval echo "~$SUDO_USER")"
  fi
fi

if [ "$ACTION" = "restore" ]; then
  "$PYTHON" "$PATCHER" --user-home "$USER_HOME" --restore --launch "$@"
else
  "$PYTHON" "$PATCHER" --user-home "$USER_HOME" --lang "$LANG_CODE" --launch ${SKIP_ASAR_ARG:+"$SKIP_ASAR_ARG"} "$@"
fi

echo
echo "完成。按回车退出。"
read -r _
