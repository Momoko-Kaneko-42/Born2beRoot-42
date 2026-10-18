*This project has been created as part of the 42 curriculum by mkaneko.*
# Born2beRoot
## Description
ホストOSの下に仮想マシンを構築し、GUIを使わず、パーティション、ユーザー、ネットワークまで1から自分で設定することで、
設定の意味と動作を説明できることを目標とする課題です。

仮想マシンとは、
ホストの資源を消費し、ホスト故障の影響も受けるため、物理的に独立した機械と同じではありません。
しかし、ホストOSの中にいながら、ホストOSの環境を壊さずに別のパソコンとして動かせるので、
同じ物理端末で複数のOSを動かす、構築や障害対応を試す、環境を分離することが可能です。

仮想マシンのメリットとしては、本番運用しているシステムと同時運用できることで移行がスムーズになったり、
増加や削除が容易で必要な時だけ使えて資源が無駄にならないことなどがあげられます。
デメリットは、オーバーヘッド（処理負荷）やリソース競合が発生し、性能が低下する可能性があることと、セキュリティや適切なリソース対策の必要性など運用が複雑化することです。

仮想マシンを安全に使いやすくするための設定をおこないました。
そのための選択とその理由は後述します。

## project description
このプロジェクトの構成の選択とその理由について

1. 仮想化ソフトウエア　VirtualBox
　  VirtualBoxは課題で基本として設定されており、多様なLinuxとの互換性に優れています。

| 比較軸 | VirtualBox（採用） | UTM |
| --- | --- | --- |
| 対応OS | MacOS Windowsほか| MacOS |
| 長所 | 多くのデバイスでLinuxのVMを管理でき、高度な機能がある | AppleシリコンMacでのパフォーマンスがよい |
| 短所・負担 |　AppleシリコンのMacではパフォーマンスが遅くなる | GUIなしなど機能が少なく、互換性の選択肢が少ない |

2. OS　Debian
  OSとしてDebianを選択したのは、初学者向けに推奨されていること、サーバー用途に定評があり、APT・UFW・AppArmorで基本的なサーバー管理を学べることからです。

| 比較軸 | Debian（採用） | Rocky Linux |
| --- | --- | --- |
| 系統・管理 | Debian系、dpkg・APT、`.deb` | RHEL互換、RPM・DNF、`.rpm` |
| 長所 | stableの安定性、豊富なパッケージと資料 | RHEL互換の運用・企業向け環境を学べる |
| 短所・負担 | 安定性重視のため最新機能が必要な用途に合わない場合がある | 初学者にはSELinuxやfirewalldの設定も含め学習負担がある |
| この課題での保護機構 | AppArmor・UFW | SELinux・firewalld |

| 比較軸 | Apparmor（採用） | SELinux |
| --- | --- | --- |
| アクセス制御方式 | ファイルパスベース | セキュリティラベル（コンテキスト）ベース |
| デフォルト採用 | Ubuntu, Debian, SUSE | RHEL, CentOS, Fedora, AlmaLinux |
| 学習コスト | 比較的低い(パスの記述が直観的) | 高い(ラベル管理の概念理解必要) | 
| カバー範囲 | プロファイルが存在するプロセスのみ | システム全体 |

3. パーティション構成にLVMを選択したのは、後から容量を変えやすくするためです。

4. sshのポートを4242に変更したのは課題要件ですが、 SShで接続できるポート番号を制限し、さらにUFWで許可ポートを絞ることとの組み合わせで効果が出てくると思います。

5. セキュリティ上の観点から以下を設定 
  - パスワードポリシーの期限・品質制限　→　文字種や数が多い強いパスワードや有効期限を設けました。
  - sudoの認証制限 → 管理者権限を誰でも使えるようすると不正な操作が行われる可能があるため、sudoを使えるユーザーを制限し、だれがどのような管理操作を行ったか記録できるようにする。
  - 操作ログ　→  安全に作動しているか確認する。
  - UFWで4242/TCPのみ受信許可 ->　ネットワークの入り口を絞ることで攻撃のリスクを減らす。
  - rootのSSHログイン禁止 →　rootは名前が知られていて最大権限を持つので、直接ログインを許すと攻撃されやすく、侵入された時の被害も大きい。一般ユーザー + sudoにすると、攻撃の難易度が上がり、操作の記録も残せる。
  - AppArmor →　起動時に自動で立ち上がるように設定されていることを確認し、今回中身は変更していない。

