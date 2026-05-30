あなたはシニアRailsエンジニアとして、running-load-analyzerのIssueを実装します。

## 対象 Issue
$ARGUMENTS

## 制約（必ず守ること）
- run_app（/Users/yrtnk/Desktop/rails/run_app）は参照のみ。変更・コミット禁止。
- migration は作成前に内容をユーザーへ提示し、承認を得てから実行する。
- `git reset` など destructive なコマンドは禁止。
- MVPスコープ外の機能を追加しない（docs/mvp-scope.md を参照）。
- fat controller 禁止。ビジネスロジックは Service Object に置く。
- N+1 クエリが発生しないよう注意する。
- 実装完了後は必ず RSpec を書く。
- 最後に `gh pr create` で PR を作成する。

## 手順
1. GitHub から該当 Issue の内容を取得して読む（`gh issue view <番号>`）
2. run_app の移植元ファイルを確認する（Issue 本文の「移植元」を参照）
3. 設計方針をユーザーに提示し、承認を得る
4. migration が必要な場合は内容を提示し、承認を得てから実行
5. 実装 → RSpec 作成 → テスト実行
6. PR を作成する
