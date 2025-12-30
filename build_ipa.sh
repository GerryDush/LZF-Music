#!/bin/bash

# iOS IPA 打包脚本
# 使用方法: ./build_ipa.sh

set -e  # 任何命令失败则退出

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "=========================================="
echo "开始打包 iOS IPA"
echo "=========================================="

# 1. 清理构建缓存
echo ""
echo "[1/5] 清理构建缓存..."
flutter clean

# 2. 获取依赖
echo ""
echo "[2/5] 获取 Flutter 依赖..."
flutter pub get

# 3. 安装 Pod 依赖
echo ""
echo "[3/5] 安装 iOS 依赖..."
cd "$PROJECT_DIR/ios"
pod install
cd "$PROJECT_DIR"

# 4. 编译 iOS Release
echo ""
echo "[4/5] 编译 iOS Release..."
flutter build ios --release

# 5. 打包成 IPA
echo ""
echo "[5/5] 打包成 IPA..."
mkdir -p build/ios/release_ipa/Payload
cp -r build/ios/iphoneos/Runner.app build/ios/release_ipa/Payload/
cd build/ios/release_ipa
zip -r -q ../../../LZF-Music.ipa Payload
cd "$PROJECT_DIR"

echo ""
echo "=========================================="
echo "✅ 打包完成！"
echo "=========================================="
echo ""
echo "IPA 文件位置: $PROJECT_DIR/LZF-Music.ipa"
ls -lh LZF-Music.ipa
echo ""
