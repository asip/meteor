
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

## Explanation
This libarary is lightweight (X)HTML(5) parser.
This can use as XML parser.
This may be false parser.

This libarary doesn't support all of XML spec.
This supports a range of xml spec
thought to be the need routinely.

軽量(簡易?)(X)HTML(5)パーサです。
XMLパーサとしても使用可能です。
パーサもどきかもしれません。

(X)HTML(5)、XMLの仕様の全てをサポートしてはいません、
日常的に必要と思われる範囲をサポートしています。

This doesn't convert the whole into objects but
converts only elements for the operation into objects.
(This library uses regular expression internally but user
don't need to concern yourself with internal logic.)

DOMのように全体をオブジェクトのツリー構造に変換するのではなく、
操作対象の要素のみをオブジェクトに変換します。
(内部では正規表現を使っていますが、ユーザがそれを意識する
必要は全くありません。)

## API
http://rubydoc.info/github/asip/meteor/master/frames

## Sample
https://github.com/asip/meteor/tree/master/demo

## License
Licensed under the LGPL V2.1.

## Author
 Yasumasa Ashida (ys.ashida@gmail.com)

## Copyright
(c) 2008-2014 Yasumasa Ashida
