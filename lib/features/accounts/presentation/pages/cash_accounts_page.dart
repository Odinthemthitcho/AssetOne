import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../portfolio/data/portfolio_store.dart';
import '../../../portfolio/domain/portfolio_models.dart';

enum _CashAction {
  create('Thêm tài khoản', Icons.add_card),
  deposit('Nạp tiền', Icons.south_west),
  withdraw('Rút tiền', Icons.north_east),
  transfer('Chuyển tiền', Icons.swap_horiz);

  const _CashAction(this.label, this.icon);
  final String label;
  final IconData icon;
}

class CashAccountsPage extends StatefulWidget {
  const CashAccountsPage({
    required this.store,
    this.startCreating = false,
    super.key,
  });
  final PortfolioStore store;
  final bool startCreating;

  @override
  State<CashAccountsPage> createState() => _CashAccountsPageState();
}

class _CashAccountsPageState extends State<CashAccountsPage> {
  PortfolioStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    if (widget.startCreating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _show(_CashAction.create);
      });
    }
  }

  Future<void> _show(_CashAction action, {String? accountId}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _CashForm(store: _store, action: action, accountId: accountId),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu.')));
    }
  }

  void _openAccount(CashAccount account) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              account.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(account.type),
          ),
          for (final action in [
            _CashAction.deposit,
            _CashAction.withdraw,
            _CashAction.transfer,
          ])
            ListTile(
              leading: Icon(action.icon),
              title: Text(action.label),
              enabled:
                  action != _CashAction.transfer || _store.accounts.length > 1,
              onTap: () {
                Navigator.pop(sheetContext);
                _show(action, accountId: account.id);
              },
            ),
          if (!account.primary)
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Đặt làm tài khoản chính'),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await _store.setPrimary(account.id);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể đổi tài khoản chính.'),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tài khoản')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final accounts = _store.accounts;
            final cash = _store.totals.cash;
            String money(int value) => _store.balanceHidden
                ? '••••••'
                : PortfolioAmounts.formatVnd(value);
            final byType = <String, int>{};
            for (final account in accounts) {
              byType.update(
                account.type,
                (total) => total + account.balance,
                ifAbsent: () => account.balance,
              );
            }
            final now = DateTime.now();
            final month = _store.activity.where(
              (e) =>
                  e.type != EntryKind.openingCash &&
                  e.date.year == now.year &&
                  e.date.month == now.month,
            );
            final inflow = month
                .where((e) => e.cashDelta > 0)
                .fold(0, (sum, e) => sum + e.cashDelta);
            final outflow = month
                .where((e) => e.cashDelta < 0)
                .fold(0, (sum, e) => sum - e.cashDelta);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
              children: [
                const Text(
                  'TỔNG SỐ DƯ',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.3,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  money(cash),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final action in _CashAction.values)
                      ActionChip(
                        label: Text(action.label),
                        avatar: Icon(action.icon, size: 18),
                        onPressed: switch (action) {
                          _CashAction.create => () => _show(action),
                          _CashAction.transfer when accounts.length < 2 => null,
                          _ when accounts.isEmpty => null,
                          _ => () => _show(action),
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _section(context, 'Tài khoản của tôi'),
                if (accounts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Thêm tài khoản đầu tiên để theo dõi số dư.'),
                    ),
                  ),
                for (final account in accounts)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      onTap: () => _openAccount(account),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.accent,
                        child: Icon(
                          account.type == 'Tiền mặt'
                              ? Icons.wallet_outlined
                              : Icons.account_balance_outlined,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (account.primary)
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.accent,
                              size: 18,
                            ),
                        ],
                      ),
                      subtitle: Text(
                        [
                          account.type,
                          if (account.institution.isNotEmpty)
                            account.institution,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        money(account.balance),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (accounts.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _section(context, 'Phân bổ số dư'),
                  Card(
                    child: Column(
                      children: [
                        for (final item in byType.entries)
                          ListTile(
                            title: Text(item.key),
                            trailing: Text(money(item.value)),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _section(context, 'Dòng tiền tháng này'),
                Card(
                  child: Column(
                    children: [
                      for (final line in [
                        ('Tiền vào', inflow),
                        ('Tiền ra', outflow),
                        ('Dòng tiền ròng', inflow - outflow),
                      ])
                        ListTile(
                          minTileHeight: 43,
                          title: Text(line.$1),
                          trailing: Text(money(line.$2)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _section(context, 'Giao dịch gần đây'),
                for (final entry
                    in _store.activity
                        .where(
                          (entry) =>
                              entry.accountId != null ||
                              entry.targetAccountId != null,
                        )
                        .take(6))
                  ListTile(
                    title: Text(entry.title),
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
            );
          },
        ),
      ),
    ),
  );

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _CashForm extends StatefulWidget {
  const _CashForm({required this.store, required this.action, this.accountId});
  final PortfolioStore store;
  final _CashAction action;
  final String? accountId;

  @override
  State<_CashForm> createState() => _CashFormState();
}

class _CashFormState extends State<_CashForm> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _institution = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _type = 'Tiền mặt';
  String? _account;
  String? _target;
  bool _primary = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _account = widget.accountId ?? widget.store.accounts.firstOrNull?.id;
  }

  @override
  void dispose() {
    for (final controller in [_name, _institution, _amount, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    final amount = PortfolioAmounts.parseVnd(_amount.text) ?? 0;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      switch (widget.action) {
        case _CashAction.create:
          await widget.store.createAccount(
            name: _name.text,
            institution: _institution.text,
            type: _type,
            openingBalance: amount,
            primary: _primary,
          );
        case _CashAction.deposit || _CashAction.withdraw:
          await widget.store.addCash(
            accountId: _account!,
            amount: amount,
            deposit: widget.action == _CashAction.deposit,
            note: _note.text,
          );
        case _CashAction.transfer:
          await widget.store.transfer(
            fromId: _account!,
            toId: _target!,
            amount: amount,
            note: _note.text,
          );
      }
      if (mounted) Navigator.pop(context, true);
    } on PortfolioException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể lưu dữ liệu. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final create = widget.action == _CashAction.create;
    final transfer = widget.action == _CashAction.transfer;
    return Scaffold(
      appBar: AppBar(title: Text(widget.action.label)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (create) ...[
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Tên tài khoản',
                    ),
                    maxLength: 80,
                    validator: (value) =>
                        value!.trim().isEmpty ? 'Nhập tên tài khoản.' : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Loại tài khoản',
                    ),
                    items: [
                      for (final type in [
                        'Tiền mặt',
                        'Ngân hàng',
                        'Ví điện tử',
                        'Chứng khoán',
                        'Khác',
                      ])
                        DropdownMenuItem(value: type, child: Text(type)),
                    ],
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _institution,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Ngân hàng / nhà cung cấp',
                    ),
                  ),
                ] else ...[
                  _accountField(
                    label: transfer ? 'Từ tài khoản' : 'Tài khoản',
                    value: _account,
                    onChanged: (value) => setState(() {
                      _account = value;
                      if (_target == value) _target = null;
                    }),
                  ),
                  if (transfer) ...[
                    const SizedBox(height: 12),
                    _accountField(
                      label: 'Đến tài khoản',
                      value: _target,
                      excluded: _account,
                      onChanged: (value) => setState(() => _target = value),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: create ? 'Số dư ban đầu' : 'Số tiền',
                    suffixText: '₫',
                  ),
                  validator: (value) {
                    if (create && value!.trim().isEmpty) return null;
                    final amount = PortfolioAmounts.parseVnd(value ?? '');
                    return amount == null || amount < (create ? 0 : 1)
                        ? 'Nhập số tiền VND hợp lệ.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                if (create)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tài khoản chính'),
                    value: _primary,
                    onChanged: (value) => setState(() => _primary = value),
                  )
                else
                  TextFormField(
                    controller: _note,
                    maxLength: 180,
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                  ),
                if (_error case final error?)
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? excluded,
  }) => DropdownButtonFormField<String>(
    key: ValueKey((label, value, excluded)),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final account in widget.store.accounts)
        if (account.id != excluded)
          DropdownMenuItem(
            value: account.id,
            child: Text(account.name, overflow: TextOverflow.ellipsis),
          ),
    ],
    onChanged: onChanged,
    validator: (value) => value == null ? 'Chọn tài khoản.' : null,
  );
}
