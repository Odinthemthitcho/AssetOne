import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../portfolio/data/portfolio_store.dart';
import '../portfolio/domain/portfolio_models.dart';

class AssetOneActivityPage extends StatefulWidget {
  const AssetOneActivityPage({super.key, required this.store});

  final PortfolioStore store;

  @override
  State<AssetOneActivityPage> createState() => _AssetOneActivityPageState();
}

enum _ActivityFilter {
  all('Tất cả'),
  inflow('Tiền vào'),
  outflow('Tiền ra');

  const _ActivityFilter(this.label);
  final String label;

  bool accepts(LedgerEntry entry) => switch (this) {
    all => true,
    inflow => entry.cashDelta > 0,
    outflow => entry.cashDelta < 0,
  };
}

class _AssetOneActivityPageState extends State<AssetOneActivityPage> {
  String _query = '';
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        final accountNames = {
          for (final account in store.accounts) account.id: account.name,
        };
        String accountLabel(LedgerEntry entry) {
          final source = accountNames[entry.accountId];
          final target = accountNames[entry.targetAccountId];
          if (source != null && target != null) return '$source → $target';
          return source ?? target ?? '';
        }

        final entries = store.activity.where((entry) {
          return _filter.accepts(entry) &&
              '${entry.title} ${entry.type.label} ${accountLabel(entry)} ${entry.note}'
                  .toLowerCase()
                  .contains(_query);
        }).toList();

