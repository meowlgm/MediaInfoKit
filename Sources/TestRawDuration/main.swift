import Foundation
import MediaInfoKit

@main
struct TestRawDuration {
    static func main() {
        // 测试 enumerateOrderedValues API
        testEnumerateOrderedValues()
        
        let startTime = Date()

        let testDir = "/Volumes/Entertainment/测试"
        print("\n" + String(repeating: "=", count: 70))
        print("递归扫描目录: \(testDir)")
        print("使用跨 Stream 批量获取 API: getAllValues()")
        print(String(repeating: "=", count: 70))

        let videoFiles = findVideoFiles(in: testDir)
        print("\n找到 \(videoFiles.count) 个视频文件\n")

        var successCount = 0
        var failCount = 0

        for (index, file) in videoFiles.enumerated() {
            let fileName = (file as NSString).lastPathComponent
            print("[\(index + 1)/\(videoFiles.count)] \(fileName)")

            if let info = MIKMediaInfo(fileURL: URL(fileURLWithPath: file)) {
                // ✅ 一次性获取所有需要的参数（跨多个 stream）
                let allValues = info.getAllValues([
                    MIKGeneralStreamKey: ["Duration"],
                    MIKVideoStreamKey: ["Width", "Height"],
                ])

                // 显示结果
                var hasData = false

                // 分辨率（来自 Video stream）
                if let videoStream = allValues[MIKVideoStreamKey],
                    let width = videoStream["Width"],
                    let height = videoStream["Height"]
                {
                    print("  📐 分辨率:")
                    print("     原始值: \(width["raw"] ?? "nil") x \(height["raw"] ?? "nil")")
                    print(
                        "     格式化: \(width["formatted"] ?? "nil") x \(height["formatted"] ?? "nil")"
                    )
                    hasData = true
                }

                // 时长（来自 General stream）
                if let generalStream = allValues[MIKGeneralStreamKey],
                    let duration = generalStream["Duration"]
                {
                    print("  ⏱️  时长:")
                    print("     原始值: \(duration["raw"] ?? "nil") ms")
                    print("     格式化: \(duration["formatted"] ?? "nil")")
                    hasData = true
                }

                if hasData {
                    successCount += 1
                } else {
                    print("  ⚠️  未获取到数据")
                    failCount += 1
                }
            } else {
                print("  ❌ 读取失败")
                failCount += 1
            }
            print("")
        }

        let endTime = Date()
        let elapsed = endTime.timeIntervalSince(startTime)

        print(String(repeating: "=", count: 70))
        print("统计信息:")
        print("  总文件数: \(videoFiles.count)")
        print("  成功: \(successCount)")
        print("  失败: \(failCount)")
        print("  总耗时: \(String(format: "%.3f", elapsed)) 秒")
        if videoFiles.count > 0 {
            print("  平均耗时: \(String(format: "%.3f", elapsed / Double(videoFiles.count))) 秒/文件")
        }
        print(String(repeating: "=", count: 70) + "\n")
    }

    static func findVideoFiles(in directory: String) -> [String] {
        let fileManager = FileManager.default
        var videoFiles: [String] = []

        let videoExtensions = [
            "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v", "mpg", "mpeg", "ts", "m2ts",
        ]

        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            print("❌ 无法访问目录")
            return []
        }

        while let relativePath = enumerator.nextObject() as? String {
            let fullPath = (directory as NSString).appendingPathComponent(relativePath)
            let ext = (relativePath as NSString).pathExtension.lowercased()

            if videoExtensions.contains(ext) {
                videoFiles.append(fullPath)
            }
        }

        return videoFiles.sorted()
    }
    
    /// 测试 enumerateOrderedValues API - 读取 WAV 文件信息
    static func testEnumerateOrderedValues() {
        let wavFile = "/Users/meowlgm/Documents/测试音频/似是故人来-梅艳芳.wav"
        
        print("\n" + String(repeating: "=", count: 70))
        print("测试 enumerateOrderedValues API")
        print("文件: \(wavFile)")
        print(String(repeating: "=", count: 70))
        
        guard let info = MIKMediaInfo(fileURL: URL(fileURLWithPath: wavFile)) else {
            print("❌ 无法读取文件")
            return
        }
        
        // 获取所有可用的 stream keys
        let streamKeys = info.streamKeys
        print("\n📋 可用的 Stream: \(streamKeys)\n")
        
        // 遍历每个 stream，使用 enumerateOrderedValues 输出信息
        for streamKey in streamKeys {
            print("【\(streamKey)】")
            print(String(repeating: "-", count: 50))
            
            info.enumerateOrderedValues({ (key, value) in
                // 格式化输出：键右对齐，值左对齐
                let paddedKey = key.padding(toLength: 30, withPad: " ", startingAt: 0)
                print("  \(paddedKey) : \(value)")
            }, forStreamKey: streamKey)
            
            print("")
        }
        
        print(String(repeating: "=", count: 70) + "\n")
    }
}
