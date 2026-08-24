import '../models/restaurant.dart';

/// 候補の表示モード。
enum CandidatePoolMode { free, premium }

/// 1回の検索で取得した候補を保持し、表示単位を管理する。
///
/// Places API はこのクラスの外で一度だけ呼び出す。Free の「次の5件」は
/// 既に保持しているリストをページングするだけで、再検索を発生させない。
class CandidatePool {
  CandidatePool({required List<Restaurant> restaurants, required this.mode})
    : _restaurants = _deduplicateAndLimit(restaurants);

  static const int maxCandidates = 20;
  static const int freePageSize = 5;

  final CandidatePoolMode mode;
  final List<Restaurant> _restaurants;

  int _batchStart = 0;
  int _cursor = 0;

  /// 重複除去・上限適用後の取得済み候補。外部から変更できない。
  List<Restaurant> get restaurants =>
      List<Restaurant>.unmodifiable(_restaurants);

  int get length => _restaurants.length;
  int get displayedCount => _cursor;
  int get remainingCount => length - _cursor;
  int get currentBatchStart => _batchStart;

  /// Premium は全候補、Free は現在の5件区切り。
  List<Restaurant> get currentBatch {
    final end = _currentBatchEnd;
    return List<Restaurant>.unmodifiable(
      _restaurants.sublist(_batchStart, end),
    );
  }

  int get currentBatchLength => _currentBatchEnd - _batchStart;

  /// 現在表示すべき店舗。候補終了後は null。
  Restaurant? get currentRestaurant {
    if (_cursor >= length || _cursor >= _currentBatchEnd) return null;
    return _restaurants[_cursor];
  }

  /// 現在の区切りをすべて表示し終えたか。
  bool get isCurrentBatchFinished {
    return _cursor >= _currentBatchEnd;
  }

  bool get isExhausted => _cursor >= length;

  /// Free に次の区切りが残っているか。Premium は常に連続表示する。
  bool get hasNextBatch {
    return mode == CandidatePoolMode.free && _currentBatchEnd < length;
  }

  /// 現在の店舗をスキップして次へ進む。
  void skipCurrent() {
    if (isCurrentBatchFinished) return;
    _cursor += 1;
  }

  /// 現在の5件区切りを最初から見直す。
  void restartCurrentBatch() {
    _cursor = _batchStart;
  }

  /// Free の次の区切りへ進む。候補終了中や Premium では何もしない。
  bool advanceToNextBatch() {
    if (!hasNextBatch || !isCurrentBatchFinished) return false;

    _batchStart = _currentBatchEnd;
    _cursor = _batchStart;
    return true;
  }

  /// 検索セッションの先頭へ戻す。
  void reset() {
    _batchStart = 0;
    _cursor = 0;
  }

  int get _currentBatchEnd {
    if (mode == CandidatePoolMode.premium) return length;

    final end = _batchStart + freePageSize;
    return end > length ? length : end;
  }

  static List<Restaurant> _deduplicateAndLimit(List<Restaurant> restaurants) {
    final seenPlaceIds = <String>{};
    final unique = <Restaurant>[];

    for (final restaurant in restaurants) {
      final placeId = restaurant.googlePlaceId;
      if (placeId != null && !seenPlaceIds.add(placeId)) continue;

      unique.add(restaurant);
      if (unique.length == maxCandidates) break;
    }

    return List<Restaurant>.unmodifiable(unique);
  }
}
