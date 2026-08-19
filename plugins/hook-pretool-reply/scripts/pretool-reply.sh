#!/bin/sh
# PreToolUse hook: 副作用系ツール（matcher で指定）の実行前に1行注入する。
# ツール間に書いた本文は表示されない思考チャネルに落ちる現象があるため、
# 「ツールの前に書け」ではなく、表示が保証されるターン末尾への再掲を要求する。
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"ツール間に書いた本文はユーザーに表示されないことがある。重要な発見・判断・結論は、ターン末尾のメッセージに必ずまとめて書くこと。"}}
EOF
