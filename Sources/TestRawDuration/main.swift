import Foundation
import MediaInfoKit

@main
struct TestRawDuration {
    static func main() {
        testFile("/Users/meowlgm/Documents/让一切随风 - 钟镇涛.mp3")
        testFile("/Volumes/Data/文档/认识Photoshop对齐功能与参考线使用.mp4")
    }

    static func testFile(_ path: String) {
        print("\n" + String(repeating: "=", count: 60))
        print("测试: \(path)")
        print(String(repeating: "=", count: 60))

        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ 文件不存在")
            return
        }

        guard let info = MIKMediaInfo(fileURL: URL(fileURLWithPath: path)) else {
            print("❌ 无法读取")
            return
        }

        print("\n[General]")
        print(
            "Duration: '\(info.getRawValue("Duration", forStreamKey: MIKGeneralStreamKey) ?? "nil")'"
        )
        print(
            "BitRate:  '\(info.getRawValue("BitRate", forStreamKey: MIKGeneralStreamKey) ?? "nil")'"
        )

        print("\n[Video]")
        print(
            "Duration: '\(info.getRawValue("Duration", forStreamKey: MIKVideoStreamKey) ?? "nil")'")
        print("Width:    '\(info.getRawValue("Width", forStreamKey: MIKVideoStreamKey) ?? "nil")'")

        print("\n[Audio]")
        print(
            "Duration: '\(info.getRawValue("Duration", forStreamKey: MIKAudioStreamKey) ?? "nil")'")

        print("\n[getDurationInMilliseconds]")
        if let ms = info.getDurationInMilliseconds(MIKGeneralStreamKey) {
            print("General Duration: \(ms) ms")
        }
    }
}
