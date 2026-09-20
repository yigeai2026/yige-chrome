# 0.5.9 / trial.1 发布验证

- 平台：Windows x64；Node.js v24.19.0，node.exe 与 nodejs.org 官方 SHASUMS256.txt 校验一致。
- 包：`yige-0.5.9-windows-x64-trial.1.zip`
- 大小：44,350,461 字节。
- SHA256：`976b3504fd52aac8c33d304bb47b5fe557ac4f27fc2ab0e49356e24538e89360`
- BUILD-MANIFEST 源码提交：`63ce9f5cb110c24efaf0aea34fbdf0c5c75cbaa7`（私有开发仓库，安装不需访问）。
- 实际 ZIP 解压后校验 3,691 个文件的大小和 SHA256，路径检查通过；包内无维护机配对文件、数据库或 Git 历史。
- 功能基线：144 项自动测试、41 工具 MCP 集成、25 个隔离 Chrome 场景通过。
- 使用实际 ZIP 的 server/extension 和包内 Node 再运行 25 个隔离 Chrome 场景通过，包含网站复用、输入保留、同站分组、相同网址去重、自然子标签入组和会话隔离。
- 安装器隔离测试通过：真实 ZIP、中文/空格路径、配置备份与保留、skill 安装、重复运行、配对保留、旧版/自定义配置保护、损坏包拒绝。
- 开发测试首次发现自然子页未入组，修正 Chrome 创建事件尚未提供完整来源信息的时序后通过；没有把首次失败当成通过。

这些验证不代表全部网站、客户端、登录方式或用户机器均通过。首次安装仍需完成 Chrome 加载、客户端重连、窗口授权和实际读取。新增 tabGroups 权限和旧版升级见 [升级说明](UPGRADE.zh-CN.md)。

公开包发布后，还会核对匿名下载哈希和本仓库 Windows 安装 CI。历史 0.5.8 及其验证记录保留在 Git 历史和旧 Release 中。
