import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage.dart';
import '../../../core/value_objects/date_only.dart';
import '../domain/portfolio_models.dart';

part 'portfolio_state.dart';
part 'portfolio_demo.dart';

/// On-device ledger. A mutation publishes only after one durable profile write.
final class PortfolioStore extends ChangeNotifier {
  PortfolioStore(this._storage);

  final LocalStorage _storage;
  _PortfolioState _state = _PortfolioState();
  Future<void> _tail = Future.value();
  String? _profileId;
  int _epoch = 0;
  int _pending = 0;
  bool _disposed = false;

  List<Position> get positions => List.unmodifiable(_state.positions);
  List<CashAccount> get accounts => _state.accountsWithBalances();
  List<LedgerEntry> get activity => _state.recentActivity();
  PortfolioTotals get totals => _state.totals();
  List<PortfolioSnapshot> get history => List.unmodifiable(_state.history);
  List<PortfolioReminder> get reminders => _state.reminders();
  bool get balanceHidden => _state.balanceHidden;
  bool get busy => _pending > 0;
  bool get isDemo => _state.isDemo;

  Position? position(String id) =>
      _state.positions.where((position) => position.id == id).firstOrNull;

  Future<void> open(String profileId, {bool seedDemo = false}) {
    final normalized = profileId.trim();
    if (normalized.isEmpty || _disposed) {
      return Future.error(const PortfolioException('Hồ sơ không hợp lệ.'));
    }
    final epoch = ++_epoch;
    _profileId = null;
    _state = _PortfolioState();
    _pending = 0;
    return _schedule(epoch, () async {
      if (_epoch != epoch) return;
      final key = _storageKey(normalized);
      final stored = await _storage.read(key);
      final next = stored == null
          ? (seedDemo ? _demoPortfolio() : _PortfolioState())
          : _PortfolioState.fromJson(
              jsonDecode(stored) as Map<String, dynamic>,
            );
      if (stored == null && seedDemo) await _storage.write(key, next.encode());
      if (_epoch != epoch) return;
      _profileId = normalized;
      _state = next;
    });
  }

  void close() {
    _epoch++;
    _profileId = null;
    _state = _PortfolioState();
    _pending = 0;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    close();
    super.dispose();
  }

  Future<void> createAccount({
    required String name,
    String institution = '',
    String type = 'Tiền mặt',
    int openingBalance = 0,
    bool primary = false,
    DateTime? date,
  }) => _change((state) {
    final accountName = _requiredText(name, 'Tên tài khoản');
    final accountType = _requiredText(type, 'Loại tài khoản');
    _money(openingBalance, 'Số dư đầu kỳ');
    final id = state.nextId('account');
    final makePrimary = primary || state.accounts.isEmpty;
    if (makePrimary) state.makePrimary(id);
    state.accounts.add(
      CashAccount(
        id: id,
        name: accountName,
        institution: institution.trim(),
        type: accountType,
        primary: makePrimary,
      ),
    );
    if (openingBalance > 0) {
      state.append(
        EntryKind.openingCash,
        'Số dư đầu kỳ · $accountName',
        openingBalance,
        _recordedDate(date),
        cashDelta: openingBalance,
        accountId: id,
      );
    }
  });

  Future<void> setPrimary(String accountId) => _change((state) {
    state.requireAccount(accountId);
    state.makePrimary(accountId);
  });

  Future<void> setBalanceHidden(bool value) =>
      _change((state) => state.balanceHidden = value);

  Future<void> addCash({
    required String accountId,
    required int amount,
    required bool deposit,
    DateTime? date,
    String note = '',
  }) => _change((state) {
    _money(amount, 'Số tiền', positive: true);
    final account = state.requireAccount(accountId);
    if (!deposit) state.requireFunds(accountId, amount);
    final kind = deposit ? EntryKind.deposit : EntryKind.withdrawal;
    state.append(
      kind,
      '${kind.label} · ${account.name}',
      amount,
      _recordedDate(date),
      cashDelta: deposit ? amount : -amount,
      accountId: accountId,
      note: note.trim(),
    );
  });

