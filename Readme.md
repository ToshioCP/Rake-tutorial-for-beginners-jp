ブログ「おもこん」に載せた「[はじめてのRake](https://toshiocp.com/entry/2022/07/25/180931)」のチュートリアルの例をそのままGithubにあげたものです。
また、Github pagesの機能を使って、[HTML](https://toshiocp.github.io/Rake-tutorial-for-beginners-jp/はじめてのRake.html)を見ることができます。

内容は「Rakeの初歩」ですが、一部深入りしています。

#### ダウンロード

緑色の「コード」と書いてあるボタンをクリックして「Download ZIP」でダウンロードできます。
gitでクローンも可能です。

#### Rakefileについて

Rakefileはトップディレクトリの「sec1.md」から「sec4.md」と「style.css」をもとに「docs」ディレクトリにHTMLファイルを作ります。
ご自分でこれらのファイルをカスタマイズしたら、

```
$ rake
```

でHTMLに変更を反映させることができます。

`rake clean`で中間ファイルの「はじめてのRake.md」を削除、`rake clobber`でさらに「docs」ディレクトリを削除します。
削除後の状態が初期状態になります。

再度「docs」にHTMLファイルを作成するには、再びコマンドラインから`rake`と入力してください。