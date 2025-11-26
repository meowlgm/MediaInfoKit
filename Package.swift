// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MediaInfoKit",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "MediaInfoKit",
            targets: ["MediaInfoKit"]
        ),
        .executable(
            name: "TestRawDuration",
            targets: ["TestRawDuration"]
        ),
    ],
    targets: [
        .target(
            name: "ZenLib",
            path: "Sources/ZenLib",
            exclude: [
                "Project",
                "debian",
                "Release",
                "Source/Doc",
                "Source/Example",
                "Source/ZenLib/HTTP_Client",
                "Source/ZenLib/HTTP_Client.cpp",
            ],
            sources: [
                "Source/ZenLib"
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("Source"),
                .define("UNICODE"),
                .define("_UNICODE"),
                .define("ZENLIB_NO_WIN32_API"),
            ],
            linkerSettings: [
                .linkedFramework("CoreFoundation")
            ]
        ),

        .target(
            name: "MediaInfoLib",
            dependencies: ["ZenLib"],
            path: "Sources/MediaInfoLib",
            exclude: [
                "Doc",
                "Example",
                "Install",
                "PreRelease",
                "RegressionTest",
                "Resource",
                "MediaInfo/Reader/Reader_libmms.cpp",
                "MediaInfo/Reader/Reader_libcurl.cpp",
                "MediaInfo/Export/Export_Graph.cpp",
                "MediaInfo/Export/Export_Graph.h",
                "MediaInfo/Export/Export_Graph_gvc_Include.h",
                "ThirdParty/aes-gladman/aesxam.c",
                "ThirdParty/aes-gladman/tablegen.c",
                "ThirdParty/aes-gladman/aes.txt",
                "ThirdParty/aes-gladman/via_ace.txt",
                "ThirdParty/aes-gladman/aes_amd64.asm",
                "ThirdParty/aes-gladman/aes_x86_v1.asm",
                "ThirdParty/aes-gladman/aes_x86_v2.asm",
                "ThirdParty/sha2-gladman/shasum.c",
                "ThirdParty/jni",
            ],
            sources: [
                "MediaInfo",
                "MediaInfoDLL/MediaInfoDLL.cpp",
                "ThirdParty/tinyxml2/tinyxml2.cpp",
                "ThirdParty/aes-gladman",
                "ThirdParty/md5/md5.c",
                "ThirdParty/sha1-gladman/sha1.c",
                "ThirdParty/sha2-gladman/sha2.c",
                "ThirdParty/hmac-gladman",
                "ThirdParty/tfsxml/tfsxml.c",
                "ThirdParty/fmt/format.cc",
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("MediaInfo"),
                .headerSearchPath("MediaInfoDLL"),
                .headerSearchPath("ThirdParty"),
                .headerSearchPath("ThirdParty/tinyxml2"),
                .headerSearchPath("ThirdParty/aes-gladman"),
                .headerSearchPath("ThirdParty/base64"),
                .headerSearchPath("ThirdParty/md5"),
                .headerSearchPath("ThirdParty/hmac-gladman"),
                .headerSearchPath("ThirdParty/sha1-gladman"),
                .headerSearchPath("ThirdParty/sha2-gladman"),
                .headerSearchPath("ThirdParty/tfsxml"),
                .headerSearchPath("../ZenLib/Source"),
                .define("UNICODE"),
                .define("_UNICODE"),
                .define("MEDIAINFO_GRAPH_NO"),
                .define("MEDIAINFO_GRAPHVIZ_NO"),
                .define("MEDIAINFO_LIBCURL_NO"),
                .define("MEDIAINFO_LIBMMS_NO"),
                .define("MEDIAINFO_JNI_NO"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
            ]
        ),

        .target(
            name: "MediaInfoKit",
            dependencies: ["MediaInfoLib"],
            path: "Sources/MediaInfoKit",
            sources: [
                "MIKMediaInfo.mm",
                "MIKConstants.m",
                "NSString+MIK.mm",
            ],
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("../MediaInfoLib"),
                .headerSearchPath("../MediaInfoLib/MediaInfoDLL"),
                .headerSearchPath("../ZenLib/Source"),
                .define("UNICODE"),
                .define("_UNICODE"),
            ],
            linkerSettings: [
                .linkedFramework("Cocoa")
            ]
        ),

        .executableTarget(
            name: "TestRawDuration",
            dependencies: ["MediaInfoKit"],
            path: "Sources/TestRawDuration",
            linkerSettings: [
                .linkedFramework("Foundation")
            ]
        ),
    ],
    cxxLanguageStandard: .cxx11
)
