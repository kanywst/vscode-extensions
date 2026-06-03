![vscode-extensions — track & reinstall your VS Code setup](assets/banner.png)

_[English](README.md) | 日本語_

VS Code の拡張機能リストを git で管理し、同じセットをどのマシンにも再現する。

`extensions.list` が拡張機能ID を保持する。`bin/` のスクリプトがエディタから書き出し / リストからインストール / 差分確認を行う。

## 使い方

### 1. このマシンの状態を記録して push する

`extensions.list` には既にこのマシンの拡張機能が入っている。commit して自分の remote へ push する。

```bash
git remote add origin git@github.com:<you>/vscode-extensions.git
git add -A
git commit -m "init: track vscode extensions"
git push -u origin main
```

### 2. 別のマシンで再現する

clone してリストどおりにインストールする。再実行は安全で、入っている拡張機能はスキップされる。

```bash
git clone git@github.com:<you>/vscode-extensions.git ~/vscode-extensions
cd ~/vscode-extensions
bin/install.sh
```

### 3. 拡張機能を追加・削除したあと

VS Code 上で入れたり消したりしたら、再書き出しして差分を commit する。

```bash
bin/export.sh
git add extensions.list
git commit -m "chore: update extensions"
```

### 差分を確認する

インストール済みと `extensions.list` を比較する。差があれば非ゼロで終了するので、CI や pre-commit hook に組み込める。

```bash
bin/diff.sh
```

### 自動でリストを同期する

pre-commit hook を入れると、commit のたびに `extensions.list` が再書き出し＆ステージされる。インストール実態とリストがずれない。

```bash
ln -s ../../bin/pre-commit .git/hooks/pre-commit
```

## 別エディタを使う場合

Cursor / VSCodium / Insiders など `code` 以外の CLI を使うときは `CODE_BIN` を指定する。

```bash
CODE_BIN=cursor bin/export.sh
CODE_BIN=codium bin/install.sh
```

## 注意点

- `code` コマンドが PATH に必要。コマンドパレットの `Shell Command: Install 'code' command in PATH` で追加する。
- 管理対象は拡張機能ID (`publisher.name`) のみ。`settings.json` やキーバインドは対象外。
- `bin/install.sh` は `code --install-extension --force` を実行するため、導入済みの拡張機能も最新版に更新される。
- `extensions.list` は小文字化・ソート済みで書き出されるので diff が安定する。
