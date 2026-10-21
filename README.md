*This project has been created as part of the 42 curriculum by mkaneko.*

# Born2beRoot

## Description

ホストOSの下に仮想マシンを構築し、GUIを使わず、パーティション、ユーザー、ネットワークまで1から自分で設定することで、設定の意味と動作を説明できることを目標とする課題です。

### 仮想マシンとは

仮想マシン(VM)とは、ソフトウェア上に仮想的に作られたコンピューターです。
ホストの資源を消費し、ホスト故障の影響も受けるため、物理的に独立した機械と同じではありません。しかし、ホストOSの環境を壊さずに別のパソコンとして動かせるので、次のことができます。

- 同じ物理端末で複数のOSを動かす
- 構築や障害対応を試す
- 環境を分離する

**メリット**

- 本番運用しているシステムと同時運用できるため、移行がスムーズになる
- 増加や削除が容易で、必要な時だけ使えるため資源が無駄にならない

**デメリット**

- オーバーヘッド(処理負荷)やリソース競合により、性能が低下する可能性がある
- セキュリティや適切なリソース対策が必要になり、運用が複雑化する

## Project description

このプロジェクトでは、仮想マシンを安全に使いやすくするための設定を行いました。構成の選択とその理由は以下の通りです。

### 1. 仮想化ソフトウェア: VirtualBox

VirtualBoxは課題で基本として設定されており、多様なLinuxとの互換性に優れています。

| 比較軸 | VirtualBox(採用) | UTM |
| --- | --- | --- |
| 対応OS | macOS、Windowsほか | macOS |
| 長所 | 多くのデバイスでLinuxのVMを管理でき、高度な機能がある | AppleシリコンMacでのパフォーマンスがよい |
| 短所・負担 | AppleシリコンのMacではamd64版のDebian ISOが使えない | VirtualBoxに比べて機能や資料が少なく、互換性の選択肢が少ない |

### 2. OS: Debian

Debianを選択したのは、初学者向けに推奨されていること、サーバー用途に定評があること、APT・UFW・AppArmorで基本的なサーバー管理を学べることからです。

| 比較軸 | Debian(採用) | Rocky Linux |
| --- | --- | --- |
| 系統・管理 | Debian系、dpkg・APT、`.deb` | RHEL互換、RPM・DNF、`.rpm` |
| 長所 | stableの安定性、豊富なパッケージと資料 | RHEL互換の運用・企業向け環境を学べる |
| 短所・負担 | 安定性重視のため、最新機能が必要な用途に合わない場合がある | 初学者にはSELinuxやfirewalldの設定も含め学習負担がある |
| この課題での保護機構 | AppArmor・UFW | SELinux・firewalld |

### 3. アクセス制御: AppArmor

| 比較軸 | AppArmor(採用) | SELinux |
| --- | --- | --- |
| アクセス制御方式 | ファイルパスベース | セキュリティラベル(コンテキスト)ベース |
| デフォルト採用 | Ubuntu、Debian、SUSE | RHEL、CentOS、Fedora、AlmaLinux |
| 学習コスト | 比較的低い(パスの記述が直感的) | 高い(ラベル管理の概念理解が必要) |
| カバー範囲 | プロファイルが存在するプロセスのみ | システム全体 |

### 4. ファイアウォール: UFW

UFWはLinuxのパケットフィルタを管理するツールです。ポートや接続元に対する許可を簡潔に記述でき、この課題のような少数のルールを扱うのに適しています。

| 比較軸 | UFW(採用) | firewalld |
| --- | --- | --- |
| 系統 | Ubuntu標準(Debianでも利用可) | CentOS / RHEL / AlmaLinux / Fedora系 |
| 長所 | コマンドが簡潔でわかりやすく、資料が多い | ゾーンベースの管理や、ランタイム/パーマネント設定の分離ができる |

### 5. パーティション構成: LVM

後から容量を変えやすくするためにLVMを選択しました。さらにLUKSで暗号化しています。

### 6. セキュリティ上の設定

