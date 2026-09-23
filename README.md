# nosleep-mac

MacBookを一定時間スリープさせないための、macOS専用コマンドラインツールです。蓋を閉じた状態で長時間の処理を継続したいときに、メニューバー、Dock、ターミナルで状態と残り時間を確認できます。

> [!WARNING]
> 本ツールは `sudo pmset` でMacの電源設定を変更します。蓋を閉じたまま稼働させると発熱・バッテリー消費が増えます。換気できる場所で使用し、鞄など密閉された場所には絶対に入れないでください。

## 特長

- 指定時間だけシステム／アイドルスリープを防止し、満了時に起動前の設定へ復元
- 蓋閉じ時のスリープ防止を試みるシステム設定と、`caffeinate`・IOKitアサーションを併用
- メニューバー・Dock・ターミナルに残り時間を表示
- `q`、`Ctrl+C`、Dock／メニューバー、または `nosleep --off` で解除
- `+` キーまたはメニューから15分・30分・1時間の延長
- バッテリー駆動時、残量10%以下で自動解除

## 動作要件

- macOS（Cocoa、IOKit、`pmset`、`caffeinate` を使用）
- Xcode Command Line Tools（`swiftc`）
- 管理者権限（電源設定変更時に `sudo` を使用）

## クイックスタート

```bash
git clone https://github.com/jantyran/nosleep-mac.git
cd nosleep-mac
make build
./nosleep 1h
```

初回起動時に管理者パスワードを求められます。起動前のスリープ設定を保存し、終了時にその値へ復元します。同時に実行できるセッションは1つです。

### インストール

ローカルコマンドとして使う場合は、シンボリックリンクを作成します。

```bash
make install
nosleep 30m
```

`/usr/local/bin` に書き込めない場合は `~/.local/bin/nosleep` にリンクします。後者を使う場合は、そのディレクトリを `PATH` に追加してください。

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### アンインストール

```bash
make uninstall
```

## 使い方

```bash
nosleep             # 30分（デフォルト）
nosleep 15m         # 15分
nosleep 1h          # 1時間
nosleep 1.5h        # 1時間30分
nosleep 90s         # 90秒
nosleep 45          # 単位なしは分

nosleep --status    # 現在の電源設定を表示
nosleep --off       # スリープ防止を強制解除
nosleep --help      # ヘルプ
```

時間は1秒以上、7日以内で指定できます。不正な値はデフォルト値に置き換えず、エラーとして終了します。

実行中の操作:

- `q` または `Ctrl+C`: 解除して終了
- `+`: 15分延長
- Dockまたはメニューバー: 残り時間の確認、延長、解除

## アーキテクチャ

```text
nosleep（Bashランチャー）
 ├─ 引数処理・sudo認証の維持
 ├─ pmset: 起動前設定を保存し、蓋閉じ／スリープ関連の設定を変更・復元
 ├─ セッションロック: 同時実行と他セッションの誤解除を防止
 ├─ caffeinate: プロセス存続中のスリープを抑制
 └─ nosleep-mac（Swift / Cocoaアプリ）
     ├─ IOKit: システム／アイドルスリープ抑制アサーション
     ├─ DispatchSourceTimer: 残り時間・低残量監視
     ├─ AppKit: メニューバー、Dock、コンテキストメニュー
     ├─ Darwin termios: `q`／`+` の即時キーボード入力
     └─ osascript: macOS通知
```

| パス | 役割 |
| --- | --- |
| `nosleep` | 実行入口。管理者認証、`pmset`、`caffeinate`、Swiftバイナリ起動を担うBashスクリプト。 |
| `src/main.swift` | UI、タイマー、電源アサーション、通知、キーボード操作を実装する単一のSwiftソース。 |
| `Makefile` | ビルド、インストール、アンインストール用コマンド。 |
| `.gitignore` | ローカルビルド成果物およびmacOSメタデータの除外設定。 |

## 開発

```bash
make build      # 最適化ビルド
make clean      # ビルド成果物を削除
make status     # 電源設定を確認
make off        # スリープ防止を解除
```

テストフレームワークは現時点では未導入です。変更時は少なくとも `make build` を実行し、短い時間指定（例: `./nosleep 10s`）で起動・終了・設定復元を確認してください。

## 既知の制約と安全性

- `pmset` の挙動はmacOSのバージョン、ハードウェア、MDMなどの組織ポリシーに左右されます。すべてのMacで蓋閉じ時の動作を保証するものではありません。
- 異常終了、強制終了、電源断時には設定復元が実行されない可能性があります。次回 `nosleep --off` を実行すると、保存済みの起動前設定からの復元を試みます。
- 本ツールの使用中は、外部ディスプレイや電源接続の有無によってmacOS標準のクラムシェル動作と異なる結果になることがあります。
- 機密情報を含む処理を無人で継続しないでください。

## コントリビュート

IssueとPull Requestを歓迎します。変更は小さく保ち、macOSの電源設定への影響と手動確認結果をPR本文に記載してください。安全性に関する問題は、公開Issueではなくリポジトリ所有者へ非公開で連絡してください。

## ライセンス

[MIT License](LICENSE) のもとで公開しています。
