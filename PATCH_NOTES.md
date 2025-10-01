# MediaInfoKit 本地修改备忘录

本文记录为了满足业务需求而对上游 MediaInfoLib 源码所做的“最小必要修改”，用于后续升级上游源码时快速定位并复用改动。

## 1) 时长字符串映射（/String、/String1、/String2）

- 所属模块: `Sources/MediaInfoLib/MediaInfo/File__Analyze_Streams.cpp`
- 目的: 保持旧版行为，确保枚举出来的时长字符串映射为：
  - `/String` = long（长格式）
  - `/String1` = full（完整格式）
  - `/String2` = short（短格式）

### 修改内容（当前实现）

在生成 `DurationString*` 之后，使用如下填充顺序：

```cpp
// Restore long/full/short mapping: /String=long, /String1=full, /String2=short
Fill(StreamKind, StreamPos, Parameter+1, DurationString1); // /String (long)
Fill(StreamKind, StreamPos, Parameter+2, DurationString1); // /String1 (full)
Fill(StreamKind, StreamPos, Parameter+3, DurationString2); // /String2 (short)
Fill(StreamKind, StreamPos, Parameter+4, DurationString3); // /String3
```

该段位于文件中部靠后（当前约 3519 行附近，实际行号可能因上游变更而偏移）。

### 升级后如何快速定位

优先以语义锚点而非行号定位：

- 在 `File__Analyze_Streams.cpp` 中搜索以下任一关键字：
  - `DurationString1` 且靠近 `Fill(StreamKind, StreamPos, Parameter+1` 的位置
  - `"/String5"`（同函数稍后会出现 `Retrieve(..., "/String5")` 的逻辑，可作为定位区域的下一个锚点）
  - `Restore long/full/short mapping`（如果上面的注释仍在）

常用搜索示例：

```bash
rg -n "Fill\(StreamKind,\s*StreamPos,\s*Parameter\+1" Sources/MediaInfoLib/MediaInfo/File__Analyze_Streams.cpp
rg -n "DurationString1" Sources/MediaInfoLib/MediaInfo/File__Analyze_Streams.cpp
rg -n "/String5" Sources/MediaInfoLib/MediaInfo/File__Analyze_Streams.cpp
```

### 复用/回填步骤

1. 升级上游后，在上述位置找到对应的 `Fill(..., Parameter+1/+2/+3/+4, DurationString*)` 片段。
2. 将其调整为“/String=long, /String1=full, /String2=short”的顺序，与上文代码片段一致。
3. 重新构建并用示例媒体文件验证：
   - 使用 `MIKMediaInfo.enumerateOrderedValues` 输出 `/String`、`/String1`、`/String2` 三种时长，确保显示分别为长/完整/短格式。

### 变更影响范围

- 仅影响时长字段三种字符串表示的映射顺序，不改变数值字段；
- 与 `MediaInfoKit` 的 Swift/ObjC API 接口保持兼容。

---

维护者注：如上游未来显式引入“full/long/short”区分的不同变量名，请以本业务期望为准修正映射关系，并在此文件更新记录。


