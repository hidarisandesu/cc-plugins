#!/bin/sh
# UserPromptSubmit hook: ユーザー発話の直後に1行注入する。
# additionalContext は system reminder として届き、画面には表示されない。
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"ツール実行より先に、この発話への返答（回答、または受け止めと進め方）を本文で書くこと。"}}
EOF
