part of 'portfolio_store.dart';

final class _PortfolioState {
  _PortfolioState({
    this.nextSequence = 1,
    this.isDemo = false,
    this.balanceHidden = false,
    List<Position>? positions,
    List<CashAccount>? accounts,
    List<LedgerEntry>? entries,
    List<PortfolioSnapshot>? history,
    Set<String>? dismissedReminders,
  }) : positions = positions ?? [],
       accounts = accounts ?? [],
       entries = entries ?? [],
       history = history ?? [],
       dismissedReminders = dismissedReminders ?? {};

  int nextSequence;
  final bool isDemo;
  bool balanceHidden;
  final List<Position> positions;
  final List<CashAccount> accounts;
  final List<LedgerEntry> entries;
  final List<PortfolioSnapshot> history;
  final Set<String> dismissedReminders;

  _PortfolioState copy() => _PortfolioState(
    nextSequence: nextSequence,
    isDemo: isDemo,
    balanceHidden: balanceHidden,
    positions: List.of(positions),
    accounts: List.of(accounts),
    entries: List.of(entries),
    history: List.of(history),
    dismissedReminders: Set.of(dismissedReminders),
  );

  factory _PortfolioState.fromJson(Map<String, dynamic> source) {
    if (source['version'] != 1) {
      throw const PortfolioException(
        'Phiên bản dữ liệu danh mục chưa được hỗ trợ.',
      );
    }
    List<T> readList<T>(String key, T Function(Map<String, dynamic>) read) =>
        (source[key] as List).cast<Map<String, dynamic>>().map(read).toList();
    return _PortfolioState(
      nextSequence: source['nextSequence'] as int,
      isDemo: source['isDemo'] as bool? ?? false,
      balanceHidden: source['balanceHidden'] as bool,
      positions: readList('positions', Position.fromJson),
      accounts: readList('accounts', CashAccount.fromJson),
      entries: readList('entries', LedgerEntry.fromJson),
      history: readList('history', PortfolioSnapshot.fromJson),
      dismissedReminders: (source['dismissedReminders'] as List)
          .cast<String>()
          .toSet(),
    );
  }

  String encode() => jsonEncode({
    'version': 1,
    'nextSequence': nextSequence,
    'isDemo': isDemo,
    'balanceHidden': balanceHidden,
    'positions': positions,
    'accounts': accounts,
    'entries': entries,
    'history': history,
    'dismissedReminders': dismissedReminders.toList(),
  });

  String nextId(String kind) => '$kind-${nextSequence++}';

  void append(
    EntryKind kind,
    String title,
    int amount,
    DateTime date, {
    int cashDelta = 0,
    String? positionId,
    String? accountId,
    String? targetAccountId,
    String note = '',
    String? quantity,
    String? unitPrice,
    int fee = 0,
    int principal = 0,
    int interest = 0,
    int? realizedProfit,
  }) => entries.add(
    LedgerEntry(
      id: nextId('entry'),
      type: kind,
      title: title,
      amount: amount,
      date: date,
      cashDelta: cashDelta,
      positionId: positionId,
      accountId: accountId,
      targetAccountId: targetAccountId,
      note: note,
      quantity: quantity,
      unitPrice: unitPrice,
      fee: fee,
      principal: principal,
      interest: interest,
      realizedProfit: realizedProfit,
    ),
  );

  List<LedgerEntry> recentActivity() {
    return List.unmodifiable(_chronologicalEntries().reversed);
  }

  Position requirePosition(String id) =>
      positions.where((position) => position.id == id).firstOrNull ??
      (throw const PortfolioException('Không tìm thấy hồ sơ trong danh mục.'));

  void replacePosition(Position newPosition) =>
      positions[positions.indexWhere(
            (position) => position.id == newPosition.id,
          )] =
          newPosition;

  CashAccount requireAccount(String id) =>
      accounts.where((account) => account.id == id).firstOrNull ??
      (throw const PortfolioException('Không tìm thấy tài khoản.'));

  void makePrimary(String id) {
    for (var i = 0; i < accounts.length; i++) {
      final account = accounts[i];
      accounts[i] = account.withStatus(primary: account.id == id);
    }
  }

