# MediaInfoKit - Swift Package 使用指南

## 🎉 成功转换为 Swift Package！

MediaInfoKit 已经成功转换为 Swift Package，包含完整的 MediaInfoLib 和 ZenLib 源码。

## ✨ 特性

- ✅ **源码集成** - 直接包含 MediaInfoLib 和 ZenLib 源码，无需预编译
- ✅ **API 完全兼容** - 保持原有的所有 API 接口不变
- ✅ **易于更新** - 每次 MediaInfoLib 更新时，只需替换 `Sources/MediaInfoLib` 和 `Sources/ZenLib` 目录
- ✅ **跨平台支持** - 支持 macOS 10.13+ (arm64 & x86_64)
- ✅ **零修改源码** - MediaInfoLib 源码保持完全原样，无需任何修改

## 📦 安装

### 方式 1: 添加本地包依赖

在你的 Xcode 项目中：

1. `File` → `Add Package Dependencies...`
2. 点击 `Add Local...`
3. 选择 `MediaInfoKit` 文件夹
4. 点击 `Add Package`

### 方式 2: Package.swift 依赖

在你的 `Package.swift` 中添加：

```swift
dependencies: [
    .package(path: "/path/to/MediaInfoKit")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["MediaInfoKit"]
    )
]
```

### 方式 3: Git 仓库（如果你将其推送到 Git）

```swift
dependencies: [
    .package(url: "https://your-repo/MediaInfoKit.git", branch: "main")
]
```

## 🔧 使用示例

### Swift 代码

```swift
import MediaInfoKit

// 创建 MIKMediaInfo 实例
guard let fileURL = Bundle.main.url(forResource: "video", withExtension: "mp4") else {
    fatalError("找不到文件")
}

guard let mediaInfo = MIKMediaInfo(fileURL: fileURL) else {
    fatalError("无法读取文件")
}

// 获取单个值
if let format = mediaInfo.value(forKey: "Format", streamKey: MIKGeneralStreamKey) {
    print("格式: \(format)")
}

// 枚举所有值（保持原始顺序）
mediaInfo.enumerateOrderedValues(forStreamKey: MIKVideoStreamKey) { key, value in
    print("\(key): \(value)")
}

// 导出为 JSON
let jsonExt = MIKMediaInfo.extension(for: .JSON)
let jsonURL = fileURL.appendingPathExtension(jsonExt)
if mediaInfo.write(as: .JSON, to: jsonURL) {
    print("已导出 JSON")
}
```

### Objective-C 代码

```objc
#import <MediaInfoKit/MediaInfoKit.h>

NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"];
MIKMediaInfo *mediaInfo = [[MIKMediaInfo alloc] initWithFileURL:fileURL];

NSString *format = [mediaInfo valueForKey:@"Format" streamKey:MIKGeneralStreamKey];
NSLog(@"格式: %@", format);
```

## 🔄 更新 MediaInfoLib

当 MediaInfoLib 有新版本时，更新步骤非常简单：

### 步骤 1: 下载新版源码

```bash
# 下载最新的 MediaInfoLib
cd /tmp
git clone --depth 1 https://github.com/MediaArea/MediaInfoLib.git
git clone --depth 1 https://github.com/MediaArea/ZenLib.git
```

### 步骤 2: 替换源码目录

```bash
cd /path/to/MediaInfoKit

# 备份（可选）
mv Sources/MediaInfoLib Sources/MediaInfoLib.backup
mv Sources/ZenLib Sources/ZenLib.backup

# 复制新源码
cp -R /tmp/MediaInfoLib/Source/* Sources/MediaInfoLib/
cp -R /tmp/ZenLib/Source/* Sources/ZenLib/

# 清理编译产物（如果有）
find Sources -name "*.o" -delete
find Sources -name "*.lo" -delete
find Sources -type d -name ".deps" -exec rm -rf {} + 2>/dev/null
find Sources -type d -name ".libs" -exec rm -rf {} + 2>/dev/null
```

### 步骤 3: 重新构建

```bash
swift build
```

就这么简单！**不需要修改任何配置文件，不需要重新编译 framework**。

## 📁 项目结构

```
MediaInfoKit/
├── Package.swift                 # Swift Package 配置文件
├── Sources/
│   ├── MediaInfoKit/            # Objective-C++ wrapper
│   │   ├── include/             # 公共头文件
│   │   │   ├── MediaInfoKit.h
│   │   │   ├── MIKMediaInfo.h
│   │   │   ├── MIKConstants.h
│   │   │   ├── MIKFormat.h
│   │   │   └── NSString+MIK.h
│   │   ├── MIKMediaInfo.mm
│   │   ├── MIKConstants.m
│   │   └── NSString+MIK.mm
│   ├── MediaInfoLib/            # MediaInfo 源码（可直接替换）
│   │   ├── MediaInfo/
│   │   ├── MediaInfoDLL/
│   │   └── ThirdParty/
│   └── ZenLib/                  # ZenLib 源码（可直接替换）
│       └── Source/
├── Tests/
│   └── MediaInfoKitTests/
└── README.md
```

## 🛠️ 构建配置

Package.swift 中的关键配置：

- **平台**: macOS 10.13+
- **语言标准**: C++11
- **编译宏**:
  - `UNICODE` / `_UNICODE` - Unicode 支持
  - `MEDIAINFO_TRACE_NO` - 禁用跟踪功能
  - `MEDIAINFO_GRAPHVIZ_NO` - 禁用 Graphviz 输出
- **排除的文件**:
  - 文档和示例代码
  - 网络流支持 (libmms, libcurl)
  - HTTP_Client (仅适用于 Windows)

## 🔍 与原 Framework 版本的区别

| 特性 | Framework 版本 | Swift Package 版本 |
|-----|--------------|------------------|
| 安装方式 | 手动编译 + 签名 | SPM 自动下载构建 |
| 更新流程 | 重新编译整个 framework | 只需替换源码文件夹 |
| 源码修改 | 需要 | **不需要** |
| 构建时间 | ~5 分钟 | ~40 秒（首次） |
| API 兼容性 | ✅ | ✅ 完全相同 |
| Xcode 集成 | 需要配置 | 自动 |

## ⚠️ 注意事项

1. **首次构建时间**: 第一次构建需要编译约 280 个 C++ 源文件，大约需要 40-50 秒
2. **增量构建**: 后续构建只编译修改的文件，速度很快
3. **磁盘空间**: 完整的源码约 30-40 MB

## 🐛 故障排除

### 构建失败

如果构建失败，尝试清理并重新构建：

```bash
rm -rf .build
swift build
```

### 找不到头文件

确保 `Sources/MediaInfoLib` 和 `Sources/ZenLib` 目录结构正确。

### 链接错误

确保已正确清理所有 `.o` 和 `.lo` 编译产物。

## 📝 许可证

MediaInfoKit 遵循 MIT 许可证。
MediaInfoLib 和 ZenLib 遵循其各自的许可证（BSD-2-Clause）。

## 🙏 鸣谢

- [MediaArea](https://mediaarea.net/) - MediaInfo 和 ZenLib 的开发者
- 原 MediaInfoKit 作者 - Jeremy Vizzini

