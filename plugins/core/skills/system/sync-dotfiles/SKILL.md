---
name: sync-dotfiles
description: chezmoi dotfilesリポジトリをリモートと双方向同期するスキル。ユーザーが「dotfiles同期して」「pushして」「リモート更新して」「コミットして」「変更をプッシュ」「dotfiles push」「最新にして」「pullして」「同期して」「リモートの変更を取得」「更新して」と言ったとき、または明示的に呼び出されたときに使用する。dotfilesやchezmoi管理下の設定ファイルに変更を加えた後の同期文脈でも積極的に使うこと。
---

# sync-dotfiles: dotfilesリポジトリの双方向同期

前提: chezmoi がインストールされ、dotfiles が chezmoi 管理下にあること。対象は常に chezmoi のソースリポジトリで、`chezmoi git --` 経由で操作する（＝カレントディレクトリに依存せず、どのプロジェクトから実行しても dotfiles を対象にする）。

どのPCでいつ実行しても、そのPCをリモートと正しく同期する。
ローカル変更のpush、リモート変更のpull、双方向差分のrebase、ネットワーク不通時のフォールバックに対応する。

## 絶対禁止事項

- `.env`、`credential`、`secret`、`token`、`password`、`.key`、`.pem`、`id_rsa` を含むファイル名のステージ禁止
- `chezmoi git -- add -A` や `chezmoi git -- add .` の使用禁止（ファイルを個別指定すること）
- ユーザー確認なしでのコミット・プッシュ禁止
- リポジトリURL・ユーザー名等の個人情報をこのファイルにハードコード禁止

## 手順

### 0. ブランチ確認

```bash
chezmoi git -- branch --show-current
```

main以外の場合はユーザーに警告し、AskUserQuestionで続行するか確認する。
理由: 以降の判定・push・rebaseはすべてmain前提で動作するため。

### 1. 状態判定

```bash
chezmoi git -- fetch origin
```

fetchが失敗した場合は **状態F（ネットワーク不通）** へ進む。

fetchが成功した場合、以下を実行:

```bash
chezmoi git -- status --short
chezmoi git -- rev-list --count HEAD..origin/main
chezmoi git -- rev-list --count origin/main..HEAD
```

以下の2軸で状態を判定する:

| | behind=0 | behind>0 |
|---|---|---|
| clean & ahead=0 | **E. 同期済み** | **C. リモート先行** |
| clean & ahead>0 | **B2. push未済** | **D. 双方向差分** |
| uncommitted変更あり & ahead=0 | **B1. ローカル変更** | **D. 双方向差分** |
| uncommitted変更あり & ahead>0 | **B1. ローカル変更** | **D. 双方向差分** |

### 2. 状態報告

判定結果と実行計画をユーザーに報告する:
- 判定された状態名
- behind数、ahead数、uncommitted変更の有無
- これから実行する手順の概要
- 状態Dではコンフリクトリスクも伝える

### 3. ユーザー確認（ゲート）

AskUserQuestion で「実行してよいですか？」と確認する。選択肢は「実行する」「中止」を用意する。
中止の場合はそこで終了。

以下の場合はステップ3のゲートを省略する:
- **B1/F（uncommitted変更あり）**: 各状態内の実行計画確認（AskUserQuestion）で兼ねるため
- **D（uncommitted変更あり）**: B1の実行計画確認で兼ねるため
- **E**: 何も実行しないため
- **F（uncommitted変更なし）**: 何も実行しないため（fetch失敗の報告のみで終了）

以下の場合はステップ3のゲートを実施する:
- **B2**: 状態内にAskUserQuestionがないため
- **C**: 状態内にAskUserQuestionがないため
- **D（uncommitted変更なし）**: コミットフェーズがスキップされrebaseに直接進むため、rebase前の確認として必要

---

## 状態別の実行手順

### B1. ローカル変更あり（uncommitted）

#### 差分の報告

`chezmoi git -- status --short` と `chezmoi git -- diff` の結果を分析し、以下の形式で報告する。

```
## 変更内容

- 新規: <ファイル一覧>
- 変更: <ファイル一覧>
- 削除: <ファイル一覧>

## 差分概要

<主要な変更の要約>
```

#### 危険ファイルのチェック

変更対象に以下のパターンが含まれていないか確認する:
`.env*`, `*credential*`, `*secret*`, `*token*`, `*password*`, `*.key`, `*.pem`, `id_rsa*`