6. Linuxのパケットフィルタを管理するツール　UFW
ポートや接続元に対する許可を簡潔に記述することができ、この課題のような少数のルールを扱うのに適しています。

| 比較軸 | UFW（採用） | firewalld |
| --- | --- | --- |
| 系統 | Ubuntu | CentOS/RHEL/AlmaLinux/Fedora系|
| 長所 | コマンドが簡潔でわかりやすい。IPv6に対応 | ゾーンベースの管理やランタイム/パーマネント設定の分離が特徴 |

＊選択方法 → ディストリビューション標準のものを素直に使う


7. サーバーの状態をログに残し、定期的にログに残してメッセージを出す(monitoring.sh cron)ことで、正常に作動しているか確認する。

8. インストールしたサービスは以下の通りです。
Visualbox
Debian
AppArmor
UFW


## Instructions
以下の順番で設定を行いました。

0. 課題要件を基準にDebianのバージョンと仮想マシン(VM)の構成を決める。
  - Debian Released(https://www.debian.org/)より最新安定板はDebian 13.7 amd64 trixie。

  - VMソフト　  VirtualBox

  - CPU　2コア

  - メモリ　2048MB

  - 仮想ディスク　20GB

  - ディスク方式　動的割り当て

  - グラフィック　最小限

  - ネットワーク　NAT(Network Address Translation) ホストOSのインターネット回線を借りてネットにつなぐ仕組み

  - GUI　なし

  - SSH　4242番

  - ディスク暗号化　LUKS + LVM

1. 仮想マシンの作成
  (1)仮想化ソフトVirtualBoxをインストールする。

  (2)設定内容
    - VM名

    - ISO Debian 13.7 netinst(ダウンロードしたファイルのパスを指定)

    - CPU　2コア

    - メモリ　2048MB

    - ディスク　20GB

    - ネットワーク　NAT(仮想マシンを右クリック→設定→ネットワーク→アダプター１にIntel PRO/1000 MT デスクトップ(NAT)を指定する)

  (3)基本モード → 新規を選択。
    - 無人インストールのチェックは外す。
  
    - ISOは空欄。
  
    - EFIにチェックはしない。
  
    - ディスクは動的割り当てにする。
  
    - 選んではいけないもの→[Full Disk Allocation(ディスクを事前に全量確保)][固定サイズ]
    　ディスクの暗号化LVMはDebianのインストーラー側で設定するため、VirtualBox側では普通の仮想ディスクを用意するだけでよい。

  (4)起動ボタンを押す。Debianのインストーラーが起動する。

2. OSのインストール
  - 公式サイトからダウンロードしたDebianをインストールする。
  
  (1)表示言語の文字コードの設定を行う。
      JapaneseやJapanを選択するが選択肢がなければEnglishやusでも問題ない。
      keyboardの欄は使っているキーボード配列によって決める。
  
  (2)ホスト名の指定
      intra名⁺42
  
  (3)Domainは空欄
  
  (4)ユーザーとパスワードの指定
    rootのパスワードの入力と一般ユーザー名＆パスワードの入力をしログインする。
  
  (5)rootまたは作成したユーザーでログインした状態でパーティショニング設定を行う。
  ```
  Guided use entire disks & set up encrypted LVM
  Separate /home, /var and /tmp partitions
  ```
  上記のメニューを選択して進むと、暗号化するためのパスフレーズを入力する画面が出るので、指定する。
  LVMで使ったVolumeGroupのうち、どれだけの容量を今回の論理ボリュームで使うか聞いてくるので、
  動的に割り当ててくれるため、100%としても大丈夫でした。
  以下が実際の分割です。

    ```
    sudo lsblk
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

    /boot はカーネルなどの起動ファイル用です。LUKS内にroot・home・swapを置き、OSやユーザーデータ、swapへの書き込みを暗号化します。rootとhomeのLVを分けて容量を個別に割り当てます。
  
  (6)パッケージマネージャを設定する、としてDebianの利用統計に送信するかどうかを聞かれたらNoにして構いません。

  (7)Software selectionでは、SSH serverと、選択できるならstandard sysetm utilitiesにチェックを入れる。要件にx.org Wayland or any other equivalent graphics server are forbiddenとあるので、デスクトップ環境は選ばないようにします。

  (8)GRUB ブートローダ　yes　→　インストール先指定 /dev/sda
    ＰＣに電源が入ると、BIOS/UEFIが動き、GRUBが起動する。GRUBとはLinuxカーネルを見つけて、メモリに読み込み起動させることが仕事です。

  (9)continueを押してプロンプトが出ていればインストールできています。


3. sudoを使えるようにする。 一般ユーザーから実行する。
  -  sudoは一般ユーザーが一時的に管理者権限を使ってコマンドを実行するための仕組みです。Windowsで例えるとインストール時に管理者として実行する操作に近いと思います。
  - Linuxにあるユーザー権限
    ・一般ユーザー（この課題ではintra名）→　普通の作業をするユーザーで自分のファイルを操作できる。システム全体に関する変更には制限がある。
    ・管理者(root)　→　システム全体を管理できる特別なユーザー。ユーザーの追加・システム設定の変更を行うことができる。

  (1)今の状態を確認する
    ```
    whoami　→　intra名ならok
    ```

  (2)sudoがあるか確認
    ```
    sudo --version
    ```
    なければ一度rootでログインしなおす
    ```
    su - →　rootのパスワードを聞かれるので入力
    apt update →Debianのパッケージ一覧を最新にしてから
    apt install sudo
    ```

  (3)一般ユーザーをsudoグループに追加する。rootから実行
    ```
    usermod -aG sudo intra名
    exit →　rootから抜ける
    exit →　一般ユーザーからもログアウト
    ```

  (4)再度一般ユーザーでログインし、sudoが使えるようになったか確認する。
    ```
    sudo whoami
    [sudo]password for 一般ユーザーのパスワード
    ```
    rootと表示されればok。sudoを使ってroot権限でコマンドを実行できたという意味です。

4. SSHの設定 一般ユーザーで実行。

  (1)実際にSSHサービスが動いているか確認する。

  ```
  sudo systemctl | status ssh　→ Active: active(running)があればok
  ```

  (2)SSHの設定ファイルを開く。

  ```
  sudo nano /etc/ssh/sshd_config
  ```
  `#port 22` →　port 4242に変更

  `#permitRootLogin prohibit-password` → PermitRootLogin noに変更

  `#`は削除し保存します。

  nano の保存は ctrl+O -> enter -> ctrl+x

  (3)設定を反映するためにSSHサービスを再起動する。

  ```
  sudo systemctl restart ssh
  sudo ss -tlnp | grep ssh ->LISTENの表示に4242が出ていれば成功
  ```

  (4)rootログイン禁止の確認

  ```
  sudo sshd -T | grep permitrootlogin -> permitrootlogin noで成功
  ```

  (5)実際に一般ユーザーでSSH接続できるかを確認する

   - VMのIPアドレスを確認する。
  ```
  ip addr -> inetと書かれているものの中で127.0.0.1でないほうを探す。
  ```

   - SSH接続を試す。
   ターミナルで
  ```
  ssh -p 4242 ホスト名@VPのIPアドレス
  "are you sure you want to continue connecting(yes/no/fingerprint)?"->yesにする
  プロンプトに戻れば成功
  ```

   - 今どこにいるか確認
  ```
  hostname ->  ホスト名
  whoami -> 一般ユーザー名
  ```

5. Apparmorの確認
  - インストール済みか確認する。VisualBoxマネージャからVMを起動 → Debianにログインし以下を実行
  ```
  sudo aa-status　→ AppArmorがどのような状態で動いているかを表示するコマンド
  sudo systemctl status apparmor → Apparmorが起動しているか確認
  sudo aa-status | grep -E 'apparmor module | profiles are loaded | profiles are in enforce mode'　→必要なプロファイルが適用されているか確認できる。
  ```

6. UFWの設定
  (1)現在の状態を確認する

  ```
  sudo ufw status → 入ってなければインストール
  sudo apt update
  sudo apt install ufw
  ```

  (2)SSH用ポートの許可が先に済んでいることを確認する
  - SSHのポート番号の確認
  ```
  sudo grep -i '^Port ' /etc/ssh/sshd_config　→ port 4242であればよい。
  ```
  (3)SSHポートを許可する
  ```
  sudo ufw allow 4242/tcp
  ```

  (4)ufwを有効にする前に4242番ポートを許可するルールが登録されたことを確認
  ```
  sudo ufw status
    To                         Action      From
    --                         ------      ----
    4242/tcp                   ALLOW       Anywhere
    4242/tcp (v6)              ALLOW       Anywhere (v6)
    のようになっていれば許可されている
  ```
  * 先頭が Status: inactive になっている場合は、ルールを登録しただけでファイアウォールは有効でない。

  (5)ufwを有効にする
  ```
  sudo ufw enable　→　その後 sudo ufw statusで有効になったか確認する。
  余分なルールがある場合は以下のように削除する。
  sudo ufw delete allow 22/tcp(または sudo ufw status numbered で番号を指定)で削除
  ```
  ```
  sudo ufw status verbose
  ```
  verbose: デフォルトポリシー(incomingはdeny、outgoingはallowなど)も一緒に表示される。

7. ユーザー・グループの設定
  ログインユーザーがuser42とsudoの両グループに所属しているか確認する
  (1)現在のユーザーとグループの状態を確認する
  ```
  whoami
  id →　今ログインしているユーザーが所属しているグループが表示される
  ```
  すでに3.でsudoグループには追加されているので、user42グループに追加。

  (2)user42グループが存在するか確認する
  ```
  getent group user42　→　何も返ってこなければ追加する必要がある
  sudo groupadd user42 →　user42:x(グループパスワード欄):1001(gid):メンバー一覧のように表示されれば成功
  ```

  (3)ユーザーをuser42グループに追加する必要があるか確認してから追加。
  ```
  id ユーザー名　→　groupsにuser42がなかったら所属させる
  sudo usermod -aG user42 ユーザー名
  id ユーザー名で確認
  ```
  - -aG　既存グループ所属を維持しながら追加のグループに所属させる

8. sudoのセキュリティ設定
  (1)現在のsudo設定を確認する。
  ```
  sudo -l ➺　パスワードを入力する
  ```
  - 表示内容
  ・sudo実行時の環境変数や実行環境を制御する設定
  ・メール通知の設定
  ・パスの制限
  ・どのホストに対する設定か
  ・そのユーザーとして実行するか
  ・実行できるコマンド

  (2)sudoの設定ファイルを確認する
  ```
  sudo cat /etc/sudoers
  sudo grep -nE '^(Defaults|%sudo|%user42|ユーザー名)' /etc/suoers ➺ 現在のデフォルト値を見ることができる
  ```
  (3)ログの保存先ディレクトリをターミナルで作成する。
  - ログの保存先は/var/log/sudo
  ```
  sudo mkdir -p /var/log/sudo
  sudo touch /var/log/sudo/sudo.log
  sudo chown root:root /var/log/sudo/sudo.log ➺　ファイルの所有者とグループをrootにする
  sudo chmod 600 /var/log/sudo/sudo.log ➺　rootだけが読み書き可にする
  ls -l /var/log/sudo/sudo.log →　作成できたか確認
  ls -ld /var/log/sudo ➺　ログのディレクトリとファイルの権限を確認

  (4)設定ファイルと編集する
  - visudoコマンドで編集すると構文チェックをしてくれて安全。

  - 設定ファイルのバックアップをしてから編集(編集内容はConfigurationに記述)
  ```
  sudo cp /etc/sudoers /etc/sudoers.bak
  sudo visudo
  sudo -l ➺　変更できたか確認
  sudo tail -n 5 /var/log/sudo/sudo.log　➺　ログに記録が表示されれば成功
  ```

9. パスワードポリシーの設定（詳細はConfigurationへ）
  (1)Debianのバージョンを確認する
  ```
  cat /etc/debian-version
  ```

  (2)パスワードの強度をチェックするためのパッケージ(libpam_pwquality)がインストールされているか調べる
  ```
  dpkg -l libpam_pwquality　➺インストール済みなら、ii libpam_pwqualityという記述がでる。
  ```
  ＊dpkg ➺　Debianパッケージのインストール・ビルド・削除・管理を行うツール

  (3)パスワードポリシーの設定ファイルを確認し編集する。
  ```
  sudo nano /etc/security/pwquality.conf
  ```
  - 負数の値は最低必要な文字数を表し、正数は長さの判定をするとき、その数の分だけプラスして判定するという意味です。

  (4)追加した設定の確認
  ```
  grep -E '^(minlen|ucredit|lcredit|dcredit|maxrepeat|usercheck)' /etc/security/pwquality.conf
  ```

  (5)パスワード変更時にルールが実際に使われるようにPAM(Pluggable Autentication Modules)の設定を確認
  ```
  grep -n 'pam_pwquality' /etc/pam.d/common-password
  grep -nE 'pam_pwquality|pam_pwhistory|pam_unix' /etc/pam.d/common_password ➺　パスワードの強度チェック、過去のパスワード履歴、通常のパスワード認証をチェック
  ```
  - PAMは設定ファイルに書かれたモジュール名を見て、必要なときにこのファイルを読み込んで実行する。

  (6)有効期限などの時間に関する設定はConfigurationsの表に記載。一般ユーザーだけでなくrootの設定も変更した。

10. 監視スクリプト(monitoring.sh)を作る。
  - 一般ユーザーで作業する。
  - ファイルの作成先　ホームディレクトリ
  - Bashスクリプトなのでシバンを入れる。
    - ディスクの管理>　
    - 通信とセキュリティの設定> 
  - 監視スクリプトの作成>
11. 新しいユーザーの作り方(Linuxではユーザーとグループを使ってファイルやシステムの捜査権限を管理する)
```
sudo adduser testuser
id testuser
su - testuser
  パスワードを入れて切り替える
whoami(確認)
testuserでログインした状態から
```
sudo whoami
```
testuserはsudoグループに所属していないから使えない
```
exit
```
mkanekoに戻る
現在のユーザーの確認
```
whoami
sudo usermod -aG sudo testuser
id testuser
su - testuser
whoami
sudo whoami
```

  <signature.txtファイルを作成>

## Resources
- VirtualBox公式サイト
  Oracle VM VirtualBox 公式ダウンロード
  (https://docs.oracle.com/en/virtualization/virtualbox/7.0/user/)

- VirtualoxとUTMの比較
  (https://linux-jp.org/?p=16476)

- Debian Releases:OSについて
  https://www.debian.org/

- LVM
  wikiwiki.jpのLVMページ
  https://wikiwiki.jp/linuxnomemo/LVM

- sudo
  SUSEの「sudoを使用したスーパーユーザ特権の設定」
  https://documentation.suse.com/ja-jp/sle-micro/6.0/html/Micro-sudo-configure-superuser-privileges/index.html

  LabExの「sudoers 設定の問題を解決する方法」
  https://labex.io/ja/tutorials/nmap-how-to-fix-sudoers-configuration-problems-419586
  
  Debianの公式サイト
  https://manpages.debian.org/unstable/manpages-ja/sudo.8.ja.html

  man 5 sudoers(sudoの権限とログ設定)
  (https://manpages.debian.org/trixie/sudo/sudoers.5.en.html)

  man 8 pam_pwquality
  (https://manpages.debian.org/trixie/libpam-pwquality/pam_pwquality.8.en.html)

- SSH
  OpenSSH公式サイト: https://www.openssh.com/
- ufw, sshd_config, lvm, wall
  manページ

- cron
  man 1 crontab(コマンド) 
  man 5 crontab(時刻の指定と実行についての書き方)
  (https://manpages.debian.org/trixie/cron/crontab.5.en.html)

- signature.txt
  certUtil -hashfile "mkaneko42.vdi" SHA1

- apt 
  man 8 apt(使い方)
  (https://manpages.debian.org/trixie/apt/apt.8.en.html)


- VM内の `man sshd_config`、`man ufw`、`man lvm`、`man cryptsetup`、`man wall`：設定・操作の確認。

### AI usage
・作業の順序の整理とコマンドの確認にAIを使った。各設定の意味は公式ドキュメントで確認した。
・監視スクリプトで抽出したい値の取り出し方（必要な情報の並び順の確認方法やコマンドの書き方）を確認。
・一次情報の調べ方と、調べたうえで意味が分からないところの解説。



#### Details
##### Configuration
項目	          ファイル	       設定	                理由
有効期限	      /etc/login.defs	 PASS_MAX_DAYS 30	    定期的な変更を強制
変更間隔の下限	/etc/login.defs	  PASS_MIN_DAYS 2	    すぐ元に戻すのを防ぐ
期限前の警告	  /etc/login.defs	  PASS_WARN_AGE 7	    期限切れ前に気づける
最小文字数・文字種・連続文字・ユーザー名禁止など	
               /etc/pam.d/common-password または 
               /etc/security/pwquality.conf	minlen, ucredit, lcredit, dcredit, maxrepeat, usercheck, difok, enforce_for_root など	強度の確保
パスワードポリシーの行に「PAM(pam_pwquality)で実装」と一言添える
##### Installation
###### VirtualBox
自分のpcにはVirtualBoxがなかったので、Oracle VM VirtualBoxからVirtualBox platform packagesよりwindows host用のVirtualBox 7.0.26をダウンロードしてインストール
##### partitioning
##### sudo
##### hostname
##### SSH
##### UFW
##### Groups
##### Passwords

