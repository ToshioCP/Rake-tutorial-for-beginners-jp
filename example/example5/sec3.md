# ファイルリスト、パスマップ、ディレクトリータスク

このセクションではファイルタスクをサポートする便利な機能を解説します。
具体的には「ファイルリスト」「パスマップ」「ディレクトリータスク」です。

## ファイルリスト

ファイルリストは、ファイル名の配列のようなオブジェクトです。
文字列の配列と同様の操作ができ、さらにいくつかの便利な機能を備えています。

まずファイルリストのインスタンスの作り方から説明しましょう。
クラス名「FileList」に`[ ]`をつけ、そのカッコのなかにファイル名をコンマで区切って書きます。
これで、そのファイルを持つファイルリストができます。

```ruby
files = FileList["a.txt", "b.txt"]
p files

task :default
```

デフォルトタスクを定義しないと、コマンドラインから`rake`を実行したときにエラーになります。
それを防ぐために何もしないデフォルトタスクを定義してあります。

ここでRakeの動作をもう一度確認しておきましょう。

1. Rakeの実行環境を初期化する
2. Rakefileはロードする。このときRakefileは（Rubyコードとして）実行される
3. デフォルトタスクを呼び出す

2番めのRakefileロード時に、ファイルリストが作成され、表示され、デフォルトタスクの定義が行われます。
これらは「タスク呼び出し」前に行われていることに注意してください。

実行してみます。
（`example/example3`では`-f Rakefile1`をつけて実行してください）

```
$ rake
["a.txt", "b.txt"]
$
```

シェルで良く使われるGlobパターンも使えます。

```ruby
files = FileList["*.txt"]
p files

task :default
```

実行してみます。
（`example/example3`では`-f Rakefile2`をつけて実行してください。
`ls`や`rake`の結果はそのディレクトリに含まれるファイルによって異なります。
Rakefile3以降でも`ls`や`rake`の結果が異なることがあります）

```
$ ls
 Rakefile   a.txt   b.txt   c.txt  '~a.txt'
$ rake
["a.txt", "b.txt", "c.txt", "~a.txt"]
$
```

