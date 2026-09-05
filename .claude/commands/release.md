# Release 发布流程

通用的版本发布流程，适用于任何版本号。

## 前置条件

- 当前在 `dev` 分支
- 所有改动已提交
- 已完成功能测试

## 使用方法

执行发布前，先设置版本号环境变量：

```bash
export VERSION=1.1.4  # 替换为实际版本号
```

## 发布前必须检查（缺一不可）

发版前逐项确认，任何一项不满足就先补齐再继续：

1. `docs/vX.Y.Z/bugfix.md` 存在，总览表格行数 == 正文小节数，覆盖本版全部修复
2. `docs/vX.Y.Z/PRD_需求文档.md` 存在，总览表格行数 == 正文小节数，覆盖本版全部功能
3. `CHANGELOG.md` 的本版条目与上面两份文档对得上
4. **`docs/vX.Y.Z/release-notes.md` 已写好**——按主题分组、能一口气读完的发行说明。
   没有这个文件时，工作流会退回去把 CHANGELOG 的整节原样贴上（v1.5.5 就是这么
   变成三十几条无序条目的），所以它是必写项，不是可选项
5. **README.md 已更新**——功能表、版本引用、截图路径要反映本版真实能力
   （历史教训：README 从 v1.1.2 之后连续多版没更新，功能表停在 8 行，
   Mermaid / 命令面板 / 导出 / 大纲 等一概没写）
6. `code/pubspec.yaml` 与 `code/lib/core/constants.dart` 的版本号都已改
7. 本机跑过 `flutter test` 全绿、`dart analyze --fatal-infos lib test` 无问题
   （**不在本机做完整构建**，打包一律交给 CI/CD）
8. **插件 SDK 与官方插件的文档是否要跟进**——本版有没有改变**插件作者看得见的东西**：
   契约（动作、字段、权限）、错误怎么呈现给他们、新增了什么他们该知道的能力。
   有的话，`marktext-plus-plugin-sdk` 的 README 与 11 份翻译要一起改。
   注意顺序：**能力发布之后**才写进 SDK 文档，否则就是 BUG-266 那个毛病
   （文档承诺一件还没兑现的事）。
   v1.6.2 的待办：编辑器开始展示「装了却读不进来的插件」和原因，而 SDK 文档的
   「Trying a plugin before you ship it」一节只讲了发布前怎么试，没讲装上之后
   不出现该去哪看

9. **`docs/vX.Y.Z/manual-test.md` 已写好并且真的走过一遍**——「未经人工测试不得发版」
   要有东西可照着测。只列**自动化测试够不到的**：视觉、真实文件系统、真实插件、
   别的应用（Word、浏览器）。纯内部收敛不必列，它们由测试和变异验证覆盖。
   写法是「怎么造出这个场景 → 该看到什么」，不是罗列改了什么

发布后再确认一次：

```bash
git fetch origin
# tag 必须在 main 上，否则说明第 4 步的合并没做成
git merge-base --is-ancestor vX.Y.Z origin/main && echo "tag 已在 main 上"
# main 不应落后 dev
git rev-list --count origin/main..origin/dev   # 期望 0
```

## 发布步骤

### 1. 更新 README 文件

发版必做，不是「如果需要」：

```bash
# 版本引用、截图路径
grep -rn "v[0-9]\+\.[0-9]\+\.[0-9]\+" README.md docs/i18n/

# 功能表是否漏了本版新增能力
sed -n '/## ✨ Features/,/## 🎨 Themes/p' README.md
```

README 改完后，`docs/i18n/` 下的翻译版本同步更新。

### 2. 更新版本记录

#### 2.1 更新 pubspec.yaml

```bash
cd code
# 编辑 pubspec.yaml，将 version 字段改为新版本
# 格式：major.minor.patch+build (例如：1.1.4+1)
sed -i "s/^version: .*/version: ${VERSION}+1/" pubspec.yaml
cd ..
```

#### 2.2 更新 CHANGELOG.md

