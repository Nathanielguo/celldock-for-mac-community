# CellDock privileged helper 安全边界

CellDock 的商业许可证体系已从 macOS 客户端移除。本文件仅说明 macOS 为修改系统网络配置而要求的管理员授权；它不限制拨号、接听、录音、短信、eSIM 或 SOCKS5 功能。

## 安装与身份

- App 必须从不可由普通用户替换的 `/Applications/CellDock.app` 运行。
- Helper 位于 `/Library/PrivilegedHelperTools/CellDockNetworkHelper`。
- LaunchDaemon 位于 `/Library/LaunchDaemons/app.celldock.mac.network.helper.plist`。
- Mach service 与 Helper 签名标识均为 `app.celldock.mac.network.helper`。
- VoWiFi runtime 签名标识为 `app.celldock.mac.vowifi.runtime`。
- App、Helper 和 VoWiFi runtime 必须由同一叶证书签名。

安装前，客户端会验证固定 bundle 位置、签名标识、叶证书、文件摘要和 LaunchDaemon 白名单字段。Helper 接受连接时还会验证调用进程 UID、固定 App 路径、签名标识与相同证书。

## 旧版本迁移

首次升级时安装器会停止并移除以下旧服务，再原子安装新的 CellDock 服务：

- `app.mavo.celldock.network.helper`
- `app.mavo.mac.network-helper`

用户数据目录、偏好设置和登录启动项也保留显式的 MaVo → CellDock 单次迁移逻辑。除这些 `legacy` 兼容常量外，当前项目、模块、工具和运行时均使用 CellDock 命名。

## 关键实现

- `Sources/CellDock/NetworkHelperInstaller.swift`
- `Sources/CellDock/NetworkHelperClient.swift`
- `Sources/CellDockNetworkHelper/main.swift`
- `Sources/CellDockNetworkIPC/CellDockNetworkIPC.swift`
- `Sources/CellDockNetworkIPC/CodeSigningPolicy.swift`
- `Resources/app.celldock.mac.network.helper.plist`
- `scripts/build_app.sh`
