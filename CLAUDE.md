# CLAUDE.md — 给后续 AI 协作者的项目备忘

> 这是 Claude Desktop 中文汉化补丁的内部工作备忘。面向后续接手的 AI 协作者（Claude Code / OpenCode 等），浓缩机制、关键改动、历史教训与工作流约定。用户面向的说明见 [README.md](README.md)。

## 项目本质

对 Anthropic Claude Desktop（Electron 应用）做中文汉化补丁。不重新编译，而是**打补丁注入**到已安装的 `/Applications/Claude.app`（macOS）或 `%LocalAppData%\AnthropicClaude\app-*`（Windows）：

- 替换前端 i18n locale 文件（`zh-CN.json` 等）+ 注册中文到语言白名单
- 替换 `app.asar` 内硬编码字符串（菜单、模型选择器档位、DOM 翻译 hook）
- 注入 DOM 翻译脚本：主进程劫持 `dom-ready`，渲染端用 `TreeWalker` 实时替换可见英文文本节点
- 锁死 locale（改 `requestLocaleChange` 行为，防止 Claude 写回英文）

## 双平台脚本（两套平行实现，共享 resources/ 翻译数据）

- macOS: `scripts/patch_claude_zh_cn.py`（~2475 行）—— 改 `.app` bundle，含 asar 解包/重打包、codesign ad-hoc、清 quarantine
- Windows: `scripts/install_windows.ps1`（~3364 行）—— 改 `.exe` + resources 目录，含 ACL 写权限、注册表自更新开关、CoworkVMService 处理
- 启动器：`install-mac.command` / `install-windows.bat`（+ 4 个辅助 .bat：allowupdate / disableupdate / simpleinstall / uninstallall）
- 翻译数据：`resources/` 下 19 个文件（frontend-zh-CN/TW/HK.json + hardcoded 变体 + desktop-zh + statsig + Localizable.strings 等），由 `resources/release.json` 标版本号

## 关键改动（2026-07 这次工作落地的）

基底是 `JasonZhang1225/claude-desktop-zh-cn-upgrade` fork 的 `2c46729`（1.3.7 之后），本轮在 fork 之上做了：

### 4a — 模型选择器/思考强度档位 "Max" 不再误译

`patch_model_picker_strings`（py 和 ps1 各有）原本把 `name:"Max"` 替换成 `name:"最高"`。模型选择器/思考强度档位的 Max 是品牌词，应保留英文。删除三套语言（zh-CN/TW/HK）的 `name:"Max"→name:"最高"` 替换行；Low/Medium/High/Extra 档位中文译名保留。

### 4b — 移除 30ms DOM 翻译 debounce（消除英文闪现）

DOM 翻译 hook 原本用 `new MutationObserver(()=>{clearTimeout(...);setTimeout(T,30)})`，30ms 延迟导致英文先渲染一帧再被替换。改为 `new MutationObserver(T)`，微任务级替换，无闪现。py 和 ps1 各一处。

### 4c — 往 en-US.json 注入 placeholder 翻译（绕过 react-intl locale 兜底）

**机制**：Code bundle 和 Cowork composer 的输入框 placeholder 通过 `formatMessage({defaultMessage, id})` 渲染。当 runtime locale 因故仍是 `en-US`，react-intl 从 `en-US.json` 取 id 对应值 → 显示英文，**即使 zh-CN.json 已译、即使 bundle 里 defaultMessage 已被硬编码替换成中文**。

**对策**：`inject_placeholders_into_en_locale`（在 `merge_frontend_locale` 之后调用）**只对一组精选 placeholder key**，把 zh-Pack 的中文翻译覆盖写进 `/Applications/Claude.app/.../en-US.json` 本身。范围严格限定在 `PLACEHOLDER_EN_OVERRIDE_KEYS` 元组（目前 14 个 key），不污染 en-US 其它内容。

