# 获取原始时长数据 API 使用指南

## 新增 API

MediaInfoKit 现在提供两个新方法来获取原始数值数据（而不是格式化文本）：

### 1. `getRawValue(_:forStreamKey:)` - 通用原始值获取

获取任意字段的原始数值：

```swift
import MediaInfoKit

guard let info = MIKMediaInfo(fileURL: videoURL) else {
    print("无法读取媒体文件")
    return
}

// 获取原始 Duration（毫秒数）
if let durationMs = info.getRawValue("Duration", forStreamKey: MIKGeneralStreamKey) {
    print("时长（毫秒）: \(durationMs)")
    print("时长（秒）: \(Double(durationMs)! / 1000.0)")
}

// 获取原始 BitRate
if let bitrate = info.getRawValue("BitRate", forStreamKey: MIKVideoStreamKey) {
    print("视频比特率: \(bitrate) bps")
}

// 获取原始 Width 和 Height
if let width = info.getRawValue("Width", forStreamKey: MIKVideoStreamKey) {
    print("视频宽度: \(width) pixels")
}
```

### 2. `getDurationInMilliseconds(_:)` - 便捷时长获取方法

直接获取时长（返回 `NSNumber`）：

```swift
import MediaInfoKit

guard let info = MIKMediaInfo(fileURL: videoURL) else {
    return
}

// 获取总时长
if let durationMs = info.getDurationInMilliseconds(MIKGeneralStreamKey) {
    let seconds = Double(truncating: durationMs) / 1000.0
    let minutes = seconds / 60.0
    let hours = minutes / 60.0
    
    print("时长: \(durationMs) 毫秒")
    print("时长: \(seconds) 秒")
    print("时长: \(minutes) 分钟")
    print("时长: \(hours) 小时")
}

// 获取视频流时长
if let videoDuration = info.getDurationInMilliseconds(MIKVideoStreamKey) {
    print("视频流时长: \(videoDuration) ms")
}

// 获取音频流时长
if let audioDuration = info.getDurationInMilliseconds(MIKAudioStreamKey) {
    print("音频流时长: \(audioDuration) ms")
}
```

## Objective-C 使用示例

```objc
#import <MediaInfoKit/MediaInfoKit.h>

MIKMediaInfo *info = [[MIKMediaInfo alloc] initWithFileURL:videoURL];

// 获取原始时长
NSNumber *durationMs = [info getDurationInMilliseconds:MIKGeneralStreamKey];
if (durationMs) {
    NSLog(@"时长: %@ 毫秒", durationMs);
    
    double seconds = [durationMs doubleValue] / 1000.0;
    NSLog(@"时长: %.2f 秒", seconds);
}

// 获取原始比特率
NSString *bitrate = [info getRawValue:@"BitRate" forStreamKey:MIKVideoStreamKey];
if (bitrate) {
    NSLog(@"比特率: %@ bps", bitrate);
}
```

## 与原有 API 对比

### 原有 API（仅返回格式化文本）

```swift
// 只能获取格式化的描述性文本
let durationFormatted = info.valueForKey("Duration/String", streamKey: MIKGeneralStreamKey)
// 返回: "1 h 30 min" 或 "01:30:00"
```

### 新 API（返回原始数值）

```swift
// 获取原始数值（毫秒）
let durationMs = info.getDurationInMilliseconds(MIKGeneralStreamKey)
// 返回: NSNumber(5400000)

// 或使用通用方法
let durationString = info.getRawValue("Duration", forStreamKey: MIKGeneralStreamKey)
// 返回: "5400000"
```

## 可用的 Stream Keys

- `MIKGeneralStreamKey` - 总体信息
- `MIKVideoStreamKey` - 视频流
- `MIKAudioStreamKey` - 音频流
- `MIKAudio1StreamKey` - 第一音频流
- `MIKAudio2StreamKey` - 第二音频流
- 其他自定义 stream keys

## 可获取的原始数值字段

- `Duration` - 时长（毫秒）
- `BitRate` - 比特率（bps）
- `Width` - 宽度（像素）
- `Height` - 高度（像素）
- `FrameRate` - 帧率
- `SamplingRate` - 采样率（音频）
- `FileSize` - 文件大小（字节）
- 以及其他 MediaInfo 支持的数值字段

## 注意事项

1. **向后兼容**: 新 API 不影响现有代码，现有的方法继续正常工作
2. **内存管理**: MediaInfo 对象现在在 `MIKMediaInfo` 生命周期内保持打开，以支持实时查询
3. **性能**: 直接查询比从预解析的字典获取稍慢，但可以获取原始数值
4. **nil 处理**: 如果字段不存在，方法返回 `nil`

## 完整示例

```swift
import Foundation
import MediaInfoKit

func analyzeVideo(at url: URL) {
    guard let info = MIKMediaInfo(fileURL: url) else {
        print("❌ 无法读取媒体文件")
        return
    }
    
    print("📹 视频分析结果:")
    print("=" * 50)
    
    // 文件信息
    if let filename = info.valueForKey("FileName", streamKey: MIKGeneralStreamKey) {
        print("文件名: \(filename)")
    }
    
    // 原始时长（毫秒）
    if let durationMs = info.getDurationInMilliseconds(MIKGeneralStreamKey) {
        let seconds = Double(truncating: durationMs) / 1000.0
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        print("时长: \(hours)h \(minutes)m \(secs)s (\(durationMs) ms)")
    }
    
    // 原始视频尺寸
    if let width = info.getRawValue("Width", forStreamKey: MIKVideoStreamKey),
       let height = info.getRawValue("Height", forStreamKey: MIKVideoStreamKey) {
        print("分辨率: \(width) x \(height)")
    }
    
    // 原始帧率
    if let frameRate = info.getRawValue("FrameRate", forStreamKey: MIKVideoStreamKey) {
        print("帧率: \(frameRate) fps")
    }
    
    // 原始比特率
    if let bitrate = info.getRawValue("BitRate", forStreamKey: MIKVideoStreamKey) {
        let mbps = Double(bitrate)! / 1_000_000.0
        print("视频比特率: \(String(format: "%.2f", mbps)) Mbps")
    }
    
    print("=" * 50)
}

// 使用示例
let videoURL = URL(fileURLWithPath: "/path/to/video.mp4")
analyzeVideo(at: videoURL)
```

## 输出示例

```
📹 视频分析结果:
==================================================
文件名: video.mp4
时长: 1h 30m 0s (5400000 ms)
分辨率: 1920 x 1080
帧率: 30.000 fps
视频比特率: 8.50 Mbps
==================================================
```
