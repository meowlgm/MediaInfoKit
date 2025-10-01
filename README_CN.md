# MediaInfoKit for macOS 10.13+

![示例截图](./images/screen_samples.png)

## 介绍

MediaInfoKit 是一个简单的 MediaInfo 库在 macOS 应用程序中的高级封装。

该框架已更新以支持 macOS 10.13 (High Sierra) 及更高版本，并与 Swift 6 和 Apple Silicon 兼容。该项目使用 ARC 和 Cocoa。

本仓库包含 MediaInfoKit 和两个示例（一个用 Objective-C 编写，另一个用 Swift 编写）。

## 什么是 MediaInfo？

**MediaInfo** 是一个便捷的统一显示视频和音频文件最相关技术和标签数据的工具。

#### MediaInfo 数据显示包括：

* 容器：格式、配置文件、格式的商业名称、持续时间、总比特率、写入应用程序和库、标题、作者、导演、专辑、轨道编号、日期、持续时间...
* 视频：格式、编解码器 ID、宽高比、帧率、比特率、色彩空间、色度抽样、位深度、扫描类型、扫描顺序...
* 音频：格式、编解码器 ID、采样率、声道、位深度、语言、比特率...
* 文本：格式、编解码器 ID、字幕语言...
* 章节：章节数量、章节列表...

##### MediaInfo 数据支持的格式包括：

* 容器：MPEG-4、QuickTime、Matroska、AVI、MPEG-PS（包括未受保护的 DVD）、MPEG-TS（包括未受保护的蓝光）、MXF、GXF、LXF、WMV、FLV、Real...
* 标签：Id3v1、Id3v2、Vorbis 注释、APE 标签...
* 视频：MPEG-1/2 视频、H.263、MPEG-4 Visual（包括 DivX、XviD）、H.264/AVC、Dirac...
* 音频：MPEG 音频（包括 MP3）、AC3、DTS、AAC、Dolby E、AES3、FLAC...
* 字幕：CEA-608、CEA-708、DTVCC、SCTE-20、SCTE-128、ATSC/53、CDP、DVB 字幕、图文电视、SRT、SSA、ASS、SAMI...

## 如何使用

框架基于仅一个名为 `MIKMediaInfo` 的类。该类允许您通过字典在常数时间内访问元数据，它还允许您获取由 MediaInfoLib 创建的原始有序元数据列表。

Swift 代码示例：（Objective-C 版本类似）

```swift
// 为指定文件创建 MIKMediaInfo 实例

let bundle = Bundle.main
guard let movieURL = bundle.url(forResource: "movie", withExtension: "mov") else {
    fatalError("找不到电影文件。")
}

guard let info = MIKMediaInfo(fileURL: movieURL) else {
    fatalError("MediaInfoLib 无法读取电影文件。")
}


// 在常数时间内获取键的单个值

let value = info.valueForKey(MIKCompleteNameKey, streamKey: MIKGeneralStreamKey)


// 在常数时间内获取索引处的单个值

let value = info.valueAtIndex(2, forStreamKey: MIKGeneralStreamKey)


// 保持原始顺序枚举所有值

info.enumerateOrderedValuesForStreamKey(MIKVideoStreamKey) { key, value in
    print("\(key) : \(value)")
}


// 以指定格式导出所有信息

let exportExt = MIKMediaInfo.extensionForFormat(.JSON)
let exportURL = movieURL.appendingPathExtension(exportExt)

if info.writeAsFormat(.JSON, toURL: exportURL) {
    print("文件已成功写入")
}
```

## 安装

由于框架包含动态库，因此您不能通过使用 cocoapods 安装 MediaInfoKit。

您可以简单地将 MediaInfoKit 添加为 git 子模块，然后将 MediaInfoKit.xcodeproj 文件拖到您的 Xcode 项目中，并将 MediaInfoKit.xcodeproj 添加为目标的依赖项。

您需要使用 Apple 开发者账户签署 MediaInfoKit，才能成功编译。


## 项目更新信息

本项目是从原始的 MediaInfoKit 项目更新而来，主要做了以下改变：

1. 更新了最低部署目标到 macOS 10.13 (High Sierra)
2. 更新了 Swift 代码到 Swift 6 语法
3. 更新了 MediaInfo 库到最新版本
4. 添加了对 Apple Silicon (arm64) 的支持

## 许可证

MediaInfoKit 根据 MIT 许可证发布。有关更多信息，请参阅 LICENSE 文件。 