該当ファイルがあればユーザーに警告し、除外して続行するか確認する。

#### コミットメッセージの生成

差分を分析し、Conventional Commits形式（日本語）でメッセージを生成する。

- prefix: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:` から適切なものを選択
- 本文: 変更内容を端的に日本語で記述
- 既存コミット履歴のスタイルに合わせる（例: `feat: .gitconfigをchezmoi管理に追加`）

複数の無関係な変更がある場合は、必ず分割コミットにする。

#### 実行計画の提示と確認

実行計画をテキストで提示したうえで、AskUserQuestion で確認を取る:

```
## 実行計画

- ステージ対象: <ファイル一覧>
- コミットメッセージ: `<メッセージ>`
- プッシュ先: origin main
```

選択肢は「実行する」「中止」を用意する。
中止の場合はそこで終了。メッセージ修正の要望があれば反映して再確認する。

#### コミットとプッシュ

承認後、順番に実行する:

```bash
chezmoi git -- add <file1> <file2> ...
chezmoi git -- commit -m "<メッセージ>"
chezmoi git -- push origin main
```

push後、**apply前ゲート** へ進む。

### B2. push未済（committed, ahead>0）

未pushコミット一覧をユーザーに提示する:

```bash
chezmoi git -- log --oneline origin/main..HEAD
```

提示後、push を実行:

```bash
chezmoi git -- push origin main
```

push後、**apply前ゲート** へ進む。

### C. リモートのみ先行

```bash
chezmoi update -v
```

`chezmoi update` は内部で `git pull --autostash --rebase` + `chezmoi apply` を一括実行する。
apply前ゲートは不要（`update -v` の出力で適用結果が見える）。

**完了報告** へ進む。

### D. 双方向差分

uncommitted変更があればまずコミットする（B1の「差分の報告」〜「実行計画の提示と確認」〜コミットまでを実行。実行計画テンプレートの「プッシュ先」は「rebase後に実行」と表示する。**pushはしない**）。

全コミット後にrebase:

```bash
chezmoi git -- pull --rebase origin main
```

#### rebase成功時

`chezmoi git -- log --oneline -5` でrebase結果を表示し、AskUserQuestionでpush続行の確認を取る。

```bash
chezmoi git -- push origin main
```

push後、**apply前ゲート** へ進む。

#### コンフリクト発生時

AskUserQuestionで選択肢を提示する:

- **「abort」**: `chezmoi git -- rebase --abort` で取り消し、終了
- **「Claudeが解決」**: Claudeがコンフリクトマーカーを検出し、ファイル内容を表示してユーザーに解決方針を確認。承認後:
  1. コンフリクトファイルを編集して解決
  2. `chezmoi git -- add <resolved files>`
  3. `chezmoi git -- rebase --continue`
  4. 解決後、push → apply前ゲートを継続

### E. 同期済み

「このPCは最新です。」と表示して終了。ゲート不要。

### F. ネットワーク不通

fetch失敗を報告する。

ローカルにuncommitted変更がない場合は、fetch失敗の報告のみで終了する。

ローカルにuncommitted変更がある場合、AskUserQuestionで「コミットのみ実行しますか？」と確認する。
承認された場合、B1の「差分の報告」〜「実行計画の提示と確認」〜コミットまでを実行する（実行計画テンプレートの「プッシュ先」は「接続回復後に手動実行」と表示する。pushはしない）。

pushは接続回復後に手動で実行するよう案内する:

```
接続回復後に以下を実行してください:
chezmoi git -- push origin main
```

---

## apply前ゲート（B1/B2/D共通）

push完了後:

```bash
chezmoi diff
```

- **差分がない場合**: 「このPCは既に最新です。」と表示して完了報告へ進む。
- **差分がある場合**: そのまま全適用の確認に進まず、まず差分をファイル単位で分類する。

#### 差分の分類

差分に含まれるファイルを2種類に分ける:

1. **今回の同期による差分**: 今回コミット・pull した変更のホームへの反映。適用が同期の目的そのもの。
2. **既存の乖離**: 今回の同期とは無関係に、以前からホーム側と正本が食い違っているファイル。ホーム側だけの意図的な設定（そのマシンで個別に有効化したプラグイン、マシン固有の値など）が含まれている可能性があり、全適用すると黙って消える。

既存の乖離があるファイルは、`chezmoi git -- log --oneline -5 -- <正本側パス>` で正本の履歴を確認する。「意図的に正本から外した」趣旨のコミットがあれば、その乖離はマシン固有の設定である可能性が高い。判断材料（どの設定が消えるか、履歴から意図的と推測できるか）をユーザーに報告する。

#### 適用範囲の確認

分類結果を報告したうえで、AskUserQuestion で確認する:

- **既存の乖離がない場合**: 「適用する」「スキップ」の二択。
- **既存の乖離がある場合**: 「今回の同期分のみ適用（推奨）」「全適用」「スキップ」の三択。各選択肢に、何が適用され、何がホーム側から消えるかを明記する。

承認された範囲を適用する（`--force` は対話プロンプトを回避するため。確認はAskUserQuestionで取得済み）:

```bash
chezmoi apply -v --force                          # 全適用
chezmoi apply -v --force <ホーム側パス1> <パス2>  # 部分適用（今回の同期分のファイルだけを指定）
```

部分適用またはスキップで乖離を残した場合は、完了報告に「既存の乖離が残っている」旨と対象ファイルを含める。乖離が恒常的なら、chezmoi のテンプレート機能でマシン別に出し分ける整理も提案できる。

## エラー対応

| エラー | 対応 |
|--------|------|
| push conflict（non-fast-forward） | 状態判定をやり直す（状態Dとして処理される） |
| 認証エラー | 「GitHubへの認証に失敗しました。credential設定やSSH鍵を確認してください」と報告 |
| リモート未設定 | `chezmoi git -- remote -v` の結果を表示し、設定を案内 |

## 完了報告

### push時（B1/B2/D）

```
## 同期完了

