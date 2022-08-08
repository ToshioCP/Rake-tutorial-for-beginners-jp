# ファイルタスク

この章ではファイルタスクを説明します。
ファイルタスクはRakeにおいて最も重要なタスクです。
ファイルタスクのためにRakeがあると言っても過言ではありません。

## ファイルタスクとは？

ファイルタスクはタスクの一種です。
ファイルタスクにも一般のタスクと同じように「名前」「事前タスク」「アクション」があります。
一般のタスクとの違いは次の3点です。

- ファイルタスクの「名前」は（ファイルの）パスを表す。
- ファイルタスクにはそのアクションを実行するかどうかについての条件がある
- ファイルタスクはfileメソッドで定義する（一般のタスクはtaskメソッド）

これ以外は一般のタスクと同じように「タスクの呼び出しの前に事前タスクを呼び出す」「タスクの実行は一度だけ」です。

それでは、ファイルタスクのアクションを実行する上での条件とは何でしょうか。
条件は2つあります。

- タスクの名前が示すファイルが存在しない
- タスクの名前が示すファイルのmtime（ファイル内容変更時間）が、その事前タスク（複数ある場合はそのどれか）のmtimeよりも古い。
ただし、事前タスクがファイルタスクではない場合（一般のタスクである場合）はmtimeの代わりに現在時刻を用いる。
したがって、事前タスクが一般のタスクを含む場合は、そのファイルタスクは常に実行される。

> ［Ｒ］ここでいうmtime（ファイル内容変更時間）はRubyのFile.mtimeメソッドの値です。
> Linuxのファイルにはatime, mtime, ctimeの3つのタイムスタンプがあります。
> 
> - atime 最後にアクセスされた時刻
> - mtime 最後に変更された時刻
> - ctime 最後にinodeが変更された時刻
> 
> RubyのFile.mtimeメソッドはこのmtimeを返します。（C言語で書かれたオリジナルのRubyはCのシステムコールでその値を取得しています）

## ファイルのバックアップ

それでは具体例を見ていきましょう。
ここではテキストファイル「a.txt」のバックアップファイル「a.bak」を作ることを考えます。
単純にファイルをコピーすれば良いので、

```
$ cp a.txt a.bak
```

で出来ますが、練習のためにRakefileにしてみます。

```ruby
file "a.bak" => "a.txt" do
  cp "a.txt", "a.bak"
end
```

このRakefileの内容を説明します。

- fileメソッドでファイルタスク「a.bak」を定義しています
- a.bakの事前タスクは「a.txt」です。
- タスク「a.bak」のアクションは`cp "a.txt", "a.bak"`です。

cpメソッドは第1引数ファイルを第2引数ファイルにコピーするメソッドです。
このメソッドはFileUtilsモジュールで定義されています。
FileUtilsはRubyの標準添付ライブラリですが、ビルトインではないため、通常は`require 'fileutils'`をプログラムに書かなければなりません。
しかし、Rakeが自動的にrequireするのでRakefileにそれを書く必要はありません。

タスク「a.bak」が呼び出されると、その実行の前に事前タスク「a.txt」が呼び出されます。
ところが、Rakefileにはタスク「a.txt」の定義が書かれていません。
Rakeは事前タスクの定義が無いときにどのように振る舞うのでしょうか？
Rakeはファイル「a.txt」存在するならば、ファイルタスク「a.txt」を名前だけのタスク（事前タスクとアクションは無い）として自ら定義します。
そしてそのタスクを呼び出しますが、アクションが無いので何もせずに「a.bak」の呼び出しに戻ります。
もし「a.txt」が存在しなければエラーになります。

それでは、コマンドラインから実行してみましょう。
（`example/example2`で試すには、`rake -f Rakefile1 a.bak`としてください。
`ls`の結果は`example/example2`では異なります）

```
$ ls
Rakefile  a.txt
$ rake a.bak
cp a.txt a.bak
$ ls
Rakefile  a.bak  a.txt
$ diff a.bak a.txt
$ rake a.bak
$
```

- 最初はカレントディレクトリには「Rakefile」と「a.txt」の2つのファイルだけがあります。
- rakeを実行すると、「a.txt」が「a.bak」にコピーされます。
- ディレクトリをリスティングすると、「a.bak」が新たに加わっています。
- diffを使って「a.bak」と「a.txt」を比較すると、同じ内容のファイルなので、何もメッセージが出ません
- 再びrakeを実行しますが、「a.bak」が「a.txt」より後に作成されているため、アクションは実行されません

ここでは、最も基本的なファイルタスクの使い方を学びました。

## 複数ファイルのバックアップ

次に3つのファイルをバックアップするRakefileについて考えてみましょう。
新たに「b.txt」と「c.txt」というファイルを作っておきます。
Rakefileのもっとも初歩的な書き方は、次のようなものでしょう。