  Future<void> transfer({
    required String fromId,
    required String toId,
    required int amount,
    DateTime? date,
    String note = '',
  }) => _change((state) {
    _money(amount, 'Số tiền chuyển', positive: true);
    if (fromId == toId) {
      throw const PortfolioException('Hãy chọn hai tài khoản khác nhau.');
    }
    final from = state.requireAccount(fromId);
    final to = state.requireAccount(toId);
    state.requireFunds(fromId, amount);
    state.append(
      EntryKind.transfer,
      '${from.name} → ${to.name}',
      amount,
      _recordedDate(date),
      accountId: fromId,
      targetAccountId: toId,
      note: note.trim(),
    );
  });

  Future<void> createPosition({
    required AssetKind kind,
    required String name,
    String symbol = '',
    String quantity = '1',
    required int cost,
    required int marketValue,
    String? accountId,
    DateTime? date,
    Map<String, String> details = const {},
    bool debitAccount = false,
    String operationLabel = '',
    PositionFinancing? financing,
  }) {
    final copy = Map<String, String>.of(details);
    return _change((state) {
      final positionName = _requiredText(name, 'Tên hồ sơ');
      _money(cost, kind == AssetKind.debt ? 'Gốc ban đầu' : 'Giá vốn');
      _money(marketValue, kind == AssetKind.debt ? 'Dư nợ gốc' : 'Định giá');
      final ownership = kind == AssetKind.realEstate
          ? copy['ownershipPercent']
          : null;
      final ownedCost = ownership == null
          ? cost
          : PortfolioAmounts.ownedShare(cost, ownership);
      final ownedValue = ownership == null
          ? marketValue
          : PortfolioAmounts.ownedShare(marketValue, ownership);
      if (ownership != null) {
        copy['fullCost'] = cost.toString();
        copy['fullMarketValue'] = marketValue.toString();
      }
      if (kind == AssetKind.debt && marketValue > cost) {
        throw const PortfolioException('Dư nợ gốc vượt gốc ban đầu.');
      }
      if (accountId != null) state.requireAccount(accountId);
      if (debitAccount) {
        if (accountId == null || kind == AssetKind.debt || financing != null) {
          throw const PortfolioException(
            'Hãy chọn tài khoản thanh toán hợp lệ.',
          );
        }
        state.requireFunds(accountId, ownedCost);
      }
      _validateDueDate(copy);
      final acquired = _recordedDate(date);
      final amount = kind.isQuantityBased
          ? _positiveDecimal(quantity, 'Số lượng')
          : null;
      final id = state.nextId('position');
      state.positions.add(
        Position(
          id: id,
          kind: kind,
          name: positionName,
          symbol: symbol.trim().toUpperCase(),
          quantity: amount?.toString() ?? '1',
          cost: ownedCost,
          marketValue: ownedValue,
          accountId: accountId,
          acquiredAt: acquired,
          updatedAt: acquired,
          details: copy,
        ),
      );
      final operation = operationLabel.trim();
      state.append(
        debitAccount ? EntryKind.purchase : EntryKind.acquisition,
        operation.isEmpty ? positionName : '$operation · $positionName',
        kind == AssetKind.debt ? ownedValue : ownedCost,
        acquired,
        positionId: id,
        accountId: accountId,
        cashDelta: debitAccount ? -ownedCost : 0,
        quantity: amount?.toString(),
        note: copy['note'] ?? '',
      );
      if (financing != null) {
        _addFinancing(state, kind, id, positionName, acquired, financing);
      }
    });
  }

