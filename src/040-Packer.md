

### /usr/sbin/packer

パスワード強度チェックツールのcracklib ^[[https://github.com/cracklib/cracklib](https://github.com/cracklib/cracklib)] のRPMパッケージには、`/usr/sbin/packer` という `cracklib-packer` コマンドへのシンボリックリンクが存在します。環境変数`PATH`の参照順序によっては、`packer` コマンドの呼び出し時にcracklibのコマンドが呼び出されることがあります。

対処としては、`packer`コマンドの`PATH`の設定で、`Packer`の`packer`コマンドが先に呼び出されるようにするか、フルパスで`packer`コマンドを実行する必要があります。。


## 環境ごとのイメージだし分け


## ユーザデータはシンプルに保つ


## Chefの二段構え

```
set -ux

export SOURCE_AMI="ami-c0394c2d"
export TARGET_NODE="software-local"

set +e

(cd jira && /usr/local/bin/packer build -machine-readable jira-ami.json |tee jira-build.log)
RET=$?
grep 'artifact,0,id' jira/jira-build.log | cut -d, -f6 | cut -d: -f2 > jira/jira.version
exit $RET
```

