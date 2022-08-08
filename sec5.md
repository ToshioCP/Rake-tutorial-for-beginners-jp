### Rakeの応用（２）、名前空間

このセクションではPandocとRakeを組み合わせてPDFファイルを作成します。
あわせて、名前空間も説明します。

#### PandocとLaTeX、PDF

PandocはMarkdownをPDFに変換することができます。
このときPandocはLaTeXを経由してPDFにします。

```
Markdown => LaTeX => PDF
```

経由する形式をConTeXt、roff ms、HTMLにすることもできますが、詳細はPandocのマニュアルで確認してください。
LaTeXからPDFに変換するのは直接Pandocが行うのではなく、LaTeXエンジンを使います。
LaTeXエンジンは、LaTeXをPDFなどに変換するアプリケーションで、pdfLaTeX、XeLaTeX、LuaLaTeXなどがあります。
ここではLuaLeTeXを使うことにします。

※　pLaTeX、upLaTeXなどのエンジンを好きな読者もいるかもしれません。
PandocはそれらをPDF作成エンジンとしてはサポートしていないようです。
それらのエンジンを使いたい場合はPandocでLaTeX文書を生成し、それをさらにそれぞれのエンジンでPDFにしてください。
Rakeの記述は若干複雑になります。

#### 準備

Pandocに対して、いくつか設定すべき項目があります。
それを、Markdownのはじめにメタデータで記述しておきます。
メタデータはYAML形式で書きます。
YAMLについての詳細は、[ウィキペディア](https://ja.wikipedia.org/wiki/YAML)または[YAMLの公式ページ](https://yaml.org/)を参照してください。

```
% はじめてのRake
% ToshioCP
% 2022/7/29

---
documentclass: ltjsarticle
geometry: margin=2.4cm
toc: true
numbersections: true
secnumdepth: 2
---
```

%で始まるメタデータは、前のセクションでHTMLを作ったときと同じです。
それぞれ、タイトル、著者、作成日時を表します。
`---`行で前後を囲まれた部分がYAMLのメタデータです。
ここで設定できる項目にどのようなものがあるかはPandocのマニュアルを見てください。
ここで設定している項目は次の通りです。

- LaTeX文書のドキュメントクラスに「ltjsarticle」を使う
- geometryパッケージを用いてマージンが2.4cmになるようにレイアウトを変更する
- 目次を出力する
- セクションに番号をふる（Pandocのデフォルトでは番号が振られません）
- セクションに番号を降るのは大きい見出しから2番めまで。
「ltjsarticle」ドキュメントクラスでは最も大きい見出しが「section」で、2番めが「subsection」です。
これらはMarkdownの「#」と「##」のATX見出しに対応します。

以上を「sec1.md」の最初に加えておきます。

今まで見出しに「###」から「#####」を使っていましたが、それではLaTeXのsection、subsectionにならないので、「#」から「###」までに変更が必要です。
手作業では面倒ですから、Rubyプログラムを作って変更します。

```ruby
files = (1..4).map {|n| "sec#{n}.md"}
files.each do |file|
  s = File.read(file)
  s.gsub!(/^###/,"#")
  s.gsub!(/^####/,"##")
  s.gsub!(/^#####/,"###")
  File.write(file,s)
end
```

これを`ch_head.rb`というファイル名で保存し、実行します。
（サンプルファイルは`example/example5`に入っています）

```
$ ruby ch_head.rb
```

これで見出しの修正はできました。

`sec2.md`のフェンスコードブロックの中に長すぎる行があります。
PDFではみ出してしまうので、調整しておきます。

```
> $ rake
> rake aborted!
> Rake::RuleRecursionOverflowError: Rule Recursion Too Deep: [ ... ...
>
> 最後の1行が長いので、分割して3行にする
>
> $ rake
> rake aborted!
> Rake::RuleRecursionOverflowError: Rule Recursion Too Deep: [~a.txt => ~a.txt =>
> ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt =>
> ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt]
```

#### Rakefileの作成

Rakefileは前回のものをPDFに合うように修正するので、比較的簡単に作れます。

```ruby
require 'rake/clean'

sources = FileList["sec*.md"]

task default: %w[はじめてのRake.pdf]

CLEAN.include %w[はじめてのRake.tex]

file "はじめてのRake.pdf" => "はじめてのRake.md" do |t|
  sh "pandoc -s --pdf-engine lualatex -o #{t.name} #{t.source}"
end
CLEAN << "はじめてのRake.md"

file "はじめてのRake.md" => sources do |t|
  firstrake = t.sources.inject("") {|s1, s2| s1 << File.read(s2) + "\n"}
  File.write("はじめてのRake.md", firstrake)
end

CLOBBER << "はじめてのRake.pdf"
```

フォルダ`example/example5`の「sec1.md」から「sec4.md」は、すでにメタデータや見出しの修正が終わっています。

それでは、Rakeを実行してみましょう。
（`example/example5`で実行してください）

```
$ rake
pandoc -s --pdf-engine lualatex -o はじめてのRake.pdf はじめてのRake.md
$
```

今までよりも少し時間がかかります（約10秒）。

できあがったPDFを確かめてください。
MarkdownがこのようなPDFになるのは便利ですね。

HTMLはウェブでの公開、PDFは手元で見るのに適しています。
次のセクションでは、この2つの作業を1つのRakefileにまとめてみます。

#### 名前空間

2つの作業（HTML、PDFの作成）を1つのRakefileにするとき、タスクをわかりやすいように整理しておきたいところです。
一般に、整理されていないプログラムは後から修正するのが難しくなります。
これを「プログラムの保守性に問題がある」といいます。
「保守性を高める」ことはプログラム開発において非常に大切です。
ここでは名前空間を使い、プログラムの保守性を高めます。

名前空間は大きなプログラムを作るときに使われる一般的手法で、Rakeに限りません。
今回は次のようにします。

- HTMLを作成するタスクは名前空間「html」の中に入れる
- PDFを作成するタスクは名前空間「pdf」の中に入れる

名前空間を定義する構文は

```
namespace 名前空間の名称 do
  タスクの定義
  ・・・・
end
```

です。
今までは、それぞれの作業はdefaultタスクで起動していましたが、今回はそれぞれに「build」タスクを設けることにします。
「build」タスクは名前空間の下に定義するので

- html:build => HTMLをビルドするタスク
- pdf:build => PDFをビルドするタスク

となります。
このように名前空間の下のタスクは「名前空間名：タスク名」のように、コロンでつなげて表します。

名前空間は（ファイルタスクやディレクトリタスクでない）一般のタスクにのみ適用されます。
ファイルタスクはファイル名であり、名前空間の中で定義されたからといってファイル名が変わるわけではありません。
ファイルタスクを参照するときにも名前空間は使われません。

#### 準備

2つの作業を1つのRakefileにするために若干の準備が必要です。

- メタデータは、（タイトル、著者、日時を含め）すべてを別ファイルにする。
HTML用の「metadata\_html.yml」とPDF用の「metadata\_pdf.yml」を用意する。
- PDFでは見出しの変更（例えば「###」を「#」にする）が必要なので、「sec1.md」の見出しを変更したものを「sec\_pdf1.md」に保存する。
他のファイルも同様にする。
この操作はRakefileの中で記述する。

まず、メタデータを作ります。

metadata\_html.yml

```yml
title: はじめてのRake
author: ToshioCP
date: 2022/7/29
```

metadata\_pdf.yml

```yml
title: はじめてのRake
author: ToshioCP
date: 2022/7/29
documentclass: ltjsarticle
geometry: margin=2.4cm
toc: true
numbersections: true
secnumdepth: 2
```

「sec1.md」の最初にあった%で始まるメタデータを消去しておきます。
「sec1.md」などは、見出しが「###」から「#####」になっていることを確認しておいてください。

#### Rakefile

では、Rakefileを書きましょう。

```ruby
require 'rake/clean'

sources = FileList["sec1.md", "sec2.md", "sec3.md", "sec4.md"]
sources_pdf = sources.pathmap("%{sec,sec_pdf}p")

task default: %w[html:build pdf:build]

namespace "html" do
  task build: %w[docs/はじめてのRake.html docs/style.css]
  
  file "docs/はじめてのRake.html" => %w[はじめてのRake.md docs] do |t|
    sh "pandoc -s --toc --metadata-file=metadata_html.yml -c style.css -o #{t.name} #{t.source}"
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
end

namespace "pdf" do
  task build: %w[はじめてのRake.pdf]

  file "はじめてのRake.pdf" => "はじめてのRake_pdf.md" do |t|
    sh "pandoc -s --pdf-engine lualatex --metadata-file=metadata_pdf.yml -o #{t.name} #{t.source}"
  end
  CLEAN << "はじめてのRake_pdf.md"
  
  file "はじめてのRake_pdf.md" => sources_pdf do |t|
    firstrake = t.sources.inject("") {|s1, s2| s1 << File.read(s2) + "\n"}
    File.write("はじめてのRake_pdf.md", firstrake)
  end
  CLEAN.include sources_pdf
    
  sources_pdf.each do |dst|
    src = dst.sub(/_pdf/,"")
    file dst => src do
      s = File.read(src)
      s = s.gsub(/^###/,"#").gsub(/^####/,"##").gsub(/^#####/,"###")
      File.write(dst, s)
    end
  end

  CLOBBER << "はじめてのRake.pdf"
end
```

ポイントを書きます

- `sources`の定義を変えた。
PDFの作成で「sec_pdf1.md」のような中間ファイルが作らる。
`sources=FileList["sec*.md"]`だと、中間ファイルも拾ってしまうので、それを防ぐためにファイル名を具体的に書いた。
- pandocのオプションに`--metadata-file=`オプションをつけてメタデータを取り込むようにした。
- PDF作成では、見出しを変更した中間ファイル「sec_pdf1.md」などを使った。
また、見出しの変更は「sec_pdf1.md」などのファイルタスクのアクションとして定義した。
文字列の置換では`gsub!`ではなく`gsub`メソッドを使った。
両者は返り値が違うので、エクスクラメーションつきのメソッドは使わないほうが良い。
（置換が起こらなかったときに`nil`が返るのでバグになりやすい）

異なる名前空間では同じ名前のタスクを定義しても名前の衝突は起こりません。
これは特にプロジェクトが大きいときに有利に働きます。

Rakeの実行においては

- `rake`　＝＞　HTMLとPDFの両方が作られる
- `rake html:build`　＝＞　HTMLのみ作られる
- `rake pdf:build`　＝＞　PDFのみ作られる
- `rake clean`　＝＞　中間ファイルが削除される
- `rake clobber`　＝＞　生成されたファイルすべてが削除される

このように使い分けをします。

#### 名前空間の利点

名前空間はRakefileが大きいときに中身を整理できて便利です。
また、Rakefileはその一部をライブラリとして別ファイルにすることができます。
とりわけライブラリではタスク名が外部と衝突するのを防ぐために名前空間が有効です。

逆に、小規模なRakefileでは名前空間なしでも問題はありません。

名前の衝突回避以外に名前空間が役に立つのは、タスクの分類です。
コマンドラインから呼び出すタスクの数が多いとき、それらを名前空間で整理することが考えられます。
たとえば

```
# データベース関係のタスク
$ rake db:create
・・・・・
# 投稿関係のタスク
$ rake post:new
・・・・・
```

のように、名前空間でそのタスクを分類するのです。
これによって、ユーザがコマンドを整理して覚えやすくなります。
