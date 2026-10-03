# nosleep-mac

[![CI](https://github.com/jantyran/nosleep-mac/actions/workflows/ci.yml/badge.svg)](https://github.com/jantyran/nosleep-mac/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

macOS のスリープを指定時間だけ抑止する、メニューバー対応のコマンドラインツールです。長時間のローカル処理を続けたいときに、残り時間をメニューバー・Dock・ターミナルで確認できます。

> [!WARNING]
> このツールは `sudo pmset` で電源設定を一時変更します。蓋を閉じたまま使用すると発熱とバッテリー消費が増えることがあります。換気できる場所で使用し、稼働中のMacを鞄など密閉された場所に入れないでください。

## 特長

- システム／アイドルスリープを指定時間だけ抑止し、終了時に元の設定へ復元
- `caffeinate`、IOKitアサーション、`pmset` を併用
- 残り時間をメニューバー、Dock、ターミナルに表示
- `q`、`Ctrl+C`、メニュー、または `nosleep --off` で安全に解除
- `+` キーまたはメニューから15分・30分・1時間延長
- バッテリー残量10%以下で自動解除

## 動作要件

- macOS
- Xcode Command Line Tools（`swiftc`）
- 管理者権限（`pmset` の変更時のみ `sudo` を使用）

Xcode Command Line Tools が未導入の場合:

```bash
xcode-select --install
```

## インストール

### GitHubから導入する（推奨）

```bash
git clone https://github.com/jantyran/nosleep-mac.git
cd nosleep-mac
make install
```

`make install` は `~/.local/bin` に `nosleep` と実行バイナリをコピーします。開発ディレクトリを削除した後も実行できます。

`~/.local/bin` が `PATH` にない場合は、zshでは次を実行して新しいターミナルを開いてください。

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

システム全体に導入する場合は、明示的に接頭辞を指定します。

```bash
sudo make install PREFIX=/usr/local
```

確認:

```bash
nosleep --help
```

### アンインストール

```bash
make uninstall
# システム全体に導入した場合
sudo make uninstall PREFIX=/usr/local
```

## 使い方

```bash
nosleep             # 30分（デフォルト）
nosleep 15m         # 15分
nosleep 1h          # 1時間
nosleep 1.5h        # 1時間30分
nosleep 90s         # 90秒
nosleep 45          # 単位なしは分

nosleep --status    # 電源設定とセッション状態を表示
nosleep --off       # 実行中のセッションを停止して設定を復元
nosleep --help      # ヘルプを表示
```

時間は1秒以上、7日以内で指定できます。実行中は `q` または `Ctrl+C` で終了し、`+` で15分延長できます。Dockまたはメニューバーからも状態確認、延長、解除が可能です。

初回実行時には管理者パスワードを求められます。同時に実行できるセッションは1つです。

## インストール設計

`nosleep` は配置先のディレクトリを解決して、同じ場所にある `nosleep-mac` を起動します。そのため、インストール時には次の2ファイルを同じ `bin` ディレクトリへコピーします。

```text
~/.local/bin/
├── nosleep       # Bashランチャー（PATHから呼び出す入口）
└── nosleep-mac   # SwiftでビルドしたmacOSアプリ
```

この構成により、カレントディレクトリやリポジトリの存在に依存せず、PATHが通った任意の場所から `nosleep` を実行できます。アップデート時はリポジトリで `git pull` 後、再度 `make install` を実行してください。

## 開発

```bash
make build      # 最適化ビルド
make test       # 時間指定パーサーのテスト
make clean      # ビルド成果物を削除
make status     # 電源設定を確認
make off        # 実行中のセッションを解除
```

開発中は `./nosleep 10s` のような短時間指定で、起動・終了・設定復元を手動確認してください。

## アーキテクチャ

```text
nosleep（Bashランチャー）
├─ sudo認証、電源設定の保存・変更・復元
├─ セッションロックと `caffeinate` の管理
└─ nosleep-mac（Swift / Cocoa）
   ├─ IOKit: スリープ抑止アサーション
   ├─ AppKit: メニューバーとDock
   ├─ DispatchSourceTimer: 残り時間・低残量監視
   └─ termios: `q`／`+` の入力処理
```

## 制約と安全性

- 蓋閉じ時の挙動は、macOSのバージョン、機種、外部電源・ディスプレイ、MDMポリシーにより異なり、保証できません。
- 起動中は `pmset disablesleep` を一時変更します。通常の `sleep` 時間設定は変更しません。
- 強制終了や電源断では設定復元が行われないことがあります。保存状態が残っている場合は `nosleep --off` を実行してください。
- `nosleep --status` でセッションが無いのに `SleepDisabled 1` と表示され、保存状態も無い場合、このツールだけでは元の値を特定できません。自身の電源設定を確認してから復旧してください。以前のバージョンは `sleep 0` も設定していました。
- 機密情報を含む処理を無人で継続しないでください。

## コントリビュート

貢献方法は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。行動規範は [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) です。脆弱性は公開Issueに投稿せず、[SECURITY.md](SECURITY.md) の手順で報告してください。

## ライセンス

[MIT License](LICENSE) のもとで公開しています。
