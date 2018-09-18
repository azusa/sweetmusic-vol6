# VagrantとPackerによる開発環境

## Vagrantの基本的な使い方

## vagrant up

## vagrant halt

## vagrant destroy

## vagrant provision

## Vagrantfile

## バージョン管理からVagrantfileを取得して仮想マシンを作成するステップ

### Windows10とVirtualboxとVagrantの微妙な関係

VagrantのBoxには、動作するVirtualBoxのバージョンに応じたVBoxGuestAdditionsが仮想マシン上のゲストOSにインストールされている必要があります。

ところで、マイクロソフト社のWindows10では「Windows as a Service」というコンセプトに基づき、数年ごとにWindowsの新しいバージョンをデリバリーするリリースサイクルから、年に２～3回、小規模な機能更新が提供されるリリースサイクルが採用されました。

このリリースサイクルの変更により、VirtualBoxがWindows側の仕様変更の影響を受け、VirutalBoxのバージョンアップが必要になる場合があります。

そしてVirtualBoxのバージョンがあがるということはVBoxGuestAdditionsの再インストールが必要となり、これまで使用していたBoxがそのままでは使用できなくなり…ということが、これまでのWindows10の機能リリースでは続いています。

VirtualBoxのバージョンアップにVagrantのBoxを追従するには、vagrant-vbguestの`vagrant vbguest`コマンドでVBoxGuestAdditionsを更新するか、VBoxGuestAdditionsを更新したVagrantのBoxを作成するかのいずれかになります。

VirtualBoxあげる→古いBoxのVboxguestAddition更新しようとする→kernel-develの新しいバージョン入れようとする→ない！

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

```
yum -y install ansible
CURRENT=$(cd $(dirname $0) && pwd)
cd $CURRENT && PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ansible-playbook --limit="default" --inventory-file=localhost -v provision/localhost.yml

```

なお、Windows上で実行するVagrantでShell Provisionerを使用してシェルスクリプトを実行する場合は、ローカルにチェックアウトした環境上でシェルスクリプトの改行コードが`LF`になっている必要があります。

Git for Windowsのデフォルト設定では改行コードを`CRLF`に変換するようになっているため、`.gitattributes`で改行コードを`LF`としてチェックアウトするよう設定する必要があります。

```
* eol=lf
```

## インストーラーをどこに配置するか

`yum`や`apt`など、OSのパッケージ管理の仕組みでなく、`tar.gz`等の形式のアーカイブを展開する形式で提供されているパッケージソフトウェアをインストールする際には、Chefでは`remote_file`リソース、Ansibleでは`get_url`の仕組みを作ってリモートからアーカイブを取得します。

しかし、商用ソフトウェアのインストーラーのように、パブリックからアクセス可能な場所にアーカイブが配置されない場合があります。

この場合は、組織で管理するサーバー上にアーカイブを配置し、先述のリモートからアーカイブを取得する方法を取る場合もありますが、PackerでEC2等のパブリッククラウドのためのイメージを作成する場合は、組織内のサーバーでなくクラウド上でプロビジョニング処理が行われるため、ネットワークのアクセス許可のための設定が複雑になる場合があります。

これらの事情に対応する方法として、Gitで大容量のファイルを扱う仕組みである`git-lfs`を用いてGitレポジトリー上にアーカイブを格納する方法があります。

～は、Oracle JDKのインストーラーのRPMファイルを格納するために、拡張子が`rpm`のファイルを`git-lfs`の対象としてコミットする`.gitarttributes`の設定です。

```
*.rpm filter=lfs diff=lfs merge=lfs -text
```

## なぜChefなのか

## Vagrantfile内でのイメージの指定

```
 vm.box_url="http://images.fieldnotes.jp/images/centos7-7.5.1804-1.box"
```

```
 vm.box = "centos7.5-1804-1"
```

Vagrantでは、`vm.box`で指定した名称のboxが存在しない場合、vm.box_urlに指定したURLからboxをダウンロードし、ローカルにインポートします。

このため、リモートに配置されているboxが更新された場合は、`Vagrantfile`内の`vm.box`のbox名称も更新し、仮想マシンの作成時に、新しいboxをリモートからダウンロードするようにします。

## vagrant-awsによる

## ツールのビルドは /tmp の下で

VagrantはVagrantfileの存在するディレクトリーをゲストOS上の`/vagrant`としてマウントします。しかし、WindowsでホストOS上のディレクトリーを`vboxsf`でマウントする場合、マウントしたディレクトリー上ではシンボリックリンクを使用できないため、ディレクトリー配下で、ソフトウェアのビルドを行うとエラーとなる場合があります。

これを回避するためには、VagrantやPackerのプロビジョニング処理によるビルド処理の際に、ビルドを`/tmp`などのゲストOS内のディレクトリーで行うようにします。