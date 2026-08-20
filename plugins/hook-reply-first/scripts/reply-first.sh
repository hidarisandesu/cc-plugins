#!/bin/sh
# UserPromptSubmit hook: ユーザー発話の直後に1行注入する。
# additionalContext は system reminder として届き、画面には表示されない。
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"ツール実行より先に、この発話が質問なら回答を、依頼なら進め方を、text ブロックで書くこと。"}}
EOF
