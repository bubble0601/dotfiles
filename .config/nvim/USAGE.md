# AstroNvim 使い方メモ

## 概要

AstroNvim は Neovim 向けのディストリビューション。主な構成要素：

| 役割 | プラグイン |
|------|-----------|
| プラグイン管理 | lazy.nvim |
| パッケージ管理（LSP/フォーマッタ等） | mason.nvim |
| ファイルエクスプローラー | neo-tree.nvim |
| 補完 | blink.cmp |
| ファジー検索 | snacks.picker |
| ターミナル | toggleterm.nvim |
| LSP統合 | astrolsp + nvim-lspconfig |
| ステータスライン | heirline.nvim |

### 設定ファイル構造

```
~/.config/nvim/
├── init.lua
└── lua/
    ├── community.lua          # AstroCommunity パックのインポート
    ├── lazy_setup.lua         # lazy.nvim 設定
    ├── plugins/               # デフォルト設定のオーバーライド
    │   ├── astrocore.lua      # vim options、キーバインド、autocommand
    │   ├── astrolsp.lua       # LSP 設定
    │   ├── astroui.lua        # UI 設定
    │   ├── mason.lua          # 自動インストール対象の設定
    │   ├── none-ls.lua        # フォーマッタ/リンタ設定
    │   └── treesitter.lua     # Tree-sitter 設定
    └── user/
        └── plugins/           # ユーザー追加プラグイン
```

---

## neo-tree

### 開く / 閉じる

| キー | 説明 |
|------|------|
| `<Leader>e` | neo-tree をトグル |
| `<Leader>o` | neo-tree へフォーカスをトグル |
| `q` | neo-tree ウィンドウを閉じる |

### ナビゲーション

| キー | 説明 |
|------|------|
| `<CR>` | ファイルを開く / ディレクトリを展開 |
| `h` | 親ディレクトリに移動 / ノードを閉じる |
| `l` | 子ディレクトリを開く |
| `<BS>` | 上のディレクトリへ移動 |
| `.` | カレントディレクトリをルートに設定 |
| `z` | 全ノードを閉じる |
| `?` | ヘルプ表示 |

### ファイル操作

| キー | 説明 |
|------|------|
| `a` | ファイル作成 |
| `A` | ディレクトリ作成 |
| `d` | 削除 |
| `r` | リネーム |
| `c` | コピー |
| `m` | 移動 |
| `y` | クリップボードへコピー |
| `x` | クリップボードへ切り取り |
| `p` | クリップボードから貼り付け |
| `Y` | パス形式を選んでコピー |
| `R` | ツリーを更新 |

### ウィンドウ操作

| キー | 説明 |
|------|------|
| `S` | 水平分割で開く |
| `s` | 垂直分割で開く |
| `t` | 新規タブで開く |
| `w` | ウィンドウピッカーで開く |
| `P` | プレビュートグル |
| `i` | ファイル詳細表示 |
| `O` | OS のデフォルトアプリで開く |

---

## toggleterm

### ターミナルを開く

| キー | 説明 |
|------|------|
| `<F7>` / `<C-'>` | 直近のターミナルをトグル |
| `<Leader>tf` | フローティングターミナル |
| `<Leader>th` | 水平分割ターミナル |
| `<Leader>tv` | 垂直分割ターミナル |

### 複数ターミナル管理

- `2<C-'>` のように数字プレフィックスで N 番目のターミナルを開く
- `:TermSelect` でインタラクティブにターミナルを選択
- `:ToggleTermToggleAll` で全ターミナルを一括トグル
- `:TermExec cmd="コマンド"` で特定コマンドを実行

### ツール統合（インストール済みの場合に自動登録）

| キー | 説明 |
|------|------|
| `<Leader>gg` | Lazygit を開く |
| `<Leader>tl` | Lazygit をトグル |
| `<Leader>tn` | Node.js REPL |
| `<Leader>tp` | Python REPL |
| `<Leader>tu` | gdu（ディスク使用量） |
| `<Leader>tt` | btm（リソースモニタ） |

---

## Lazygit

`<Leader>gg` または `<Leader>tl` でフローティングターミナルとして起動。

### 主要キーバインド

| キー | 説明 |
|------|------|
| `q` | lazygit を終了（nvim に戻る） |
| `<Esc>` | キャンセル / 前のパネルへ |
| `hjkl` / 矢印キー | ナビゲーション |
| `<Space>` | ファイルのステージ / アンステージ |
| `a` | 全ファイルをステージ / アンステージ |
| `c` | コミット |
| `p` | Push |
| `P` | Pull |
| `b` | ブランチ操作パネル |
| `?` | ヘルプ表示 |

---

## LSP

### サーバーのインストール

**方法1: mason.lua で自動インストール（推奨）**

```lua
-- lua/plugins/mason.lua
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "typescript-language-server",
        "stylua",
        "prettier",
      },
    },
  },
}
```

**方法2: `:Mason` UI から手動インストール**

**方法3: システムにインストール済みの LSP を使う**

```lua
-- lua/plugins/astrolsp.lua
opts = {
  servers = { "pyright" },
}
```

### 言語パックを使う（AstroCommunity）

```lua
-- lua/community.lua
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.python" },
}
```

LSP・フォーマッタ・Tree-sitter・デバッガが一括で設定される。

### astrolsp.lua の主な設定項目

```lua
opts = {
  features = {
    inlay_hints = false,   -- インレイヒント
    codelens = true,
  },
  formatting = {
    format_on_save = {
      enabled = true,
      ignore_filetypes = { "markdown" },
    },
    disabled = { "lua_ls" },  -- 特定 LSP のフォーマットを無効化
  },
  -- LSP アタッチ時のカスタムキーバインド
  mappings = {
    n = {
      gD = {
        function() vim.lsp.buf.declaration() end,
        desc = "宣言へジャンプ",
        cond = "textDocument/declaration",
      },
    },
  },
}
```

### LSP キーバインド（デフォルト）

| キー | 説明 |
|------|------|
| `K` | ホバードキュメント |
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gy` | 型定義へジャンプ |
| `gri` | 実装へジャンプ |
| `grr` / `<Leader>lR` | 参照一覧 |
| `gra` / `<Leader>la` | コードアクション |
| `grn` / `<Leader>lr` | リネーム |
| `gl` / `<Leader>ld` | 行の診断を表示 |
| `<Leader>lD` | 全診断一覧 |
| `<Leader>lf` | フォーマット |
| `<Leader>ls` | ドキュメントシンボル |
| `<Leader>lS` | シンボルアウトライン（aerial） |
| `<Leader>li` | LSP 情報 |
| `]d` / `[d` | 次/前の診断へ移動 |
| `]e` / `[e` | 次/前のエラーへ移動 |
| `<Leader>uh` | インレイヒントトグル（バッファ） |
| `<Leader>uH` | インレイヒントトグル（グローバル） |
