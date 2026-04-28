---
name: log-add
description: 作業ログに追記する
disable-model-invocation: true
---

# 作業ログに追記する

現在の作業ログファイル[(project root)/_local/logs/*$ARGUMENTS.md]に現在の作業内容などをテンプレートに従って追加してください。

まず、作業ログファイルが存在するか確認し、存在しない場合は新規作成してください。

### 新規作成の場合のテンプレート:

---markdown

# 作業ログ $(date +%Y年%m月%d日)

## 📝 作業内容

## 💡 学びと気づき

## 愚痴

---