| 設定 | 内容と理由 |
| --- | --- |
| SSHポートを4242に変更 | 課題要件です。接続できるポート番号を限定し、UFWで許可ポートを絞ることとの組み合わせで効果が出ます。 |
| rootのSSHログイン禁止 | rootは名前が知られていて最大権限を持つため、直接ログインを許すと攻撃されやすく、侵入時の被害も大きくなります。一般ユーザー + sudoにすると攻撃の難易度が上がり、操作の記録も残せます。 |
| UFWで4242/TCPのみ受信許可 | ネットワークの入り口を絞ることで、攻撃のリスクを減らします。 |
| パスワードポリシー(期限・品質) | 文字種や文字数の条件を厳しくし、有効期限を設けて、漏洩や推測のリスクを下げます。 |
| sudoの認証制限 | 管理者権限を誰でも使えると不正な操作が行われる可能性があるため、sudoを使えるユーザーを制限し、誰がどのような管理操作を行ったかを記録します。 |
| 操作ログ | sudoの操作を記録し、安全に動作しているか確認できるようにします。 |
| AppArmor | 起動時に自動で立ち上がる設定になっていることを確認しました。プロファイルの中身は変更していません。 |
| monitoring.sh + cron | サーバーの状態を定期的に全端末へ表示し、正常に動作しているか確認します。 |

### 7. インストールしたサービス

| 分類 | サービス |
| --- | --- |
| 管理・認証 | SSH、sudo、cron、libpam-pwquality |
| セキュリティ | AppArmor、UFW |

## Instructions

以下の順番で設定を行いました。

### 0. 構成を決める

課題要件を基準に、Debianのバージョンと仮想マシンの構成を決めます。

