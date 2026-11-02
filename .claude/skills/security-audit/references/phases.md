# 観点ごとの調べ方

観点は 1 つずつ進め、終わるたびに資料へ反映して commit する。順番の目安は、被害が大きくスキャンが見落としやすいものから。

## 目次

1. コードのスキャン
2. 個人情報の流れ
3. 業務ロジックの悪用
4. CI/CD・供給経路
5. ブラウザの防御
6. 基盤(IaC)
7. クラウドの設定(利用者に CLI を実行してもらう)
8. 聞き取り
9. 未調査を埋める

---

## 1. コードのスキャン(接頭辞の例: F = API、W = フロント)

- Claude Security プラグインのスキャン(`/claude-security`)を、API とフロントで分けて回す。費用が大きいので、回す前に利用者に確認する
- 生成物(`CLAUDE-SECURITY-*` のディレクトリ)はコミットしない
- 結果は資料に写す前に、今のコードで再確認する(直っているものは excluded に「対応済み」と書く)
- フロントで検査しなかった範囲は notExamined に書く。あとで grep だけで確かめた場合は「危ない書き方の検索だけで、1 行ずつは読んでいない」と明記する

## 2. 個人情報の流れ(接頭辞の例: P)

- 調査役のエージェントを経路ごと(入口・保存・外部送信・ログ・帳票・削除など)に数体と、反証役を数体動かす。反証役には結論ではなくコードを渡す
- 「説明文書(顧客向けの概要シート・FAQ)と実態が食い違う」ことは検査の問題にしない。必要以上に渡している、消していない、という実害を問題にし、文書は別に直す
- 外部サービス側の保存期間など、コードで分からないことは確認事項に回す

## 3. 業務ロジックの悪用(接頭辞の例: L)

- 調査役を領域ごと(打刻・給与・請求のような業務単位)に数体、反証役を数体
- 見るもの: 本人のデータかの照合、クライアントから受け取る金額・時刻、確定・承認後の書き換え、認証のない API、繰り返しで通知や外部送信を起こせる操作
- 反証では「仕様として意図しているか」(コード・テスト・画面の警告)を必ず確かめる。仕様と判断したものは excluded に理由付きで書く
- 載せるかどうかは利用者が決める。候補を一覧で見せ、載せないものを選んでもらう

## 4. CI/CD・供給経路(接頭辞の例: C)

ワークフローはリポジトリから読み、設定は `gh api` で読む(値は読まない)。

```sh
R=<owner>/<repo>
grep -n "^on:\|pull_request_target\|workflow_run\|permissions\|id-token\|secrets\.\|role-to-assume\|uses:" .github/workflows/*.yml
gh api repos/$R/environments --jq '.environments[] | {name, protection_rules: [.protection_rules[]?.type]}'
gh api repos/$R/actions/secrets --jq '.secrets[] | [.name, .created_at] | @tsv'   # 名前と作成日だけ
for e in $(gh api repos/$R/environments --jq '.environments[].name'); do gh api repos/$R/environments/$e/secrets --jq '.secrets[].name'; done
gh api repos/$R/rulesets --jq '.[].id' | xargs -I{} gh api repos/$R/rulesets/{} --jq '{name, conditions: .conditions.ref_name, bypass: .bypass_actors, rules: [.rules[] | {type, p: .parameters}]}'
gh api repos/$R/actions/permissions; gh api repos/$R/actions/permissions/workflow
gh api repos/$R --jq '.security_and_analysis'
gh api "repos/$R/dependabot/alerts?state=open&per_page=100" --paginate --jq '.[] | [.security_advisory.severity, .dependency.package.name] | @tsv' | cut -f1 | sort | uniq -c
gh api orgs/<org> --jq '{two_factor_requirement_enabled, default_repository_permission}'
gh api "orgs/<org>/members?filter=2fa_disabled" --paginate --jq 'length'
```

見落としやすい点:
- pull_request のワークフローは PR のブランチの定義で動く。PR で使えるクラウドのロールが本番と同じなら、書き込める人は承認なしで本番に届く。PR の実行で本番の plan などが成功しているかを、実行記録(`gh run view --json jobs`)で確かめる
- OIDC の信頼ポリシーの sub が `repo:<org>/<repo>:*` のように広くないか(利用者にクラウドの CLI で確かめてもらう)
- ruleset の dismiss stale reviews・last push approval・除外(bypass)の対象、Actions による PR の承認、既定の権限
- 参照されていない secret(長期キーが残っていないか)
- 組織の既定の権限が write なら、他のリポジトリの secret も同じ人数が読める。他のリポジトリに個人の長期キーがないか(7 の CloudTrail で使い手を特定できる)
- 依存の critical は `yarn why` などで依存元を見て、本番に入るかを仕分ける

## 5. ブラウザの防御(接頭辞の例: B)

```sh
curl -sS -I -L https://<本番の画面>/ | grep -iE "^(HTTP|location|content-security|x-frame|strict-transport|x-content-type|referrer-policy|permissions-policy|set-cookie)"
curl -sS -I http://<本番の画面>/ | head -3   # HTTPS への転送
```

- 設定の場所(next.config の headers、ホスティングのカスタムヘッダー)をリポジトリで探す
- トークンの置き場所(localStorage・JS から読める Cookie)、Cookie の SameSite、リフレッシュトークンの期間を確かめ、CSP がないときの被害を書く
- SameSite=Lax ならクリックジャッキングは成り立ちにくい、のように、既にある防御で弱まる点も書く
- 対策はヘッダーごとに「何を指定するか」と「どのリスクを防ぐか」を書く(利用者から求められた書き方)

