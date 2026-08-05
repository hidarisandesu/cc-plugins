# cc-plugins

hidarisandesu の個人用 Claude Code プラグイン集（マーケットプレイス）。Agent Skills・hook・output style を収録している。

- **skills-core** — 常時使うコアスキル
- **hook-reply-first** — ツール実行より先に返答を本文で書かせる UserPromptSubmit hook
- **style-structured** — Structured output style（有効化するだけで自動適用される）

各プラグインの中身は、`plugins/*/skills/*/SKILL.md` の frontmatter、または Claude Code の `/plugin`（Discover タブ）で確認する。この README には個別スキルの説明を書かない（増減のたびに陳腐化するため、一覧は一次情報に任せる）。

## インストール

Claude Code のセッション内から：

```
/plugin marketplace add hidarisandesu/cc-plugins
/plugin install <プラグイン名>@cc-plugins
```

例: `/plugin install skills-core@cc-plugins`

シェルからは `claude plugin marketplace add` / `claude plugin install` で同じ形。
`claude plugin install` は既定で user scope（`~/.claude`）に入る。プロジェクト単位・ローカル限定にするなら `--scope project` / `--scope local` を付ける。

## 更新

```
/plugin marketplace update cc-plugins
/plugin update <プラグイン名>@cc-plugins
```

## 参考

core のスキルには以下を翻訳・改変したものが含まれる（いずれも MIT License）。

- [mattpocock/skills](https://github.com/mattpocock/skills) — Copyright (c) 2026 Matt Pocock
- [mathbullet/skills](https://github.com/mathbullet/skills) — Copyright (c) 2026 mathbullet