**Key 来源**：从 `/Applications/Claude.app/Contents/Resources/ion-dist/assets/v1/*.js` 实地反查 `placeholder: formatMessage({defaultMessage, id})` 提取。新增 placeholder 时必须同时：(1) 在 `resources/frontend-zh-{CN,TW,HK}.json` 有翻译；(2) 把 key 加进 `PLACEHOLDER_EN_OVERRIDE_KEYS`。

**已知 placeholder 分布在多个 bundle**：`c5610fbe3-CrkoaGht.js`（Code bundle）、`index-BSvCx8kl.js`（Cowork composer）、`ca768caa9-DpaJl-88.js` 等。Code bundle 不含 `data-placeholder` 属性（旧版机制已弃用，统一走 `placeholder:` prop + formatMessage）。

### Cowork 欢迎词 / 图标+输入框 / 词元 / 将文件添加到上下文

这些翻译在 `resources/frontend-zh-CN.json`、`desktop-zh-CN.json`、`frontend-hardcoded-zh-CN.json` 里。本轮把它们从一份"工作区未提交"副本里救回并入此仓库（见下"历史教训"）。

## 历史教训（怎么乱的 + 别再这样）

2026-07 这次工作之前，项目在 Mac↔Windows 之间用**复制/剪切文件夹**同步，演化出 3 份独立副本：

- 一份无 git 的 `main`（写 1.3.7，但翻译数据是被官方版冲掉的旧版，**不含新翻译成果**）
- 一份 javaht 上游 git 副本 `win`（1.1.5 base，工作区有新翻译未提交）
- 一份 JasonZhang1225 fork git 副本 `oldes`（1.3.7 base，工作区有新翻译未提交，但脚本被实验性删残缺）

教训：

- **复制文件法同步多台机器 = 必然乱套**。现在已 git 化单源到 fork，Windows 端走 `git pull`，禁止再复制。
- **release.json 标的版本号不可信**——`main` 标 1.3.7 翻译却最旧。判断真实翻译新旧要看 `frontend-zh-CN.json` 的内容/大小/关键词命中（如"词元"），不是 release.json。
- **Py 脚本是 mac 完整版、Ps1 是 win 完整版**，分两套实现，不要假定一处改动另一处自动同步——改 DOM 注入、模型选择器、菜单等横跨 py+ps1 双份地方，要**同时改两处并验证**。

## 工作机制约定（给后续 AI）

### 改脚本逻辑前

- 双平台改动必须同步 py + ps1 两处，grep 确认全改干净，跑 `python3 -c "import ast; ast.parse(open('scripts/patch_claude_zh_cn.py',encoding='utf-8').read())"` 确认 py 语法。
- ps1 的 DOM 注入串是单行巨型 here-string，改它要用精确子串替换。

### 改翻译资源前

- `resources/frontend-zh-{CN,TW,HK}.json` 三套要保持同步（zh-TW/zh-HK 用繁体，术语一致）。
- 用 Python `json.dumps(d, ensure_ascii=False, indent=2)` 改 JSON——本项目 JSON 即此格式，不会污染 diff。
- 新增 i18n key 翻译后，若该 key 是 placeholder 用途，记得加进 `PLACEHOLDER_EN_OVERRIDE_KEYS`。

### 反查 placeholder key 的方法

```sh
# 在已安装的 Claude.app 实地反查
cd /Applications/Claude.app/Contents/Resources/ion-dist/assets/v1
grep -oE 'placeholder:[a-zA-Z?.]+\.formatMessage\(\{defaultMessage:"[^"]*"[^}]*id:"[^"]+"' *.js
# 拿 id 去 i18n/en-US.json 看英文、zh-CN.json 看有无翻译
grep '"<id>"' ../i18n/en-US.json ../i18n/zh-CN.json
```

### 验证

- 跑 `install-mac.command` 对 `/Applications/Claude.app` 实测：placeholder 中文、无英文闪现、菜单中文、Max 显示英文 "Max"。
- `git status` 干净、`git log` / `git tag` 含本次 release。

