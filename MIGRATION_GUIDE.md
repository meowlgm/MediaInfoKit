# 从 Framework 迁移到 Swift Package - 迁移指南

## 🎯 好消息：无需修改任何代码！

Swift Package 版本的 MediaInfoKit **100% 兼容**原 Framework 版本的 API。你的现有代码可以直接使用，无需任何修改。

## ✅ API 完全一致性验证

所有公共头文件完全相同：
- ✅ `MediaInfoKit.h` - 主头文件
- ✅ `MIKMediaInfo.h` - 核心类接口
- ✅ `MIKConstants.h` - 常量定义
- ✅ `MIKFormat.h` - 格式枚举
- ✅ `NSString+MIK.h` - 字符串扩展

**所有类、方法、属性、常量完全相同！**

## 📦 迁移步骤

### 步骤 1: 移除旧的 Framework 依赖

在 Xcode 项目中：

1. 选择你的项目 → Target → `General` 标签
2. 在 `Frameworks, Libraries, and Embedded Content` 中找到 `MediaInfoKit.framework`
3. 点击 `-` 删除它

### 步骤 2: 添加 Swift Package

1. `File` → `Add Package Dependencies...`
2. 点击 `Add Local...`
3. 选择 `MediaInfoKit` 文件夹
4. 点击 `Add Package`
5. 在弹出的对话框中选择 `MediaInfoKit` 库

### 步骤 3: 验证导入语句

**无需修改！** 导入语句保持不变：

#### Swift
```swift
import MediaInfoKit  // 完全一样
```

#### Objective-C
```objc
#import <MediaInfoKit/MediaInfoKit.h>  // 完全一样
```

### 步骤 4: 编译运行

就这样！直接编译运行即可。

## 📋 代码示例对比

### Objective-C 代码

**Framework 版本：**
```objc
#import <MediaInfoKit/MediaInfoKit.h>

NSURL *url = [NSURL fileURLWithPath:@"/path/to/video.mp4"];
MIKMediaInfo *info = [[MIKMediaInfo alloc] initWithFileURL:url];
NSString *format = [info valueForKey:@"Format" streamKey:MIKGeneralStreamKey];
```

**Swift Package 版本：**
```objc
#import <MediaInfoKit/MediaInfoKit.h>  // 完全一样

NSURL *url = [NSURL fileURLWithPath:@"/path/to/video.mp4"];
MIKMediaInfo *info = [[MIKMediaInfo alloc] initWithFileURL:url];  // 完全一样
NSString *format = [info valueForKey:@"Format" streamKey:MIKGeneralStreamKey];  // 完全一样
```

### Swift 代码

**Framework 版本：**
```swift
import MediaInfoKit

let url = URL(fileURLWithPath: "/path/to/video.mp4")
let info = MIKMediaInfo(fileURL: url)
let format = info?.value(forKey: "Format", streamKey: MIKGeneralStreamKey)
```

**Swift Package 版本：**
```swift
import MediaInfoKit  // 完全一样

let url = URL(fileURLWithPath: "/path/to/video.mp4")
let info = MIKMediaInfo(fileURL: url)  // 完全一样
let format = info?.value(forKey: "Format", streamKey: MIKGeneralStreamKey)  // 完全一样
```

## 🔍 完整 API 列表（完全保留）

### MIKMediaInfo 类

#### 初始化方法
```objc
- (nullable instancetype)initWithFileURL:(NSURL *)fileURL;
```

#### 属性
```objc
@property(readonly, strong, nonatomic) NSArray<NSString *> *streamKeys;
@property(readonly, strong, nonatomic) NSString *text;
@property(readonly, strong, nonatomic) NSAttributedString *attributedText;
@property(readonly, strong, nonatomic) NSString *xmlText;
@property(readonly, strong, nonatomic, nullable) NSString *jsonText;
@property(readonly, strong, nonatomic, nullable) NSString *plistText;
```

#### 实例方法
```objc
- (NSDictionary<NSString *, NSString *> *)valuesForStreamKey:(NSString *)streamKey;
- (nullable NSString *)valueForKey:(NSString *)valueKey streamKey:(NSString *)streamKey;
- (NSInteger)countOfValuesForStreamKey:(NSString *)streamKey;
- (nullable NSString *)keyAtIndex:(NSInteger)index forStreamKey:(NSString *)streamKey;
- (nullable NSString *)valueAtIndex:(NSInteger)index forStreamKey:(NSString *)streamKey;
- (nullable NSAttributedString *)attributedTextForFormat:(MIKFormat)format;
- (void)enumerateValuesForStreamKey:(NSString *)streamKey block:(MIKStreamEnumerationBlock)block;
- (void)enumerateOrderedValuesForStreamKey:(NSString *)streamKey block:(MIKStreamEnumerationBlock)block;
- (void)enumerateOrderedValues:(MIKStreamEnumerationBlock)block forStreamKey:(NSString *)streamKey;
- (BOOL)writeAsFormat:(MIKFormat)format toURL:(NSURL *)fileURL;
- (BOOL)writeAsFormat:(MIKFormat)format toURL:(NSURL *)fileURL atomically:(BOOL)flag;
```

