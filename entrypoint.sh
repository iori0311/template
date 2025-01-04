#!/bin/sh

# 環境変数が未定義の場合はデフォルト値を設定
: "${HB_EXECUTABLE_NAME:=HummingbirdServer}"

# 実行可能ファイルを実行
exec "./${HB_EXECUTABLE_NAME}" "$@"