<!-- TODO: 校舎PCで使ったバージョンに更新(Debian / VirtualBox) -->
- Debian: [Debian Releases](https://www.debian.org/) の最新安定版 Debian 13.7 amd64 (trixie)
- 仮想化ソフト: VirtualBox 7.0.26

| 項目 | 設定 |
| --- | --- |
| CPU | 2コア |
| メモリ | 2048MB |
| 仮想ディスク | 20GB(動的割り当て) |
| グラフィック | 最小限 |
| ネットワーク | NAT(Network Address Translation。ホストOSのインターネット回線を借りてネットにつなぐ仕組み) |
| GUI | なし |
| SSHポート | 4242 |
| ディスク暗号化 | LUKS + LVM |

### 1. 仮想マシンの作成

1. 仮想化ソフトVirtualBoxをインストールする。
2. VirtualBoxマネージャで「新規」を選び(基本モード)、次を設定する。
    - VM名
    - ISO: Debian 13.7 netinst(ダウンロードしたファイルのパスを指定)
    - 「無人インストール」のチェックは外す
    - 「EFI」にチェックは入れない（要件とは違う構成になるため）
    - CPU: 2コア / メモリ: 2048MB / ディスク: 30GB
    - ディスクは**動的割り当て**にする(「Full Disk Allocation(事前に全量確保)」や固定サイズは選ばない)
3. ネットワークを設定する。VMを右クリック → 設定 → ネットワーク → アダプター1に「Intel PRO/1000 MT デスクトップ(NAT)」を指定する。
4. 起動ボタンを押すと、Debianのインストーラーが起動する。

ディスクの暗号化(LVM)はDebianのインストーラー側で設定するため、VirtualBox側では普通の仮想ディスクを用意するだけで十分です。

<!-- TODO: 校舎PCでISOの保存場所・VirtualBoxの画面表示が違えば更新 -->

### 2. Debianのインストールとパーティション設定

公式サイトからダウンロードしたISOをVirtualBoxに指定しておくと、続けてインストールが始まります。

1. **言語・キーボード**: JapaneseやJapanを選ぶ。選択肢がなければEnglishやusでも問題ない。キーボードは使っている配列に合わせる。
2. **ホスト名**: `intra名42`(例: `mkaneko42`)
3. **ドメイン**: 空欄
4. **ユーザーとパスワード**: rootのパスワードと、一般ユーザー名・パスワードを設定する。
5. **パーティショニング**: 次のメニューを選ぶ。

```
    Guided - use entire disk and set up encrypted LVM
    Separate /home, /var and /tmp partitions
```

    暗号化用のパスフレーズの入力画面が出るので指定する。LVMのボリュームグループのうち、どれだけの容量を使うか聞かれるが、動的割り当てなので100%で問題なかった。実際の分割は以下の通り。

    <!-- TODO: 校舎PCで実装後、sudo lsblk の結果に差し替え -->
```
    $ sudo lsblk
    NAME                       MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
    sda                          8:0    0   20G  0 disk
    ├─sda1                       8:1    0  918M  0 part  /boot
    ├─sda2                       8:2    0    1K  0 part
    └─sda5                       8:5    0 19.1G  0 part
      └─sda5_crypt             254:0    0 19.1G  0 crypt
        ├─mkaneko42--vg-root   254:1    0    7G  0 lvm   /
        ├─mkaneko42--vg-var    254:2    0    2G  0 lvm   /var
        ├─mkaneko42--vg-swap_1 254:3    0  936M  0 lvm   [SWAP]
        ├─mkaneko42--vg-tmp    254:4    0  568M  0 lvm   /tmp
        └─mkaneko42--vg-home   254:5    0  8.6G  0 lvm   /home
    sr0                         11:0    1 1024M  1 rom
```

    `/boot` はカーネルなどの起動ファイル用です。LUKSの中にroot・home・swapなどを置くことで、OSやユーザーデータ、swapへの書き込みが暗号化されます。rootとhomeは論理ボリュームを分けて、容量を個別に割り当てています。

6. **パッケージマネージャの設定**: Debianの利用統計を送信するか聞かれたら、Noにして問題ない。
7. **Software selection**: 「SSH server」と、選べるなら「standard system utilities」にチェックを入れる。課題要件でX.OrgやWaylandなどのグラフィックサーバーが禁止されているので、デスクトップ環境は選ばない。
8. **GRUBブートローダ**: インストールする(Yes)。インストール先は `/dev/sda`。PCの電源が入るとBIOS/UEFIが動き、続いてGRUBが起動する。GRUBの役割は、Linuxカーネルを見つけてメモリに読み込み、起動させること。
9. **完了**: continueを押し、再起動後に暗号化のパスフレーズ入力、続いてログイン画面が出ればインストール成功。

### 3. sudoを使えるようにする

sudoは、一般ユーザーが一時的に管理者権限でコマンドを実行するための仕組みです。Windowsで例えると、インストール時に「管理者として実行」する操作に近いです。

| 種類 | 説明 |
| --- | --- |
| 一般ユーザー(この課題では `intra名`) | 普通の作業をするユーザー。自分のファイルは操作できるが、システム全体に関わる変更は制限される。 |
| 管理者(root) | システム全体を管理できる特別なユーザー。ユーザーの追加やシステム設定の変更ができる。 |

1. 現在のユーザーを確認する(`intra名` ならOK)。

```
    whoami
```

2. sudoがあるか確認する。

```
    sudo --version
```

    なければ、一度rootでログインし直してインストールする。

```
    su -              # rootのパスワードを入力
    apt update        # パッケージ一覧を最新にする
    apt install sudo
```

3. rootから、一般ユーザーをsudoグループに追加する。

```
    usermod -aG sudo intra名
    exit              # rootから抜ける
    exit              # 一般ユーザーからもログアウト
```

4. 再度一般ユーザーでログインし、sudoが使えるか確認する。`root` と表示されればOK(sudoでroot権限のコマンドを実行できたという意味)。

```
    sudo whoami
```

### 4. SSHのポートを4242にする

一般ユーザーで実行します。

1. SSHサービスが動いているか確認する。`Active: active (running)` があればOK。

```
    sudo systemctl status ssh
```

2. 設定ファイルを編集する。

```
    sudo nano /etc/ssh/sshd_config
```

 | 変更前 | 変更後 |
 | --- | --- |
 | `#Port 22` | `Port 4242` |
 | `#PermitRootLogin prohibit-password` | `PermitRootLogin no` |

    先頭の `#`(コメントアウト)は削除する。nanoの保存は `Ctrl+O` → `Enter` → `Ctrl+X`。

3. 設定を反映するためにSSHを再起動し、ポートを確認する。LISTENの表示に4242が出ていれば成功。

```
    sudo systemctl restart ssh
    sudo ss -tlnp | grep ssh
```

4. rootログイン禁止を確認する。`permitrootlogin no` と出れば成功。

```
    sudo sshd -T | grep permitrootlogin
```

5. 一般ユーザーでSSH接続できるか確認する。
    - ネットワークがNATなので、VirtualBoxでポートフォワーディング(ホスト4242 → ゲスト4242)を設定する。
    - ホストのターミナルから接続する。`Are you sure you want to continue connecting` と聞かれたら `yes` を入力し、プロンプトに戻れば成功。

```
        ssh -p 4242 ユーザー名@127.0.0.1
```

    - 接続先を確認する。

```
        hostname    # ホスト名
        whoami      # 一般ユーザー名
```

### 5. AppArmorの確認

VirtualBoxマネージャからVMを起動し、Debianにログインして実行します。

```
sudo aa-status                        # AppArmorの状態を表示
sudo systemctl status apparmor        # AppArmorが起動しているか確認
sudo aa-status | grep -E 'apparmor module|profiles are loaded|profiles are in enforce mode'
```

最後のコマンドで、必要なプロファイルが適用されているか確認できます。

### 6. UFWを有効にする

1. UFWがインストールされているか確認し、なければインストールする。

```
    dpkg -l ufw
    sudo apt update
    sudo apt install ufw
```

2. SSHのポート番号を確認する。`Port 4242` であればよい。

```
    sudo grep -i '^Port ' /etc/ssh/sshd_config
```

3. SSHポートを許可する。

```
    sudo ufw allow 4242/tcp
```

4. 有効にする前に、ルールが登録されたことを確認する。

```
    sudo ufw status
```

```
    To                         Action      From
    --                         ------      ----
    4242/tcp                   ALLOW       Anywhere
    4242/tcp (v6)              ALLOW       Anywhere (v6)
```

    上のようになっていれば許可されている。先頭が `Status: inactive` の場合は、ルールを登録しただけでファイアウォールはまだ有効になっていない。

5. UFWを有効にして確認する。

```
    sudo ufw enable
    sudo ufw status verbose
```

    `verbose` を付けると、デフォルトポリシー(incomingはdeny、outgoingはallowなど)も一緒に表示される。余分なルールがある場合は削除する。

```
    sudo ufw delete allow 22/tcp
    # または sudo ufw status numbered で番号を確認し、番号を指定して削除
```

### 7. ユーザーをグループに追加する

ログインユーザーが `user42` と `sudo` の両方のグループに所属している状態にします。

1. 現在のユーザーとグループを確認する。`id` は所属グループを表示する。sudoグループには手順3で追加済みなので、`user42` グループに追加する。

```
    whoami
    id
```

2. `user42` グループが存在するか確認する。何も返らなければ作成する。`user42:x:1001:メンバー一覧` のように表示されれば成功。

```
    getent group user42
    sudo groupadd user42
    getent group user42
```

3. ユーザーが `user42` に所属しているか確認し、いなければ追加する。`-aG` は、既存のグループ所属を維持したまま追加のグループに所属させるオプション。

```
    id ユーザー名
    sudo usermod -aG user42 ユーザー名
    id ユーザー名
```

### 8. sudoのセキュリティ設定

設定内容は[Configuration](#sudoの設定)に記載しています。

1. 現在のsudo設定を確認する(パスワードを入力)。表示される内容は、sudo実行時の環境変数、メール通知、パスの制限、対象ホスト、実行ユーザー、実行できるコマンドなど。

```
    sudo -l
```

2. 設定ファイルの現在のデフォルト値を確認する。

```
    sudo cat /etc/sudoers
    sudo grep -nE '^(Defaults|%sudo|%user42|ユーザー名)' /etc/sudoers
```

3. ログの保存先(`/var/log/sudo`)を作成する。

```
    sudo mkdir -p /var/log/sudo
    sudo touch /var/log/sudo/sudo.log
    sudo chown root:root /var/log/sudo/sudo.log    # 所有者とグループをrootにする
    sudo chmod 600 /var/log/sudo/sudo.log          # rootだけが読み書き可にする
    ls -l /var/log/sudo/sudo.log                   # ファイルの権限を確認
    ls -ld /var/log/sudo                           # ディレクトリの権限を確認
```

4. 設定ファイルをバックアップしてから、`visudo` で編集する。`visudo` は構文チェックをしてくれるので安全。

```
    sudo cp /etc/sudoers /etc/sudoers.bak
    sudo visudo
```
5. TTYモードの動作を確認する。端末を割り当てない形でSSH経由のsudoを実行すると、拒否されればOK。

```
    ssh -T -p 4242 ユーザー名@127.0.0.1 sudo whoami

```
    `sudo: a tty is required` のようなエラーが出れば、TTY必須の設定が効いている。

6. 変更を確認する。ログに記録が表示されれば成功。

```
    sudo -l
    sudo tail -n 5 /var/log/sudo/sudo.log
```

### 9. パスワードポリシーの設定

PAM(`pam_pwquality`)で実装します。設定値は[Configuration](#パスワード設定)に記載しています。

1. Debianのバージョンを確認する。

```
    cat /etc/debian_version
```

2. パスワードの強度チェック用パッケージ(`libpam-pwquality`)がインストールされているか確認する。インストール済みなら `ii  libpam-pwquality` と表示される(`dpkg` はDebianのパッケージを管理するツール)。

```
    dpkg -l libpam-pwquality
```

3. 設定ファイルを編集する。

```
    sudo nano /etc/security/pwquality.conf
```

    `*credit` の値は、負数なら「最低限必要な文字数」、正数なら「長さの判定時に加算できる上限」を意味する。

4. 追加した設定を確認する。

```
    grep -E '^(minlen|ucredit|lcredit|dcredit|maxrepeat|usercheck|difok)' /etc/security/pwquality.conf
```

5. パスワード変更時にルールが使われるよう、PAM(Pluggable Authentication Modules)の設定を確認する。PAMは設定ファイルに書かれたモジュール名を見て、必要なときにそのモジュールを読み込んで実行する。

```
    grep -nE 'pam_pwquality|pam_pwhistory|pam_unix' /etc/pam.d/common-password
```

    表示例:

```
    password requisite pam_pwquality.so retry=3 enforce_for_root
    password [success=1 default=ignore] pam_unix.so obscure use_authtok try_first_pass yescrypt
```

    先にパスワードの品質をチェック(`pam_pwquality.so`)し、次にパスワードを設定(`pam_unix.so`)する。

6. 有効期限などの時間に関する設定は、[Configuration](#パスワード設定)の表の通り `/etc/login.defs` に書く。ただし `login.defs` の `PASS_MAX_DAYS` などはこれから作るユーザーにしか効かないため、**既存のユーザーとroot**には `chage` で個別に指定する。

```
    sudo chage -M 30 -m 2 -W 7 ユーザー名
    sudo chage -M 30 -m 2 -W 7 root
```

7. 設定後に既存ユーザーのパスワードを変更する。
    1. `pwquality.conf` で `difok`(前のパスワードと異なっていなければならない文字数)を確認する。

```
        grep -n 'difok' /etc/security/pwquality.conf
```

    2. 対象アカウント(rootとUID 1000以上)のユーザー名・UID・ログインシェルを表示する。

```
        awk -F: '$3 >= 1000 || $1 == "root" {print $1, $3, $7}' /etc/passwd
```

    3. 一般ユーザーのパスワードを変更する。現在のパスワード → 新しいパスワード → 再入力の順に入力する。

```
        passwd
```

    4. rootのパスワードを変更する。

```
        sudo passwd root
```

### 10. 監視スクリプト(monitoring.sh)を作る

rootでホームディレクトリに作成します。Bashスクリプトなので、先頭にシバン(`#!/bin/bash`)を入れます。

```
nano monitoring.sh
```

取得した情報を1つのメッセージにまとめ、`wall` で全端末に送信します。表示項目と取得方法は[Configuration](#監視スクリプト)に記載しています。

### 11. 定期実行の設定(cron)

cronを使うと、決まった間隔でスクリプトを自動実行できます。

1. cronをインストールする。

```
    sudo apt update
    sudo apt install cron
```

2. cronサービスを起動し、自動起動を有効にする。

```
    sudo systemctl enable --now cron
    sudo systemctl status cron
```

3. スクリプトに実行権限を付け、まず手動で実行してエラーがないことを確認する。


```
    sudo cp ~/monitoring.sh /usr/local/bin/monitoring.sh
    sudo chown root:root /usr/local/bin/monitoring.sh
    sudo chmod 755 /usr/local/bin/monitoring.sh
    sudo /usr/local/bin/monitoring.sh
```

4. rootのcrontabに定期実行を登録する。

```
    sudo crontab -e
```

    次の行を追加する。

```
    */10 * * * * /usr/local/bin/monitoring.sh
```

    `*/10` は10分ごとの意味。残りの `*` は、毎時・毎日・毎月・すべての曜日で実行するという意味。登録後に確認する。

```
    sudo crontab -l
```

### 12. 新しいユーザーの作り方

Linuxでは、ユーザーとグループを使ってファイルやシステムの操作権限を管理します。

```
# 一般ユーザーで実行
sudo adduser testuser
id testuser
su - testuser            # testuserのパスワードを入力して切り替え
whoami                   # testuser と表示されれば切り替え成功
sudo whoami              # sudoグループに所属していないので使えない
exit                     # 元のユーザーに戻る

# sudoグループに追加
whoami
sudo usermod -aG sudo testuser
id testuser
su - testuser
whoami
sudo whoami              # 今度は root と表示される
```

### 13. signature.txt の作成

VMをシャットダウンし、仮想ディスク(`.vdi`)のSHA-1ハッシュ値を計算して `signature.txt` に保存します。

<!-- TODO: 校舎PCで実際に使ったコマンドと .vdi の保存場所に更新 -->
```
sudo shutdown -h now      # VMをシャットダウン
```

`.vdi` ファイルのあるディレクトリで、ホストOSに合わせて次のいずれかを実行します。

| ホストOS | コマンド |
| --- | --- |
| Linux(Ubuntu) | `sha1sum Born2beRoot.vdi` |
| macOS | `shasum Born2beRoot.vdi` |
| Windows | `certUtil -hashfile "Born2beRoot.vdi" SHA1` |

> **注意**: `signature.txt` のハッシュ値は `.vdi` のSHA-1と一致している必要があります。VMを起動するとハッシュ値が変わるため、評価時はクローンやスナップショットを使います。

## Configuration

### ユーザーの設定

| 項目 | 名称 | 設定場所 |
| --- | --- | --- |
| ホスト名 | mkaneko42 | Debianのインストール |
| ユーザー名 | mkaneko | Debianのインストール |

### パスワード設定

| 要件 | ファイル | 設定 | 理由 |
| --- | --- | --- | --- |
| 有効期限30日 | `/etc/login.defs` | `PASS_MAX_DAYS 30` | 漏洩のリスクを下げる |
| 変更間隔の下限2日 | `/etc/login.defs` | `PASS_MIN_DAYS 2` | 頻繁に変えすぎない |
| 期限7日前の警告 | `/etc/login.defs` | `PASS_WARN_AGE 7` | 期限切れ前に気づける |
| 最少10文字 | `/etc/security/pwquality.conf` | `minlen = 10` | 短すぎないほうが安全 |
| 数字・大文字・小文字を含む | `/etc/security/pwquality.conf` | `dcredit = -1` `ucredit = -1` `lcredit = -1` | 複雑にする |
| 同一文字の連続は3文字まで | `/etc/security/pwquality.conf` | `maxrepeat = 3` | 推測されにくくする |
| ユーザー名を含まない | `/etc/security/pwquality.conf` | `usercheck = 1` | 推測されにくくする |
| 前のパスワードと異なる文字を7文字以上含む(root以外) | `/etc/security/pwquality.conf` | `difok = 7` | 使いまわしの防止 |
| rootもポリシーに従う(difok以外) | `/etc/pam.d/common-password` | `enforce_for_root` | rootの安全も守る |

### sudoの設定

| 要件 | ファイル | 設定 |
| --- | --- | --- |
| パスワード誤入力は3回まで | `/etc/sudoers` | `Defaults passwd_tries=3` |
| 誤パスワード時のメッセージ | `/etc/sudoers` | `Defaults badpass_message="Password is incorrect"` |
| 入出力をログに記録 | `/etc/sudoers` | `Defaults log_input, log_output`<br>`Defaults iolog_dir="/var/log/sudo"`<br>`Defaults logfile="/var/log/sudo/sudo.log"` |
| TTYモードの有効化(コマンドを専用の擬似端末内で実行) | `/etc/sudoers` | `Defaults requiretty` |
| (補足)コマンドを専用の擬似端末内で実行 | `/etc/sudoers` | `Defaults use_pty`|
| コマンドを探索するパスの制限 | `/etc/sudoers` | `Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"` |

### 監視スクリプト

| 表示項目 | 表示データの取得方法 |
| --- | --- |
| OS | `uname -a` |
| CPUソケット数 / vCPU | `/proc/cpuinfo` の `physical id` の重複を削除して数える / `processor` 行を数える |
| RAM使用量(割合) | `free` の used と total から計算(used × 100 / total)。使用量・総量・割合を表示 |
| ディスク使用量(割合) | `df` の出力から容量の表示単位を削除して集計 |
| CPU負荷 | `top` のCPU行からアイドル率(id)を取り出し、100から引く |
| 最終起動日時 | `who -b` |
| LVM使用の有無 | `lsblk` の出力に `lvm` の行があるかどうか |
| TCP接続数 | `ss -tan` の ESTABLISHED の行数 |
| ログイン中のユーザー数 | `who` のユーザー名の重複を除いた数 |
| IPアドレス / MACアドレス | `hostname -I` / `ip link show` で最初に見つかったMACアドレス |
| sudo実行回数 | `journalctl _COMM=sudo` の `COMMAND` を含む行の数 |

## Resources

- [Oracle VM VirtualBox 公式ダウンロード](https://www.oracle.com/virtualization/technologies/vm/downloads/virtualbox-downloads.html)
- [VirtualBoxとUTMの比較](https://linux-jp.org/?p=16476)
- [Debian Releases(OSについて)](https://www.debian.org/)
- [LVM(wikiwiki.jp)](https://wikiwiki.jp/linuxnomemo/LVM)
- sudo
    - [SUSE: sudoを使用したスーパーユーザ特権の設定](https://documentation.suse.com/ja-jp/sle-micro/6.0/html/Micro-sudo-configure-superuser-privileges/index.html)
    - [LabEx: sudoers設定の問題を解決する方法](https://labex.io/ja/tutorials/nmap-how-to-fix-sudoers-configuration-problems-419586)
    - [Debian man: sudo(8)(日本語)](https://manpages.debian.org/unstable/manpages-ja/sudo.8.ja.html)
    - [man 5 sudoers(権限とログ設定)](https://manpages.debian.org/trixie/sudo/sudoers.5.en.html)
- [man 8 pam_pwquality](https://manpages.debian.org/trixie/libpam-pwquality/pam_pwquality.8.en.html)
- [OpenSSH公式サイト](https://www.openssh.com/)
- cron: [man 5 crontab(時刻の指定と実行の書き方)](https://manpages.debian.org/trixie/cron/crontab.5.en.html)、man 1 crontab(コマンド)
- apt: [man 8 apt(使い方)](https://manpages.debian.org/trixie/apt/apt.8.en.html)
- manページ: `ufw`、`sshd_config`、`lvm`、`cryptsetup`、`wall`(VM内で `man` コマンドにより設定・操作を確認)

### AI usage

- 作業の順序の整理と、コマンドの確認に使用した。各設定の意味は公式ドキュメントで確認した。
- 監視スクリプトで抽出したい値の取り出し方(必要な情報の並び順の確認方法やコマンドの書き方)の確認に使用した。
- 一次情報の調べ方と、調べたうえで意味が分からなかった部分の解説に使用した。