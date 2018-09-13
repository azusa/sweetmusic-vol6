# VagrantとPackerによる開発環境

## IaCにおける開発環境の必要性

# Vagrantのボックスの仕様

Vagrantでは、Vagrantbox.es ^[[https://www.vagrantbox.es/](https://www.vagrantbox.es/)] でボックスが公開されていますが、ボックスの構成の仕様は明文化されていないものもあります。

VagrantのBoxを、Infrastructure as Codeのベースとして使用するには、ボックス内のVMのOSがどのような構成で構築されているかを、厳密に管理する必要があります。

この場合、VagrantのBoxを、Vagrantの仕様にのっとり、OSをセットアップするところからはじめることになります。

VagrantのBoxを作成するにあたっての仕様は、以下のURLで公開されています。

- [https://www.vagrantup.com/docs/boxes/base.html]https://www.vagrantup.com/docs/boxes/base.html

主な仕様は、以下の通りです。

- ユーザー: `vagrant`がパスワード`vagrant`でログインできること
- rootのパスワードは `vagrant` であること
- `vagrant` ユーザーがパスワードなしでsudoできること

## BoxCutterによるベースイメージの作成

Vagrantのボックス作成はVirtualBox等の仮想マシンで手動でOSをセットアップした後、`vagrant package` コマンドで仮想マシンのイメージをエクスポートすることでも行えますが、OSのアップデートごとに手動の作業を繰り返すことになります。

この本で取り上げるPackerを使用して、OSセットアップの手順をスクリプト化したプロダクトがBoxcutterです。BoxcutterはGitHubで公開 ^[[https://github.com/boxcutter](https://github.com/boxcutter)] されています。BoxCutterはChef社出身で、現在はAppleで自動化に関わるエンジニアであるMischa Taylor氏が中心となってメンテナンスしています。

## Packer

Packerは複数プラットフォームの仮想マシンのイメージ構築をコード化するプロダクトです。Hashicorpによって開発され、オープンソースで公開されています。

## Packerの導入

Packerはgoで開発されており、単一バイナリーで提供されています。Packerを導入するには、[https://www.packer.io/downloads.html](https://www.packer.io/downloads.html) から、プラットフォームにあわせたアーカイブをダウンロードし、展開した中にあるファイルを環境変数`PATH`の通ったディレクトリーに配置し、パーミッションを適切に設定します。

### /usr/sbin/packer

パスワード強度チェックツールのcracklib ^[[https://github.com/cracklib/cracklib](https://github.com/cracklib/cracklib)] のRPMパッケージには、`/usr/sbin/packer` という `cracklib-packer` コマンドへのシンボリックリンクが存在します。環境変数`PATH`の参照順序によっては、`packer` コマンドの呼び出し時にcracklibのコマンドが呼び出されることがあります。

対処としては、`packer`コマンドの`PATH`の設定で、`Packer`の`packer`コマンドが先に呼び出されるようにするか、フルパスで`packer`コマンドを実行する必要があります。。

## Boxcutterの

Packerは、構成のテンプレートをjson形式で記述します。boxcutterでは、`centos.json`です。

## 変数

Packerでは、テンプレートをビルドする際に、パラメーターをユーザー変数(User Variables)として渡すことができます。

ユーザー変数を渡す方法には、

- コマンドライン引数
- JSON形式のファイル

の二通りの方法があります。

BoxcutterではJSON形式のファイルでユーザー変数を定義する方法を採用しており、そのファイルは `centos7.json`ないし`centos6.json`となります。

```
packer build -only=virtualbox-iso -var-file=centos7.json centos.json
```

# boxcutterのビルドの高速化

Packerによるビルド時に、OSのインストールイメージとなるisoファイルを初回にダウンロードします。テンプレート内で指定されている`mirros.sonic.net`のエッジサーバーが日本国内に存在しないため、日本国内のネットワークからはダウンロードに時間がかかります。

ダウンロードを高速化するためには、変数指定されている`centos7.json`ないし`centos6.json`内の`iso_url`の項目を日本国内のミラーサイトのURLに修正します。


## プロビジョニングツールとの連携

シェルで連携する

## インストーラーをどこに配置するか


## なぜChefなのか

## Vagrantfile内でのイメージの指定

```
 config.vm.box_url="http://images.fieldnotes.jp/images/centos7-7.5.1804-1.box"
```

```
 local.vm.box = "centos7.5-1804-1"
```