```bash
# 在 CHANGELOG.md 顶部添加新版本条目
# 格式参考：
cat << EOF
## [v${VERSION}] - $(date +%Y-%m-%d)

### Added
- 新增功能描述

### Fixed
- 修复问题描述

### Changed
- 改进内容描述

EOF

# 手动编辑 CHANGELOG.md，将上述内容插入到文件开头（第 7 行之后）
```

### 3. 提交并推送到当前分支

```bash
# 暂存所有改动
git add -A

# 提交发布准备
git commit -m "release: prepare v${VERSION}"

# 推送到远程 dev 分支
git push origin dev
```

### 4. 合并到主分支

```bash
# 切换到 main 分支
git checkout main

# 合并 dev 分支（使用 --no-ff 保留合并历史）
git merge dev --no-ff -m "Merge branch 'dev' for v${VERSION} release"

# 推送到远程 main 分支
git push origin main
```

### 5. 发布 tag

```bash
# 创建带注释的标签
git tag -a v${VERSION} -m "Release v${VERSION}

## 新增功能
- 功能 1
- 功能 2

## 修复
- 修复 1
- 修复 2

## 改进
- 改进 1
"

# 推送标签到远程
git push origin v${VERSION}

# 切回 dev 分支并同步
git checkout dev
git merge main
git push origin dev
```

## 验证

```bash
# 检查最新标签
git tag --sort=-creatordate | head -5

# 检查分支状态
git log --oneline --graph --all -10

# 检查远程分支是否同步
git fetch origin
git status
```

## 快速发布脚本

将以下内容保存为 `scripts/release.sh`：

```bash
#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./scripts/release.sh <version>"
  echo "Example: ./scripts/release.sh 1.1.4"
  exit 1
fi

VERSION=$1
echo "🚀 Starting release process for v${VERSION}..."

# 1. 更新版本号
echo "📝 Updating version in pubspec.yaml..."
cd code
sed -i "s/^version: .*/version: ${VERSION}+1/" pubspec.yaml
cd ..

# 2. 提示更新 CHANGELOG
echo "⚠️  Please update CHANGELOG.md manually, then press Enter to continue..."
read

# 3. 提交到 dev
echo "💾 Committing changes to dev branch..."
git add -A
git commit -m "release: prepare v${VERSION}"
git push origin dev

# 4. 合并到 main
echo "🔀 Merging to main branch..."
git checkout main
git merge dev --no-ff -m "Merge branch 'dev' for v${VERSION} release"
git push origin main

# 5. 创建标签
echo "🏷️  Creating tag v${VERSION}..."
echo "Please enter release notes (Ctrl+D when done):"
NOTES=$(cat)
git tag -a v${VERSION} -m "Release v${VERSION}

${NOTES}"
git push origin v${VERSION}

# 6. 同步 dev
echo "🔄 Syncing dev branch..."
git checkout dev
git merge main
git push origin dev

echo "✅ Release v${VERSION} completed successfully!"
git tag --sort=-creatordate | head -5
```

使用方法：

```bash
chmod +x scripts/release.sh
./scripts/release.sh 1.1.4
```

## 回滚（紧急情况）

```bash
VERSION=1.1.4  # 要回滚的版本

# 删除本地标签
git tag -d v${VERSION}

# 删除远程标签
git push origin :refs/tags/v${VERSION}

# 重置 main 分支到上一个版本
git checkout main
git reset --hard HEAD~1
git push origin main --force

# 重置 dev 分支
git checkout dev
git reset --hard origin/dev
```

## 注意事项

1. **版本号格式**：遵循语义化版本 `major.minor.patch`
2. **CHANGELOG 格式**：遵循 [Keep a Changelog](https://keepachangelog.com/) 规范
3. **提交信息**：使用 `release: prepare vX.Y.Z` 格式
4. **标签注释**：包含完整的更新说明，方便 GitHub Release 使用
5. **分支同步**：确保 dev 和 main 在发布后保持同步
6. **推送顺序**：先推送 dev → 合并到 main → 推送 main → 推送 tag → 同步 dev