  Future<void> trade({
    required String positionId,
    required bool buy,
    required String quantity,
    required String unitPrice,
    int fee = 0,
    String? accountId,
    DateTime? date,
    String note = '',
  }) => _change((state) {
    final current = state.requirePosition(positionId);
    if (!current.kind.isQuantityBased) {
      throw const PortfolioException(
        'Loại hồ sơ này không giao dịch theo số lượng.',
      );
    }
    if (accountId != null) state.requireAccount(accountId);
    final timestamp = _positionDate(current, date);
    _money(fee, 'Phí');
    final units = _positiveDecimal(quantity, 'Số lượng');
    final price = _positiveDecimal(unitPrice, 'Đơn giá');
    final holding = PortfolioDecimal.parse(current.quantity);
    if (!buy && units.compareTo(holding) > 0) {
      throw const PortfolioException('Số lượng bán vượt số lượng đang sở hữu.');
    }
    final gross = units.times(price);
    if (gross == 0) {
      throw const PortfolioException('Giá trị giao dịch phải ít nhất 1 ₫.');
    }
    if (!buy && fee > gross) {
      throw const PortfolioException('Phí vượt tiền bán.');
    }
    final cashAmount = buy ? gross + fee : gross - fee;
    _money(cashAmount, 'Giá trị giao dịch');
    if (buy && accountId != null) state.requireFunds(accountId, cashAmount);
    final nextQuantity = buy ? holding + units : holding - units;
    final quantityText = nextQuantity.toString();
    if (PortfolioAmounts.parseDecimal(quantityText) == null) {
      throw const PortfolioException('Số lượng sở hữu vượt giới hạn ghi nhận.');
    }
    final soldCost = buy ? 0 : units.portionOf(current.cost, holding);
    final newCost = buy ? current.cost + cashAmount : current.cost - soldCost;
    _money(newCost, 'Giá vốn');
    state.replacePosition(
      current.withAmounts(
        quantity: quantityText,
        cost: newCost,
        marketValue: nextQuantity.times(price),
        updatedAt: timestamp,
      ),
    );
    final entry = buy ? EntryKind.purchase : EntryKind.sale;
    state.append(
      entry,
      '${entry.label} · ${current.name}',
      cashAmount,
      timestamp,
      positionId: positionId,
      accountId: accountId,
      cashDelta: accountId == null ? 0 : (buy ? -cashAmount : cashAmount),
      note: note.trim(),
      quantity: units.toString(),
      unitPrice: price.toString(),
      fee: fee,
      realizedProfit: buy ? null : cashAmount - soldCost,
    );
  });

  Future<void> revalue({
    required String positionId,
    required int marketValue,
    DateTime? date,
  }) => _change((state) {
    final current = state.requirePosition(positionId);
    if (current.kind == AssetKind.debt || current.closed) {
      throw const PortfolioException('Hồ sơ này không thể cập nhật định giá.');
    }
    final timestamp = _positionDate(current, date);
    _money(marketValue, 'Định giá');
    final details = Map.of(current.details)..remove('fullMarketValue');
    state.replacePosition(
      current.withAmounts(
        marketValue: marketValue,
        updatedAt: timestamp,
        details: details,
      ),
    );
    state.append(
      EntryKind.valuation,
      'Định giá · ${current.name}',
      marketValue,
      timestamp,
      positionId: positionId,
    );
  });

  Future<void> redeemDeposit({
    required String positionId,
    int interest = 0,
    String? accountId,
    DateTime? date,
    String note = '',
  }) => _change((state) {
    final current = state.requirePosition(positionId);
    if (current.kind != AssetKind.deposit || current.closed) {
      throw const PortfolioException('Sổ tiền gửi này không còn hiệu lực.');
    }
    if (accountId != null) state.requireAccount(accountId);
    final timestamp = _positionDate(current, date);
    _money(interest, 'Tiền lãi thực nhận');
    final principal = current.cost;
    final proceeds = principal + interest;
    _money(proceeds, 'Tiền tất toán', positive: true);
    state.replacePosition(
      current.withAmounts(
        quantity: '0',
        cost: 0,
        marketValue: 0,
        updatedAt: timestamp,
      ),
    );
    state.append(
      EntryKind.redemption,
      'Tất toán · ${current.name}',
      proceeds,
      timestamp,
      positionId: positionId,
      accountId: accountId,
      cashDelta: accountId == null ? 0 : proceeds,
      principal: principal,
      interest: interest,
      realizedProfit: interest,
      note: note.trim(),
    );
  });