  void requireFunds(String accountId, int amount) {
    if ((_balances()[accountId] ?? 0) < amount) {
      throw const PortfolioException('Số dư tài khoản không đủ.');
    }
  }

  List<CashAccount> accountsWithBalances() {
    final balances = _balances();
    return List.unmodifiable(
      accounts.map(
        (account) => account.withStatus(balance: balances[account.id] ?? 0),
      ),
    );
  }

  Map<String, int> _balances({bool verifyHistory = false}) {
    final balances = <String, int>{};
    void adjust(String? id, int delta) {
      if (id == null || delta == 0) return;
      final previous = balances[id] ?? 0;
      final balance = previous + delta;
      if (verifyHistory && balance < 0) {
        throw const PortfolioException(
          'Tài khoản không đủ số dư vào ngày giao dịch đã chọn.',
        );
      }
      if (verifyHistory && balance > PortfolioAmounts.maxVnd) {
        throw const PortfolioException(
          'Số dư tài khoản vượt giới hạn ghi nhận.',
        );
      }
      balances[id] = balance;
    }

    for (final entry in _chronologicalEntries()) {
      if (entry.type == EntryKind.transfer) {
        adjust(entry.accountId, -entry.amount);
        adjust(entry.targetAccountId, entry.amount);
      } else {
        adjust(entry.accountId, entry.cashDelta);
      }
    }
    return balances;
  }

  List<LedgerEntry> _chronologicalEntries() => List.of(entries)
    ..sort((a, b) {
      final order = _calendarDay(a.date).compareTo(_calendarDay(b.date));
      return order != 0
          ? order
          : _entrySequence(a).compareTo(_entrySequence(b));
    });

  PortfolioTotals totals({bool verifyCashHistory = false}) {
    final byKind = <AssetKind, int>{};
    var cost = 0;
    var assets = 0;
    var cash = 0;
    for (final balance in _balances(verifyHistory: verifyCashHistory).values) {
      cash = _total(cash, balance);
    }
    for (final position in positions) {
      final kind = position.kind;
      final value = position.marketValue;
      byKind.update(
        kind,
        (previous) => _total(previous, value),
        ifAbsent: () => value,
      );
      if (kind == AssetKind.debt) continue;
      cost = _total(cost, position.cost);
      assets = _total(assets, value);
    }
    return PortfolioTotals(
      cash: cash,
      assets: _total(assets, cash),
      debts: byKind[AssetKind.debt] ?? 0,
      investedCost: cost,
      byKind: byKind,
    );
  }

  void recordSnapshot({bool verifyCashHistory = false}) {
    final total = totals(verifyCashHistory: verifyCashHistory);
    if (history.isEmpty && entries.isEmpty) return;
    final today = _calendarDay(DateTime.now());
    final snapshot = PortfolioSnapshot(
      date: today,
      assets: total.assets,
      debts: total.debts,
    );
    if (history.isNotEmpty && history.last.date == today) {
      history[history.length - 1] = snapshot;
    } else {
      history.add(snapshot);
    }
  }

  List<PortfolioReminder> reminders() {
    final items = <PortfolioReminder>[];
    for (final position in positions) {
      if (position.closed) continue;
      final value = position.details['dueDate'] ?? '';
      final dueDate = DateOnly.tryParse(value);
      if (dueDate == null) continue;
      final id = '${position.id}:$value';
      if (dismissedReminders.contains(id)) continue;
      items.add(
        PortfolioReminder(
          id: id,
          positionId: position.id,
          kind: position.kind,
          title: position.name,
          dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day),
        ),
      );
    }
    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return List.unmodifiable(items);
  }

  static DateTime _calendarDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _entrySequence(LedgerEntry entry) =>
      int.parse(entry.id.substring('entry-'.length));

  static int _total(int running, int amount) {
    final total = running + amount;
    if (total < 0 || total > PortfolioAmounts.maxVnd) {
      throw const PortfolioException(
        'Tổng giá trị danh mục vượt giới hạn ghi nhận.',
      );
    }
    return total;
  }
}
