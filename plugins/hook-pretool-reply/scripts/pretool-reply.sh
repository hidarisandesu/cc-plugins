#!/bin/sh
# PreToolUse hook: 副作用系ツール（matcher で指定）の実行前に1行注入する。
# ツール間の文章は表示されない思考チャネルに落ちることがあり、モデル自身は落ちたか確認できない。
# そのため要求先は表示が保証されるターン末尾に置く。「質問への回答」を明示するのは、
# 末尾が作業報告だけになり回答が落ちた実害があったため。text ブロックは出力仕様上一意の語。
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"ツール実行の合間に書いた文章と、ユーザーの質問への回答は、ターン最後の text ブロックに省略せず書くこと。"}}
EOF
