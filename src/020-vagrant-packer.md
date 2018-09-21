# VagrantとPackerによる開発環境

## バージョン管理からVagrantfileを取得して仮想マシンを作成するステップ

```
git clone https://github.com/azusa/techbookfest6-vagrant
cd techbookfest6-vagrant
vagrant up
```

仮想マシンの作成後に、AnsibleのPlaybook等でのVMの構成が
変更になった場合は、`git pull`コマンドで変更内容を取得し、
`vagrant provision`コマンドでプロビジョニング処理を実行します。

```
git pull origin master
vagrant provision
```

VMの再起動は`vagrant reload`コマンド、終了は`vagrant halt`コマンドで行います。
```
# 再起動
vagrant reload
# 終了
vagrant halt
```

VMを破棄する場合は`vagrant destroy`コマンドを実行します。

```
vagrant destroy
```

## Vagrantfile

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

また、VMイメージのファイルサイズの縮小のため、仮想ハードディスクの領域をエクスポートする前に`/dev/zero`でクリアすることが望ましいです。他にも、RedHat 6 / CentOS 6 の場合は、ネットワークインターフェースのMacアドレスの情報が保存されないように、`/etc/udev/rules.d/70-persistent-net.rules`をディレクトリーにしておくなどの手順が必要になります。

Vagrantのボックス作成はVirtualBox等の仮想マシンで手動でOSをセットアップした後、`vagrant package` コマンドで仮想マシンのイメージをエクスポートすることでも行えますが、`vagrant package`コマンドを使用した場合はOSのアップデートごとに手動の作業を繰り返すことになります。

### Windows10とVirtualboxとVagrantの微妙な関係

VagrantのBoxには、動作するVirtualBoxのバージョンに応じたVBoxGuestAdditionsが仮想マシン上のゲストOSにインストールされている必要があります。

ところで、マイクロソフト社のWindows10では「Windows as a Service」というコンセプトに基づき、数年ごとにWindowsの新しいバージョンをデリバリーするリリースサイクルから、年に２～3回、小規模な機能更新が提供されるリリースサイクルが採用されました。

このリリースサイクルの変更により、VirtualBoxがWindows側の仕様変更の影響を受け、VirutalBoxのバージョンアップが必要になる場合があります。

そしてVirtualBoxのバージョンがあがるということはVBoxGuestAdditionsの再インストールが必要となり、これまで使用していたBoxがそのままでは使用できなくなり…ということが、これまでのWindows10の機能リリースでは続いています。

VirtualBoxのバージョンアップにVagrantのBoxを追従するには、vagrant-vbguestの`vagrant vbguest`コマンドでVBoxGuestAdditionsを更新するか、VBoxGuestAdditionsを更新したVagrantのBoxを作成するかのいずれかになります。

また、VirutalBoxのバージョンアップ時に、ゲストOSのパッケージの更新が行われていない状態だと、
VboxguestAdditionのビルド時に必要な、Linux Kernelの開発者向けのパッケージ ^[RPMだとkernel-devel]がインストールできず、VboxguestAdditionの更新に失敗する場合があります。

これらの問題を踏まえて、開発の現場でVagrantを用いたローカル開発環境の運用を継続的に行うためには、
この本で取り上げるPackerを使用して、ボックスの更新とその配付の仕組みを作り込む必要があります。

## BoxCutterによるベースイメージの作成