- コミット: `<short hash>` <メッセージ>
- プッシュ先: origin/main
- 対象ファイル数: <N>ファイル

## 他のPCへの適用

`chezmoi update -v`
```

### pull時（C）

```
## 同期完了

- 取得コミット数: <N>コミット
- 適用結果: <chezmoi update -v の出力概要>
```

---

## 出力フォーマット

スキルの全出力はMarkdown見出し（`##`）でフェーズを区切る。ユーザーがどこを読んでいるか一目でわかるようにする。絵文字は使用しない。

### フェーズ一覧

- **ブランチ警告**: main以外の場合のみ表示。AskUserQuestionで確認
- **状態判定**: ブランチ名、状態名、behind/ahead数、uncommitted変更の有無
- **変更内容**: 新規/変更/削除のファイル一覧と差分概要
- **危険ファイル警告**: 該当ファイルがある場合のみ表示
- **実行計画**: ステージ対象、コミットメッセージ、プッシュ先。AskUserQuestionで確認。分割コミット時は各コミットごとに繰り返す
- **rebase結果**: 状態Dのrebase成功時。ログ表示+AskUserQuestionで確認
- **コンフリクト報告**: 状態Dのコンフリクト発生時。AskUserQuestionで選択
- **ローカル適用確認**: chezmoi diffの結果を「今回の同期による差分」と「既存の乖離」に分類して報告。差分ありの場合AskUserQuestionで適用範囲（全適用/部分適用/スキップ）を確認
- **同期完了**: push時はコミットhash/ファイル数、pull時は取得コミット数/適用結果
- **他のPCへの適用**: push完了時のみ。`chezmoi update -v` を案内

### 状態別のフェーズ構成

- B1: 状態判定 → 変更内容 → （危険ファイル警告）→ 実行計画（確認）→ ローカル適用確認 → 同期完了 → 他PC案内
- B2: 状態判定 → 未pushコミット一覧 → ステップ3ゲート（確認）→ ローカル適用確認 → 同期完了 → 他PC案内
- C: 状態判定 → ステップ3ゲート（確認）→ 同期完了（pull用）
- D（変更あり）: 状態判定 → 変更内容 → 実行計画（確認）→ rebase結果（確認）→ （コンフリクト時: コンフリクト報告 → 確認）→ ローカル適用確認 → 同期完了 → 他PC案内
- D（変更なし）: 状態判定 → ステップ3ゲート（確認）→ rebase結果（確認）→ （コンフリクト時: コンフリクト報告 → 確認）→ ローカル適用確認 → 同期完了 → 他PC案内
- E: 状態判定のみ（「このPCは最新です。」）
- F: 状態判定 → （変更あり: 変更内容 → 実行計画（確認）→ コミット完了 + 手動push案内）or（変更なし: 終了）
