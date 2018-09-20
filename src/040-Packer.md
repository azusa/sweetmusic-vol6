



## プロビジョニングツールとの連携


## 環境ごとのイメージだし分け

## 作成したAMIイメージの取得と引き渡し

OSのベースイメージからアプリケーションの基本設定ずみイメージ、環境ごとのカスタムイメージと、イメージの構築にあたってパイプラインを構築するには、前の段のパイプラインで作成したイメージのIDを引き渡す必要があります。

ビルドの出力からイメージのIDを取得するには、`packer`を`-machine-readable`オプションを付けて実行し、出力されたログからgrepすることで、イメージのIDを取り出します。

そして取り出したファイルをCIサーバーのartifact(この場合`jira.version`)とすることで、後続の処理でイメージのIDを取得可能にします。

```
/usr/local/bin/packer build -machine-readable jira-ami.json |tee jira-build.log
RET=$?
grep 'artifact,0,id' jira/jira-build.log | cut -d, -f6 | cut -d: -f2 jira.version
exit $RET
```

後続のテンプレートでは、


## ユーザデータはシンプルに保つ

ec2には、ユーザーデータを使って、起動時に実行するスクリプトを指定できます。このスクリプト内で、サーバーのプロビジョニングを行う事ができます。

しかしユーザーデータのスクリプトには、プロビジョニングツールなど、他のサーバー構築の仕組みでカバーしきれない処理が集中しがちであり、肥大化しがちです。また、ユーザーデータのスクリプトのデバッグを確実に行うためにはec2のインスタンを作成する必要がある、ユーザデータが肥大化すると、スクリプトのデバッグが難しくなってきます。

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

