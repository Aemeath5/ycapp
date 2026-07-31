# RustDesk Android Standalone（澎湃 OS 风格）

这是从 `Aemeath5/rustdeskapp` 分离出的 Android 独立工程。它只提供 Android 应用和 APK 构建入口，保留 RustDesk 的 Flutter + Rust 架构，并包含本次完成的 Xiaomi HyperOS / 澎湃 OS 风格移动界面。

## 已分离的范围

- `flutter/android/`：Android 原生层、Gradle、Manifest、无障碍和前台服务。
- `flutter/lib/mobile/`：手机页面及澎湃 OS 主题。
- `flutter/lib/main.dart`：Android 专用入口，不再启动桌面、多窗口、Web 或安装器页面。
- `src/`：生成 `librustdesk.so` 的 Rust 核心。
- `libs/`：Rust 工作区及 protobuf 所需共享库，`hbb_common` 已直接嵌入，不再需要 Git submodule。
- `scripts/`：桥接代码、Rust JNI 库和 APK 的完整构建链。
- `.github/workflows/android-apk.yml`：可手动运行的 APK 构建工作流。

工程中仍保留了少量位于 `flutter/lib/desktop/` 的 Dart 文件。这些不是桌面平台入口，而是上游移动页面直接复用的弹窗、设置项和连接管理组件；删除它们会破坏 Android 编译。Linux、Windows、macOS、iOS 和 Web 的平台工程已经不在此仓库中。

Rust 内核也保留了若干由 `cfg(target_os = ...)` 隔离的上游源码。Android 构建只编译对应目标，但保留这些文件可以避免改写已验证的协议、编解码和 bridge 工作区结构。

## 推荐环境

- Ubuntu 24.04（本地构建脚本目前按 Linux 主机编写）
- Flutter 3.24.5
- Flutter 3.22.3（仅用于生成 bridge；GitHub Actions 会自动处理）
- Dart（由 Flutter 自带）
- Rust 1.75
- JDK 17
- Android SDK 与 Android NDK r28c
- vcpkg baseline `120deac3062162151622ca4860575a33844ba10b`
- `cargo-ndk` 3.1.2
- `cargo-expand` 1.0.95
- `flutter_rust_bridge_codegen` 1.80.1

## 第一次准备

安装 Rust 构建工具：

```bash
rustup toolchain install 1.75
rustup default 1.75
cargo install cargo-ndk --version 3.1.2 --locked
cargo install cargo-expand --version 1.0.95 --locked
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked
```

准备 vcpkg：

```bash
git clone https://github.com/microsoft/vcpkg.git "$HOME/vcpkg"
git -C "$HOME/vcpkg" checkout 120deac3062162151622ca4860575a33844ba10b
"$HOME/vcpkg/bootstrap-vcpkg.sh"
```

设置本机路径：

```bash
export ANDROID_SDK_ROOT=/path/to/android-sdk
export ANDROID_NDK_HOME="$ANDROID_SDK_ROOT/ndk/28.2.13676358"
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
export VCPKG_ROOT="$HOME/vcpkg"
```

Flutter 3.24.4/3.24.5 存在上游 DropdownMenu 状态问题。使用这两个版本时执行一次：

```bash
./scripts/patch-flutter.sh
```

该命令只会修改当前 `flutter` 命令对应的 SDK；重复运行是安全的。

如需完全复现上游的本地 bridge 流程，可先让 Flutter 3.22.3 位于 `PATH` 首位并运行：

```bash
./scripts/generate-bridge.sh
```

脚本会临时使用 `extended_text` 13.0.0，结束时自动还原 `pubspec.yaml` 和 `pubspec.lock`。随后切回 Flutter 3.24.5，再执行下面的 APK 构建命令。

## 构建 APK

现代小米/Redmi/POCO 手机通常使用 ARM64，直接运行：

```bash
./scripts/build-android.sh arm64-v8a
```

脚本会依次：

1. 执行 `flutter pub get` 并生成 Flutter-Rust bridge；
2. 用 vcpkg 构建 Android 原生依赖；
3. 用 `cargo-ndk` 生成 `librustdesk.so`；
4. 打包 Flutter APK；
5. 输出 `dist/rustdesk-hyperos-arm64-v8a.apk`。

也可传入 `armeabi-v7a`、`x86_64` 或 `x86`。每个 ABI 需要单独构建一次。

## GitHub Actions 构建

将工程推送到 GitHub 后，打开 Actions，选择 **Build Android APK**，点击 **Run workflow** 并选择 ABI。完成后可在该次工作流的 Artifacts 下载 APK。默认选择 `arm64-v8a`。

工作流按上游方式分成两个阶段：先用 Flutter 3.22.3 生成 Flutter-Rust bridge，再用 Flutter 3.24.5 和 NDK r28c 构建 APK。

## 正式签名

未提供签名配置时，Release 构建会自动使用 Android 调试证书，方便测试安装。正式发布前，将 keystore 放入 `flutter/android/`，并创建不会提交到 Git 的 `flutter/android/key.properties`：

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=key.jks
```

不要提交 keystore、密码或 `key.properties`。

## 来源与许可

- 上游仓库：`Aemeath5/rustdeskapp`
- 上游基线：`be01eb12e7c7c2ef13257c71f9cb2c1ce628a7ec`
- `hbb_common` 基线：`87b11a795964b00deded250657a63626f2c1efa0`
- 许可：GNU Affero General Public License v3，见 `LICENCE`。
