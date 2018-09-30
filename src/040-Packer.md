# Packerによる仮想マシンイメージ作成

この章では、アトラシアン社の課題管理システムであるJira Software(以降JIra)のサーバーをVagrantならびにPackerで構築するサンプルコードを題材として、Packerによる仮想マシンのイメージ構築の例について述べます。ローカルの仮想環境にはVirtualBox、クラウド環境にはAmazon EC2(以下EC2)、プロビジョニングツールにはChefを使用します。

サンプルコードは以下で公開されています。

- [https://github.com/azusa/techbookfest5-packer](https://github.com/azusa/techbookfest5-packer)

## Packerの要素

PackerではJSONファイルで設定を記述しますが、その中で最も主要な要素がBuilderとProvisionerです。

## Builder

Builderは、構築する仮想マシンの指定と、VirtualBoxやEC2など、構築する仮想マシン特有の設定を記述します。[@lst:code_040_code005]は、Amazon EC2でEBS上のAMIイメージを構築する場合のBuilderの指定例です。

```{#lst:code_040_code005 caption="amazon-ebsビルダー"}
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "{{user `aws_access_key`}}",
    "secret_key": "{{user `aws_secret_key`}}",
    "region": "ap-northeast-1",
    "source_ami": "{{user `source_ami`}}",
    "instance_type": "t2.medium",
    "ssh_username": "centos",
    "ami_name": "jira-7.12.0-base {{timestamp}}"
  }],
```

## Provisioner

Provisonerは、AnsibleやChef、そしてシェルスクリプトなど、プロビジョニングツールの実行の設定を記述します。

[@lst:code_040_code006]は、Shell Provisionerと連携して、サーバーのプロビジョニングを行う設定の例です。


```{#lst:code_040_code006 caption="Shellプロビジョナー"}
  "provisioners": [
 (略)
    {
      "environment_vars": [
        "SSH_USERNAME={{user `ssh_username`}}",
        "SSH_PASSWORD={{user `ssh_password`}}",
        "http_proxy={{user `http_proxy`}}",
        "https_proxy={{user `https_proxy`}}",
        "ftp_proxy={{user `ftp_proxy`}}",
        "rsync_proxy={{user `rsync_proxy`}}",
        "no_proxy={{user `no_proxy`}}",
        "TARGET_NODE={{user `target_node`}}"
      ],
      "execute_command": "echo 'vagrant' | {{.Vars}} sudo -E -S bash '{{.Path}}'",
      "scripts": [
        "provisioning-packer.sh",
        "spec.sh"
      ],
      "type": "shell",
      "pause_before": "10s"
    }
  ],
(以下略)
  }
```

## ワークスペースの転送

PackerのShellプロビジョナーの機能を使い、プロビジョニング処理を対象ホスト上で実行するには、テンプレートファイルが存在するワークスペース以下のファイルを対象ホストに転送する必要があります。

Packerでは、プロビジョニング処理の先頭にfileプロビジョナーを使用してリソースの転送を行う事ができます。([@lst:code_040_code010])

```{#lst:code_040_code010 caption="fileプロビジョナー"}
  "provisioners": [
    {
      "type": "file",
      "source": ".",
      "destination": "/tmp/"
    },
    (以下略)
```

## プロビジョニング処理の実行

PackerにもAnsibleをはじめとするプロビジョニングツールとの連携機能があります
。この書籍では前章で述べたとおり、Vagrant上でプロビジョニング処理を実行する場合とのインターフェースの統一のために、シェルスクリプトを介してPackerとプロビジョニングツールとの連携を行います。

プロビジョニング処理は、Vagrantで処理を行うシェルスクリプトと同一の処理を
呼び出すことにより行います。Packerではshellプロビジョナーでスクリプトを
呼び出し、スクリプトの中でツールのセットアップとプロビジョニング処理の呼び出しを行います。

[@lst:code_040_code020])ではプロビジョング処理を行う`provisioning-packer.sh`の後に`spec.sh`を呼び出していますが、これは次の章でのべるServerspecによるサーバー構成のテストを行うものです。

