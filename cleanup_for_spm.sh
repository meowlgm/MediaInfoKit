#!/bin/bash

echo "🧹 清理 Swift Package 不需要的文件..."
echo ""

cd /Users/meowlgm/Downloads/MediaInfoKit

# 计算要删除的大小
echo "📊 计算需要清理的空间..."
TOTAL_SIZE=$(du -sh MediaInfoKit.xcodeproj MediaInfoKit.xcworkspace MediaInfoDemo MediaInfoLib MediaInfoLib_Source TestFiles TestsCLI Tools Scripts Solution Source ASMR.m4a info.txt cleanup.sh 2>/dev/null | awk '{sum+=$1} END {print sum}')

echo ""
echo "🗂️  将要删除的文件和目录："
echo ""

# 1. Xcode 项目文件（不再需要）
echo "  📁 MediaInfoKit.xcodeproj/ - 旧的 Xcode 项目"
echo "  📁 MediaInfoKit.xcworkspace/ - Xcode workspace"

# 2. 示例项目（可选，但 SPM 用户可以自己创建）
echo "  📁 MediaInfoDemo/ - 示例项目（可参考 README）"

# 3. 预编译的库（不再需要）
echo "  📁 MediaInfoLib/ - 预编译动态库（已不需要）"

# 4. 原始源码（已复制到 Sources/）
echo "  📁 MediaInfoLib_Source/ - 原始源码（已复制）"

# 5. 测试文件
echo "  📁 TestFiles/ - 测试文件"
echo "  📁 TestsCLI/ - CLI 测试"

# 6. 构建脚本（SPM 不需要）
echo "  📁 Tools/ - 构建工具脚本"
echo "  📁 Scripts/ - 构建脚本"
echo "  📁 Solution/ - 解决方案文件"

# 7. 旧的源码目录（如果存在）
echo "  📁 Source/ - 旧源码目录"

# 8. 测试文件和临时文件
echo "  📄 ASMR.m4a - 测试音频文件"
echo "  📄 info.txt - 临时信息文件"
echo "  📄 cleanup.sh - 旧清理脚本"

# 9. 原始的 MediaInfoKit 源码目录（已复制到 Sources/MediaInfoKit/）
echo "  📁 MediaInfoKit/ - 原始源码（已复制到 Sources/）"

echo ""
echo "✅ 将保留的目录："
echo "  📁 Sources/ - Swift Package 源码"
echo "  📁 Tests/ - 测试代码"
echo "  📄 Package.swift - SPM 配置"
echo "  📄 README*.md - 文档"
echo "  📄 SPM_USAGE.md - SPM 使用指南"
echo "  📄 MIGRATION_GUIDE.md - 迁移指南"
echo "  📄 LICENSE - 许可证"
echo "  📄 PROJECT_ENHANCEMENTS.md - 项目改进文档"
echo "  📄 SOLUTION_SUMMARY.md - 解决方案总结"
echo "  📁 images/ - 文档图片（部分）"

echo ""
read -p "⚠️  确认删除以上文件？这将极大简化项目目录。(y/N): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo ""
    echo "🗑️  开始清理..."
    
    # 删除 Xcode 项目文件
    rm -rf MediaInfoKit.xcodeproj MediaInfoKit.xcworkspace
    
    # 删除示例项目
    rm -rf MediaInfoDemo
    
    # 删除预编译库
    rm -rf MediaInfoLib
    
    # 删除原始源码
    rm -rf MediaInfoLib_Source
    
    # 删除测试文件
    rm -rf TestFiles TestsCLI
    
    # 删除构建脚本
    rm -rf Tools Scripts Solution
    
    # 删除旧源码
    rm -rf Source
    
    # 删除临时文件
    rm -f ASMR.m4a info.txt cleanup.sh
    
    # 删除原始 MediaInfoKit 目录（源码已复制到 Sources/MediaInfoKit/）
    rm -rf MediaInfoKit
    
    echo ""
    echo "✅ 清理完成！"
    echo ""
    echo "📦 当前项目结构："
    echo ""
    ls -la | grep -v "^\." | tail -n +2
    echo ""
    echo "💾 释放的空间："
    du -sh . 2>/dev/null
    
else
    echo ""
    echo "❌ 取消清理"
fi

echo ""
echo "提示：清理后你仍然可以："
echo "  1. 使用 Swift Package Manager 构建和使用"
echo "  2. 参考 README.md 和 SPM_USAGE.md 获取使用说明"
echo "  3. 查看 MIGRATION_GUIDE.md 了解迁移指南"