## 6. 基盤(IaC、接頭辞の例: T)

- 踏み台・Security Group の 0.0.0.0/0、DB の暗号化、ログに出る値(スロークエリのパラメータなど)
- 実行ロールの Resource *(全 secret の読み取り、PassRole、使っていない権限)
- 認証基盤の MFA・パスワードの条件・脅威保護。IaC の外(Amplify など)で管理しているプールも読む
- 特別な利用者(全テナントに入れる管理者など)が、一般の利用者と同じプールの同じ条件で守られていないか
- S3 の公開ブロック・バージョニング、KMS のローテーション、secret のローテーション
- IaC を読んだだけで実際の設定は見ていない、と meta と notExamined に書く

## 7. クラウドの設定(接頭辞の例: A)

Claude 側からはクラウドの CLI を実行できないことが多い。読み取りだけのコマンドを提示し、利用者に `! <command>` で実行してもらう。出力に個人名が含まれる場合は、資料に載せる形(人数かイニシャルか)を利用者に確かめる。

```sh
# 監査ログと検知
aws cloudtrail describe-trails --query 'trailList[].{Name:Name,MultiRegion:IsMultiRegionTrail,Bucket:S3BucketName}' --output table
aws cloudtrail get-trail-status --name <trail> --query '{Logging:IsLogging,LatestDelivery:LatestDeliveryTime}'
aws cloudtrail get-event-selectors --trail-name <trail>          # S3 のデータイベントを記録しているか
aws s3api get-bucket-lifecycle-configuration --bucket <trail のバケット>   # 保持期間
aws guardduty list-detectors --output text
aws configservice describe-configuration-recorder-status
aws securityhub describe-hub --query HubArn

# IAM ユーザー・長期キー・MFA
aws iam generate-credential-report >/dev/null; sleep 5; aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,4,5,8,9,11,14,16 | column -t -s,
for u in $(aws iam list-users --query 'Users[].UserName' --output text); do echo "== $u"; aws iam list-groups-for-user --user-name $u --query 'Groups[].GroupName' --output text; aws iam list-attached-user-policies --user-name $u --query 'AttachedPolicies[].PolicyName' --output text; sleep 0.5; done
for g in $(aws iam list-groups --query 'Groups[].GroupName' --output text); do echo "== $g"; aws iam list-attached-group-policies --group-name $g --query 'AttachedPolicies[].PolicyName' --output text; sleep 1; done
# 独自ポリシーの中身
arn=arn:aws:iam::<account>:policy/<name>; aws iam get-policy-version --policy-arn $arn --version-id $(aws iam get-policy --policy-arn $arn --query Policy.DefaultVersionId --output text) --query PolicyVersion.Document

# CI のロール
aws iam list-roles --query "Roles[?contains(to_string(AssumeRolePolicyDocument), 'token.actions.githubusercontent.com')].RoleName" --output text
aws iam get-role --role-name <role> --query Role.AssumeRolePolicyDocument
aws iam list-attached-role-policies --role-name <role> --output table; aws iam list-role-policies --role-name <role> --output text

# 長期キーの使い手(IP と User-Agent で、CI か端末かサーバーかが分かる)
aws iam list-access-keys --user-name <user>
aws cloudtrail lookup-events --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=<key> --max-results 30 --query 'Events[].CloudTrailEvent' --output text | jq -r '[.eventTime,.eventSource,.eventName,.sourceIPAddress,.userAgent]|@tsv'
```

読み方の注意:
- 認証情報レポートには SSO(IAM Identity Center)の利用者は出ない。`~/.aws/config` の `sso_session` などで SSO の有無を確かめてから「IAM ユーザーで運用している」と書く
- `MFA_AUTHENTICATION` のような名前のポリシーでも、MFA を強制しているとは限らない。中身を読む
- IAMFullAccess や、CreateRole + AttachRolePolicy を持つポリシーは実質的に管理者
- AWS 管理の ReadOnlyAccess は s3:GetObject とログの読み取りを含む
- 長期キーが CI から使われていたら、GitHub Actions の実行記録(`gh api repos/<org>/<repo>/actions/runs?created=<時刻の範囲>`)と時刻を突き合わせてリポジトリを特定する

## 8. 聞き取り(接頭辞の例: H)

コードと設定で分からないものは、AskUserQuestion で選択肢付きで聞く(4 問ずつ)。

- 退職のとき、クラウド・リポジトリ・管理画面の権限を外す手順はあるか
- 権限を定期的に見直しているか
- サポートで本番データを見るとき、直接書き換えるときに記録を残しているか
- 本番データ(ダンプ・CSV)を手元に落とすことがあるか。マスクの仕組みがあれば、その実装も読む
- 急ぎで出す判断の基準、出したものを戻す手順
- 鍵・トークンの失効の手順、顧客と当局(個人情報保護委員会など)への報告の手順
- バックアップの復元を試したか、障害の訓練をしているか
- 外部のペネトレーションテストを受けたことがあるか
- 共有の鍵(踏み台など)を誰が持っているか
- レビューの除外の理由

答えに「?」が付いていたり曖昧だったりしたら、コードで裏を取ってから書く。

## 9. 未調査を埋める

- 問題のない小分類が「未調査」のまま残っていないかを一覧する
  ```sh
  node -e "global.window={};require('./security-review.data.js');const D=window.SCAN;const u=new Set(D.issues.map(i=>i.category));D.categories.filter(c=>!u.has(c.key)&&!c.checkedAt).forEach(c=>console.log(c.scope,c.key,c.name))"
  ```
- 調べて問題がなければ、消さずに `checkedAt` を付けて「問題なし」と表示し、points に調べた結果を書く