Packerを使用して、Vagnrantなどの仮想環境でのOSセットアップの手順をスクリプト化したプロダクトがBoxcutterです。BoxcutterはGitHubで公開 ^[[https://github.com/boxcutter](https://github.com/boxcutter)] されています。BoxCutterはChef社出身で、現在はAppleで自動化に関わるエンジニアであるMischa Taylor氏が中心となってメンテナンスしています。

## Packer

Packerは複数プラットフォームの仮想マシンのイメージ構築をコード化するプロダクトです。Hashicorpによって開発され、オープンソースで公開されています。

## Packerの導入

Packerはgoで開発されており、単一バイナリーで提供されています。Packerを導入するには、[https://www.packer.io/downloads.html](https://www.packer.io/downloads.html) から、プラットフォームにあわせたアーカイブをダウンロードし、展開した中にあるファイルを環境変数`PATH`の通ったディレクトリーに配置し、パーミッションを適切に設定します。

## Boxcutterの設定ファイル

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

## boxcutterのビルドの高速化

Packerはビルド時に、OSのインストールイメージとなるisoファイルを初回のビルドにダウンロードします。テンプレート内で指定されている`mirros.sonic.net`は日本国内にエッジサーバーが存在しないため、デフォルトの指定ではisoファイルのダウンロードに時間がかかります。

ダウンロードを高速化するためには、変数指定されている`centos7.json`ないし`centos6.json`内の`iso_url`ならびに`iso_checksum`の項目を日本国内のミラーサイトのURLならびにチェックサムに修正します。

```
{
 (略)
  "iso_checksum": "506e4e06abf778c3435b4e5745df13e79ebfc86565d7ea1e128067ef6b5a6345",
  "iso_checksum_type": "sha256",
  "iso_url": "http://ftp.riken.jp/Linux/centos/7.5.1804/isos/x86_64/CentOS-7-x86_64-DVD-1804.iso",
 (略)
} 
```


## Vagrantとプロビジョニングツールとの連携

Vagrantには、プロビジョニングの仕組みの中でChefやAnsibleなど、プロビジョニングツールと連携する仕組みがあり、Vagrantによる仮想マシンの起動時にプロビジョニングの処理を実行することができます。

しかし、Vagrantによるプロビジョニング処理の実行は、実際にサーバーをセットアップする時と異なるインターフェースやパラメーターで処理を行う事になり、実機のセットアップ時に落としていた問題が発生しがちです。

Vagrantによるプロビジョニングと、実機のプロビジョニングで、構成を揃えるためには、VagrantのShell Provisioner ^[[https://www.vagrantup.com/docs/provisioning/shell.html](https://www.vagrantup.com/docs/provisioning/shell.html)] の仕組みを使用し、Vagrantから実行するときの実機で実行するときで、同一のシェルスクリプトを実行するようにします。

```
curl -L https://www.opscode.com/chef/install.sh | bash
set +e
service systemctl stop jira
set -e
chef-client -z -c ${CURRENT}/solo.rb -j ${CURRENT}/nodes/${1}.json -N ${1}

```

VagrantのShell Provisionerを実行する際、Vagrantfileで指定したスクリプトは`/tmp`にアップロードされて実行されます。通所Ansibleのplaybook等は`/vagrant`配下にマウントされていますので、シェルスクリプト上からプロビジョニングツールを実行する場合は、Vagrantから実行する場合に限りカレントディレクトリーを`/vagrant`に切り替えて実行します。実機でのプロビジョニング時は、実行するスクリプトのあるディレクトリー上にカレントディレクトリーを切り替えて実行します。

```
cd /vagrant
bash provisioning.sh
```

```
yum -y install ansible

CURRENT=$(cd $(dirname $0) && pwd)
cd $CURRENT

PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ansible-playbook --limit="default" --inventory-file=localhost -v provision/localhost.yml
```


なお、Windows上で実行するVagrantでShell Provisionerを使用してシェルスクリプトを実行する場合は、ローカルにチェックアウトした環境上でシェルスクリプトの改行コードが`LF`になっている必要があります。

Git for Windowsのデフォルト設定では改行コードを`CRLF`に変換するようになっているため、`.gitattributes`で改行コードを`LF`としてチェックアウトするよう設定する必要があります。

```
* eol=lf
```


## Vagrantfile内でのイメージの指定

Packerで作成したボックスを開発チームに配布するには、ボックスのファイルをhttpでアクセス可能な場所に
配置し、そのURLをVagrantfileの`vm.box_url`に指定します。

```
 vm.box_url="http://images.fieldnotes.jp/images/centos7-7.5.1804-1.box"
 vm.box = "centos7.5-1804-1"
```

Vagrantでは、`vagrant up`の実行時に`vm.box`で指定した名称のboxが存在しない場合、vm.box_urlに指定したURLからboxをダウンロードし、ローカルにインポートします。

このため、リモートに配置されているboxが更新された場合は、`Vagrantfile`内の`vm.box`のbox名称も更新し、仮想マシンの作成時に、新しいboxをリモートからダウンロードするようにします。

## vagrant-awsによるマルチVM

Vagrantでは、単一のVagrantfileで複数のVM定義を指定することができます。

これとAmazon EC2上でVagrantの仮想マシンを起動するプラグインであるvagrant-awsを使って、ローカル環境のVMとパブリッククラウド上の環境を
切り替えて使用することができます。

vagrant-awsを使用してEC2上に仮想マシンを作成するには、VagrantfileでVMのproviderにawsを指定するとともに、`vagrant up`コマンドでVMを作成する際に`--provider aws`を指定します。

ブロックの指定の方法

VagrantfileでawsのVMを定義する際に、指定が必要な項目は以下の通りです。

- アクセスキー
- リージョン
- インスタンスタイプ
- AMIID
- セキュリティーグループ
- キーペア
- パブリックIPの指定
- サブネットID

また、Vagrantの実行時にEC2インスタンスにsshおよびrsync接続するために、以下の設定が必要です。

- ssh接続のユーザー名
- 秘密鍵のパス
- `/vagrant`ディレクトリーのrsyncの設定

Vagrantfileのグローバルの設定として、Vagrantのboxのbox_urlを定義している場合は、
awsのVM定義では、中身が空のボックスである [https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box](https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box)を指定して上書きします。

VMを複数定義した場合、vagrantでは `up`/`halt`/`provision`/`destroy`のコマンドの後ろにVMの名称を
付けて操作対象を区別します。VMの名称のオプションを付与しないで`vagrant up`等のコマンドを実行した時の
動作のために、ローカルのVM定義に`primary: true`のオプションを、またAWS上でのVM定義に `autostart: false`オプションを指定します。

vagrant-awsでVMをプロビジョニングする場合は、リソースの転送にrsyncのコマンドを使用します。
Windows環境ででrsyncを使用するには、msys2のレポジトリーからアーカイブを入手し、展開します。^[[http://repo.msys2.org/msys/x86_64/rsync-3.1.3-1-x86_64.pkg.tar.xz](http://repo.msys2.org/msys/x86_64/rsync-3.1.3-1-x86_64.pkg.tar.xz)]

## Windows環境にvagrant-awsをインストールするには

この章の執筆時点で(2018/9/20)、Windows環境でvagrant-awsをインストールするには、libxml2の依存関係の導入に失敗する問題があります。

これはGitHubのIssueにあげられていますが、^[[[https://github.com/mitchellh/vagrant-aws/issues/539#issuecomment-398100794](https://github.com/mitchellh/vagrant-aws/issues/539#issuecomment-398100794)] この問題に対処するには、vagrant-awsのインストール前に以下のコマンドでfog-ovirtをインストールし、その後vagrant-awsをインストールします。

> vagrant plugin install --plugin-version 1.0.1 fog-ovirt
> vagrant plugin install vagrant-aws
> vagrant up --provider aws

## AMIイメージの指定時にはライセンスの同意が必要

AWSで提供されているAMIイメージのうち、AWS Marketplaceで提供されているイメージについては、CLIからの起動するの前に、WebインターフェースからライセンスをSubscribeする必要があります。

またVagrantfile内で指定するAMIのIdは、Subscribeした後の「Configure this software」の画面上で取得することができます。

## ツールのビルドは ゲストOSのディレクトリー内で行う

VagrantはVagrantfileの存在するディレクトリーをゲストOS上の`/vagrant`としてマウントします。しかしでホストOS上のディレクトリーを`vboxsf`でマウントする場合、マウントしたディレクトリー上ではシンボリックリンクを使用できないため、ディレクトリー配下で、ソフトウェアのビルドを行うとエラーとなる場合があります。

これを回避するためには、VagrantやPackerのプロビジョニング処理によるビルド処理の際に、ビルドを`/tmp`などのゲストOS内のディレクトリーで行うようにします。




