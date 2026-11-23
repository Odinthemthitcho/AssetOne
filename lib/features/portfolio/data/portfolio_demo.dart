part of 'portfolio_store.dart';

_PortfolioState _demoPortfolio() {
  final state = _PortfolioState(isDemo: true);
  final now = DateTime.now();
  DateTime daysFromNow(int days) =>
      DateTime(now.year, now.month, now.day + days);
  String dateText(int days) {
    final date = daysFromNow(days);
    return DateOnly(date.year, date.month, date.day).toString();
  }

  final firstDate = daysFromNow(-28);
  final wallet = state.nextId('account');
  final bank = state.nextId('account');
  state.accounts.addAll([
    CashAccount(
      id: wallet,
      name: 'Ví cá nhân',
      institution: '',
      type: 'Tiền mặt',
    ),
    CashAccount(
      id: bank,
      name: 'Tài khoản thanh toán',
      institution: 'Ngân hàng mẫu',
      type: 'Ngân hàng',
      primary: true,
    ),
  ]);
  state.append(
    EntryKind.openingCash,
    'Số dư đầu kỳ · Ví cá nhân',
    5000000,
    firstDate,
    accountId: wallet,
    cashDelta: 5000000,
  );
  state.append(
    EntryKind.openingCash,
    'Số dư đầu kỳ · Tài khoản thanh toán',
    45000000,
    firstDate,
    accountId: bank,
    cashDelta: 45000000,
  );

  void holding(
    AssetKind kind,
    String name,
    int cost,
    int marketValue, {
    String symbol = '',
    String quantity = '1',
    Map<String, String> details = const {},
  }) {
    final id = state.nextId('position');
    state.positions.add(
      Position(
        id: id,
        kind: kind,
        name: name,
        symbol: symbol,
        quantity: quantity,
        cost: cost,
        marketValue: marketValue,
        acquiredAt: firstDate,
        updatedAt: firstDate,
        details: details,
      ),
    );
    state.append(
      EntryKind.acquisition,
      name,
      kind == AssetKind.debt ? marketValue : cost,
      firstDate,
      positionId: id,
      quantity: kind.isQuantityBased ? quantity : null,
    );
  }

  holding(
    AssetKind.stock,
    'Cổ phiếu FPT',
    24000000,
    26700000,
    symbol: 'FPT',
    quantity: '200',
  );
  holding(
    AssetKind.etf,
    'Quỹ ETF VN30',
    14500000,
    15250000,
    symbol: 'E1VFVN30',
    quantity: '500',
  );
  holding(
    AssetKind.bond,
    'Trái phiếu doanh nghiệp mẫu',
    30000000,
    30000000,
    symbol: 'TP01',
    quantity: '300',
    details: {'dueDate': dateText(137)},
  );
  holding(
    AssetKind.fund,
    'Quỹ cân bằng mẫu',
    18000000,
    19800000,
    symbol: 'QUY01',
    quantity: '550',
  );
  holding(
    AssetKind.crypto,
    'Bitcoin',
    22000000,
    24400000,
    symbol: 'BTC',
    quantity: '0.01',
  );
  holding(
    AssetKind.realEstate,
    'Căn hộ',
    2150000000,
    2350000000,
    details: {
      'ownershipPercent': '50',
      'fullCost': '4300000000',
      'fullMarketValue': '4700000000',
    },
  );
  holding(
    AssetKind.deposit,
    'Sổ tiết kiệm 6 tháng',
    100000000,
    100000000,
    details: {'Lãi suất năm': '5,4%', 'dueDate': dateText(21)},
  );
  holding(
    AssetKind.foreignCurrency,
    'Đô la Mỹ',
    24800000,
    25400000,
    symbol: 'USD',
    quantity: '1000',
  );
  holding(
    AssetKind.metal,
    'Vàng 9999',
    12000000,
    13100000,
    symbol: 'VÀNG 9999',
    quantity: '1',
    details: {'Đơn vị': 'Chỉ'},
  );
  holding(AssetKind.vehicle, 'Ô tô gia đình', 620000000, 545000000);
  holding(AssetKind.retirement, 'Quỹ hưu trí cá nhân', 75000000, 78000000);
  holding(
    AssetKind.insurance,
    'Bảo hiểm nhân thọ',
    42000000,
    32500000,
    details: {'Quyền lợi bảo vệ': '600.000.000 ₫', 'dueDate': dateText(9)},
  );
  holding(AssetKind.other, 'Bộ sưu tập', 13500000, 16000000);
  holding(
    AssetKind.debt,
    'Khoản vay mua căn hộ',
    950000000,
    832000000,
    details: {'lender': 'Ngân hàng mẫu', 'dueDate': dateText(5)},
  );

  void snapshot(DateTime date) {
    final totals = state.totals();
    state.history.add(
      PortfolioSnapshot(date: date, assets: totals.assets, debts: totals.debts),
    );
  }

  snapshot(firstDate);
  final stock = state.positions.first;
  final valuationDate = daysFromNow(-20);
  state.replacePosition(
    stock.withAmounts(marketValue: 28100000, updatedAt: valuationDate),
  );
  state.append(
    EntryKind.valuation,
    'Định giá · ${stock.name}',
    28100000,
    valuationDate,
    positionId: stock.id,
  );
  snapshot(valuationDate);

  final incomeDate = daysFromNow(-13);
  state.append(
    EntryKind.deposit,
    'Nạp tiền · Tài khoản thanh toán',
    6000000,
    incomeDate,
    cashDelta: 6000000,
    accountId: bank,
    note: 'Tiền tích lũy',
  );
  snapshot(incomeDate);

  final debt = state.positions.last;
  final duePayment = daysFromNow(-6);
  state.replacePosition(
    debt.withAmounts(marketValue: 824000000, updatedAt: duePayment),
  );
  state.append(
    EntryKind.debtPayment,
    'Trả nợ · ${debt.name}',
    10300000,
    duePayment,
    positionId: debt.id,
    accountId: bank,
    cashDelta: -10300000,
    principal: 8000000,
    interest: 2300000,
  );
  snapshot(duePayment);
  snapshot(daysFromNow(0));
  return state;
}
