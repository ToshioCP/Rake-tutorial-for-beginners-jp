### Rakeのその他の機能

いままで触れなかったRakeの機能について解説します。
内容は、

- タスクの引数
- ディスクリプション
- `rake`コマンドのオプション
- Rakefileのサーチ
- ライブラリ

です。

マルチタスク、テストタスクは次のセクションで説明します。

#### タスクの引数

コマンドラインからタスクを起動するときに引数を渡すことができます。
たとえば、

```
$ rake hello[James]
```

では、タスク名が`hello`で引数が`James`です。

複数の引数を渡したいときはコンマで区切ります。

```
$ rake hello[James,Kelly]
```

ここで注意が必要なのは、スペースを途中に入れてはいけないということです。
なぜなら、スペースはコマンドラインにおいて「引数の区切り」という特別な意味を持っているからです。

- `rake hello[James,Kelly]` => コマンド`rake`に対して1つの引数`hello[James,Kelly]`が渡される。
rakeの中で`hello`がタスク名、`James`と`Kelly`がタスクへの引数という解釈が行われる。
- `rake hello[James, Kelly]` => コマンド`rake`に対して2つの引数`hello[James,`と`Kelly]`が渡される。
rakeは`hello[James,`が閉じカッコ無しなので、文字列全体をタスク名と解釈し、エラーになる。

引数にスペースを入れたいときはダブルクォート（`"`）で囲めば大丈夫です。

```
$ rake "hello[James Robinson,Kelly Baker]"
```

一方、Rakefileにおけるタスク定義では、パラメータをタスク名の次にコンマで区切って書きます。

```
task :a, [:param1, :param2]
```

このタスク`a`はパラメータに`:param1`と`:param2`を持ちます。
パラメータの名前には通常シンボルを用いますが、文字列も可能です。
また、パラメータがひとつならば配列にしなくても構いません。

タスク`a`ではアクションがないので、引数の効果はありません。
引数の効果はアクションの中で発揮されます。

アクション（ブロック）には2番めのパラメータとして引数のインスタンス（TaskArgumentsクラスのインスタンス）が渡されます。

```ruby
task :hello, [:person1, :person2] do |t, args|
  print "Hello, #{args.person1}.\n"
  print "Hello, #{args.person2}.\n"
end
```

ブロック・パラメータは

- t => タスク「hello」のインスタンス
- arg => 引数。TaskArgumentsクラスのインスタンス。

です。

このとき、コマンドラインから次のようにタスクが呼び出されたとします。
（`example/example7`でオプション`-f Rakefile1`をつけて実行してください）

```
$ rake hello[James,Kelly,David]
Hello, James.
Hello, Kelly.
```

パラメータの数よりも引数の数が多いことに気づいた方もいると思います。
このように数が一致しなくてもエラーにはなりません。

TaskArgumentsクラスのインスタンスメソッドをいくつか列挙します。
上の例を使って説明します。

- [] => パラメータの値を返す。
`args[:person1]`とすると`James`が返される。
- パラメータ名。パラメータの値を返す。
`args.person1`とすると`James`が返される。
- to_a => 値の一覧を返す。
`args.to_a`とすると、`["James", "Kelly", "David"]`が返される。
- extras => パラメータより引数が多いとき、余った引数が返される。
`args.extras`とすると、`["David"]`が返される。
- to_hash => パラメータと値を組み合わせたハッシュを返す。
余った引数は除かれる。
`args.to_hash`とすると、`{:person1=>"James", :person2=>"Kelly"}`が返される。
- each => `to_hash`のハッシュについてeachメソッドを実行する。

> ［Ｒ］上にあげた2番めのパラメータ名をメソッドとして使う方法は、実はメソッドとして定義されたものではありません。
> Rakeは`method_missing`メソッド（BasicObjectのメソッド）を使い、メソッド名が定義されていなければパラメータ名の値を返すようにしています。
> それであたかもパラメータ名のメソッドが実行されたように見えるのです。

パラメータのデフォルト値を設定することも出来ます。
`with_defaults`メソッドにハッシュをつけて使います。

```ruby
task :hello, [:person1, :person2] do |t, args|
  args.with_defaults person1: "Dad", person2: "Mom"
  print "Hello, #{args.person1}.\n"
  print "Hello, #{args.person2}.\n"
end
```

デフォルト値が`person1`に対して`Dad`、`person2`に対して`Mom`になりました。
実行してみます。
（`example/example7`でオプション`-f Rakefile2`をつけて実行してください）

```
$ rake hello[James,Kelly,David]
Hello, James.
Hello, Kelly.
$ rake hello[,Kelly,David]
Hello, Dad.
Hello, Kelly.
$ rake hello
Hello, Dad.
Hello, Mom.
```

タスク定義に事前タスクがある場合はパラメータに続けて`=>`、事前タスクを書きます。

