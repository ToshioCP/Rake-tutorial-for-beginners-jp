### はじめてのRake（４）

「はじめてのRake」の第4回です。 今回はRakeの応用です。
Pandocを使ってマークダウンからHTMLを作る例を紹介します。

はじめてこのブログを見る方は「[はじめてのRake（１）](https://toshiocp.com/entry/2022/07/22/112021)」からご覧になってください。

文中に［Ｒ］という記号で始まる段落は、「Ruby上級者向けの解説」です。
上級とは、ほぼ「クラスを記述できるレベル」を指します。
上級以外の方はこの部分を飛ばしてください。

#### Pandoc

まず、Pandocがどのようなアプリケーションなのかを説明します。
Pandocは、文書の形式を変換するアプリケーションです。
例えば、

- Wordの文書をHTML文書にする
- Markdownの文書をPDF文書にする

これ以外にも多数の文書形式がサポートされています。
詳しくは[Pandocのウェブサイト](https://pandoc.org/)をご覧ください。

例として`example.docx`というワードファイルをHTMLにしてみましょう。
ワードファイルはこんな感じです。

![ワード画面](word.png)

~~~
$ pandoc -so example.html example.docx
~~~

これにより、`example.html`というファイルができます。
ダブルクリックするとブラウザで内容が表示されます。

![ブラウザ画面](html.png){width=80%}

画面の見栄えはともかく、ワードで書いた内容がHTMLとして表示されていることが確認できるでしょう。

では、どのようなHTMLが生成されたのでしょうか。

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="" xml:lang="">
<head>
  <meta charset="utf-8" />
  <meta name="generator" content="pandoc" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes" />
  <title>example</title>
  <style>
    code{white-space: pre-wrap;}
    span.smallcaps{font-variant: small-caps;}
    span.underline{text-decoration: underline;}
    div.column{display: inline-block; vertical-align: top; width: 50%;}
    div.hanging-indent{margin-left: 1.5em; text-indent: -1.5em;}
    ul.task-list{list-style: none;}
  </style>
</head>
<body>
<h2 id="pandocのインストール"><strong>P</strong>andocのインストール</h2>
<p>以下ではUbuntu22.04でのインストールを説明する。</p>
<p>端末から、apt-getを使ってインストールする。</p>
<p>$ sudo apt-get install pandoc</p>
<p>これでインストールできるPandocはたいていの場合、最新版ではない。Pandocの最新版は、
そのホームページからダウンロードできる。インストーラがあるので、それを用いるのが簡単である。</p>
<h2 id="rubyのインストール">Rubyのインストール</h2>
<p>端末から、apt-getを使ってインストールする。</p>
<p>$ sudo apt-get install ruby</p>
<p>最新版のRubyをインストールにはrbenvが良いが、rbenvをマスターするには時間がかかる。
詳しくは<a href="https://github.com/rbenv/rbenv">rbenv</a>と
<a href="https://github.com/rbenv/ruby-build">ruby-build</a>のウェブサイトを参照してほしい。</p>
</body>
</html>
```

HTMLのソースコードから分かることで最も重要なことは、ヘッダが追加されていることです。
これはpandocに`-s`オプションをつけたからです。
`-s`をつけなければ、bodyタグで挟まれた本文の部分だけが生成されます。

#### マークダウンをHTMLに変換する

ここからは、マークダウンをHTMLに変換し、さらにRakeで作業を自動化する方法を学びます。

ソースファイルはすべてカレントディレクトリにあるとします。
生成するHTMLはdocsディレクトリに作成します。
マークダウンファイルは、「sec1.md」「sec2.md」「sec3.md」「sec4.md」ですが、将来ファイルが増えても対応できるようにRakefileを作ります。

※　「sec1.md」は「はじめてのRake（１）」の編集画面に書き込んだマークダウンファイルに手を加えたものです。
「sec2.md」「sec3.md」「sec4.md」も同様に「はじめてのRake」のマークダウンファイルです。
これらのソースコードはこの記事の最後に載せておきますので、Rakefileを試すときにコピペして使ってください。

Pandocでは、最初に%とともにメタデータを書きます。
これは、タイトル、著者、日付を表します。

```
% はじめてのRake
% ToshioCP
% 2022/7/25
```

タイトルはHTMLのヘッダのタイトル・タグの内容にもなります。

PandocでHTMLにすると画面全面を使うので、横幅のあるPCでは広がりすぎて読みにくくなります。
それを解消するために、次のCSSファイル「style.css」を用意しました。

```css
body {
  width: 100%;
  padding-right: 0.75rem;
  padding-left: 0.75rem;
  margin-right: auto;
  margin-left: auto;
}

@media (min-width: 576px) {
  body {
    max-width: 540px;
  }
}
@media (min-width: 768px) {
  body {
    max-width: 720px;
  }
}
@media (min-width: 992px) {
  body {
    max-width: 960px;
  }
}
@media (min-width: 1200px) {
  body {
    max-width: 1140px;
  }
}
@media (min-width: 1400px) {
  body {
    max-width: 1320px;
  }
}
```

このCSSはBootstrapのcontainerクラスの定義を参考に作りました。
CSSの内容説明は省略します。

これを`style.css`という名前のファイルにしてRakefileのあるディレクトリに保存します。

Pandocで`-c`オプションを使うと、生成されたHTMLのヘッダで`style.css`を取り込むようになります。

#### Rakefileの作成

それでは、「sec1.md」から「sec4.md」までの4つのファイルからHTMLファイルを作るRakefileを作ってみましょう。
ここで、2つの考え方があります。

- sec1からsec4までを別々のHTMLファイルにし、それらをリンクでつなぐ。
目次を含むトップページはそれらとは別に作る
- sec1.mdからsec4.mdまでを一つのファイルにつなげ、それをHTMLにする。

どちらにも一長一短があります。
ここでは、作成の簡単な2番目の方法を採用しましょう。

```ruby
sources = FileList["sec*.md"]

task default: %w[docs/はじめてのRake.html docs/style.css]

file "docs/はじめてのRake.html" => %w[はじめてのRake.md docs] do |t|
  sh "pandoc -s --toc -c style.css -o #{t.name} #{t.source}"
end

file "はじめてのRake.md" => sources do |t|
  firstrake = t.sources.inject("") {|s1, s2| s1 << File.read(s2) + "\n"}
  File.write("はじめてのRake.md", firstrake)
end

file "docs/style.css" => %w[style.css docs] do |t|
  cp t.source, t.name
end

directory "docs"
```
少しタスクの間の関連が複雑になっています。

- デフォルトのタスク「default」の事前タスクは「docs/はじめてのRake.html」と「docs/style.css」です
- 「docs/はじめてのRake.html」はマークダウン「はじめてのRake.md」とディレクトリ「docs」に依存しています
- 「はじめてのRake.md」は4つのファイル（「sec1.md」から「sec4.md」）に依存しています
- 「docs/style.css」はそのコピー元の「style.css」とディレクトリ「docs」に依存しています
- 「docs」はディレクトリタスクで、directoryメソッドで定義されます

6行目の`sh`は、Rubyの`system`メソッドと似ています。
引数を外部コマンドとして実行します。
6行目の場合、シェルを介してpandocを起動します。
`sh`メソッドはRakeがFileUtilsに拡張したもので、オリジナルのFileUtilsにはありません。

Pandocの`--toc`オプションは目次を自動生成するオプションです。
デフォルトでは`#`から`###`までが目次になります。

10行目の`inject`メソッドは畳み込みを行う、配列インスタンスのメソッドです。
引数を初期値として、配列の値を次々にs2に代入して計算し、結果を次のs1に代入します。
順を追って説明しましょう

- 初期値は引数の空文字列`""`です。
それがブロックのs1に代入されます
- s2には最初の配列の要素である「sec1.md」が代入され、ブロック本体の`s1 << File.read(s2) + "\n"`が実行されます。
これにより、s1には「sec1.mdの内容＋改行」が代入され、それが次のブロックのs1に代入されます。
- 2回目のブロック実行で、s1は「sec1.mdの内容＋改行」、s2には次の配列要素の「sec2.md」が代入されます。
ブロック本体が実行され、「s1」には「sec2.mdの内容＋改行」が追加されます。
その結果、s1は「se1.mdの内容＋改行＋sec2.mdの内容＋改行」となります。
これが次のs1に代入されます。
- 3回目のブロック実行で、s1には前回実行の結果、s2には次の配列要素の「sec3.md」が代入されます。
前と同様に「sec3.mdの内容＋改行」が追加されます。
- 4回目（最後）のブロック実行で、s1には前回実行の結果、s2には次の配列要素の「sec4.md」が代入されます。
前と同様に「sec4.mdの内容＋改行」が追加されます。
- 以上の結果、firstrakeには「sec1.mdの内容＋改行＋sec2.mdの内容＋改行＋sec3.mdの内容＋改行＋sec4.mdの内容＋改行」が代入されます。
要するに、4つのファイルを改行を挟んで結合した文字列になります。
11行目でそれがファイル「はじめてのRake.md」として保存されます。

改行をファイルの末尾に足したのは、一般に「テキストファイルの末尾は改行がある場合とない場合がある」からです。
改行が無い場合に次のファイルを接続すると、2番めのファイルの先頭の文字が行頭に来ません。
すると、見出しの「#」が行頭からずれて見出しでなくなるということが起こりえます。
これを避けるために改行を足しているのです。

#### cleanとclobber

この処理において「はじてのRake.md」というファイルは中間ファイルです。
重要なのはソースファイルと結果ファイルだと考えれば、処理後に中間ファイルは削除したいと思うかもしれません。
そのような操作を行うのがcleanタスクです。
cleanタスクを使うには

- `rake/clean`をrequireする
- 定数`CLEAN`の指すファイルリスト・オブジェクト（それも「CLEAN」と呼ぶことにします）に中間ファイルを追加する。
ファイルリストには配列と同様のメソッドが備わっているので、`<<`または`append`、`push`メソッドで追加ができる。

また、結果ファイルも含めて全て生成ファイルを消去するタスクがclobberです。

- clobberタスクは、CLEANに登録されたファイルを削除する
- さらに、ファイルリストCLOBBERに登録されたファイルも削除する

以上を付け加えたRakefileは次のようになります。

```ruby
require 'rake/clean'

sources = FileList["sec*.md"]

task default: %w[docs/はじめてのRake.html docs/style.css]

file "docs/はじめてのRake.html" => %w[はじめてのRake.md docs] do |t|
  sh "pandoc -s --toc -c style.css -o #{t.name} #{t.source}"
end
CLEAN << "はじめてのRake.md"

file "はじめてのRake.md" => sources do |t|
  firstrake = t.sources.inject("") {|s1, s2| s1 << File.read(s2) + "\n"}
  File.write("はじめてのRake.md", firstrake)
end

file "docs/style.css" => %w[style.css docs] do |t|
  cp t.source, t.name
end

directory "docs"
CLOBBER << "docs"
```

中間ファイルを削除するには

```
$ rake clean
```

生成ファイル全てを削除するには

```
$ rake clobber
```

とします。

以上で4回にわたった「はじめてのRake」を終わります。
ここでは基本的な事項に限定して説明しましたが、それだけでもRakefileを書くのに十分な知識は得られたと思います。
これ以外には、

- タスクをマルチスレッドで実行し、高速化するための`multitask`メソッド
- Rakefileをカレントディレクトリ以外に置くこと、複数のRakefileを使うこと
- タスクの名前空間
- タスクの説明をするための`describe`メソッド
- `rake`コマンドのオプション、とくにトレースなどのデバッグに使えるもの

などへ学習を進めていくと良いと思います。

また、Rakeの機能を学習するだけでなく、ビルドをどのように構成するかについての学習も大事です。
これには経験を重ねることが一番大事だと思います。
