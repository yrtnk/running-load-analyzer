# Running Load Analyzer

市民ランナー向けに、トレーニング負荷・疲労蓄積・故障リスクを可視化する Web アプリ。

「感覚でしか把握できなかった練習負荷」を独自スコアで定量化し、故障リスクをコントロールできるようにすることが中心価値です。

**デモ**: https://running-load-analyzer.onrender.com

---

## 対象ユーザー

マラソン・ランニングに継続的に取り組む市民ランナー（目標タイムを持ち、計画的にトレーニングしている人）

---

## 機能一覧

| 機能 | 説明 |
|------|------|
| Strava OAuth 連携 | Strava アカウントでログイン |
| Activity 取得・保存 | Strava のランニングデータを自動取り込み |
| 負荷スコア計算 | VDOT × 線形補間 × km 単位 Split で独自スコアを算出 |
| 目標タイム設定 | マラソン目標タイムを入力 → ペースゾーン自動生成 |
| ダッシュボード | STL/LTL グラフ・故障リスク表示 |
| Activity 一覧 | load_score 付きのランニングログ |

---

## 負荷スコア（load_score）の仕組み

### 概要

```
目標タイム（TargetTime）
  ↓
VDOT定数テーブルで各カテゴリのペースゾーンを算出（線形補間）
  ↓
Activity の各 Split（1km ごと）の実績ペースがどのゾーンか判定（線形補間）
  ↓
負荷係数（LOAD_HASH）× Split の走行時間 ÷ 基準値 × 100 = Split の load_score
  ↓
全 Split を合算 → Activity の load_score
```

**threshold ペースで 60 分走ったとき = 100 点** を基準とし、他のペース・時間を相対評価します。

### LOAD_HASH（負荷係数テーブル）

| カテゴリ | 係数 | 対応するトレーニング |
|---------|------|-----------------|
| easy | 0.2 | ジョグ・回復走 |
| marathon | 0.4 | マラソンペース走 |
| threshold | 0.8 | 閾値走（基準） |
| cv | 1.0 | クリティカルベロシティ走 |
| interval | 1.2 | インターバル走 |
| repetition | 1.5 | レペティション |

係数は Jack Daniels の Running Formula をベースに設定しています。

### ペースゾーン判定：2段階の線形補間

ランナーの目標タイムは 3:30 や 3:45 などキリのよい数字とは限りません。  
VDOT テーブルの整数値だけでなく、**目標タイムに対して連続的にペースゾーンを算出**するため、線形補間を2段階で使っています。

**Step 1: 目標タイム → 各カテゴリのターゲットペースを算出**

```ruby
# lib/vdot_table.rb に Jack Daniels の定数テーブルを保持
# TargetTime#target_pace が VDOT テーブルで線形補間してペースを返す
def target_pace(category)
  lower = VdotTable.find_lower(target_marathon_time)  # 下位 VDOT エントリ
  upper = VdotTable.find_upper(target_marathon_time)  # 上位 VDOT エントリ
  a = (upper[pace_key] - lower[pace_key]).to_f / (upper[:vdot] - lower[:vdot])
  b = upper[pace_key] - a * upper[:vdot]
  (a * target_vdot + b).round(2)  # 秒/km で返す
end
```

**Step 2: 実績ペース → 負荷係数を線形補間**

```ruby
# app/services/running_load/load_factor.rb
def factor_for_pace(pace, target_time)
  target_paces = target_paces_for(target_time)  # Step 1 の結果

  # ペースがゾーンの境界をまたぐ場合は係数を補間
  target_paces.each_cons(2) do |(current_cat, current_pace), (next_cat, next_pace)|
    if current_pace >= pace && pace > next_pace
      return interpolate(pace, current_pace, next_pace,
                         LOAD_HASH[current_cat], LOAD_HASH[next_cat])
    end
  end
end

def interpolate(pace, current_pace, next_pace, current_load, next_load)
  slope = (next_load - current_load) / (next_pace - current_pace).to_f
  current_load + slope * (pace - current_pace)
end
```

この2段階補間により、「km3分45秒で走ったときの負荷」が目標タイムに応じて動的に変わります。  
サブ3ランナーにとっての 3:45 は easy ですが、サブ4ランナーにとっては threshold に相当するという実態を反映しています。

### Split 単位での積み上げ計算

Activity の平均ペースだけでなく、**1km ごとの Split ペースから積み上げる**ことで精度を高めています。

```ruby
# app/models/activity_split.rb
def split_load(target_time)
  RunningLoad::LoadFactor.score(
    pace: pace,            # 1km Split の実績ペース（秒/km）
    duration: moving_time, # この Split の走行時間（秒）
    target_time: target_time
  ) || 0.0
end
```

