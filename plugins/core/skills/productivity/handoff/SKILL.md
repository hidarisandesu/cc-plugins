---
name: handoff
description: 現在の会話を、次のセッションへの引き継ぎ資料に圧縮する。
argument-hint: "次のセッションは何に使う？"
disable-model-invocation: true
---

現在の会話を要約した引き継ぎ資料を書く。新しいセッションでそのまま作業を再開できるだけの情報を残す。保存先は作業中プロジェクトの `.handoff/HANDOFF.md`。

既存の `HANDOFF.md` があれば、上書きする前に退避する。frontmatter の `updated` の値を使って `.handoff/YYYY-MM-DD-HHMM.md` にリネームする。

他の成果物（仕様・計画・ADR・issue・コミット・差分）に既にある内容は繰り返さない。パスやURLで参照する。

APIキー・パスワード・個人情報などの機密情報は記載しない。

引数が渡された場合は、それを次セッションの焦点の説明とみなし、資料の内容をその焦点に合わせる。
