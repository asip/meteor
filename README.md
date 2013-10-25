
Meteor
==================
 A lightweight (X)HTML(5) & XML Parser

```shell
  gem install meteor #gem installation
```
```shell
  #archive installation
  gem build meteor.gemspec
  gem install meteor-*.gem
```

##Explanation
Sorry, written in Japanese.

軽量(簡易?)(X)HTML(5)パーサです。
XMLパーサとしても使用可能です。
パーサもどきかもしれません。
(X)HTML(5)、XMLの仕様の全てをサポートしてはいません、
日常的に必要と思われる範囲をサポートしています。

DOMのように全体をオブジェクトのツリー構造に変換するのではなく、
操作対象の要素のみをオブジェクトにする仕組みになっています。
(内部では正規表現を使っていますが、ユーザがそれを意識する
必要はありません。)


## License
Licensed under the LGPL V2.1.

##Author
 Yasumasa Ashida (ys.ashida@gmail.com)

##Copyright
(c) 2008-2013 Yasumasa Ashida