```{#lst:code_040_code020 caption="Packerでのプロビジョニング処理"}
    {
      "environment_vars": [
        "SSH_USERNAME={{user `ssh_username`}}",
        "SSH_PASSWORD={{user `ssh_password`}}",
        "http_proxy={{user `http_proxy`}}",
        "https_proxy={{user `https_proxy`}}",
        "ftp_proxy={{user `ftp_proxy`}}",
        "rsync_proxy={{user `rsync_proxy`}}",
        "no_proxy={{user `no_proxy`}}",
        "TARGET_NODE={{user `target_node`}}"
      ],
      "execute_command": "echo 'vagrant' | {{.Vars}} sudo -E -S bash '{{.Path}}'",
      "scripts": [
        "provisioning-packer.sh",
        "spec.sh"
      ],
      "type": "shell",
      "pause_before": "10s"
    }
  ],

```

```{#lst:code_040_code030 caption="provisioning-packer.sh"}
#!/bin/bash

bash /tmp/provisioning.sh ${TARGET_NODE}
```

```{#lst:code_040_code040 caption="provisioning.sh"}
set -eux


CURRENT=$(cd $(dirname $0) && pwd)
cd $CURRENT

curl -L https://www.opscode.com/chef/install.sh | bash

set +e
service systemctl stop jira
while `ps aux |grep java |grep jira |grep -v grep >/dev/null`; do
        sleep 1
done
set -e

chef-client -z -c ${CURRENT}/solo.rb -j ${CURRENT}/nodes/${1}.json -N ${1}

DATE=$(date "+%Y%m%d-%H%M%S")

mkdir -p /var/local/backup/chef/${DATE}

rsync -a ${CURRENT}/local-mode-cache/backup/ /var/local/backup/chef/${DATE}/
```

## 環境ごとのイメージだし分け

