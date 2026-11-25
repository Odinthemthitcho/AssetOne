export 'portfolio_amounts.dart';

enum AssetKind {
  stock('Cổ phiếu', isQuantityBased: true),
  etf('ETF', isQuantityBased: true),
  bond('Trái phiếu', isQuantityBased: true),
  fund('Quỹ đầu tư', isQuantityBased: true),
  crypto('Tiền mã hóa', isQuantityBased: true),
  realEstate('Bất động sản'),
  deposit('Tiền gửi'),
  foreignCurrency('Ngoại tệ', isQuantityBased: true),
  metal('Vàng & kim loại', isQuantityBased: true),
  vehicle('Ô tô'),
  retirement('Quỹ hưu trí'),
  insurance('Bảo hiểm'),
  other('Tài sản khác'),
  debt('Khoản nợ');

  const AssetKind(this.label, {this.isQuantityBased = false});

  final String label;
  final bool isQuantityBased;
}

enum EntryKind {
  openingCash('Số dư đầu kỳ'),
  deposit('Nạp tiền'),
  withdrawal('Rút tiền'),
  transfer('Chuyển tiền'),
  acquisition('Ghi nhận'),
  purchase('Mua'),
  sale('Bán'),
  redemption('Tất toán tiền gửi'),
  valuation('Định giá'),
  debtPayment('Trả nợ'),
  removal('Xóa hồ sơ');

  const EntryKind(this.label);

  final String label;
}

final class PortfolioException implements Exception {
  const PortfolioException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class Position {
  Position({
    required this.id,
    required this.kind,
    required this.name,
    required this.symbol,
    required this.quantity,
    required this.cost,
    required this.marketValue,
    required this.acquiredAt,
    required this.updatedAt,
    this.accountId,
    Map<String, String> details = const {},
  }) : details = Map.unmodifiable(details);

  final String id;
  final AssetKind kind;
  final String name;
  final String symbol;
  final String quantity;
  final int cost;
  final int marketValue;
  final String? accountId;
  final DateTime acquiredAt;
  final DateTime updatedAt;
  final Map<String, String> details;

  int get profit => kind == AssetKind.debt ? 0 : marketValue - cost;

  bool get closed =>
      kind == AssetKind.debt ? marketValue == 0 : quantity == '0';

  Position withAmounts({
    String? quantity,
    int? cost,
    required int marketValue,
    required DateTime updatedAt,
    Map<String, String>? details,
  }) => Position(
    id: id,
    kind: kind,
    name: name,
    symbol: symbol,
    quantity: quantity ?? this.quantity,
    cost: cost ?? this.cost,
    marketValue: marketValue,
    acquiredAt: acquiredAt,
    updatedAt: updatedAt,
    accountId: accountId,
    details: details ?? this.details,
  );

  Position withMetadata({
    required String name,
    required Map<String, String> details,
  }) => Position(
    id: id,
    kind: kind,
    name: name,
    symbol: symbol,
    quantity: quantity,
    cost: cost,
    marketValue: marketValue,
    acquiredAt: acquiredAt,
    updatedAt: updatedAt,
    accountId: accountId,
    details: details,
  );

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    id: json['id'] as String,
    kind: AssetKind.values.byName(json['kind'] as String),
    name: json['name'] as String,
    symbol: json['symbol'] as String,
    quantity: json['quantity'] as String,
    cost: json['cost'] as int,
    marketValue: json['marketValue'] as int,
    accountId: json['accountId'] as String?,
    acquiredAt: DateTime.parse(json['acquiredAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    details: Map<String, String>.from(json['details'] as Map),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'symbol': symbol,
    'quantity': quantity,
    'cost': cost,
    'marketValue': marketValue,
    'accountId': accountId,
    'acquiredAt': acquiredAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'details': details,
  };
}

final class PositionFinancing {
  PositionFinancing({
    required this.lender,
    required this.originalPrincipal,
    required this.outstandingPrincipal,
    Map<String, String> details = const {},
  }) : details = Map.unmodifiable(details);

  final String lender;
  final int originalPrincipal;
  final int outstandingPrincipal;
  final Map<String, String> details;
}

final class CashAccount {
  const CashAccount({
    required this.id,
    required this.name,
    required this.institution,
    required this.type,
    this.balance = 0,
    this.primary = false,
  });

  final String id;
  final String name;
  final String institution;
  final String type;
  final int balance;
  final bool primary;

  CashAccount withStatus({int? balance, bool? primary}) => CashAccount(
    id: id,
    name: name,
    institution: institution,
    type: type,
    balance: balance ?? this.balance,
    primary: primary ?? this.primary,
  );

  factory CashAccount.fromJson(Map<String, dynamic> json) => CashAccount(
    id: json['id'] as String,
    name: json['name'] as String,
    institution: json['institution'] as String,
    type: json['type'] as String,
    primary: json['primary'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'institution': institution,
    'type': type,
    'primary': primary,
  };
}

final class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.cashDelta = 0,
    this.note = '',
    this.positionId,
    this.accountId,
    this.targetAccountId,
    this.quantity,
    this.unitPrice,
    this.fee = 0,
    this.principal = 0,
    this.interest = 0,
    this.realizedProfit,
  });

  final String id;
  final EntryKind type;
  final String title;
  final int amount;
  final int cashDelta;
  final DateTime date;
  final String note;
  final String? positionId;
  final String? accountId;
  final String? targetAccountId;
  final String? quantity;
  final String? unitPrice;
  final int fee;
  final int principal;
  final int interest;
  final int? realizedProfit;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['id'] as String,
    type: EntryKind.values.byName(json['type'] as String),
    title: json['title'] as String,
    amount: json['amount'] as int,
    cashDelta: json['cashDelta'] as int,
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String,
    positionId: json['positionId'] as String?,
    accountId: json['accountId'] as String?,
    targetAccountId: json['targetAccountId'] as String?,
    quantity: json['quantity'] as String?,
    unitPrice: json['unitPrice'] as String?,
    fee: json['fee'] as int? ?? 0,
    principal: json['principal'] as int? ?? 0,
    interest: json['interest'] as int? ?? 0,
    realizedProfit: json['realizedProfit'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'amount': amount,
    'cashDelta': cashDelta,
    'date': date.toIso8601String(),
    'note': note,
    'positionId': positionId,
    'accountId': accountId,
    'targetAccountId': targetAccountId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'fee': fee,
    'principal': principal,
    'interest': interest,
    'realizedProfit': realizedProfit,
  };
}

final class PortfolioTotals {
  PortfolioTotals({
    required this.cash,
    required this.assets,
    required this.debts,
    required this.investedCost,
    required Map<AssetKind, int> byKind,
  }) : byKind = Map.unmodifiable(byKind);

  final int cash;
  final int assets;
  final int debts;
  final int investedCost;
  final Map<AssetKind, int> byKind;

  int get netWorth => assets - debts;
  int get profit => assets - cash - investedCost;
}

final class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.date,
    required this.assets,
    required this.debts,
  });

  final DateTime date;
  final int assets;
  final int debts;

  int get netWorth => assets - debts;

  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) =>
      PortfolioSnapshot(
        date: DateTime.parse(json['date'] as String),
        assets: json['assets'] as int,
        debts: json['debts'] as int,
      );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'assets': assets,
    'debts': debts,
  };
}

final class PortfolioReminder {
  const PortfolioReminder({
    required this.id,
    required this.positionId,
    required this.kind,
    required this.title,
    required this.dueDate,
  });

  final String id;
  final String positionId;
  final AssetKind kind;
  final String title;
  final DateTime dueDate;
}
