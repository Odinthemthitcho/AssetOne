import 'package:flutter/foundation.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/asset_summary.dart';
import '../../domain/usecases/get_assets.dart';

/// Presentation state. Dependencies are supplied from the app composition root.
final class AssetsController extends ChangeNotifier {
  AssetsController(this._getAssets);

  final GetAssets _getAssets;
  bool _isLoading = false;
  bool _isDisposed = false;
  int _requestId = 0;
  List<AssetSummary> _items = const [];
  AppFailure? _failure;

  bool get isLoading => _isLoading;
  List<AssetSummary> get items => _items;
  AppFailure? get failure => _failure;

  Future<void> load() async {
    if (_isDisposed) return;
    final requestId = ++_requestId;
    _isLoading = true;
    _failure = null;
    notifyListeners();

    Result<List<AssetSummary>> result;
    try {
      result = await _getAssets();
    } on Exception {
      result = const Failure(
        AppFailure(
          'Không thể tải tài sản. Vui lòng thử lại.',
          code: 'unexpected',
        ),
      );
    }

    // Ignore stale requests and completions after the owning page is removed.
    if (_isDisposed || requestId != _requestId) return;
    switch (result) {
      case Success<List<AssetSummary>>(:final value):
        _items = List.unmodifiable(value);
        _failure = null;
      case Failure<List<AssetSummary>>(:final failure):
        _items = const [];
        _failure = failure;
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestId++;
    super.dispose();
  }
}
