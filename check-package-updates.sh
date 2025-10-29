#!/bin/bash

# Swift Package 更新检查脚本

echo "🔍 检查 Swift Package 更新..."
echo ""

# PhotoEffectsKit
echo "📦 PhotoEffectsKit:"
cd /tmp && rm -rf PhotoEffectsKit 2>/dev/null
git clone --quiet https://github.com/Feversun/PhotoEffectsKit.git 2>/dev/null
cd PhotoEffectsKit
LATEST_COMMIT=$(git rev-parse HEAD)
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "无标签")
echo "  最新 commit: ${LATEST_COMMIT:0:7}"
echo "  最新 tag: $LATEST_TAG"
echo ""

# ObjectRecognitionKit
echo "📦 ObjectRecognitionKit:"
cd /tmp && rm -rf ObjectRecognitionKit 2>/dev/null
git clone --quiet https://github.com/Feversun/ObjectRecognitionKit.git 2>/dev/null
cd ObjectRecognitionKit
LATEST_COMMIT=$(git rev-parse HEAD)
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "无标签")
echo "  最新 commit: ${LATEST_COMMIT:0:7}"
echo "  最新 tag: $LATEST_TAG"
echo ""

echo "✅ 检查完成!"
echo ""
echo "💡 如需更新,在 Xcode 中执行:"
echo "   File → Packages → Update to Latest Package Versions"
