/**
 * セキュリティ検査 — 内容。表示側は security-review.html。
 *
 * 攻撃の成立条件は「誰が、どういう条件で」までにとどめ、再現手順やペイロードは書かない。
 *
 * 指摘はどれか 1 つの問題にだけ置く。対策は fixes(単独で解消)と reduces(軽減するが単独では残る)で
 * 指摘に紐づき、他の問題に置いた指摘を指してもよい。prevent は既存の指摘ではなく再発を防ぐ対策。
 * 直った指摘は消さずに resolved を付け、どの対策で直ったかを追えるようにする。
 */
window.SCAN = {
  meta: {
    title: '{{プロダクト名}} セキュリティ検査',
    // localStorage のキー。資料ごとに変える
    storeKey: '{{project}}-security-review',
    // 指摘の接頭辞ごとに 1 つ。調査を足すたびに増やす
    sources: [
      // { prefix: 'F', label: 'Claude Security による apps/api のスキャン', revision: 'abc1234567', date: '2026-01-01', note: 'effort medium' },
    ],
  },

  // 検査していない範囲。ここで見つかっていないことは、問題がないことを意味しない
  notExamined: [],

  // 攻撃者の立ち位置。外側(公開)から内側へ並べる。プロダクトに合わせて足し引きする
  zones: [
    { key: 'external', name: '認証なしの外部', desc: 'ログイン不要で届く人' },
    { key: 'user', name: '利用者', desc: 'ログインできる利用者。必要な権限は指摘ごとに違う' },
    { key: 'logs', name: 'ログを閲覧できる人', desc: 'ログとその転送先を読める人' },
    { key: 'repo', name: 'リポジトリに書き込める人', desc: 'リポジトリに push できる開発者と、そのアカウントを乗っ取った人' },
    { key: 'insider', name: '社員・クラウドを操作できる人', desc: 'クラウドのアカウント、DB、管理画面の権限を持つ人。漏えいした認証情報を含む' },
    { key: 'vendor', name: '外部サービスの事業者', desc: '個人情報を受け取る委託先・連携先と、その中で閲覧できる人' },
    { key: 'upstream', name: '取り込むコードの作者', desc: '依存パッケージや CI の Action の作者と、そのアカウントを乗っ取った人' },
  ],

  // 守る対象の範囲。画面ではタブに分ける
  scopes: [
    { key: 'app', name: 'アプリケーション', desc: '自社のコードの欠陥と、コードやブラウザの機能で入れる防御' },
    { key: 'infra', name: '基盤', desc: 'クラウド上の構成。IaC とクラウドの設定で決まるもの' },
    { key: 'data', name: 'データ', desc: '何を持ち、どこへ渡し、いつ消すか。コードの誤りで漏れるものはアプリケーションの「機密情報の露出」に置く' },
    { key: 'dev', name: '開発・供給経路', desc: 'コードと依存パッケージが本番に届くまで' },
    { key: 'ops', name: '運用', desc: '本番に触れる人と、その人に渡す権限' },
    { key: 'response', name: '検知と対応', desc: '問題に気づき、直して出し、被害を止め、元に戻すまで' },
  ],

  // 小分類。問題がない小分類は points が「未調査」として出る。調べて問題がなければ checkedAt を付けると「問題なし」になる
  categories: [
    { key: 'authn', scope: 'app', name: '認証', desc: '誰であるかの確認', points: ['ログインの経路ごとの本人確認', '試行回数の制限', '退職者・無効化した利用者のセッション'] },
    { key: 'authz', scope: 'app', name: '権限', desc: 'その人がその操作をしてよいか', points: ['各ルートの権限の確認', '自分の権限を上げられないか', '帳票・メール・非同期ジョブの権限'] },
    { key: 'tenant', scope: 'app', name: 'テナントの分離', desc: '他社や他の拠点のデータに届くか', points: ['ID だけで対象を引いていないか', 'ファイルの置き場所のテナントの区切り'] },
    { key: 'input', scope: 'app', name: '入力の検証', desc: '受け取った値の型・形式', points: ['入口での型と範囲の検証', 'ファイル名・パス・URL の組み立て'] },
    { key: 'output', scope: 'app', name: '出力の無害化', desc: '出力先(CSV・Excel・メール)で値が解釈されないか', points: ['CSV・Excel の数式', 'メールの本文と件名'] },
    { key: 'exposure', scope: 'app', name: '機密情報の露出', desc: '応答・ログ・公開 API に出してはいけない値', points: ['API の応答に余計な項目', 'ログとエラー応答', '認証なしの API'] },
    { key: 'browser', scope: 'app', name: 'ブラウザの防御', desc: 'コードに欠陥があっても、ブラウザの機能で被害を小さくする', points: ['CSP', 'frame-ancestors', 'HSTS・nosniff・Referrer-Policy', 'Cookie の属性とトークンの置き場所'] },
    { key: 'logic', scope: 'app', name: '業務ロジックの悪用', desc: '権限の範囲内の操作で、値を不正に動かせないか', points: ['本人のデータかの照合', '確定後の書き換え', '金額・時刻をクライアントから受け取っていないか'] },

    { key: 'network', scope: 'infra', name: 'ネットワークと公開範囲', desc: '外から届く入口と、その手前の防御', points: ['公開している入口の一覧', 'WAF', '踏み台と DB に届く経路'] },
    { key: 'db', scope: 'infra', name: 'DB', desc: '接続の経路、行の分離、暗号化', points: ['ストレージの暗号化', 'アプリのユーザーの権限', 'ログに残る値'] },
    { key: 'storage', scope: 'infra', name: 'ファイルの保管', desc: 'オブジェクトストレージ', points: ['公開設定と CORS', '署名付き URL の期限と発行前の権限確認', '暗号化'] },
    { key: 'iam', scope: 'infra', name: 'IAM', desc: 'クラウドの中で、誰が何をできるか', points: ['実行ロールの権限', 'Resource * の操作'] },
    { key: 'secrets', scope: 'infra', name: '鍵と secret の保管', desc: 'KMS、Secrets Manager、環境変数に置いた値', points: ['環境変数に平文で置いた値', 'ローテーション'] },
    { key: 'idp', scope: 'infra', name: '認証基盤の設定', desc: 'ユーザープールとアプリクライアント', points: ['MFA とパスワードの条件', '許可している認証フロー', '不審なログインの検知'] },

    { key: 'holding', scope: 'data', name: '持つデータの最小化', desc: '使わない機微なデータを持たない', points: ['使っていない機微な項目'] },
    { key: 'flow', scope: 'data', name: '外へ出る経路', desc: '設計として外に出している値。出す項目と相手が必要な範囲か', points: ['解析ツール・外部 API に渡す項目'] },
    { key: 'retention', scope: 'data', name: '保管期間と削除', desc: 'いつまで持ち、どう消すか', points: ['解約後の削除', '一時ファイルの期限'] },
    { key: 'vendor', scope: 'data', name: '委託先', desc: '外部のサービスに預けているデータ', points: ['委託先ごとに渡す項目', '海外への移転'] },

    { key: 'local', scope: 'dev', name: '開発者の端末', desc: '手元の環境に置く secret とデータ', points: ['.env の本番の値', '本番データの手元へのコピー', 'AI エージェントが読める範囲'] },
    { key: 'ci', scope: 'dev', name: 'リポジトリと CI/CD', desc: 'リポジトリと CI', points: ['PR のワークフローが使える権限と secret', 'クラウドへの認証(長期キーか OIDC か、OIDC の条件)', 'ブランチ保護とレビューの必須、除外の対象', '組織の 2 段階認証と既定の権限'] },
    { key: 'deps', scope: 'dev', name: '依存パッケージ', desc: '他人のコードを取り込む経路', points: ['脆弱性のアラートと更新の流れ', 'Action の固定'] },
    { key: 'checks', scope: 'dev', name: '検査の自動化', desc: '同じ種類の欠陥を、マージの前に止める仕組み', points: ['secret のスキャン', 'SAST と独自の lint', '外部のペネトレーションテスト'] },
    { key: 'env', scope: 'dev', name: '環境の分離', desc: '本番と開発・検証の境界', points: ['本番と開発のアカウントの分離'] },

    { key: 'prodAccess', scope: 'ops', name: '本番への入口', desc: '本番に直接触れる手段と、それを持つ人', points: ['クラウドの利用者と MFA、長期キー', '管理者相当の人数', '共有の鍵やアカウント'] },
    { key: 'lifecycle', scope: 'ops', name: '権限の付与と剥奪', desc: '入社・異動・退職のときの手順', points: ['退職時の手順', '定期的な見直し'] },
    { key: 'support', scope: 'ops', name: 'サポートでの本番データの扱い', desc: '問い合わせ対応で本番データを見るとき', points: ['閲覧と直接の書き換えの手順と記録'] },

    { key: 'detect', scope: 'response', name: '気づく', desc: '攻撃や漏えいに気づく仕組み', points: ['監査ログと保持期間', '異常の検知と通知', '脆弱性の報告の窓口'] },
    { key: 'patch', scope: 'response', name: '直して出す', desc: '見つかった脆弱性を、すぐ本番に届けられるか', points: ['急ぎで出す経路と判断の基準', '戻す手順'] },
    { key: 'contain', scope: 'response', name: '止めて知らせる', desc: '被害を止め、関係者に知らせる', points: ['鍵・トークンの失効の手順', '顧客と当局への報告の手順'] },
    { key: 'recover', scope: 'response', name: '戻す', desc: 'データと環境を元に戻す', points: ['バックアップと復元の試験', '障害の訓練'] },
  ],

  // 問題として扱わないもの(対応済み、重複、仕様と判断したもの)
  excluded: [
    // { ids: 'F1, F2', reason: '...' },
  ],

  // 記号は小分類の key + 連番(authn-1 など)。足すときはその小分類の次の番号を取り、振り直さない
  issues: [
    // {
    //   key: 'authn-1',
    //   category: 'authn',
    //   title: '問題の要約(1 行)',
    //   effect: '起きること',
    //   approach: '対策の方向',
    //   scope: '小',            // 直す規模: 小 / 中 / 大
    //   scopeNote: '',          // 規模の補足(任意)
    //   cause: '原因',
    //   impact: '影響',
    //   findings: [
    //     {
    //       id: 'F1',
    //       sev: 'HIGH',        // HIGH / MEDIUM / LOW
    //       source: 'Claude Security のスキャン',
    //       zones: ['external'],
    //       title: '指摘の要約',
    //       cond: '誰が、どういう条件で',
    //       where: 'ファイルや設定の場所',
    //       // alsoFound: 'W3',
    //       // resolved: { by: '#123', checkedAt: 'abc1234567', note: '...' },
    //     },
    //   ],
    //   measures: [
    //     { label: '対策', body: '中身', fixes: ['F1'], reduces: [] },
    //     // quick: true で「先行して入れられる」、prevent: true で「再発防止」
    //   ],
    //   note: '',
    // },
  ],

  // 担当者に確かめる事項
  openQuestions: [],
};