  Future<void> updatePositionMetadata({
    required String positionId,
    String? name,
    Map<String, String> details = const {},
  }) {
    final changes = Map<String, String>.of(details);
    return _change((state) {
      final current = state.requirePosition(positionId);
      final updated = Map<String, String>.of(current.details);
      for (final key in ['note', 'dueDate', 'attachmentReference']) {
        final value = changes[key]?.trim();
        if (value == null) continue;
        if (key == 'attachmentReference' && value != updated[key]) {
          updated.remove('attachmentUri');
        }
        if (value.isEmpty) {
          updated.remove(key);
        } else {
          updated[key] = value;
        }
      }
      _validateDueDate(updated);
      state.replacePosition(
        current.withMetadata(
          name: name == null ? current.name : _requiredText(name, 'Tên hồ sơ'),
          details: updated,
        ),
      );
    });
  }

  Future<void> payDebt({
    required String positionId,
    required int principal,
    int interest = 0,
    int fee = 0,
    String? accountId,
    DateTime? date,
    String note = '',
  }) => _change((state) {
    final current = state.requirePosition(positionId);
    if (current.kind != AssetKind.debt || current.closed) {
      throw const PortfolioException('Khoản nợ này không còn dư nợ gốc.');
    }
    final timestamp = _positionDate(current, date);
    _money(principal, 'Tiền gốc');
    _money(interest, 'Tiền lãi');
    _money(fee, 'Phí');
    final amount = principal + interest + fee;
    _money(amount, 'Tiền thanh toán', positive: true);
    if (principal > current.marketValue) {
      throw const PortfolioException('Tiền gốc trả vượt dư nợ gốc.');
    }
    if (accountId != null) {
      state.requireAccount(accountId);
      state.requireFunds(accountId, amount);
    }
    state.replacePosition(
      current.withAmounts(
        marketValue: current.marketValue - principal,
        updatedAt: timestamp,
      ),
    );
    state.append(
      EntryKind.debtPayment,
      'Trả nợ · ${current.name}',
      amount,
      timestamp,
      positionId: positionId,
      accountId: accountId,
      cashDelta: accountId == null ? 0 : -amount,
      principal: principal,
      interest: interest,
      fee: fee,
      note: note.trim(),
    );
  });

  Future<void> deletePosition({required String positionId}) => _change((state) {
    final current = state.requirePosition(positionId);
    final hasCash = state.entries.any(
      (entry) => entry.positionId == positionId && entry.cashDelta != 0,
    );
    final hasFinancing = state.positions.any(
      (position) => position.details['assetId'] == positionId,
    );
    if (hasCash || hasFinancing) {
      throw const PortfolioException(
        'Hồ sơ đang liên kết với biến động tài khoản hoặc khoản vay.',
      );
    }
    state.positions.remove(current);
    state.dismissedReminders.removeWhere((id) => id.startsWith('$positionId:'));
    state.append(
      EntryKind.removal,
      'Xóa hồ sơ · ${current.name}',
      current.marketValue,
      DateTime.now(),
      positionId: positionId,
    );
  });

  Future<void> dismissReminder(String reminderId) => _change((state) {
    if (state.reminders().any((item) => item.id == reminderId)) {
      state.dismissedReminders.add(reminderId);
    }
  });

