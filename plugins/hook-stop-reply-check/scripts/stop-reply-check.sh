#!/bin/sh
# Stop hook: ターン最終応答に表示される本文（text）があったかをログに記録する。観測のみで介入しない。
# 判定は入力 JSON の last_assistant_message を使う。公式仕様上、これが最終応答の text 内容であり、
# transcript ファイルは Stop 時点で最終メッセージを含む保証がないため読まない。
in=$(cat)
sid=$(printf '%s' "$in" | sed -n 's/.*"session_id":"\([^"]*\)".*/\1/p')
if printf '%s' "$in" | grep -q '"last_assistant_message":"[^"]'; then
  result=ok
else
  result=missing
fi
printf '%s %s session=%s\n' "$(date -Is)" "$result" "$sid" >> "$HOME/.claude/hook-stop-reply-check.log"
exit 0
