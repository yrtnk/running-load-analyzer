# 開発ワークフロー

## 毎日のリズム（1〜2時間/日）

| タイミング | 時間 | やること |
|-----------|------|---------|
| 朝 | 10分 | 前日の PR をマージ or コメント → 次の Issue 確認 |
| 昼 or 夜 | 1時間 | Claude Code を起動して Issue を渡す |
| 夜 | 20〜30分 | PR の差分確認 → マージ → 次 Issue に `ready-for-claude` を付ける |

---

## ラベルの意味

| ラベル | 意味 | あなたのアクション |
|--------|------|-----------------|
| `ready-for-claude` | Claude が今すぐ実装できる状態 | Claude Code を起動して Issue 番号を渡す |
| `in-progress-by-claude` | Claude が実装中 | 触らない |
| `needs-review` | PR 作成済み | レビューしてマージ |

---

## Claude Code への指示テンプレート

毎回このテンプレートをコピーして使う：

```
あなたはシニアRailsエンジニアとして、running-load-analyzerのIssueを実装します。

制約:
- run_app（/Users/yrtnk/Desktop/rails/run_app）は参照のみ。変更禁止。
- migration は作成前に内容をユーザーへ提示し、承認を得てから実行。
- git reset など destructive コマンド禁止。
- MVPスコープ外の機能を追加しない。
- fat controller 禁止（ロジックは Service Object へ）。
- 実装完了後は必ず RSpec を書き、gh pr create でPRを作成する。

今回の対象: Issue #__
```

---

## PR レビューでチェックすること

コードの細部より以下を確認する：

- [ ] Issue に書いてあった機能が実装されているか
- [ ] 余計な機能が追加されていないか（MVPスコープ外）
- [ ] テスト（RSpec）が含まれているか

問題なければ「Merge pull request」を押すだけでOK。

---

## 週次チェックリスト（金曜夜・5分）

- [ ] 今週マージした Issue 数：__
- [ ] 来週の `ready-for-claude` 対象 Issue：__
- [ ] ブロッカー（依存関係が未解消のもの）：__
- [ ] Milestone 進捗：Week__ が __%

---

## 今すぐ着手できる Issue（ready-for-claude）

- [#5 Strava OAuth 連携](https://github.com/yrtnk/running-load-analyzer/issues/5)
- [#7 TargetTime 設定](https://github.com/yrtnk/running-load-analyzer/issues/7)

※ #5 と #7 は互いに依存していないので Cowork で同時実装も可能
