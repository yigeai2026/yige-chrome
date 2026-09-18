# 0.5.8 / trial.1 发布验证

- 平台：Windows x64；Node.js v24.19.0，运行时与官方归档 SHA256 校验一致。
- 包：`yige-0.5.8-windows-x64-trial.1.zip`
- 大小：44,344,598 字节。
- SHA256：`acf9a50e37ef82c8ed99d64dd82e859c21fa4ffb6683a00f417fcb53fb556ca3`
- BUILD-MANIFEST 源码提交：`288341222cc15875c2007f3732d5837bfcfcb463`（私有开发仓库，普通安装无需访问）。
- ZIP 内 3,689 个文件与构建清单逐项校验。未包含维护机配对文件、数据库、日志或 Git 历史；凭据模式扫描无命中，不等于完整安全审计。
- 功能基线：135 项自动测试、40 工具集成、22 个隔离 Chrome 场景；Windows 云端功能 CI 已通过。
- 对实际 ZIP 解压的 server/extension，使用包内 Node 再验收 22 个隔离 Chrome 场景通过，包含工作窗口、新页、双会话隔离、文件上传与实际下载。
- 包验证首次与安装测试并行运行时，初次快照出现一次 `EXTENSION_TIMEOUT_OUTCOME_UNKNOWN`；独立重跑 22 场景全部通过。根因未确认，作为待跟踪的时序问题保留，不宣称零超时。
- 安装器隔离测试：真实包校验、中文/空格目录、配置备份与保留、skill 安装、重复运行保持配对、旧版/自定义冲突保护、损坏包拒绝。

这些验证不等于所有客户端/登录方式、真实平台页面或用户机器通过。首次安装仍需完成 Chrome 加载、客户端重连、授权和实际读取。升级说明见 UPGRADE.zh-CN.md。云端安装测试见本仓库 Actions。

## 公开发布后的检查

- [v0.5.8-trial.1](https://github.com/yigeai2026/yige-chrome/releases/tag/v0.5.8-trial.1) 已公开发布，保留 trial 预发布标记。
- [全新 Windows 安装 CI](https://github.com/yigeai2026/yige-chrome/actions/runs/35313449337) 通过：从公开 Release 下载并校验，完成隔离安装、配置保护和重复运行检查。
- 私有源码精确构建提交 2883412 的完整 Windows CI 同样通过（135 项测试、40 工具集成、22 场景）。
- 维护端另行匿名下载返回 HTTP 200，ZIP 大小和 SHA256 一致，公开 install.ps1 指向同一固定包。