```ruby
file "a.bak" => "a.txt" do
  cp "a.txt", "a.bak"
end

file "b.bak" => "b.txt" do
  cp "b.txt", "b.bak"
end

file "c.bak" => "c.txt" do
  cp "c.txt", "c.bak"
end
```

ここには、3つのファイルタスクが定義されています。
それを実行してみましょう。
（`example/example2`では`-f Rakefile2`をつけて実行してください）

あらかじめ、「a.bak」は削除しておきます。

```
$ ls
Rakefile  a.txt  b.txt  c.txt
$ rake a.bak
cp a.txt a.bak
$ rake b.bak
cp b.txt b.bak
$ rake c.bak
cp c.txt c.bak
$ ls
Rakefile  a.bak  a.txt  b.bak  b.txt  c.bak  c.txt
```

皆さん既に気がついたことと思います。
「自分だったらこんなことしない。rakeを3回使うのならcpを3回使うのと変わらないじゃないか」。
その通りです。

一度のRake実行で3個のファイルをコピーしたいですね。
これは、一般のタスクと3つのファイルタスクを関連付けることで実現できます。
最初に「copy」タスクを作り、3つのファイルタスクをその事前タスクにしてみましょう。

```ruby
task copy: %w[a.bak b.bak c.bak]

file "a.bak" => "a.txt" do
  cp "a.txt", "a.bak"
end

file "b.bak" => "b.txt" do
  cp "b.txt", "b.bak"
end

file "c.bak" => "c.txt" do
  cp "c.txt", "c.bak"
end
```

実行してみます。
（`example/example2`では`-f Rakefile3`をつけて実行してください）

```
$ rm *.bak
$ rake copy
cp a.txt a.bak
cp b.txt b.bak
cp c.txt c.bak
```

一度のrake実行で3つのコピーができました。

リファクタリングしましょう。
2つのことを改善します。

- トップレベルのタスクを「copy」から「default」に変えます。
「default」はrakeの引数が省略されたときに実行されるデフォルトのタスクです。
- 3つのファイルタスクをRubyのイテレーションを使って1つにまとめます。

```ruby
backup_files = %w[a.bak b.bak c.bak]

task default: backup_files

backup_files.each do |backup|
  source = backup.ext(".txt")
  file backup => source do
    cp source, backup
  end
end
```

- はじめに、バックアップ・ファイルの配列を作り、「backup\_files」という変数に代入しておきます。
- トップレベルのタスクを「default」にします。
- バックアップファイルの配列の一つひとつの要素を取り出すeachメソッドを用います。
取り出した要素がブロックのbackup変数に代入されます。
- 変数sourceに、backupの拡張子を「.txt」に変えたものを代入します。
「ext」メソッドはRakeがStringクラスに追加したメソッドで、拡張子を変更するものです。
元々のStringクラスには「ext」メソッドはありません。
- fileコマンドでファイルタスクを定義します。
「each」メソッドで、ブロックが3回繰り返されるので、fileコマンドも3回実行され、「a.bak」「b.bak」「c.bak」の3つのファイルタスクが定義されます。

実行してみます。
（`example/example2`では`-f Rakefile3`をつけて実行してください）

```
$ rm *.bak
$ rake
cp a.txt a.bak
cp b.txt b.bak
cp c.txt c.bak
$ touch a.txt
$rake
cp a.txt a.bak
$
```

- バックアップファイルをすべて削除します
- rakeを実行すると、3つのファイル全てがコピーされます。
- touchを使って「a.txt」のmtimeを更新します（現在時刻に設定する）
- rakeを実行すると、「a.bak」のmtimeよりも「a.txt」のmtimeの方が新しいので、ファイルタスク「a.bak」のアクションを実行します。
他のファイルタスクはバックアップのmtimeの方が新しいので、アクションは実行されません。

例の最後で「touch」を使ってmtimeを変更しましたが、通常はエディタでファイルを上書きするときにmtimeの更新が起こります。
つまり、元ファイルが新しくなるとファイルタスクのアクションを実行する条件が整うことになります。

少々リファクタリングを追加し、ブロックの中でタスクのインスタンスを使う方法を紹介します。

ファイルタスクの定義の部分を次のように変更します。

```ruby
file backup => source do |t|
  cp t.source, t.name
end
```

ブロックに新たにパラメータ「t」が加わりました。
「t」にはファイルタスク「backup」が代入されます。
（Ruby的にはそのインスタンスがだいにゅうされます）

taskメソッドのブロックでも同じパラメータが使えます。

タスクやファイルタスクには便利なメソッドがあります。

- `name` タスクの名前を返す
- `prerequisites` 事前タスクの配列を返す
- `sources` 自身が依存するファイルのリストを返す
- `source` 自身が依存するファイルのリストの最初の要素を返す

この他にもメソッドはありますが、よく使われるのは上の4つのメソッドです。

