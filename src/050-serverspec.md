# ServerspecによるインフラCI

## Serverspec

Serverspecは、宮下剛輔(mizzy)氏が中心となって開発を進めている、サーバー構成をテストするソフトウェアです。オープンソース(MIT License)で公開されており、で提供されています。

Serverspecは、RSpecのDSLの構文を生かし、宣言的にサーバーの構成をテストすることができます。以下は、サービスとしてJiraのプロセスが起動していることを確認するServerspecの記述です。

```
describe service("jira") do
  it { should be_enabled }
  it { should be_running }
end
```

## インフラCIの実行パターン

インフラのサーバー構成を継続的にテストするためにServerspecを実行するには、以下の方法があります。

- CIサーバー上でVagrantなどを使用して仮想マシンを起動し、起動したサーバー上でServerspecを実行する
- CIサーバー上でPackerでビルドする際に、ビルド処理内でServerspecを実行する
- Packerのビルドで作成したイメージを使用して仮想マシンを起動し、起動した仮想マシン上でServerspecを実行する

また、Serverspecは、テストを実行する際のホストへの接続方法として、以下の二通りの方法があります。

- Serverspecの実行時に、sshで対象ホストに接続する
- 自ホスト(backend)上で実行する

ここでは、CIを行う上でのプロセスと構成の単純化のために、Packerのビルド時にビルド処理内でServerspecを実行し、対象ホストには直接(exec)で接続するものとします。

## Serverspecのワークスペースの転送

Packerのビルド時にServerspecを実行する場合、サーバーのプロビジョニングのためにFileプロビジョナーでワークスペースのリソースを転送した際に、Serverspecのソースコードもまとめて対象ホストに転送します。

## Serverspecの起動に使うRubyの構成

Serverspecをsshで接続する場合、対象となるホストにRubyのランタイムのインストールは必要ありません。

しかし、対象となるホスト上で実行する場合は、Rubyのランタイムが必要となります。

Packerによるプロビジョニングに使用しているツールが、Rubyで記述されているChefないしitamaeの場合は、ominibusインストーラー内のRubyランタイムを使用することで、追加でRubyをインストールすることなくServerspecを実行することができます。

以下は、Packerでのビルド時にPackerのShellプロビジョナーから呼び出される、シェルスクリプトの実装です。

```
set -x

export PATH=/opt/chef/embedded/bin:$PATH
export BACKEND_LOCAL="local"

CURRENT=$(cd $(dirname $0) && pwd)
cd $CURRENT

sudo -E /opt/chef/embedded/bin/bundle install
bundle exec rake spec

RET=$?

systemctl stop jira
rm -rf /mnt/atlassian/jira/data/*
rm -rf /tmp/*

exit $RET
```

## Packer上でServerspecを実行するためのspec_helper.rbの設定

Serverspecを実行する際に、開発環境のVagrant上での実行と、Packerでのビルド時の自ホスト上での実行を切り替えられるようにするには、`serverspec-init`コマンドが生成する`spec/spec_helper.rb`に、実行時の環境変数によって` set :backend, :exec`を設定するロジックを追加します。

```
require 'serverspec'
require 'net/ssh'
require 'tempfile'

if ENV['BACKEND_LOCAL']
  set :backend, :exec
  return
end


set :backend, :ssh

if ENV['ASK_SUDO_PASSWORD']
  begin
    require 'highline/import'
  rescue LoadError
    fail "highline is not available. Try installing it."
  end
  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
else
  set :sudo_password, ENV['SUDO_PASSWORD']
end

host = ENV['TARGET_HOST']

`vagrant up #{host}`

config = Tempfile.new('', Dir.tmpdir)
config.write(`vagrant ssh-config`)
config.close

options = Net::SSH::Config.for(host, [config.path])
1
options[:user] ||= Etc.getlogin

set :host,        options[:host_name] || host
set :ssh_options, options

# Disable sudo
# set :disable_sudo, true


# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C'

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'
```


## Vagrant上でのServerspecの実行

Vagrant上で動作している仮想マシンに対してServerspecを実行するには、
Vagrantを実行しているホスト上でServerspecを実行します。


```
bundle install
bundle exec rake spec:default
```

## Packer上でのServerspecの実行

Packer上でServerspecを実行するには、前述の`BACKEND_LOCAL`環境変数を設定した上で、Chefの組み込みRubyに`PATH`を通した上で実行します。

`bundle install`を実行する際に`sudo`しているのは、`root`ユーザーでは直接`bundle`コマンドを実行できないためです。

```
set -x

export BACKEND_LOCAL="local"
export PATH=/opt/chef/embedded/bin:$PATH


CURRENT=$(cd $(dirname $0) && pwd)
cd $CURRENT

sudo -E /opt/chef/embedded/bin/bundle install
bundle exec rake spec

RET=$?

systemctl stop jira
rm -rf /mnt/atlassian/jira/data/*
rm -rf /tmp/*

exit $RET
```

## SELinux

サンプルコード内でサーバーのプロビジョニングを行う際に、SELinuxの無効化をおこなっていますが、`/etc/selinux/config`の設定を反映するにはOSの再起動が必要です。

このため、サンプルコード内のspec内で`getenforce`コマンドの結果を確認している箇所はpendingにしています。

```
describe command("getenforce") do
    pending("it fails before reboot.")
     its(:stdout) { should contain "Disabled" }
end
```