例えば「前半ゆっくり・後半上げる」ネガティブスプリットのランは、平均ペースで計算するより高い load_score になります。

### STL / LTL と故障リスク

```
STL（短期負荷） = 直近7日の load_score 合計 ÷ 7
LTL（長期負荷） = 直近30日の load_score 合計 ÷ 30

STL / LTL > 1.2 → 故障リスクゾーン
```

STL が LTL の1.2倍を超えると、急激に負荷が増えている状態を示します。  
スポーツ科学では "Acute:Chronic Workload Ratio (ACWR)" として知られる指標で、故障リスクの予測に利用されています。

---

## アーキテクチャ

### クラス構成

```
app/
├── controllers/
│   ├── activities_controller.rb      # Activity 一覧・Strava 同期
│   ├── dashboard_controller.rb       # STL/LTL グラフデータ
│   ├── home_controller.rb            # トップページ
│   └── target_times_controller.rb    # 目標タイム設定
│
├── models/
│   ├── user.rb           # Strava OAuth トークン管理
│   ├── activity.rb       # load_score・load_category カラム保持
│   ├── activity_split.rb # 1km 単位の Split データ
│   └── target_time.rb    # 目標タイム → ペースゾーン変換
│
├── services/
│   ├── strava/
│   │   └── token_refresher.rb           # Strava トークンリフレッシュ
│   ├── strava_activity_sync_service.rb  # Strava API → Activity/Split 保存
│   └── running_load/
│       ├── calculator.rb        # Activity 単位の load_score 計算
│       ├── load_factor.rb       # LOAD_HASH・線形補間（副作用なし）
│       └── weekly_aggregator.rb # 週次グラフ・STL/LTL 集計
│
lib/
└── vdot_table.rb  # Jack Daniels の VDOT 定数テーブル
```

### Service Object の責務分担

| クラス | 責務 |
|--------|------|
| `RunningLoad::LoadFactor` | VDOT・線形補間の純粋ロジック（副作用なし） |
| `RunningLoad::Calculator` | 1つの Activity の load_score を算出 |
| `RunningLoad::WeeklyAggregator` | 週次グラフ・STL/LTL の集計（DB クエリ） |
| `StravaActivitySyncService` | Strava API 取得・Activity/Split 保存・load_score 計算 |

`LoadFactor` は Activity 単位・Split 単位の双方から呼ばれるため、副作用のない純粋なロジックとして分離しています。

### データモデル

```
User
 ├── has_many :activities
 │    └── has_many :activity_splits  ← 1km 単位の Split
 └── has_many :target_times          ← 目標タイム履歴
```

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
- Strava API のクライアント ID・シークレット（取得方法は下記）

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/yrtnk/running-load-analyzer.git
cd running-load-analyzer

# 依存 gem をインストール
bundle install

# 環境変数を設定
cp .env.example .env
# .env を編集して STRAVA_CLIENT_ID と STRAVA_CLIENT_SECRET を記入

# データベース作成・マイグレーション・起動まで一括セットアップ
bin/setup

# サーバー起動（ポート 3001）
bin/rails server -p 3001
```

ブラウザで `http://localhost:3001` にアクセスして確認してください。

### 環境変数一覧

| 変数名 | 説明 | 必須 |
|--------|------|------|
| `STRAVA_CLIENT_ID` | Strava API のクライアント ID | ✅ |
| `STRAVA_CLIENT_SECRET` | Strava API のクライアントシークレット | ✅ |
| `SECRET_KEY_BASE` | Devise の秘密鍵（本番環境のみ） | 本番のみ |
| `DATABASE_URL` | DB 接続 URL（本番環境のみ） | 本番のみ |

### テスト実行

```bash
bundle exec rspec
```

---

## Strava API 設定手順

1. [Strava Developers](https://developers.strava.com/) にアクセス → 「Create & Manage Your App」
2. アプリを作成
   - **Application Name**: 任意（例: `Running Load Analyzer`）
   - **Category**: `Training`
   - **Authorization Callback Domain**: ローカルは `localhost`、本番は Render のドメイン
3. 作成後に表示される **Client ID** と **Client Secret** を `.env` に記入
4. 本番環境の場合は Render の環境変数にも同様に設定

> **注意**: Callback Domain はローカルと本番で別々に設定が必要です。  
> ローカル開発時は `localhost`、Render デプロイ後は Strava アプリ設定の Callback Domain を本番ドメインに変更してください。

---

## ライセンス

MIT
