# 从旧版升级到 0.5.8

无需新建 GitHub 地址。当前包为 Windows x64 `0.5.8 / trial.1`，入口仍是 https://github.com/yigeai2026/yige-chrome 。

**升级不是只点旧扩展的“重新加载”。** 安装目录按版本区分，客户端入口、Agent skill、Chrome 扩展和后台服务都需要一致。安装器会保护旧配置，不会自动覆盖。

## 给普通用户：把这段发给 Codex

> 请按 https://github.com/yigeai2026/yige-chrome/blob/main/UPGRADE.zh-CN.md 帮我升级一格到 0.5.8。先检查当前安装方式，保留模型和其他 MCP 配置，备份一格配置和 skill。先准备新包，再协调所有使用一格的客户端停止旧任务、切换入口和扩展。需要我操作 Chrome 时一次指导一步。不要强杀其他任务，不要重复安装两份 MCP，最终检查版本和测试页读取。

已有明确的许可接受记录不必重复接受。升级没有自动清空任务数据库；但共享授权、元素 ID、媒体 ID 和会话归属不能跨版本沿用。先记下正在研究的作品链接，不保存凭据。

## Agent 执行步骤

### 1. 确认实际安装

只检查一格的客户端入口、已加载扩展目录、版本和相关进程。不要输出整个客户端配置或其他服务的凭据。

- 确认是否使用本仓库安装器、手工 MCP，或旧 Codex/Grok 插件方式。混合安装不能新增同名入口。
- 记录现有一格 MCP 段落、skill 路径、数据目录和扩展目录，备份这些相关内容。保留旧版安装目录以便回退。
- 不默认将数据目录改成新路径；旧环境设置了 `YIGEAI_DATA_DIR` 时继续使用它。

### 2. 准备新包，暂不修改客户端

检查当前 `install.ps1` 后运行，不传 `-ConfigureCodex`：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -AcceptLicense
```

这会校验固定包、安装到新版本目录并生成本机配对和配置示例，不会启动浏览器或替换旧 MCP/skill。接受许可是传参前提；不要复制他人配对文件。
如果旧环境使用了自定义数据目录，应在此子进程设置原 `YIGEAI_DATA_DIR` 后执行。不要切换到空的数据目录。

记录输出的 `extensionDirectory` 和 `clientExamples`；路径以本机输出为准。

### 3. 停止相关任务，再切换入口和 skill

先让所有使用一格的 Codex、Grok 会话完成或停止浏览器任务，并撤销旧扩展的页面/窗口授权。

- 备份客户端配置，**只更新既有的一格 MCP 项**为新包 `client-config/codex.toml` 或 `mcp.json` 的内容。保留其他 MCP、模型和登录项。
- 安装器管理的 Codex 项有 `BEGIN/END YIGE INSTALLER MCP` 标记；整段替换这一块，保留标记，不追加第二段同名项。
- 将旧的一格 skill 备份到技能搜索目录以外，再替换为新包 `skills/use-local-chrome`。自定义修改先对比保留；不要同时加载两份一格 skill。
- Grok 手工 MCP 同样更新既有入口。Grok 插件安装需要更新对应适配器/skill，不能只改 Codex 配置；不确定安装方式时先明确来源。
- 重新读取配置，验证一格 command/args 指向同一新版本包且数据目录未变。不要把完整配置打印到日志。

若运行首次安装命令收到 `CODEX_CONFIG_NEEDS_REVIEW` / `CODEX_SKILL_NEEDS_REVIEW`，表示旧配置受保护。按上面步骤合并，不删除整个配置目录，不反复重跑。

### 4. 用户切换 Chrome 扩展

按一次一个动作指导用户：

1. Chrome 地址栏打开 `chrome://extensions`，停用旧的一格扩展。
2. “加载已解压的扩展程序”，选择**新包**的 `extensionDirectory`。路径粘贴在文件夹选择窗口，不是 PowerShell。
3. 确认新的一格显示 **0.5.8**，启用状态正常，只保留一份一格处于启用状态。

0.5.8 新增 `downloads` 权限，用于明确发起的任务链接下载，不读取全部下载历史。如果 Chrome 提示新增权限，需要用户确认。

### 5. 重启旧服务与客户端

旧 daemon 可能在客户端退出后仍驻留。**重启 Codex 或重载扩展不保证已切换 daemon。**

普通用户最容易核实的方式：保存工作，正常退出使用一格的客户端，重启 Windows，然后打开 Chrome 和客户端。不要恢复仍指向旧包的 Grok/其他入口。

维护者也可在确认全部相关任务停止后，核对监听本地 32146 端口的进程、完整路径和命令行，仅停止该旧一格 daemon，再重连新入口。不能按 `node.exe` 名称批量结束进程，也不能仅凭端口号认定进程身份。此操作由本机维护任务执行，本安装器不会强杀进程。

### 6. 实际验证

在独立 Chrome 任务窗口打开无敏感信息的测试页，点一格 → **启用此工作窗口（无需逐页共享）**。

Agent 先 `local_chrome_status`，再 `local_chrome_list_shared_tabs`，确认 extension/daemon/schema 为 **0.5.8**、可发现 **40 个工具**，读取匹配测试页的标题和 URL。
然后用户在该窗口新开普通网页，Agent 再发现并只读核验；这次不需单独点共享。不要读取其他任务窗口。

如果仍出现旧版本或工具目录，先核对实际进程和客户端连接缓存；不要连续 bind/connect 或要求绑定 Playwright。页面操作失败先复读状态，不自动重放。

## 回退

先停止相关任务，恢复之前备份的一格客户端段落和 skill，停用新扩展，启用旧目录扩展，并用上面第 5 步协调服务重启。重新授权测试页后核验版本一致。
不要将旧、新扩展同时启用，不要删除数据目录来解决版本冲突。旧包仍保留在 [0.5.7 Release](https://github.com/yigeai2026/yige-chrome/releases/tag/v0.5.7-trial.1)。

无法完成时提交 [问题反馈](https://github.com/yigeai2026/yige-chrome/issues/new?template=bug_report.md)，说明卡在第几步及脱敏后的版本/错误，不上传完整配置、配对文件或私密页面。
