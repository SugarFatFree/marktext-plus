#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./scripts/release.sh <version>"
  echo "Example: ./scripts/release.sh 1.1.4"
  exit 1
fi

VERSION=$1
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "dev" ]; then
  echo "❌ Error: Must be on 'dev' branch. Current branch: $CURRENT_BRANCH"
  exit 1
fi

echo "🚀 Starting release process for v${VERSION}..."
echo ""

# 1. 更新版本号
echo "📝 Step 1/5: Updating version in pubspec.yaml..."
cd code
sed -i "s/^version: .*/version: ${VERSION}+1/" pubspec.yaml
cd ..
echo "✓ Version updated to ${VERSION}+1"
echo ""

# 2. 提示更新 CHANGELOG
echo "📋 Step 2/5: Update CHANGELOG.md"
echo "Please add the following entry at the top of CHANGELOG.md:"
echo ""
echo "## [v${VERSION}] - $(date +%Y-%m-%d)"
echo ""
echo "### Added"
echo "- "
echo ""
echo "### Fixed"
echo "- "
echo ""
echo "### Changed"
echo "- "
echo ""
echo "Press Enter when done..."
read
echo ""

# 3. 提交到 dev
echo "💾 Step 3/5: Committing and pushing to dev branch..."
git add -A
git commit -m "release: prepare v${VERSION}

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
git push origin dev
echo "✓ Changes pushed to dev"
echo ""

# 4. 合并到 main
echo "🔀 Step 4/5: Merging to main branch..."
git checkout main
git merge dev --no-ff -m "Merge branch 'dev' for v${VERSION} release"
git push origin main
echo "✓ Merged and pushed to main"
echo ""

# 5. 创建标签
echo "🏷️  Step 5/5: Creating and pushing tag v${VERSION}..."
echo "Enter release notes (press Ctrl+D when done):"
echo "Example:"
echo "## 新增功能"
echo "- Feature 1"
echo ""
echo "## 修复"
echo "- Fix 1"
echo ""
NOTES=$(cat)

git tag -a v${VERSION} -m "Release v${VERSION}

${NOTES}"
git push origin v${VERSION}
echo "✓ Tag v${VERSION} created and pushed"
echo ""

# 6. 同步 dev
echo "🔄 Syncing dev branch..."
git checkout dev
git merge main
git push origin dev
echo "✓ Dev branch synced"
echo ""

echo "✅ Release v${VERSION} completed successfully!"
echo ""
echo "Recent tags:"
git tag --sort=-creatordate | head -5
