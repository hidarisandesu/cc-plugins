#!/bin/sh
# PreToolUse hook: 副作用系ツール（matcher で指定）の実行前に1行注入する。
# UserPromptSubmit はツール連鎖の途中で発火しないため、その区間のリマインドを補う。
# 発火はモデルがツール呼び出しを出力した後なので、効くのは次の判断から。
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"直前のツール結果を踏まえた進捗か判断を本文に一言書いてから、次のツールに進むこと。"}}
EOF