  Future<void> _change(void Function(_PortfolioState) update) {
    final epoch = _epoch;
    final profile = _profileId;
    if (profile == null || _disposed) {
      return Future.error(
        const PortfolioException('Hãy mở hồ sơ trước khi lưu.'),
      );
    }
    return _schedule(epoch, () async {
      if (_epoch != epoch) {
        throw const PortfolioException(
          'Hồ sơ đã đổi. Vui lòng thực hiện lại thao tác.',
        );
      }
      final next = _state.copy();
      try {
        update(next);
        next.recordSnapshot(
          verifyCashHistory: next.entries.length != _state.entries.length,
        );
      } on FormatException catch (error) {
        throw PortfolioException(error.message);
      }
      await _storage.write(_storageKey(profile), next.encode());
      if (_epoch == epoch) _state = next;
    });
  }

  Future<void> _schedule(int epoch, Future<void> Function() action) {
    _pending++;
    final scheduled = _tail.then((_) => action()).whenComplete(() {
      if (_epoch != epoch || _disposed) return;
      _pending--;
      notifyListeners();
    });
    _tail = scheduled.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    notifyListeners();
    return scheduled;
  }

  static String _storageKey(String profileId) =>
      'portfolio-v1-${base64Url.encode(utf8.encode(profileId)).replaceAll('=', '')}';

  static DateTime _recordedDate(DateTime? value) {
    final now = DateTime.now();
    final effective = value ?? now;
    if (_day(effective).isAfter(_day(now))) {
      throw const PortfolioException(
        'Ngày ghi nhận phải là hôm nay hoặc trước đó.',
      );
    }
    return effective;
  }

  static DateTime _positionDate(Position position, DateTime? value) {
    final date = _recordedDate(value);
    if (_day(date).isBefore(_day(position.updatedAt))) {
      throw const PortfolioException(
        'Ngày ghi nhận sớm hơn lần cập nhật hồ sơ gần nhất.',
      );
    }
    return date;
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static void _money(int value, String label, {bool positive = false}) {
    if (value < (positive ? 1 : 0) || value > PortfolioAmounts.maxVnd) {
      throw PortfolioException('$label chưa hợp lệ.');
    }
  }

  static String _requiredText(String value, String label) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) throw PortfolioException('Vui lòng nhập $label.');
    return trimmed;
  }

  static PortfolioDecimal _positiveDecimal(String value, String label) {
    final canonical = PortfolioAmounts.parseDecimal(value);
    if (canonical == null) throw PortfolioException('$label chưa hợp lệ.');
    final decimal = PortfolioDecimal.parse(canonical);
    if (!decimal.isPositive) throw PortfolioException('$label phải lớn hơn 0.');
    return decimal;
  }

  static void _validateDueDate(Map<String, String> details) {
    final value = details['dueDate'];
    if (value != null && value.isNotEmpty && DateOnly.tryParse(value) == null) {
      throw const PortfolioException('Ngày đến hạn chưa hợp lệ.');
    }
  }

  static void _addFinancing(
    _PortfolioState state,
    AssetKind kind,
    String assetId,
    String assetName,
    DateTime date,
    PositionFinancing financing,
  ) {
    if (kind != AssetKind.realEstate && kind != AssetKind.vehicle) {
      throw const PortfolioException(
        'Loại tài sản này không hỗ trợ khoản vay liên kết.',
      );
    }
    final lender = _requiredText(financing.lender, 'Bên cho vay');
    final original = financing.originalPrincipal;
    final outstanding = financing.outstandingPrincipal;
    _money(original, 'Gốc vay ban đầu', positive: true);
    _money(outstanding, 'Dư nợ gốc');
    if (outstanding > original) {
      throw const PortfolioException('Dư nợ gốc vượt gốc vay ban đầu.');
    }
    _validateDueDate(financing.details);
    final id = state.nextId('position');
    final name = 'Khoản vay · $assetName';
    state.positions.add(
      Position(
        id: id,
        kind: AssetKind.debt,
        name: name,
        symbol: '',
        quantity: '1',
        cost: original,
        marketValue: outstanding,
        acquiredAt: date,
        updatedAt: date,
        details: {...financing.details, 'assetId': assetId, 'lender': lender},
      ),
    );
    state.append(
      EntryKind.acquisition,
      name,
      outstanding,
      date,
      positionId: id,
    );
  }
}
