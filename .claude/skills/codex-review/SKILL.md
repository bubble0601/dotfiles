---
name: codex-review
description: "Codexにセカンドオピニオンを求める。AI同士の忖度なしガチレビュー。Use when user mentions 'Codex レビュー', 'セカンドオピニオン', 'Codex の意見', 'Codex でレビュー', or 'Codex セットアップ'. Do NOT load for: 'Codex に実装させて', 'Codex Worker', 'Codex に作らせて', '実装を依頼'."
---

# Codex Review Integration Skill

OpenAI Codex CLI を使って Claude Code のコードレビュー時にセカンドオピニオンを提供するスキル。

## 実行方法

### 直接呼び出し

```bash
# codex のフルパスを使用（PATH に /opt/homebrew/bin が含まれない環境対策）
CODEX=$(command -v codex || echo "/opt/homebrew/bin/codex")

# プロンプトは stdin 経由で渡す（"$(...)" 展開では長文が失敗する場合あり）
cat <<'EOF' > /tmp/codex-review-prompt.md
以下のコードをレビューしてください: ...
EOF
$CODEX exec - < /tmp/codex-review-prompt.md 2>/dev/null
```

---

## レビュープロンプト

### デフォルトプロンプト

```
日本語でコードレビューを行い、問題点と改善提案を出力してください
```

### カスタマイズ例

**セキュリティ重視**:

```yaml
review:
  codex:
    prompt: |
      以下の観点でセキュリティレビューを行ってください：
      1. 入力検証の不備
      2. 認証・認可の問題
      3. インジェクション脆弱性
      4. 機密情報の露出
      日本語で回答してください。
```

**パフォーマンス重視**:

```yaml
review:
  codex:
    prompt: |
      以下の観点でパフォーマンスレビューを行ってください：
      1. N+1クエリ
      2. 不要な再レンダリング
      3. メモリリーク
      4. 非効率なアルゴリズム
      日本語で回答してください。
```

---

## レビュー結果の形式

### Codex からの出力例

```json
{
  "review": {
    "summary": "3件の改善提案があります",
    "issues": [
      {
        "file": "src/api/users.ts",
        "line": 45,
        "severity": "high",
        "message": "SQL インジェクションの可能性"
      },
      {
        "file": "src/components/Form.tsx",
        "line": 12,
        "severity": "medium",
        "message": "useEffect の依存配列が不完全"
      }
    ],
    "suggestions": ["関数を分割して可読性を向上", "型定義を厳密化"]
  }
}
```

### 統合フォーマット

```markdown
## 🤖 Codex レビュー結果

**サマリ**: 3 件の改善提案

### 問題点

| ファイル                | 行  | 重要度 | 内容                         |
| ----------------------- | --- | ------ | ---------------------------- |
| src/api/users.ts        | 45  | 高     | SQL インジェクションの可能性 |
| src/components/Form.tsx | 12  | 中     | useEffect の依存配列が不完全 |

### 改善提案

1. 関数を分割して可読性を向上
2. 型定義を厳密化
```

---

## ベストプラクティス

### 効果的なレビューのために

1. **対象を絞る**: 大量のファイルより重要なファイルに集中
2. **観点を明確に**: プロンプトでレビュー観点を指定
3. **結果を比較**: Claude と Codex の指摘を比較して優先度判断

### 避けるべきこと

1. **全ファイル一括**: 大規模プロジェクトで全ファイルは非効率
2. **プロンプトなし**: デフォルトプロンプトは汎用的すぎる場合あり
3. **結果の盲信**: AI の指摘は参考情報、最終判断は人間

---

## ⚠️ 注意事項

### パフォーマンス

- Codex CLI 呼び出しには数秒〜数十秒かかる場合があります
- 大規模ファイルの場合はチャンク分割が推奨

### トラブルシューティング

**問題**: Codex CLI が応答しない
**解決策**:

1. `which codex` でインストール確認
2. `codex login status` で認証確認

**問題**: レビュー結果が返らない
**解決策**:

1. ネットワーク接続を確認
2. API クレジット残高を確認
3. タイムアウト値を延長して再試行

---

## 📚 参考資料

- [Codex CLI Reference](https://developers.openai.com/codex/cli/reference/)
