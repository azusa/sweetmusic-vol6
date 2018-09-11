

### /usr/sbin/packer

パスワード強度チェックツールのcracklib ^[[https://github.com/cracklib/cracklib](https://github.com/cracklib/cracklib)] のRedHat向けパッケージには、`/usr/sbin/packer` という `cracklib-packer` コマンドへのシンボリックリンクが存在します。環境変数`PATH`の参照順序によっては、`packer` コマンドの呼び出し時にcracklibのコマンドが呼び出されることがあります。

対処としては、`packer`コマンドの`PATH`の設定で、`Packer`の`packer`コマンドが先に呼び出されるようにするか、フルパスで`packer`コマンドを実行する必要があります。。


## 環境ごとのイメージだし分け

## ユーザデータはシンプルに保つ

## Chefの二段構え