Globパターンについては[Rubyのドキュメント](https://docs.ruby-lang.org/ja/3.0/class/Dir.html#S_--5B--5D)を参考にしてください。

## すべてのテキストファイルのバックアップ

すべてのテキストファイルをバックアップすることを考えてみます。
ここでは、「テキストファイル」を「拡張子が.txtのファイル」としておきます。
このとき、「すべて」というのは「現時点でのすべて」ではなく、「Rakeを実行する時点でのすべて」です。
将来テキストファイルが追加されたり、削除されたりする可能性がありますから、「現時点でのすべてのテキストファイル」と「Rakeを実行する時点でのすべてのテキストファイル」は同じとは限りません。
ですから、Rakefileの記述の中に、その時点でのテキストファイルを捕まえる仕組みを作らなければなりません。
それにはファイルリストを使います。

```ruby
files = FileList["*.txt"]
```

さて、この中に「~a.txt」が含まれていますが、これはオリジナルが「a.txt」であるバックアップファイルですから、コピーの対象から外します。
そのときにはexcludeメソッドを使います。

```ruby
files = FileList["*.txt"]
files.exclude("~*.txt")
p files

task :default
```

excludeメソッドは、与えられたパターンを自身の除外リストに加えます。
実行してみましょう。
（`example/example3`では`-f Rakefile3`をつけて実行してください）

```
$ rake
["a.txt", "b.txt", "c.txt"]
$
```

「~a.txt」が取り除かれました。

今ファイルリストにはオリジナルのファイル（コピー元のファイル）がセットされました。
一方、ファイルタスクの名前はバックアップファイル名です。
例えば「a.txt」を「a.bak」にコピーするファイルタスクでは、

- タスク名は「a.bak」
- 依存ファイル名が「a.txt」

です。
ファイルタスクを定義するためには、ファイルリストに含まれる「コピー元のファイル名」からタスク名である「コピー先のファイル名」を取得する必要があります。
それにはファイルタスクのextメソッドを使います。
extメソッドはファイルタスクに含まれる全てのファイルの拡張子を変更します。

```ruby
names = sources.ext(".bak")
```

それではRakefileを書いてみましょう。

```ruby
sources = FileList["*.txt"]
sources.exclude("~*.txt")
names = sources.ext(".bak")

task default: names

rule ".bak" => ".txt" do |t|
  cp t.source, t.name
end
```

実行してみます。
（`example/example3`では`-f Rakefile4`をつけて実行してください）

```
$ rake
cp a.txt a.bak
cp b.txt b.bak
cp c.txt c.bak
$
```

上手く動きました。
ここでテキストファイルを増やして、rakeを実行してみます。

```
$ echo Appended text file. >d.txt
$ rm *.bak
$ rake
cp a.txt a.bak
cp b.txt b.bak
cp c.txt c.bak
cp d.txt d.bak
$
```

新しいファイル「d.txt」もコピーされました。
ということは、Rakefileが「Rake実行時点でのすべてのテキストファイル」をバックアップしたのが確認できた、ということです。

この例の「\*.txt」ファイルをソース、「\*.bak」ファイルをターゲットということがあります。
一般に、「ソースは存在するが、ターゲットは存在するとは限らない」ということがいえます。
そのため、Rakefileではまずソースを取得して、そのソースからターゲットを生成する、という方法が良く用いられます。

## パスマップ

パスマップ・メソッドはファイルリストの強力なメソッドです。
元々はpathmapはStringオブジェクトのインスタンス・メソッドです。
これをFileListの各要素に対して実行するのがファイルリストのパスマップ・メソッドです。
パスマップは、その引数によって、様々な情報を返します。
よく使われる例をあげます。

- %p => 完全なパスを表します
- %f => 拡張子付きのファイル名を表します。ディレクトリ名は含まれません。
- %n => 拡張子なしのファイル名を表します。
- %d => パスに含まれるディレクトリのリストを表します。

パスマップの例示す前に、その準備としてカレントディレクトリに「src」ディレクトリを作り、その下に「a.txt」「b.txt」「c.txt」を作ります。

```
$ mkdir src
$ touch src/a.txt src/b.txt src/c.txt
$ tree
.
├── Rakefile
├── a.bak
├── a.txt
├── b.bak
├── b.txt
├── c.bak
├── c.txt
├── d.bak
├── d.txt
├── src
│   ├── a.txt
│   ├── b.txt
│   └── c.txt
└── ~a.txt

1 directory, 14 files
$
```

Rakefileを次のように書きます。

```ruby
sources = FileList["src/*.txt"]
p sources.pathmap("%p")
p sources.pathmap("%f")
p sources.pathmap("%n")
p sources.pathmap("%d")

task :default
```

変数sourcesに代入されるファイルリスト・オブジェクトは「src/a.txt」「src/b.txt」「src/c.txt」を含みます。
では、実行してみます。
（`example/example3`では`-f Rakefile5`をつけて実行してください）

```
$ rake
["src/a.txt", "src/b.txt", "src/c.txt"]
["a.txt", "b.txt", "c.txt"]
["a", "b", "c"]
["src", "src", "src"]
```

パスマップでは、単純な文字列置換を行うための置換パターンを表すパラメータを指定することができます。
パターンと置換文字列はコンマで区切り、全体を波括弧でくくります。
置換指定は、% と指示子の間に置きます。
例えば、「%{src,dst}p」とすると、「src」が「dst」に置換されたパス名が返されます。
これは、「依存ファイル名」から「タスク名」を取得するときに使うことができます。

パスマップの置換指定を使って、「srcディレクトリ以下のすべてのテキストファイルをdstディレクトリ以下にバックアップする」というRakefileを作ってみましょう。

```ruby
sources = FileList["src/*.txt"]
names = sources.pathmap("%{src,dst}p")

task default: names

mkdir "dst" unless Dir.exist?("dst")
names.each do |name|
  source = name.pathmap("%{dst,src}p")
  file name => source do |t|
    cp t.source, t.name
  end
end
```

2行目でパスマップの置換指定を使っています。

- `sources`は配列`["src/a.txt", "src/b.txt", "src/c.txt"]`なので
- `names`は配列`["dst/a.txt", "dst/b.txt", "dst/c.txt"]`になる
 
6行目では、バックアップ先のディレクトリ「dst」が存在しなければ作成します。
mkdirはFileUtilsモジュールのメソッドですが、このモジュールはRakeが自動的にrequireします。
8行目では文字列のpathmapメソッドを使って、タスク名から依存ファイル名を取得しています。

- `name`が`dst/a.txt`または`dst/b.txt`または`dst/c.txt`なので
- sourceは`src/a.txt`または`src/b.txt`または`src/c.txt`になる

`example/example3`フォルダでは`Rakefile6`を使って試してください。

> [R]　正規表現とProcオブジェクトを使ったルールを用いることもできます。
> 
> ```ruby
> sources = FileList["src/*.txt"]
> names = sources.pathmap("%{src,dst}p")
> 
> task default: names
> 
> mkdir "dst" unless Dir.exist?("dst")
> 
> rule /^dst\/.*\.txt$/ => proc {|tn| tn.pathmap("%{dst,src}p")} do |t|
>   cp t.source, t.name
> end
> ```
> 
> 実行してみます。
> （`example/example3`では`-f Rakefile7`をつけて実行してください）
> 
> ```
> $ rm dst/*
> $ rake
> cp src/a.txt dst/a.txt
> cp src/b.txt dst/b.txt
> cp src/c.txt dst/c.txt
> $
> ```
> 
> ルールを使う方がよりシンプルなRakefileになります。

## ディレクトリタスク

ディレクトリタスクを作るdirectoryメソッドをこのセクションの最後に紹介します。
ディレクトリタスクはタスク名の「ディレクトリが存在しなければ作成する」というタスクです。

```ruby
directory "a/b/c"
```

このディレクトリタスクは、「a/b/c」というディレクトリを作成するタスクです。
もし、cの親であるb、aも存在しなければ、それも作成します。

これを用いてdstディレクトリを作ることもできます。

```ruby
sources = FileList["src/*.txt"]
names = sources.pathmap("%{src,dst}p")

task default: names
directory "dst"

names.each do |name|
  source = name.pathmap("%{dst,src}p")
  file name => [source, "dst"] do |t|
    cp t.source, t.name
  end
end
```

注意しなければいけないのは、ディレクトリタスクは「タスク」なので、Rakefileのロード実行中はそのタスクが定義されるだけだということです。
ディレクトリの作成にはタスク呼び出しが必要です。
そこで、「dst」を「dst/a.txt」「dst/b.txt」「dst/c.txt」の事前タスクに追加します。
このことにより、コピーの前にディレクトリの作成が行われます。
（`example/example3`では`-f Rakefile8`をつけて実行してください）

> ｛Ｒ｝ルールを使って書き直してみます。
> 
> ```ruby
> sources = FileList["src/*.txt"]
> names = sources.pathmap("%{src,dst}p")
> 
> task default: names
> directory "dst"
> 
> rule /^dst\/.*\.txt$/ => [proc {|tn| tn.pathmap("%{dst,src}p")}, "dst"] do |t|
>   cp t.source, t.name
> end
> ```
> 
> ルールの事前タスクにディレクトリタスクが追加されています。
> （`example/example3`では`-f Rakefile9`をつけて実行してください）