Herokuの創設者であり、現在はInk & Switch社のCEOであるAdam Wiggins氏が
記したThe Twelve-Factor Appというドキュメントがあります。([https://12factor.net/](https://12factor.net/))このドキュメントは、可搬性とスケーラビリティーに優れたWebアプリケーションのための方法論についてまとめたものです。この中で「設定を環境変数に格納する」という節があります。

設定を環境変数に格納するということは、アプリケーションのソースコードやミドルウェアの設定ファイル中から環境依存の要素を排除し、ステージング環境や本番環境などのシステムのステージ、顧客ごとの設定の際に関わりなく、単一のアプリケーションのパッケージを、あらゆる環境で動作させることを目指しています。

しかし、アーキテクチャーとして可搬性を意識したミドルウェアやフレームワークの場合はいいのですが、Javaで記述されたアプリケーションのように、設定ファイルをXMLファイルやプロパティファイル形式で記述しているものや、ネットワーク通信の動作のために`hosts`にエントリーを追加する必要があるものなど、環境変数だけでの設定が不可能なアプリケーションやミドルウェアというものはどうしても存在します。

## ユーザーデータをシンプルに保つ

EC2には、ユーザーデータを使って、起動時に実行するスクリプトを指定できます。このスクリプト内で、サーバーのプロビジョニングを行う事ができます。サーバーの構成に環境ごとに差分がある場合は、ユーザーデータの処理内で、設定ファイルの差し替えなど、環境のカスタマイズを行う事が可能です。

しかしユーザーデータのスクリプトには、プロビジョニングツールなど、他のサーバー構築の仕組みでカバーしきれない処理が集中しがちであり、肥大化しがちです。また、ユーザーデータのスクリプトのデバッグを行うためにはEC2のインスタンスを作成する必要があり、ユーザーデータが肥大化すると、スクリプトのデバッグが難しくなってきます。

ユーザーデータをどのようにシンプルに保つかと言うことを考えると、
ユーザーデータの中ではEBSのマウント設定やホスト名の設定など、
必要最小限の処理に留めるべきであり、環境ごとにイメージの構成が異なる場合は、
Packerによるプロビジョニング処理内で環境のカスタマイズを行っておくことが
望ましいです。

## イメージ作成時のカスタマイズのステージ分割

環境変数のみで設定が不可能なアプリケーションの存在や、ユーザーデータのスクリプトのシンプルさを保つことを考えると、環境ごとにカスタマイズが必要なアプリケーションのカスタマイズの方法は、以下の通り、デフォルトの構成のイメージ作成と、カスタマイズしたイメージの作成でステージを分割する、というものになります。

- デフォルト設定で構成したアプリケーションのイメージを構成し、Serverspecを用いてテストを行う。
- テストを行ったデフォルト設定のイメージに対してカスタマイズを行い、環境ごとにイメージを作成する。

## 作成したAMIイメージの取得と引き渡し

OSのベースイメージからアプリケーションの基本設定ずみイメージ、環境ごとのカスタムイメージと、イメージの構築にあたってパイプラインを構築するには、前の段のパイプラインで作成したイメージのIDを引き渡す必要があります。

ビルドの出力からイメージのIDを取得するには、[@lst:code_040_code050]のように`packer`を`-machine-readable`オプションを付けて実行し、出力されたログから作成した出力部分からgrepすることで、イメージのIDを取り出します。

そして取り出したファイルをCIサーバーのartifact(この場合`jira.version`というファイル)とすることで、後続の処理でイメージのIDを取得可能にします。

```{#lst:code_040_code050 caption="PackerでのイメージのID取り出し"}
/usr/local/bin/packer build -machine-readable jira-ami.json |tee jira-build.log
RET=$?
grep 'artifact,0,id' jira-build.log | cut -d, -f6 | cut -d: -f2 >jira.version
exit $RET
```

後続の処理は、[@lst:code_040_code060]のようにartifactとして取得したファイルを読み込んでイメージのIDを
環境変数として設定し、[@lst:code_040_code070]のようにテンプレート内でユーザー変数として取得します。

```{#lst:code_040_code060 caption="PackerでのイメージのID取りこみ"}
export SOURCE_AMI=$(<jira.version)
export TARGET_NODE="production"

/usr/local/bin/packer build jira-custom.json
```

```{#lst:code_040_code070 caption="PackerでのイメージのID取りこみ"}
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "{{user `aws_access_key`}}",
    "secret_key": "{{user `aws_secret_key`}}",
    "region": "ap-northeast-1",
    "source_ami": "{{user `source_ami`}}",
    "instance_type": "t2.medium",
    "ssh_username": "centos",
    "ami_name": "jira-7.12.0-base {{timestamp}}"
  }],

  "variables": {
    (略)
    "source_ami": "{{env `SOURCE_AMI`}}"
  }
```

## ビルド時のインストーラーをどこに配置するか

`yum`や`apt`など、OSのパッケージ管理の仕組みでなく、`tar.gz`等の形式のアーカイブを展開する形式で提供されているパッケージソフトウェアをインストールする際には、Chefでは`remote_file`リソース、Ansibleでは`get_url`の仕組みを作ってリモートからアーカイブを取得します。

しかし、商用ソフトウェアのインストーラーのように、パブリックからアクセス可能な場所にアーカイブが配置されない場合があります。

この場合は、組織で管理するサーバー上にアーカイブを配置し、先述のリモートからアーカイブを取得する方法を取る場合もありますが、PackerでEC2等のパブリッククラウドのためのイメージを作成する場合は、組織内のサーバーでなくクラウド上でプロビジョニング処理が行われるため、ネットワークのアクセス許可のための設定が複雑になる場合があります。

これらの事情に対応する方法として、Gitで大容量のファイルを扱う仕組みである`git-lfs`を用いてGitレポジトリー上にアーカイブを格納する方法があります。

[@lst:code_040_code080]は、Oracle JDKのインストーラーのRPMファイルを格納するために、拡張子が`rpm`のファイルを`git-lfs`の対象としてコミットする`.gitarttributes`の設定です。

```{#lst:code_040_code080 caption=".gitattributes"}
*.rpm filter=lfs diff=lfs merge=lfs -text
```

## Packerビルド時のhostsのカスタマイズ方法

`uname -n`コマンドで取得できる、`localhost`の
ホスト名が、`/etc/hosts`に設定されているミドルウェアが存在します。代表例はOracle Databaseです。

プロビジョニングツールによるサーバー構築時に、`/etc/hosts`にホスト名を設定するには、以下の様に行います。

Vagrantで構築するhostに関しては、Chef/Itamaeの場合は[@lst:code_040_code090]のように、Rubyの`Socket::gethostname`を使用して、erbテンプレートにホスト名を設定します。

```{#lst:code_040_code090 caption="hosts.erb"}
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4 <%= Socket::gethostname %>
::1       localhost localhost.localdomain localhost6 localhost6.localdomain6
```

Packerで構築するイメージについては、ホスト名が設定されるのがイメージ構築の後ですので、[@lst:code_040_code100]のようにerbテンプートには、ホスト名を直接記述し、[@lst:code_040_code110]のようにユーザーデータの起動スクリプト内で、引数として渡されたホスト名を設定します。

```{#lst:code_040_code100 caption="hosts.erb"}
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 atls-production-jira
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
```

```{#lst:code_040_code110 caption="user-data.sh(抜粋)"}
(前略)
# 静的ホスト名の設定
hostnamectl set-hostname --static $1

echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

```