        return CustomScrollView(
          key: const PageStorageKey('assetone-activity'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Tìm giao dịch',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final filter in _ActivityFilter.values)
                          ChoiceChip(
                            label: Text(filter.label),
                            selected: _filter == filter,
                            onSelected: (selected) {
                              if (selected) setState(() => _filter = filter);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: store.activity.isEmpty
                      ? 'Chưa có giao dịch'
                      : 'Không tìm thấy giao dịch',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final date = _formatDate(entry.date);
                    final newDay =
                        index == 0 ||
                        _formatDate(entries[index - 1].date) != date;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (newDay)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                            child: Text(
                              date,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        _ActivityRow(
                          entry: entry,
                          accountLabel: accountLabel(entry),
                          balanceHidden: store.balanceHidden,
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.entry,
    required this.accountLabel,
    required this.balanceHidden,
  });

  final LedgerEntry entry;
  final String accountLabel;
  final bool balanceHidden;

  @override
  Widget build(BuildContext context) {
    final cashDelta = entry.cashDelta;
    final visibleAmount = cashDelta == 0 ? entry.amount : cashDelta;
    final prefix = cashDelta > 0 ? '+' : '';
    final amountColor = cashDelta > 0 ? AppColors.accent : AppColors.foreground;
    final caption = [
      entry.type.label,
      accountLabel,
      entry.note.trim(),
    ].where((text) => text.isNotEmpty).join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.surfaceElevated,
              foregroundColor: amountColor,
              child: Icon(
                cashDelta > 0
                    ? Icons.south_west
                    : cashDelta < 0
                    ? Icons.north_east
                    : Icons.swap_horiz,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(caption, style: Theme.of(context).textTheme.bodySmall),
                  if (visibleAmount != 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      balanceHidden
                          ? '••••••'
                          : '$prefix${PortfolioAmounts.formatVnd(visibleAmount)}',
                      style: _amountStyle(context, amountColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssetOneMarketPage extends StatefulWidget {
  const AssetOneMarketPage({super.key, required this.store});

  final PortfolioStore store;

  @override
  State<AssetOneMarketPage> createState() => _AssetOneMarketPageState();
}

class _AssetOneMarketPageState extends State<AssetOneMarketPage> {
  static const _quotedKinds = {
    AssetKind.stock,
    AssetKind.etf,
    AssetKind.bond,
    AssetKind.fund,
    AssetKind.crypto,
    AssetKind.foreignCurrency,
    AssetKind.metal,
  };

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        final positions = store.positions.where((position) {
          return !position.closed &&
              _quotedKinds.contains(position.kind) &&
              '${position.symbol} ${position.name} ${position.kind.label}'
                  .toLowerCase()
                  .contains(_query);
        }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return CustomScrollView(
          key: const PageStorageKey('assetone-market'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Định giá đã lưu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.isDemo
                          ? 'Nguồn dữ liệu là danh mục khách trên thiết bị.'
                          : 'Nguồn dữ liệu là danh mục của bạn trên thiết bị.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Tìm theo mã hoặc tên tài sản',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (positions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Icons.show_chart,
                  title: _query.isEmpty
                      ? 'Chưa có vị thế để theo dõi'
                      : 'Không tìm thấy vị thế',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final position = positions[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              position.symbol.isEmpty ||
                                      position.symbol == position.name
                                  ? position.name
                                  : '${position.symbol} · ${position.name}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${position.kind.label} · ${_formatDate(position.updatedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              store.balanceHidden
                                  ? '••••••'
                                  : PortfolioAmounts.formatVnd(
                                      position.marketValue,
                                    ),
                              style: _amountStyle(context, AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class AssetOneProfilePage extends StatelessWidget {
  const AssetOneProfilePage({
    super.key,
    required this.store,
    required this.name,
    required this.email,
    required this.isGuest,
    required this.onSignOut,
    this.onOpenAccounts,
  });

  final PortfolioStore store;
  final String name;
  final String email;
  final bool isGuest;
  final VoidCallback onSignOut;
  final VoidCallback? onOpenAccounts;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, child) => ListView(
        key: const PageStorageKey('assetone-profile'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                child: Icon(Icons.person_outline),
              ),
              title: Text(isGuest ? 'Khách' : name),
              subtitle: Text(isGuest ? 'Danh mục trải nghiệm' : email),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Cài đặt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Ẩn số dư'),
                  subtitle: const Text('Ẩn các số tiền trong danh mục'),
                  value: store.balanceHidden,
                  onChanged: store.busy
                      ? null
                      : (value) => _saveChange(
                          context,
                          () => store.setBalanceHidden(value),
                        ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.currency_exchange),
                  title: Text('Đồng tiền báo cáo'),
                  trailing: Text('VND'),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                if (onOpenAccounts != null) ...[
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Tài khoản'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenAccounts,
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Nhắc lịch'),
                  trailing: Badge.count(
                    count: store.reminders.length,
                    isLabelVisible: store.reminders.isNotEmpty,
                    child: const Icon(Icons.chevron_right),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => AssetOneRemindersPage(store: store),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: store.busy ? null : onSignOut,
            icon: const Icon(Icons.logout),
            label: Text(isGuest ? 'Thoát chế độ khách' : 'Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class AssetOneRemindersPage extends StatelessWidget {
  const AssetOneRemindersPage({super.key, required this.store});

  final PortfolioStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc lịch')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, child) {
          final reminders = store.reminders;
          if (reminders.isEmpty) {
            return const _EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Chưa có lịch cần nhắc',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final today = DateUtils.dateOnly(DateTime.now());
              final dueDate = DateUtils.dateOnly(reminder.dueDate);
              final dateLabel = dueDate.isBefore(today) ? 'Quá hạn' : 'Đến hạn';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reminder.kind.label} · $dateLabel ${_formatDate(dueDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: store.busy
                            ? null
                            : () => _saveChange(
                                context,
                                () => store.dismissReminder(reminder.id),
                              ),
                        icon: const Icon(Icons.check),
                        label: const Text('Đánh dấu đã xem'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _saveChange(
  BuildContext context,
  Future<void> Function() save,
) async {
  try {
    await save();
  } on Exception {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu thay đổi. Vui lòng thử lại.'),
        ),
      );
    }
  }
}

TextStyle? _amountStyle(BuildContext context, Color color) => Theme.of(context)
    .textTheme
    .titleSmall
    ?.copyWith(fontFamily: 'Outfit', fontWeight: FontWeight.w500, color: color);

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
