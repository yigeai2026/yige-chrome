# 安装一格：给用户和 Agent

## 前提

仅 Windows x64，Chrome 已安装，客户端支持本地 stdio MCP。无需管理员权限。
先读 LICENSE.txt：允许免费使用，禁止修改/转售一格自有代码，第三方权利依其许可证保留。
用户同意后才传 `-AcceptLicense`；不要求密码、API Key、GitHub Token 或远程控制授权。

## 自动下载与配置

1. 从本仓库下载并先检查 `install.ps1`，保存为本地文件；不要把远程响应直接管道送入执行。
2. 运行本地文件。默认解压到 `%LOCALAPPDATA%\Yige\apps`，在本机生成配对，备份并追加 Codex 配置，安装一格 skill。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -AcceptLicense -ConfigureCodex
```

ExecutionPolicy 仅对这个子进程生效，不修改机器或用户的全局策略。若组织策略禁止脚本，停止并交由管理员处理，不规避组织策略。
也可使用环境允许的 PowerShell 7。不要以管理员身份运行。

本脚本固定包版本、URL、长度和 SHA256，先验证再解压执行；不请求仓库登录。
支持 `-PackagePath C:\path\yige-0.5.7-windows-x64-trial.1.zip` 使用提前下载的**同一哈希**文件。
支持 `-InstallRoot D:\Yige\apps` 自选目录；Codex 配置目录依次取显式 `-CodexConfigDirectory`、现有 CODEX_HOME、用户目录 `.codex`。

已有同名配置或 skill 时不覆盖；脚本可能返回“需要合并”并保留文件。Agent 仅核对一格相关段落，提出具体合并，不展示其他服务中的凭据。
脚本生成的配置中会固定本机数据路径；不会把生成的配置提交到 GitHub。
不用 Codex 时省略 `-ConfigureCodex`，把输出的 `client-config/mcp.json` 合并到 Grok 等客户端的 MCP 设置。

## Chrome 端（不能省略）

1. 打开 `chrome://extensions`，启用“开发者模式”。
2. 点击“加载已解压的扩展程序”，选择安装器输出的 `extensionDirectory`。
3. 重连 MCP 或重启 Codex。手动配置的 MCP 不一定在当前会话中立即出现；skill 也可能需要新会话加载。
4. 打开一个无敏感信息的测试页面，点击一格图标，主动共享。
5. Agent 先 `local_chrome_status`，再 `local_chrome_list_shared_tabs`；仅对匹配且已共享标签读取标题。

不要为了省步骤修改 Chrome 配置库、关闭扩展安全机制、读取浏览器存储、抢占其他会话或启动不受共享约束的浏览器路径。
不得把已配置的安装目录发给别人；每台机器的配对信息必须在本机生成。

## 成功判据与失败恢复

分别报告：包校验、文件安装、Codex 配置、skill 安装、扩展加载、MCP 连接、共享页面读取。
在真实 status 中确认核心/扩展/schema 都是 0.5.7；未共享或扩展未加载时明确待用户处理。
连接失败先检查实际状态，不循环 bind/connect，不要求用户绑定额外 Playwright 扩展。
动作超时先复读，不能自动重放点击或提交。验证码由用户处理。
已有同机一格时先结束相关任务再安排升级，不强杀进程，不并行启动不同版本。

安装脚本保留日志式状态输出但不输出密钥。反馈填写 Issues 模板；截图和错误信息先脱敏。
卸载先取消共享、移除客户端的一格配置及本次安装的 skill，再移除 Chrome 扩展。
结束一格进程后可删除解压目录；配置备份和数据目录由用户自行保留或清除，不自动删除。

Codex 配置依据：https://developers.openai.com/codex/mcp/ 。本项目不是 OpenAI、Google 或 xAI 官方产品。
