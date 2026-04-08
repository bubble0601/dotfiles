" エンコーディング
set encoding=utf-8
scriptencoding utf-8

".vim/bundleで管理してるpluginを読み込む
if !has('nvim')
  source ~/.vim/.vimrc.bundle
endif

"基本設定
source ~/.vim/.vimrc.basic
"インデント設定
source ~/.vim/.vimrc.indent
"表示関連
source ~/.vim/.vimrc.appearance
"補完関連
source ~/.vim/.vimrc.completion
"検索関連
source ~/.vim/.vimrc.search
"移動関連
source ~/.vim/.vimrc.moving
"ウィンドウ関連
source ~/.vim/.vimrc.window
"Color関連
source ~/.vim/.vimrc.colors
"編集関連
source ~/.vim/.vimrc.editing
"その他
source ~/.vim/.vimrc.misc

"プラグインに依存するアレ
if !has('nvim')
  source ~/.vim/.vimrc.plugins_setting
endif

"言語別の設定
source ~/.vim/.vimrc.lang
