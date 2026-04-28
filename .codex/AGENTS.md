Please provide all answers in Japanese

## git

- **コミットメッセージは日本語で、ただし文中に英語も併用する**
  例: company テーブルに name カラムを追加した
- ブランチ名は feature, bugfix, refactor, chore のいずれかで始めること
- git add は禁止です。必要であればユーザーにフィードバックすること

## coding

- boolean 型の修飾子名は is,has,can,should または状態動詞の 3 人称単数現在形で始めること
- テストを修正するときは実装とテストのどちらを修正すべきか慎重に判断し、迷う場合はユーザーに確認すること

### TypeScript

- `as any`は使用してはいけない。使用したくなったときはユーザーに判断を仰ぐ
  - `as`も極力使用しないこと
