# 0.5.9 / trial.1 发布验证

- 平台：Windows x64；Node.js v24.19.0，node.exe 与 nodejs.org 官方 SHASUMS256.txt 校验一致。
- 包：`yige-0.5.9-windows-x64-trial.1.zip`
- 大小：44,350,612 字节。
- SHA256：`2751e4584363a8786aa263edc8fcc7a704ef1dc78cf0870469bd74f7c6bba35e`
- BUILD-MANIFEST 源码提交：`39c906a8d4922d3ded47c832c3202af670b0f4ac`（私有开发仓库，安装不需访问）。
- 实际 ZIP 解压后校验 3,691 个文件的大小和 SHA256，路径检查通过；包内无维护机配对文件、数据库或 Git 历史。
- 功能基线：146 项自动测试、41 工具 MCP 集成、25 个隔离 Chrome 场景通过。
- 使用实际 ZIP 的 server/extension 和包内 Node 再运行 25 个隔离 Chrome 场景通过，包含网站复用、输入保留、同站分组、相同网址去重、自然子标签入组和会话隔离。
- 安装器隔离测试通过：真实 ZIP、中文/空格路径、配置备份与保留、skill 安装、重复运行、配对保留、旧版/自定义配置保护、损坏包拒绝。
- 开发测试首次发现自然子页未入组，修正 Chrome 创建事件尚未提供完整来源信息的时序后通过；没有把首次失败当成通过。

这些验证不代表全部网站、客户端、登录方式或用户机器均通过。首次安装仍需完成 Chrome 加载、客户端重连、窗口授权和实际读取。新增 tabGroups 权限和旧版升级见 [升级说明](UPGRADE.zh-CN.md)。

首轮云端检查在新标签尚无可读 URL 时调用等待工具报 Invalid URL；发布前补充只读元数据等待和两项回归，旧草稿未公开。

## 公开发布检查

- [0.5.9 Release](https://github.com/yigeai2026/yige-chrome/releases/tag/v0.5.9-trial.1) 已公开，保留免费 trial 预发布标记，固定下载及哈希已写入安装器。
- [全新 Windows 安装 CI](https://github.com/yigeai2026/yige-chrome/actions/runs/35486015230) 通过：从公开 Release 下载，校验实际包、隔离安装、配置保护和重复运行。
- 精确源码提交 39c906a 的 Windows 功能 CI 已通过（146 测试、41 工具集成、25 场景）。
- 维护端匿名 asset API 下载 HTTP 200，44,350,612 字节和 SHA256 一致；匿名读取公开 install.ps1 确认固定同一版本和哈希。
- 维护机直连标准 github.com 下载网址曾超时；云端标准下载通过。下载需要用户网络能访问 GitHub，不将本机网络失败算为包验证通过或插件故障。

历史 0.5.8 及其验证记录保留在 Git 历史和旧 Release 中。
