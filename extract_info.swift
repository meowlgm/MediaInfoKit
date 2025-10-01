#!/usr/bin/env swift

import Foundation

// 简单的命令行工具，使用原始的 MediaInfoLib dylib
// 不依赖 Swift Package

let dylibPath = "/Users/meowlgm/Downloads/MediaInfoKit/MediaInfoLib/libmediainfo.dylib"
let whisperPath = "/Users/meowlgm/Downloads/MediaInfoKit/Whisper.m4a"

print("检查文件...")
print("dylib: \(FileManager.default.fileExists(atPath: dylibPath))")
print("音频文件: \(FileManager.default.fileExists(atPath: whisperPath))")
print("")
print("请使用原始的 framework 版本或 mediainfo 命令行工具来提取信息")
print("")
print("方法 1 - 使用 mediainfo 命令行工具:")
print("brew install mediainfo")
print("mediainfo '\(whisperPath)' > Whisper_MediaInfo.txt")
print("")
print("方法 2 - 使用原始 MediaInfoKit.framework")