新しいファイルタスクの定義では、そのアクションが「t.source」から「t.name」にコピーするように変わっています。
これは、それぞれ「source」と「backup」になりますから、以前のファイルタスクと内容的には同じです。
（`example/example3`では`-f Rakefile5`をつけて実行してください）

## ルール

これまでのバックアップは「.txt拡張子のファイルを.bak拡張子のファイルにコピーする」というものでした。
これを「a.bak」というファイル名にあてはめれば、「a.txtをa.bakにコピーする」というアクションを持つファイルタスクが得られます。
このように、ファイルタスクを作るための規則をルールと呼びます。
ルールは「rule」メソッドで定義できます。
具体的に「rule」を使ったRakefileの例を見てみましょう。

```ruby
backup_files = %w[a.bak b.bak c.bak]

task default: backup_files

rule '.bak' => '.txt' do |t|
  cp t.source, t.name
end
```

はじめの3行は今までと変わりません。
3行目の定義によると、defaultの事前タスクは「a.bak」「b.bak」「c.bak」ですが、それらのタスクの定義は書かれていません。
Rakeは、事前タスクの定義がないときは、その呼び出しの直前に事前タスクの定義を試みます。

- ルールが定義されていて、タスク名がルールに合致するときは、そのルールを用いてタスクを定義する
- 合致するルールが無く、タスク名が、その時点で存在するファイル名に一致すれば、タスク名のみ（事前タスクとアクションが無い）のファイルタスクを定義する
- 以上のどれでもなければ、エラーになる

この例におけるルールは次のようになります。

- タスク名の拡張子が「.bak」である
- 依存するファイル名の拡張子が「.txt」である
- アクションは、そのタスクの「t.source」（タスクが依存するファイルの配列の最初の要素）を「t.name」（タスク名＝ファイル名）にコピーする、ということである

3つのタスク「a.bak」「b.bak」「c.bak」はすべてルールに合致するので、ルールに従ってタスクが定義されます。
それでは、実行してみましょう。
（`example/example2`では`-f Rakefile6`をつけて実行してください）

```
$ rm *.bak
$ rake
cp a.txt a.bak
cp b.txt b.bak
cp c.txt c.bak
$
```

今までと同じように動作しました。

ruleメソッドの`'.bak'`の部分は、Rakeが正規表現`/\.bak$/`に変換します。
この正規表現とタスク名の「a.bak」「b.bak」「c.bak」が比較されるのです。
そこで、最初から正規表現にしておいてもルールを定義できます。
（`example/example2`では`-f Rakefile7`をつけて実行してください）

```ruby
rule /\.bak$/ => '.txt' do |t|
  cp t.source, t.name
end
```

> [R]　このことは、「拡張子の一致」だけでなく「任意のパターンに対する一致」を可能にします。
> 例えば、バックアップファイルを「~a.txt」のように先頭にチルダ「`~`」を付けるように変更することが可能です。
>
> ```ruby
> backup_files = %w[~a.txt ~b.txt ~c.txt]
>
> task default: backup_files
>
> rule /^~.*\.txt$/ => '.txt' do |t|
>   cp t.source, t.name
> end
> ```
>
> ところが、これではエラーになってしまいます。
>
> ```
> $ rake
> rake aborted!
> Rake::RuleRecursionOverflowError: Rule Recursion Too Deep: [~a.txt => ~a.txt =>
> ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt =>
> ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt => ~a.txt]
>
> Tasks: TOP => default
> (See full trace by running task with --trace)
> ```
>
> これは、`=> '.txt'`の部分が良くないのです。
> これだと「~a.txt」の依存ファイルが、タスク名の「~a.txt」の拡張子を「.txt」に変えたものである「~a.txt」になってしまいます。
> つまりタスク名と依存タスク名が同じなので、ルールを適用するときに無限ループに陥ってしまうのです。
> Rakeでは、16回のループが起きたときにエラーとして処理します。
>
> これを避けるには、依存ファイルをProcオブジェクトで定義します。
>
> ```ruby
> backup_files = %w[~a.txt ~b.txt ~c.txt]
>
> task default: backup_files
>
> rule /^~.*\.txt$/ => proc {|tn| tn.sub(/^~/,"")} do |t|
>   cp t.source, t.name
> end
> ```
> procメソッドのブロックの引数には、タスク名（例えば「~a.txt」）がRakeによって渡されます。
> Procインスタンスの生成には、lambdaメソッドや「->\( \)\{ \}」（[Rubyのドキュメント参照](https://docs.ruby-lang.org/ja/3.0/doc/symref.html#rangl)）も使えます。
>
> 実行してみます。
> （`example/example2`では`-f Rakefile8`をつけて実行してください）
>
> ```
> $ rake
> cp a.txt ~a.txt
> cp b.txt ~b.txt
> cp c.txt ~c.txt
> $
> ```
