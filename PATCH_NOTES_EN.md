# MediaInfoKit Local Patch Notes (English)

This document records the minimal, intentional changes applied on top of upstream MediaInfoLib, so future upgrades can quickly re-apply them.

## 1) Duration string mapping (/String, /String1, /String2)

- Module: `Sources/MediaInfoLib/MediaInfo/File__Analyze_Streams.cpp`
- Goal: Preserve the legacy behavior so that enumerated duration strings map as follows:
  - `/String` = long
  - `/String1` = full
  - `/String2` = short

### Current implementation

After building `DurationString*`, the fill order must be:

```cpp
// Restore long/full/short mapping: /String=long, /String1=full, /String2=short
Fill(StreamKind, StreamPos, Parameter+1, DurationString1); // /String (long)
Fill(StreamKind, StreamPos, Parameter+2, DurationString1); // /String1 (full)
Fill(StreamKind, StreamPos, Parameter+3, DurationString2); // /String2 (short)
Fill(StreamKind, StreamPos, Parameter+4, DurationString3); // /String3
```

This block currently sits around line ~3519 (exact line numbers may shift with upstream updates).

### How to locate this block after upgrading

Use semantic anchors rather than line numbers:

- Search within `File__Analyze_Streams.cpp` for one of the following:
  - `DurationString1` near `Fill(StreamKind, StreamPos, Parameter+1` calls
  - The `"/String5"` reference (later in the same function, used as a forward anchor)
  - The comment `Restore long/full/short mapping` (if kept)

Examples:

```bash
rg -n "Fill\(StreamKind,\s*StreamPos,\s*Parameter\+1" Sources/MediaInfoLib/MediaInfo/File__Analyze_Streams.cpp
rg -n "DurationString1" Sources/MediaInfoLib/MediaInfo/File__Analyze_Streams.cpp
rg -n "/String5" Sources/MediaInfoLib/MediaInfo/File__Analyze_Streams.cpp
```

### Re-apply steps after upgrading

1. In the located block, adjust the `Fill(..., Parameter+1/+2/+3/+4, DurationString*)` sequence to match the snippet above.
2. Rebuild the package and validate with a sample media file using `MIKMediaInfo.enumerateOrderedValues` to check:
   - `/String` → long
   - `/String1` → full
   - `/String2` → short

### Impact scope

- Only the mapping order of duration string variants is affected; numeric fields are not changed.
- Public APIs of `MediaInfoKit` remain fully compatible.

---

Maintainer note: If upstream later introduces explicit variables for full/long/short, keep the business expectation above and update this note accordingly.
