### はじめてのRake（３）

「はじめてのRake」の第3回です。 今回はファイルタスクの説明（後半）です。
今回はファイルタスクを記述する上で便利なファイルリストとパスマップを解説します。

はじめてこのブログを見る方は「[はじめてのRake（１）](https://toshiocp.com/entry/2022/07/22/112021)」からご覧になってください。

文中に［Ｒ］という記号で始まる段落は、「Ruby上級者向けの解説」です。
上級とは、ほぼ「クラスを記述できるレベル」を指します。
上級以外の方はこの部分を飛ばしてください。

#### ファイルリスト

ファイルリストは、ファイル名のリストで、文字列の配列と同様の操作ができ、さらにいくつかの便利な機能を備えているオブジェクトです。
まずファイルリストのインスタンスの作り方からお話しましょう。
クラス名「FileList」に`[ ]`をつけ、そのカッコのなかにファイル名をコンマで区切って書きます。
これで、そのファイルのファイルリストができます。

```ruby
files = FileList["a.txt", "b.txt"]
p files

task :default
```

実行してみます。

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

```
$ ls
 Rakefile   a.txt   b.txt   c.txt  '~a.txt'
$ rake
["a.txt", "b.txt", "c.txt", "~a.txt"]
$
```

Globパターンについては[Rubyのドキュメント](https://docs.ruby-lang.org/ja/3.0/class/Dir.html#S_--5B--5D)を参考にしてください。

#### すべてのテキストファイルのバックアップ

すべてのテキストファイルをバックアップすることを考えてみます。
ここでは、「テキストファイル」を「拡張子が.txtのファイル」としておきます。
このとき、「すべて」というのは「現時点でのすべて」ではなく、「Rakeを実行する時点でのすべて」です。
将来テキストファイルが追加されたり、削除されたりする可能性があまりすから、「現時点でのすべてのテキストファイル」と将来「Rakeを実行する時点でのすべてのテキストファイル」は同じとは限りません。
ですから、Rakefileの記述の中に、その時点でのテキストファイルを捕まえる仕組みを作らなければなりません。
それは、ファイルリストを使うと、

```ruby
files = FileList["*.txt"]
```

と表せます。

さて、この中に「~a.txt」が含まれていますが、これはオリジナルが「a.txt」であるバックアップファイルですから、コピーの対象から外したいですね。
そのときにはexcludeメソッドを使います。

```ruby
files = FileList["*.txt"]
files.exclude("~*.txt")
p files

task :default
```

excludeメソッドは、与えられたパターンを自身の除外リストに加えます。
実行してみましょう。

```
$ rake
["a.txt", "b.txt", "c.txt"]
$
```

「~a.txt」が取り除かれました。

今ファイルリストにしたのは、オリジナルのファイルです。
Rakefileのファイルタスクはバックアップファイルでした。
どういうことかというと、例えば「a.txt」を「a.bak」にコピーするファイルタスクでは、

- タスク名は「a.bak」
- 依存ファイル名が「a.txt」

です。
今のファイルリストは「依存ファイルのリスト」であって、「ファイルタスク（タスク名）のリスト」ではありません。
そこで、タスク名のリストを取得する必要があります。
ファイルタスクにはextメソッドがあり、拡張子を変更できます。

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
上の例もその手法を用いています。

#### パスマップ

パスマップ・メソッドはファイルリストの強力なメソッドです。
元々はpathmapはStringオブジェクトのインスタンス・メソッドです。
これをFileListの各要素に対して実行するのがファイルリストのパスマップ・メソッドです。
パスマップは、その引数によって、様々な情報を返します。
よく使われる例をあげます。

- %p => 完全なパスを表します
- %f => 拡張子付きのファイル名を表します。ディレクトリ名は含まれません。
- %n => 拡張子なしのファイル名を表します。
- %d => パスに含まれるディレクトリのリストを表します。

Rakefileにパスマップの例を書いて実行してみましょう。
まず、カレントディレクトリの下に「src」ディレクトリを作り、その下に「a.txt」「b.txt」「c.txt」を作ります。

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

実行してみます。

```
$ rake
["src/a.txt", "src/b.txt", "src/c.txt"]
["a.txt", "b.txt", "c.txt"]
["a", "b", "c"]
["src", "src", "src"]
```

パスマップでは、単純な文字列置換を行うための置換パターンを表すパラメータを指定することが出来ます。
パターンと置換文字列はコンマで区切り、全体を波括弧でくくります。
置換指定は、% と指示子の間に置きます。

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
mkdirはFileUtilsモジュールのメソッドですが、このモジュールはRakeがrequireするので、このように使うことが出来ます。
8行目では文字列のpathmapメソッドを使っています。

- `name`が`dst/a.txt`または`dst/b.txt`または`dst/c.txt`なので
- sourceは`src/a.txt`または`src/b.txt`または`src/c.txt`になる

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
> 
> ```
> $ rm dst/*
> $ rake
> cp src/a.txt dst/a.txt
> cp src/b.txt dst/b.txt
> cp src/c.txt dst/c.txt
> $
> ```

#### ディレクトリタスク

ディレクトリタスクを作るdirectoryメソッドを最後に紹介します。
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

rule /^dst\/.*\.txt$/ => [proc {|tn| tn.pathmap("%{dst,src}p")}, "dst"] do |t|
  cp t.source, t.name
end
```

注意しなければいけないのは、ディレクトリタスクは「タスク」なので、Rakefileのロード、実行中はそのタスクが定義されるだけで、ディレクトリの作成はRakefileのロード、実行後に行われるということです。
そのため、タスクの依存関係の中にディレクトリタスクを組み込まなければなりません。
例では、ルールの事前タスクにディレクトリタスクを追加しました。
このことにより、コピーの前にディレクトリの作成が行われます。

以上、ファイルタスクを補助するファイルリスト、パスマップ・メソッド、ディレクトリタスクについて説明しました。
次回はこれまでの知識を使って、実践的なRakefileを書いてみます。
