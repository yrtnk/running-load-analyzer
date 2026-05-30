# データモデル設計

## モデル一覧と関係

```
┌─────────────────────┐
│        User         │
│─────────────────────│
│ id                  │
│ email               │
│ password_digest     │──────────────────────┐
│ strava_access_token │                      │
│ strava_refresh_token│                      │
│ strava_expires_at   │                      │
└─────────────────────┘                      │
          │ 1                                │ 1
          │                                  │
          │ 多                               │ 多
┌─────────────────────┐        ┌─────────────────────┐
│      Activity       │        │     TargetTime      │
│─────────────────────│        │─────────────────────│
│ id                  │        │ id                  │
│ user_id             │        │ user_id             │
│ strava_activity_id  │        │ target_marathon_time│
│ name                │        │ revised_at          │
│ distance            │        └─────────────────────┘
│ moving_time         │                  │
│ average_pace        │                  │ 参照（外部キーなし）
│ load_score  ◀───────┼──────────────────┘
│ activity_type       │   負荷計算時にその日時点の
│ start_date          │   TargetTime を使う
└─────────────────────┘
```

---

## それぞれの役割

| モデル | 役割 | 補足 |
|--------|------|------|
| **User** | ログインユーザー | Stravaのトークンもここに保存 |
| **Activity** | Stravaから取り込んだ1回のランニング | `load_score` がこのアプリの中心値 |
| **TargetTime** | ユーザーの目標マラソンタイム | ペースゾーンの計算に使う |
| **VdotChart** | VDOTとペースの対応表 | DBテーブルではなくRubyの定数として持つ |

---

## load_score が計算される仕組み

```
TargetTime（目標タイム）
    ↓
VdotChart（定数）でペースゾーンを算出
    ↓ 例: threshold = 5:20/km, easy = 6:30/km ...

Activity の average_pace（実際のペース）
    ↓
「このペースはどのゾーンに近いか」を線形補間で判定
    ↓
負荷係数（0.2〜1.5）× 時間 ÷ 基準値 × 100
    ↓
load_score として Activity に保存
```

### 負荷係数の定義

| カテゴリ | 係数 | 目安 |
|---------|------|------|
| easy | 0.2 | ジョグ・回復走 |
| marathon | 0.4 | マラソンペース |
| threshold | 0.8 | 閾値走（基準） |
| cv | 1.0 | クリティカルベロシティ |
| interval | 1.2 | インターバル |
| repetition | 1.5 | レペティション |

threshold ペースで 60 分走ったときの値を基準（100点）として、他のペース・時間を相対評価する。

---

## 画面と使うモデルの対応

```
/dashboard
  └─ STL/LTL グラフ（短期・長期負荷のトレンド）
  └─ 直近 Activity 一覧
        └─ User の全 Activity を集計

/activities
  └─ Activity 一覧テーブル
        └─ load_score の色分け表示（青:低 / 黄:中 / 赤:高）

/target_times
  └─ TargetTime の入力フォーム
        └─ ここを設定しないと load_score が計算できない
```

---

## STL / LTL とは

| 指標 | 計算方法 | 意味 |
|------|---------|------|
| **STL**（短期負荷） | 直近7日の load_score 移動平均 | 今の疲労度 |
| **LTL**（長期負荷） | 直近30日の load_score 移動平均 | 体の慣れ・フィットネス |
| **差分 STL - LTL** | STL ÷ LTL | 1.2 超で故障リスクゾーン |

LTL の ±20% を「安全な負荷ゾーン」として表示する。