#### 类方法
```objc
+ (NSString *)extensionForFormat:(MIKFormat)format;
+ (void)setUseInternetConnection:(BOOL)use;
+ (void)setLanguageWithContents:(NSString *)langContents;
```

### MIKConstants 常量

所有常量完全保留：

```objc
// Stream Keys
extern NSString * const MIKGeneralStreamKey;
extern NSString * const MIKVideoStreamKey;
extern NSString * const MIKAudioStreamKey;
extern NSString * const MIKTextStreamKey;
extern NSString * const MIKMenuStreamKey;
extern NSString * const MIKImageStreamKey;

// Info Keys (部分示例)
extern NSString * const MIKCompleteNameKey;
extern NSString * const MIKFormatKey;
extern NSString * const MIKDurationKey;
extern NSString * const MIKBitRateKey;
extern NSString * const MIKWidthKey;
extern NSString * const MIKHeightKey;
// ... 等等
```

### MIKFormat 枚举

```objc
typedef NS_ENUM(NSInteger, MIKFormat) {
    MIKFormatText,
    MIKFormatHTML,
    MIKFormatXML,
    MIKFormatJSON,
    MIKFormatPLIST
};
```

## 🆚 使用体验对比

| 方面 | Framework 版本 | Swift Package 版本 |
|-----|--------------|------------------|
| **API 接口** | ✅ | ✅ **完全相同** |
| **导入方式** | `import MediaInfoKit` | `import MediaInfoKit` ✅ |
| **类名/方法名** | `MIKMediaInfo` | `MIKMediaInfo` ✅ |
| **常量定义** | `MIKGeneralStreamKey` | `MIKGeneralStreamKey` ✅ |
| **安装方式** | 手动拖入 + 签名 | SPM 自动管理 ⚡ |
| **更新流程** | 重新编译 framework | 替换源码文件夹 ⚡ |
| **代码修改** | 无 | 无 ✅ |

## ⚙️ 底层变化（对开发者透明）

虽然 API 完全相同，但底层有这些改进：

### ✅ 优点

1. **自动依赖管理** - SPM 自动处理所有依赖
2. **源码透明** - 可以直接查看和调试 MediaInfoLib 源码
3. **易于更新** - 只需替换源码文件夹
4. **无需签名** - SPM 自动处理代码签名
5. **版本控制友好** - 可以用 Git 管理整个包

### ⚠️ 注意事项

1. **首次构建时间** - 第一次编译需要约 40-50 秒（编译 C++ 源码）
2. **后续构建** - 增量编译，只编译修改的文件，速度很快
3. **二进制大小** - 最终二进制大小相同（都是静态链接）

## 🧪 测试建议

迁移后建议进行以下测试：

1. **基本功能测试**
   ```swift
   let url = // 你的测试文件
   let info = MIKMediaInfo(fileURL: url)
   XCTAssertNotNil(info)
   ```

2. **数据一致性测试**
   - 对比 Framework 和 SPM 版本的输出
   - 应该完全一致

3. **性能测试**
   - 运行时性能完全相同
   - 首次编译时间会较长

## ❓ 常见问题

### Q: 需要修改现有代码吗？
**A: 不需要！** API 100% 兼容。

### Q: 性能会有变化吗？
**A: 运行时性能完全相同。** 都是编译为原生代码。

### Q: 可以同时安装 Framework 和 SPM 版本吗？
**A: 不建议。** 会导致符号冲突。选择其中一个即可。

### Q: 如何回退到 Framework 版本？
**A: 简单！**
1. 移除 SPM 依赖
2. 重新添加 Framework
3. 代码无需修改

### Q: SPM 版本支持哪些平台？
**A: macOS 10.13+** (arm64 & x86_64)，与 Framework 版本相同。

### Q: MediaInfoLib 的版本是否相同？
**A: 是的。** 使用相同的 MediaInfoLib 源码。

## 📞 需要帮助？

如果迁移过程中遇到问题：

1. 检查 Xcode 版本（建议 Xcode 13+）
2. 清理构建缓存：`Product` → `Clean Build Folder`
3. 重新构建项目

## 🎉 总结

**迁移到 Swift Package 版本：**
- ✅ **零代码修改**
- ✅ **完全兼容**
- ✅ **更易维护**
- ✅ **更易更新**

享受更现代化的依赖管理方式吧！🚀

