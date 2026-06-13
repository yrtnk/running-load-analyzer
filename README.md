# Running Load Analyzer

市民ランナー向けに、トレーニング負荷・疲労蓄積・故障リスクを可視化する Web アプリ。

「感覚でしか把握できなかった練習負荷」を独自スコアで定量化し、故障リスクをコントロールできるようにすることが中心価値です。

---

## 対象ユーザー

マラソン・ランニングに継続的に取り組む市民ランナー（目標タイムを持ち、計画的にトレーニングしている人）

---

## MVPスコープ

### Must Have（作る）

| 機能 | 説明 |
|------|------|
| Strava OAuth 連携 | Strava アカウントでログイン |
| Activity 取得・保存 | Strava のランニングデータを自動取り込み |
| 負荷スコア計算 | ペース × 時間 × カテゴリ係数で独自スコアを算出 |
| 目標タイム設定 | マラソン目標タイムを入力 → ペースゾーン自動生成 |
| ダッシュボード | STL/LTL グラフ・故障リスク表示 |
| Activity 一覧 | load_score 付きのランニングログ |
| Render デプロイ | 本番公開 |

### Not Included（作らない）

- SNS・フォロー・通知機能
- AIチャット・コミュニティ
- 管理画面
- 手動でのトレーニング登録（Strava 連携のみ）
- ラップ単位の詳細分析
- トレーニング計画・達成管理

---

## 負荷スコア（load_score）の仕組み

```
目標タイム（TargetTime）
  ↓
VDOT定数でペースゾーンを算出（easy / marathon / threshold / cv / interval / repetition）
  ↓
Activity の平均ペース（average_pace）がどのゾーンに近いかを線形補間で判定
  ↓
負荷係数（0.2〜1.5）× 走行時間 ÷ 基準値 × 100 = load_score
```

**threshold ペースで 60 分走ったとき = 100 点** を基準として、他のペース・時間を相対評価します。

| カテゴリ | 係数 |
|---------|------|
| easy | 0.2 |
| marathon | 0.4 |
| threshold | 0.8（基準） |
| cv | 1.0 |
| interval | 1.2 |
| repetition | 1.5 |

**STL**（短期負荷）= 直近7日の load_score 移動平均 → 今の疲労度  
**LTL**（長期負荷）= 直近30日の load_score 移動平均 → 体の慣れ  
**STL / LTL > 1.2** で故障リスクゾーンと判定します。

---

## 技術スタック

| 項目 | 内容 |
|------|------|
| 言語 | Ruby 3.2.6 |
| フレームワーク | Rails 7.2 |
| データベース | PostgreSQL |
| 認証 | Devise + OmniAuth（Strava OAuth2） |
| 外部 API | Strava API（strava-ruby-client） |
| テスト | RSpec / FactoryBot / Shoulda Matchers |
| デプロイ | Render |

---

## ローカル環境構築

### 前提条件

- Ruby 3.2.6
- PostgreSQL
- Strava API のクライアント ID・シークレット（[Strava Developers](https://developers.strava.com/) で取得）

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/yrtnk/running-load-analyzer.git
cd running-load-analyzer

# 依存 gem をインストール
bundle install

# 環境変数を設定（.env.example を参考に .env を作成）
cp .env.example .env
# STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET を記入

# データベースを作成・マイグレーション
bin/rails db:create db:migrate

# サーバー起動（ポート 3001）
bin/rails server -p 3001
```

ブラウザで `http://localhost:3001` にアクセスして確認してください。

### テスト実行

```bash
bundle exec rspec
```

---

## ディレクトリ構成（主要部分）

```
app/
├── controllers/
├── models/
│   ├── user.rb
│   ├── activity.rb
│   └── target_time.rb
├── services/
│   ├── strava/             # Strava API 連携
│   └── load_calculator.rb  # 負荷スコア計算
└── views/
docs/
├── mvp-scope.md            # MVPスコープ詳細
├── model-design.md         # データモデル設計
└── workflow.md             # 開発ワークフロー
```

---

## ライセンス

MIT
