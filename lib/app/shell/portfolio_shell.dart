import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/accounts/presentation/pages/cash_accounts_page.dart';
import '../../features/auth/data/local_auth.dart';
import '../../features/overview/auxiliary_pages.dart';
import '../../features/portfolio/data/portfolio_store.dart';
import '../../features/portfolio/domain/portfolio_models.dart';
import '../../features/portfolio/presentation/portfolio_category_page.dart';
import '../../features/portfolio/presentation/portfolio_form_page.dart';

class PortfolioShell extends StatefulWidget {
  const PortfolioShell({
    required this.store,
    required this.profile,
    required this.demo,
    required this.onSignOut,
    super.key,
  });
  final PortfolioStore store;
  final LocalProfile profile;
  final bool demo;
  final VoidCallback onSignOut;

  @override
  State<PortfolioShell> createState() => _PortfolioShellState();
}

class _PortfolioShellState extends State<PortfolioShell> {
  int _index = 0;
  PortfolioStore get _store => widget.store;

  void _push(Widget page) =>
      Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));

  void _openAccounts() => _push(CashAccountsPage(store: _store));

  void _showCategory(AssetKind kind) =>
      _push(PortfolioCategoryPage(store: _store, kind: kind));

  Future<void> _create() async {
    final kind = await showModalBottomSheet<AssetKind>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .8,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Text('Tạo mới', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Tài khoản'),
                onTap: () {
                  Navigator.pop(context);
                  _push(CashAccountsPage(store: _store, startCreating: true));
                },
              ),
              for (final kind in AssetKind.values)
                ListTile(
                  leading: Icon(_kindIcon(kind)),
                  title: Text(kind.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, kind),
                ),
            ],
          ),
        ),
      ),
    );
    if (kind != null && mounted) {
      _push(PortfolioFormPage(store: _store, kind: kind));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = ['Tài sản', 'Thị trường', 'Giao dịch', 'Cá nhân'][_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_index == 0) ...[
            IconButton(
              tooltip: 'Nhắc hạn',
              onPressed: () => _push(AssetOneRemindersPage(store: _store)),
              icon: const Icon(Icons.notifications_none),
            ),
            IconButton(
              tooltip: 'Tài khoản',
              onPressed: _openAccounts,
              icon: const Icon(Icons.account_balance_wallet_outlined),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: IndexedStack(
            index: _index,
            children: [
              _Dashboard(
                store: _store,
                demo: widget.demo,
                onAccounts: _openAccounts,
                onCategory: _showCategory,
                onActivity: () => setState(() => _index = 2),
              ),
              AssetOneMarketPage(store: _store),
              AssetOneActivityPage(store: _store),
              AssetOneProfilePage(
                store: _store,
                name: widget.profile.name,
                email: widget.profile.email,
                isGuest: widget.profile.isGuest,
                onSignOut: widget.onSignOut,
                onOpenAccounts: _openAccounts,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: AppColors.surface,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _tab(0, Icons.layers_outlined, 'Tài sản'),
                _tab(1, Icons.show_chart, 'Thị trường'),
                Expanded(
                  child: Center(
                    child: IconButton.filled(
                      tooltip: 'Tạo',
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
                _tab(2, Icons.swap_horiz, 'Giao dịch'),
                _tab(3, Icons.person_outline, 'Cá nhân'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final color = index == _index
        ? AppColors.accent
        : AppColors.mutedForeground;
    return Expanded(
      child: Semantics(
        selected: index == _index,
        button: true,
        child: InkWell(
          onTap: () => setState(() => _index = index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _groups = [
  (
    'Chứng khoán & đầu tư tài chính',
    [AssetKind.stock, AssetKind.etf, AssetKind.bond, AssetKind.fund],
  ),
  ('Tiền & thanh khoản', [AssetKind.deposit, AssetKind.foreignCurrency]),
  ('Tài sản thay thế', [AssetKind.crypto, AssetKind.metal]),
  ('Bất động sản & phương tiện', [AssetKind.realEstate, AssetKind.vehicle]),
  ('Bảo vệ & dài hạn', [AssetKind.retirement, AssetKind.insurance]),
  ('Tài sản khác', [AssetKind.other]),
  ('Nghĩa vụ tài chính', [AssetKind.debt]),
];

const _chartColors = [
  AppColors.accent,
  Color(0xff72b999),
  Color(0xff72a4ee),
  Color(0xffb09ae7),
  Color(0xfff2c37b),
  Color(0xffe89086),
];

IconData _kindIcon(AssetKind kind) => switch (kind) {
  AssetKind.stock => Icons.candlestick_chart_outlined,
  AssetKind.etf => Icons.grid_view_rounded,
  AssetKind.bond => Icons.description_outlined,
  AssetKind.fund => Icons.pie_chart_outline,
  AssetKind.crypto => Icons.currency_bitcoin,
  AssetKind.realEstate => Icons.apartment,
  AssetKind.deposit => Icons.savings_outlined,
  AssetKind.foreignCurrency => Icons.currency_exchange,
  AssetKind.metal => Icons.diamond_outlined,
  AssetKind.vehicle => Icons.directions_car_outlined,
  AssetKind.retirement => Icons.emoji_people,
  AssetKind.insurance => Icons.verified_user_outlined,
  AssetKind.other => Icons.category_outlined,
  AssetKind.debt => Icons.request_quote_outlined,
};

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.store,
    required this.demo,
    required this.onAccounts,
    required this.onCategory,
    required this.onActivity,
  });
  final PortfolioStore store;
  final bool demo;
  final VoidCallback onAccounts;
  final ValueChanged<AssetKind> onCategory;
  final VoidCallback onActivity;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, child) {
      final totals = store.totals;
      final hidden = store.balanceHidden;
      final history = store.history;
      String money(int amount) =>
          hidden ? '••••••' : PortfolioAmounts.formatVnd(amount);
      final now = DateTime.now();
      final month = store.activity.where(
        (entry) =>
            entry.type != EntryKind.openingCash &&
            entry.date.year == now.year &&
            entry.date.month == now.month,
      );
      final income = month
          .where((e) => e.cashDelta > 0)
          .fold<int>(0, (sum, e) => sum + e.cashDelta);
      final expense = month
          .where((e) => e.cashDelta < 0)
          .fold<int>(0, (sum, e) => sum - e.cashDelta);
      final allocation = <(String, int)>[
        for (final (index, group) in _groups.indexed.take(6))
          (
            group.$1,
            group.$2.fold<int>(
              index == 1 ? totals.cash : 0,
              (sum, kind) => sum + (totals.byKind[kind] ?? 0),
            ),
          ),
      ];
      Future<void> toggle() async {
        try {
          await store.setBalanceHidden(!hidden);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể lưu tùy chọn hiển thị.')),
            );
          }
        }
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        children: [
          if (demo)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'DỮ LIỆU MINH HỌA · DANH MỤC KHÁCH',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedForeground,
                  letterSpacing: 1,
                ),
              ),
            ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TỔNG GIÁ TRỊ TÀI SẢN RÒNG',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
              IconButton(
                tooltip: hidden ? 'Hiện số dư' : 'Ẩn số dư',
                onPressed: store.busy ? null : toggle,
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ],
          ),
          Text(
            money(totals.netWorth),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _line('Tổng tài sản', money(totals.assets)),
              _line('Dư nợ', money(totals.debts)),
            ],
          ),
          const SizedBox(height: 16),
          _panel(context, 'Phân bổ danh mục', [
            if (totals.assets > 0 && !hidden) ...[
              Center(
                child: SizedBox.square(
                  dimension: 132,
                  child: CustomPaint(
                    painter: _AllocationChart(
                      allocation
                          .map((item) => item.$2 / totals.assets)
                          .toList(),
                    ),
                    child: Center(
                      child: Text(
                        '${allocation.where((item) => item.$2 > 0).length}\nnhóm',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final (index, item) in allocation.indexed)
                if (item.$2 > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: _chartColors[index], size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.$1)),
                        Text(
                          '${(item.$2 * 100 / totals.assets).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
            ] else
              Text(hidden ? 'Đã ẩn số liệu' : 'Thêm tài sản để xem phân bổ.'),
          ]),
          _panel(context, 'Dòng tiền tháng này', [
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                _line('Tiền vào', money(income)),
                _line('Tiền ra', money(expense)),
                _line('Dòng tiền ròng', money(income - expense)),
              ],
            ),
          ]),
          if (!hidden && history.length > 1)
            _panel(context, 'Biến động tài sản ròng', [
              Semantics(
                label:
                    'Từ ${money(history.first.netWorth)} đến ${money(history.last.netWorth)}',
                child: SizedBox(
                  width: double.infinity,
                  height: 96,
                  child: CustomPaint(painter: _NetWorthChart(history)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatShortDate(history.first.date),
                  ),
                  Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatShortDate(history.last.date),
                  ),
                ],
              ),
            ]),
          for (final (index, group) in _groups.indexed)
            _panel(context, group.$1, [
              if (index == 1)
                _item(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Tài khoản',
                  value: money(totals.cash),
                  onTap: onAccounts,
                ),
              for (final kind in group.$2)
                _item(
                  icon: _kindIcon(kind),
                  title: kind.label,
                  value: money(
                    (totals.byKind[kind] ?? 0) *
                        (kind == AssetKind.debt ? -1 : 1),
                  ),
                  onTap: () => onCategory(kind),
                ),
            ]),
          _panel(
            context,
            'Hoạt động gần đây',
            [
              if (store.activity.isEmpty) const Text('Chưa có giao dịch.'),
              for (final entry in store.activity.take(5))
                ListTile(
                  minTileHeight: 48,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                  ),
                  trailing: Text(
                    money(
                      entry.cashDelta == 0 ? entry.amount : entry.cashDelta,
                    ),
                  ),
                ),
            ],
            action: TextButton(
              onPressed: onActivity,
              child: const Text('Xem tất cả'),
            ),
          ),
        ],
      );
    },
  );

  Widget _line(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
      ),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );

  Widget _panel(
    BuildContext context,
    String title,
    List<Widget> content, {
    Widget? action,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 10),
            ...content,
          ],
        ),
      ),
    ),
  );

  Widget _item({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) => ListTile(
    minTileHeight: 44,
    contentPadding: EdgeInsets.zero,
    minLeadingWidth: 20,
    leading: Icon(icon, size: 20, color: AppColors.accent),
    title: Text(title),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 12)),
        const Icon(Icons.chevron_right, size: 18),
      ],
    ),
    onTap: onTap,
  );
}