```
task :hello, [:person1, :person2] => [:prerequisite1, :prerequisite2] do |t, args|
・・・・
end
```

この例では`prerequisite1`と`prerequisite2`が事前タスクです。
事前タスクには引数が受け継がれますので、その中でパラメータを設定しておけば引数を使うことができます。

```ruby
task :how, [:person1, :person2] => :hello do |t, args|
  print "How are you, #{args.person1}?\n"
  print "How are you, #{args.person2}?\n"
end

task :hello, [:person1, :person2] do |t, args|
  print "Hello, #{args.person1}.\n"
  print "Hello, #{args.person2}.\n"
end
```

タスクhowに与えられる引数が事前タスクhelloにも与えられます。
（`example/example7`では`-f Rakefile3`をつけて実行してください）

```
$ rake -f Rakefile3 how[James,Kelly,David]
Hello, James.
Hello, Kelly.
How are you, James?
How are you, Kelly?
```

上記の例は実用的ではないですが、読者がRakefileの引数を理解する手助けにはなると思います。

引数以外に環境変数を使ってRakeに値を渡すこともできますが、これは古い方法です。
Rakeはバージョン0.8.0以前では引数をサポートしていませんでした。
そのときには環境変数を使うのが引数に代わる方法でした。
現時点では環境変数を引数として使う必要はありません。

#### ディスクリプションとコマンドライン・オプション

タスクの説明（ディスクリプション description）をつけることができます。
`desc`コマンドを使い、対象のタスクの前に記述します。

```
desc "あいさつをするタスク"
task :hello do
  print "Hello.\n"
end
```

説明の文字列はタスク定義時にタスクインスタンスにセットされます。
説明は`rake -T`または`rake -D`で表示されます。

```
$ rake -T
rake hello  # あいさつをするタスク
$ rake -D
rake hello
    あいさつをするタスク

$
```

表示されるのはディスクリプションがあるタスクだけです。
ディスクリプションは、ユーザがコマンドラインから呼び出す可能性のあるタスクにのみ付けるべきです。
例えば、前セクションのHTMLやPDFを作成するRakefileでは、

```ruby
・・・・・
desc "HTMLとPDFの両方のファイルを作成します"
task default: %w[html:build pdf:build]
・・・・・
namespace "html" do
  desc "HTMLのファイルを作成します"
  task build: %w[docs/はじめてのRake.html docs/style.css]
・・・・・
namespace "pdf" do
  desc "PDFのファイルを作成します"
  task build: %w[はじめてのRake.pdf]
・・・・・
```

とするとコマンドラインからタスクの説明を見ることができます。
（`example/example6`で`-f Rakefile1`をつけて実行してください）

```
$ rake -T
rake clean       # Remove any temporary products
rake clobber     # Remove any generated files
rake default     # HTMLとPDFの両方のファイルを作成します
rake html:build  # HTMLのファイルを作成します
rake pdf:build   # PDFのファイルを作成します
```

これでユーザはどのタスクを使えばよいのかが分かります。
ディスクリプションはユーザのためのコメントだということがいえます。

これに対して開発者がプログラムのメモを残したいときはRubyのコメント（`#`から改行まで）を用います。

`-T`オプションでは1行に収まる分しか表示されませんが、`-D`オプションではディスクリプションすべてを表示します。
また、これらのオプションではパターンをつけてタスクを限定することができます。

開発者向けのオプションとしては

- `-AT` => すべての定義されたタスクを表示。
タスク呼び出し時に定義される事前タスクは、この時点では未定義のため表示されません。
- `-P` => タスクの依存関係を表示
- `-t`または`--trace` => すべてのバックトレースを表示

とくに、`-t`または`--trace`オプションは開発の上で有益です。

#### Rakefileのサーチとライブラリ

カレントディレクトリにRakefileが見つからない場合、上位のディレクトリを探していきます。
たとえば、カレントディレクトリが`a/b/c`で、Rakefileが`a`にあれば、

- `a/b/c`でRakefileをサーチ　＝＞　ない。ひとつ上のディレクトリへ
- `a/b`でRakefileをサーチ　＝＞　ない。ひとつ上のディレクトリへ
- `a`でRakefileをサーチ　＝＞　ある。Rakefileを読み込んで実行。このときRakeのカレントディレクトリは`a`になる（`a/b/c`ではないことに注意）。

また、`-f`オプションでRakefileを指定することも可能です。

Rakefileは1つのファイルに書くことが多いと思いますが、大きな規模の開発では複数のファイルに分けることが考えられます。
その際は

- ライブラリとなるRakefileには`.rake`の拡張子をつける（ファイル名はRakefileでなくてもよい）
- ライブラリはトップディレクトリ（Rakefileのあるディレクトリ）直下の`rakelib`ディレクトリにおく

このとき、Rakefileとライブラリにプログラム上の主従関係はないのですが、トップディレクトリのRakefileを「メインのRakefile」ということがあります。
