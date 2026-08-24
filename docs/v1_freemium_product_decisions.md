# Swipeat v1.0 Product Decision Register（Issue 02）

この文書は、実装指示書で「今回勝手に決定しない」とされた項目を管理するための決定台帳です。未決定の値をアプリコードへ埋め込まず、実装可能な範囲は安全な暫定方針で進めます。

## ステータス定義

- `pending`: プロダクトオーナーの決定待ち。実装では仮定しない。
- `provisional`: 決定までの暫定動作が文書化されている。後から変更可能な境界に閉じ込める。
- `decided`: 採用案が決定され、関連 Issue の受け入れ条件へ反映済み。

## 決定一覧

| ID | 項目 | Status | Owner | 決定期限 | 決定がない間の暫定方針 |
| --- | --- | --- | --- | --- | --- |
| PD-01 | 20候補を使い切った後の動作 | `pending` | プロダクトオーナー | Issue 10 開始前 | 既存の再検索導線は削除せず、CandidatePool の消費完了と分離する。新しい自動動作は追加しない。 |
| PD-02 | Free 候補不足時の自動距離拡大 | `provisional` | プロダクトオーナー | Issue 10 開始前 | 既存 Free の距離再検索を維持する。Premium のジャンル検索には自動拡大を適用しない。 |
| PD-03 | Premium v1.0 の追加絞り込み | `pending` | プロダクトオーナー | Issue 12 開始前 | Issue 13 のジャンル精度フィルタと広告非表示・20件連続だけを v1.0 の確定コアとして進める。評価・価格帯・チェーン制御等は実装しない。 |
| PD-04 | Google Play Premium の最終価格・商品設定 | `pending` | プロダクトオーナー / ストア担当 | Issue 17 の Play Console 作成前 | 価格を Dart の定数・UI文言へ固定しない。表示は Play の商品情報を供給源にする設計だけ先に作る。 |
| PD-05 | 日本国外での Premium 動作 | `pending` | プロダクトオーナー | 日本国外公開前 | 日本向け分類辞書を使い、国外の分類精度を保証しない。対象地域をストア設定で制御する。 |
| PD-06 | Android 本番 Application ID | `pending` | プロダクトオーナー / Android担当 | Issue 24 開始前 | 現行 ID は開発用として扱う。Release 署名・公開設定へ進む前に確定する。 |

## 決定フォーマット

各項目を決めるときは、次の形式でこのファイルを更新する。

```text
ID: PD-xx
決定日: YYYY-MM-DD
採用案: （1つ）
理由: （ユーザー体験・コスト・審査・技術制約）
影響する Issue: （番号）
```

## 暫定方針で進められる Issue

次の Issue は、PD-01〜PD-06 の最終決定を待たずに実装できる。

- Issue 03: 独自ジャンルモデル
- Issue 04: チェーン辞書
- Issue 05: Google primaryType マッパー
- Issue 06: RestaurantClassifier
- Issue 07: Places レスポンス対応
- Issue 08: CandidatePool
- Issue 09: PremiumEntitlement のドメインモデル
- Issue 11: 区切り画面のレイアウト（価格文言・最終導線を除く）

## 実装を止める決定

次の Issue を完了する前には、該当する決定を `decided` にする。

- Issue 10: PD-01、PD-02
- Issue 12: PD-03、PD-04（課金価格の表示導線を含める場合）
- Issue 14: PD-03
- Issue 17: PD-04
- Issue 24: PD-06
- Issue 25: PD-04、PD-05

## Issue 02 の完了条件

- 未確定項目が ID 付きで一覧化されている。
- 各項目に owner、期限、保留理由、暫定方針がある。
- 未確定値がコードへ埋め込まれないよう、後続 Issue の停止条件が明示されている。
- 後続の分類基盤を進められる項目と、決定待ちで止める項目が分離されている。