## 本轮新增改动（1.3.8 系列）

### 4d — Cowork Scheduled 翻译修正 + token 误译

`frontend-zh-CN.json` 中 Cowork 主页的 Scheduled 原译"已安排"，改为"定时任务"。zh-HK/zh-TW 的"排程任務"同步改"定時任務"。zh-HK/zh-TW 的 token 翻译误用"權杖"（OAuth 登录相关），改为"詞元"（LLM 词元）。hardcoded 替换文件同步修正。

### 4e — Windows PS1 脚本 PS5.1 兼容性修复 + 新增 Merge-FrontendLocale

PowrShell 5.1（Win10/11 默认）不认识 `ConvertFrom-Json -AsHashtable`（PS7 才有）。改为 .NET `JavaScriptSerializer` 解析 JSON，同时解决 PS5.1 下 PSCustomObject 大小写不敏感导致的撞键崩溃。

新增 `Merge-FrontendLocale` 函数：逐 key 合并 en-US.json + zh-CN.json，确保 locale 翻译全覆盖（macOS 早有此功能，Windows 一直缺失）。这是 **Customize 等 hardcoded 替换未命中时的关键兜底**——如果没有 merge，前端 key 缺翻译时 react-intl 直接显示英文。

### 4f — 菜单显示选项 4 + 第 7 步进度

Windows 交互菜单（install-windows.bat）补上缺失的 `[4] 自动更新设置` 行。第 7 步（硬编码文本替换）加逐文件进度 `[进度] [1/772] filename.js`，消除无响应感。

### 4g — simpleinstall / uninstallall .bat 修复

- simpleinstall-windows.bat：LF 行尾导致 cmd.exe 崩溃 → 保存为 UTF-8+CRLF+chcp。
- uninstallall-windows.bat：ISO-8859 编码+传无效 `-NoPause` 参数 → 重写 UTF-8+CRLF，删无效参数。
- 日志改写入 `logs/` 目录，文件名含时间戳。

### 4h — Customize 翻译不生效（经验记录）

**现象**：Windows 上 Customize 页面（设置→自定义）标题/文案仍是英文。

**机制分析**：Customize 渲染走了两条路径：
1. **locale JSON 路径**：key `l48+J1nxkN` + `woFlBYmlIQ` 在 `frontend-zh-CN.json` 中已有翻译。但 PS1 此前缺失 `Merge-FrontendLocale`，未与 en-US.json 合并 → 前端 `formatMessage({id})` 时 zh-CN.json 缺 key → react-intl 回退英文。
2. **hardcoded 替换路径**：`label:"Customize"` 在 `frontend-hardcoded-zh-CN.json` 中有条目。但 JS minifier 可能改变了源码格式（如 `label:/* @__PURE__ */ "Customize"`），精确字符串匹配失败 → 静默跳过。

**教训**：hardcoded 替换是脆弱的——JS bundle 打包方式变化（minifier 版本、注释注入、变量重命名）都会破坏精确字符串匹配。通过 `Merge-FrontendLocale` 覆盖 locale JSON 路径是更稳健的方式。Windows 实现隔了一轮才补上 merge 功能，导致 Customize 等翻译在 Windows 上长期未生效。以后新增翻译应先确认 locale JSON（`formatMessage`）路径，hardcoded 替换作为辅助。

## Git 落库约定

- 单一真相源 = 本仓库（fork：`https://github.com/JasonZhang1225/claude-desktop-zh-cn-upgrade`）
- 大版本用 `git tag` 标 `1.3.x`，`resources/release.json` 同步标 release 字段
- force push 已授权覆盖 fork 远程（multiple working copies 都已废弃）。用户让你 git 时，请通过 git 保存修改

## 相邻保留资料

- `_archive/` 本级目录下保留了两个旧翻译快照（`resources-01.20.45`=1.3.7 旧版翻译、`resources-v1`=1.1.5 最旧版），不在 git 内，仅作历史回溯参考。
