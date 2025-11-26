# 原始时长数据 API 实现总结

## 📋 实现概述

为 MediaInfoKit 添加了两个新 API，允许用户直接获取**原始数值数据**（如时长的毫秒数），而不仅仅是格式化的描述性文本。

## ✨ 新增的 API

### 1. `getRawValue(_:forStreamKey:)` - 通用原始值获取

```swift
func getRawValue(_ valueKey: String, forStreamKey streamKey: String) -> String?
```

**用途**: 获取任意字段的原始数值
**示例**:
```swift
let durationMs = info.getRawValue("Duration", forStreamKey: MIKGeneralStreamKey)
// 返回: "5400000" (字符串形式的毫秒数)

let bitrate = info.getRawValue("BitRate", forStreamKey: MIKVideoStreamKey)
// 返回: "8500000" (字符串形式的 bps)
```

### 2. `getDurationInMilliseconds(_:)` - 便捷时长获取

```swift
func getDurationInMilliseconds(_ streamKey: String) -> NSNumber?
```

**用途**: 直接获取时长（返回 NSNumber）
**示例**:
```swift
let durationMs = info.getDurationInMilliseconds(MIKGeneralStreamKey)
// 返回: NSNumber(5400000)

let seconds = Double(truncating: durationMs) / 1000.0
// 计算秒数
```

## 🔧 技术实现

### 修改的文件

1. **MIKMediaInfo.h** (头文件)
   - 添加两个新方法声明

2. **MIKMediaInfo.mm** (实现文件)
   - 添加私有属性 `mediaInfoHandle` 和 `fileURL`
   - 修改 `initWithFileURL:` 保留 MediaInfo 对象
   - 添加 `dealloc` 方法清理资源
   - 实现两个新方法

3. **MIKFormat.h**
   - 添加 `#import <Foundation/Foundation.h>` 修复编译错误

### 核心变更

#### 之前的实现
```objc
// 初始化后立即关闭和删除 MediaInfo 对象
mi->Close();
delete mi;
```

#### 现在的实现
```objc
// 保留 MediaInfo 对象以支持实时查询
self.mediaInfoHandle = mi;
// 在 dealloc 时才清理
```

### 实现原理

```objc
- (nullable NSString *)getRawValue:(NSString *)valueKey 
                      forStreamKey:(NSString *)streamKey {
    // 1. 获取保留的 MediaInfo 句柄
    MediaInfoDLL::MediaInfo *mi = (MediaInfoDLL::MediaInfo *)self.mediaInfoHandle;
    
    // 2. 将 streamKey 字符串映射到 MediaInfo 的 stream_t 枚举
    MediaInfoDLL::stream_t streamKind = /* 映射逻辑 */;
    
    // 3. 直接调用 MediaInfo 的 Get() 方法获取原始值
    std::basic_string<MediaInfoDLL::Char> rawValue = 
        mi->Get(streamKind, 0, [valueKey mik_WCHARString], MediaInfoDLL::Info_Text);
    
    // 4. 转换为 NSString 返回
    return [[NSString alloc] mik_initWithWCHAR:rawValue.c_str()];
}
```

## 📊 新旧 API 对比

| 需求 | 旧 API | 新 API | 返回示例 |
|------|--------|--------|----------|
| 获取时长文本 | `valueForKey("Duration/String", ...)` | `getRawValue("Duration", ...)` | 旧: "1 h 30 min"<br>新: "5400000" |
| 获取时长数值 | ❌ 不支持 | `getDurationInMilliseconds(...)` | `NSNumber(5400000)` |
| 获取比特率 | `valueForKey("Bit rate", ...)` | `getRawValue("BitRate", ...)` | 旧: "8.50 Mb/s"<br>新: "8500000" |
| 获取分辨率 | `valueForKey("Width", ...)` | `getRawValue("Width", ...)` | 旧: "1 920 pixels"<br>新: "1920" |

## ✅ 优势

1. **获取纯数值**: 可以直接进行数学计算，无需解析文本
2. **向后兼容**: 不影响现有代码，旧 API 继续正常工作
3. **灵活性**: 可以获取任意字段的原始值
4. **便捷性**: 提供专门的时长获取方法

## ⚠️ 注意事项

1. **内存管理**: MediaInfo 对象现在在 MIKMediaInfo 生命周期内保持打开
2. **性能**: 直接查询比从缓存获取稍慢（但通常可忽略）
3. **文件保持打开**: 媒体文件在对象生命周期内可能保持打开状态

## 🚀 使用示例

### 基础使用

```swift
import MediaInfoKit

let info = MIKMediaInfo(fileURL: videoURL)!

// 获取原始时长（毫秒）
if let ms = info.getDurationInMilliseconds(MIKGeneralStreamKey) {
    print("时长: \(ms) 毫秒")
}

// 获取原始比特率
if let bitrate = info.getRawValue("BitRate", forStreamKey: MIKVideoStreamKey) {
    print("比特率: \(bitrate) bps")
}
```

### 完整示例

参见:
- `RAW_VALUE_API_GUIDE.md` - 详细使用指南
- `test_raw_duration.swift` - 测试脚本

## 🔨 编译状态

✅ **编译成功**

⚠️ 有一个警告（不影响功能）:
- `'_UNICODE' macro redefined` - 可以通过删除 MIKMediaInfo.mm 第14行来消除

```bash
# 编译命令
swift build

# 输出
Build complete! (0.73s)
```

## 📝 问题解决

### 问题：为什么 `Duration` 原来返回 nil？

**原因**: 
- 旧实现使用 `mi->Inform()` 方法，只返回格式化文本
- `Inform()` 输出中**不包含**原始数值字段（如 `Duration`）
- 只有格式化的变体（如 `Duration/String`）

**解决方案**:
- 保留 MediaInfo 对象
- 使用 `mi->Get()` 方法直接查询原始值

## 🎯 实现目标达成

✅ 提供了获取原始时长的 API  
✅ 支持获取任意原始数值字段  
✅ 保持向后兼容  
✅ 编译通过  
✅ 提供了完整文档和示例  

---

**实现日期**: 2025-11-26  
**作者**: Antigravity AI Assistant  
**版本**: MediaInfoKit v1.1 (添加原始值支持)