class _AllocationChart extends CustomPainter {
  const _AllocationChart(this.shares);
  final List<double> shares;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = (Offset.zero & size).deflate(9);
    var start = -math.pi / 2;
    for (final (index, share) in shares.indexed) {
      final sweep = share * 2 * math.pi;
      if (sweep > 0) {
        final gap = sweep < .07 || share >= .999 ? 0.0 : .025;
        final paint = Paint()
          ..color = _chartColors[index]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14;
        canvas.drawArc(ring, start + gap, sweep - 2 * gap, false, paint);
        start += sweep;
      }
    }
  }

  @override
  bool shouldRepaint(_AllocationChart oldDelegate) =>
      oldDelegate.shares != shares;
}

class _NetWorthChart extends CustomPainter {
  const _NetWorthChart(this.history);
  final List<PortfolioSnapshot> history;

  @override
  void paint(Canvas canvas, Size size) {
    final values = history.map((snapshot) => snapshot.netWorth);
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final start = history.first.date.millisecondsSinceEpoch;
    final dateRange = math.max(
      1,
      history.last.date.millisecondsSinceEpoch - start,
    );
    final chart = (Offset.zero & size).deflate(4);
    final path = Path();
    for (final (index, snapshot) in history.indexed) {
      final elapsed = snapshot.date.millisecondsSinceEpoch - start;
      final x = chart.left + chart.width * elapsed / dateRange;
      final y = high == low
          ? chart.center.dy
          : chart.bottom -
                chart.height * (snapshot.netWorth - low) / (high - low);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawLine(
      chart.bottomLeft,
      chart.bottomRight,
      Paint()..color = AppColors.border,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_NetWorthChart oldDelegate) =>
      oldDelegate.history != history;
}
