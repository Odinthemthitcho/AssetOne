import 'package:flutter/material.dart';

import '../../../core/attachments/local_documents.dart';
import '../data/portfolio_store.dart';
import '../domain/portfolio_models.dart';
import 'portfolio_action_page.dart';
import 'portfolio_fields.dart';
import 'portfolio_form_page.dart';
import 'portfolio_inputs.dart';

enum _PositionOrder {
  latest('Mới cập nhật'),
  value('Giá trị giảm dần'),
  name('Tên A–Z');

  const _PositionOrder(this.label);

  final String label;

  int compare(Position a, Position b) => switch (this) {
    latest => b.updatedAt.compareTo(a.updatedAt),
    value => b.marketValue.compareTo(a.marketValue),
    name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  };
}

class PortfolioCategoryPage extends StatefulWidget {
  const PortfolioCategoryPage({
    super.key,
    required this.store,
    required this.kind,
  });

  final PortfolioStore store;
  final AssetKind kind;

  @override
  State<PortfolioCategoryPage> createState() => _PortfolioCategoryPageState();
}

class _PortfolioCategoryPageState extends State<PortfolioCategoryPage> {
  String _query = '';
  bool _showClosed = false;
  _PositionOrder _order = _PositionOrder.latest;

  AssetKind get kind => widget.kind;

  Future<void> _add() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PortfolioFormPage(store: widget.store, kind: kind),
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${kind.label.toLowerCase()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final debt = kind == AssetKind.debt;
    final money = PortfolioAmounts.formatVnd;
    return Scaffold(
      appBar: AppBar(title: Text(kind.label)),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final all =
              widget.store.positions
                  .where((asset) => asset.kind == kind)
                  .toList()
                ..sort(_order.compare);
          final active = all.where((asset) => !asset.closed);
          final ids = all.map((asset) => asset.id).toSet();
          final recent = widget.store.activity
              .where((event) => ids.contains(event.positionId))
              .take(4)
              .toList();
          final upcoming = widget.store.reminders
              .where((reminder) => reminder.kind == kind)
              .firstOrNull;
          final total = active.fold<int>(
            0,
            (sum, asset) => sum + asset.marketValue,
          );
          final cost = active.fold<int>(0, (sum, asset) => sum + asset.cost);
          final filtered = all.where((asset) {
            if (!_showClosed && asset.closed) return false;
            return asset.name.toLowerCase().contains(_query) ||
                asset.symbol.toLowerCase().contains(_query);
          }).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 95),
            children: [
              PortfolioSummaryCard(
                label: debt ? 'Tổng dư nợ' : 'Tổng giá trị hiện tại',
                amount: total,
                icon: kind.icon,
                rows: {
                  if (!debt) kind.costLabel: money(cost),
                  if (!debt) 'Lãi / lỗ chưa thực hiện': money(total - cost),
                  debt ? 'Khoản nợ đang trả' : 'Tài sản đang nắm giữ': active
                      .length
                      .toString(),
                  if (upcoming != null)
                    'Lịch đến hạn gần nhất': portfolioDate(
                      context,
                      upcoming.dueDate,
                    ),
                },
              ),
              if (all.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tìm theo tên hoặc mã',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) =>
                      setState(() => _query = query.trim().toLowerCase()),
                ),
                if (all.any((asset) => asset.closed))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      label: Text(
                        debt ? 'Hiện khoản đã trả hết' : 'Hiện vị thế đã đóng',
                      ),
                      selected: _showClosed,
                      onSelected: (selected) =>
                          setState(() => _showClosed = selected),
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              if (all.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        debt ? 'Danh mục khoản nợ' : 'Danh mục nắm giữ',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    PopupMenuButton<_PositionOrder>(
                      tooltip: 'Sắp xếp',
                      initialValue: _order,
                      icon: const Icon(Icons.sort),
                      onSelected: (order) => setState(() => _order = order),
                      itemBuilder: (_) => [
                        for (final sort in _PositionOrder.values)
                          PopupMenuItem(value: sort, child: Text(sort.label)),
                      ],
                    ),
                  ],
                ),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      all.isEmpty
                          ? 'Chưa có ${kind.label.toLowerCase()} trong danh mục.'
                          : 'Không tìm thấy kết quả phù hợp.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              for (final asset in filtered)
                Card(
                  child: ListTile(
                    key: ValueKey(asset.id),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PortfolioPositionPage(
                          store: widget.store,
                          positionId: asset.id,
                        ),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        kind.icon,
                        size: 19,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      asset.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if (asset.symbol.isNotEmpty &&
                            asset.symbol != asset.name)
                          asset.symbol,
                        if (asset.closed) debt ? 'Đã trả hết' : 'Đã đóng',
                        if (!asset.closed &&
                            (asset.kind.isQuantityBased || !debt))
                          asset.kind.isQuantityBased
                              ? '${asset.quantity} ${asset.details['unit'] ?? asset.kind.unitLabel}'
                                    .trim()
                              : 'Vốn ${money(asset.cost)}',
                      ].join(' · '),
                    ),
                    trailing: Text(
                      money(asset.marketValue),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 22),
                PortfolioSection(
                  title: 'Hoạt động gần đây',
                  children: [
                    for (final event in recent)
                      Card(
                        child: ListTile(
                          dense: true,
                          title: Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(portfolioDate(context, event.date)),
                          trailing: Text(money(event.amount)),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text('Thêm ${kind.label.toLowerCase()}'),
      ),
    );
  }
}

class PortfolioPositionPage extends StatefulWidget {
  const PortfolioPositionPage({
    super.key,
    required this.store,
    required this.positionId,
  });

  final PortfolioStore store;
  final String positionId;

  @override
  State<PortfolioPositionPage> createState() => _PortfolioPositionPageState();
}

class _PortfolioPositionPageState extends State<PortfolioPositionPage> {
  bool _deleting = false;
  String? _error;

  Future<void> _delete(Position position) async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa hồ sơ?'),
        content: Text('Hồ sơ “${position.name}” sẽ bị xóa khỏi danh mục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.store.deletePosition(positionId: position.id);
      if (mounted) Navigator.pop(context);
    } on PortfolioException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Chưa thể xóa hồ sơ. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _record(Position position, PortfolioAction action) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PortfolioActionPage(
          store: widget.store,
          position: position,
          action: action,
        ),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu thay đổi')));
    }
  }

  Future<void> _edit(Position position) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _EditPositionDialog(store: widget.store, position: position),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ')));
    }
  }

  Future<void> _openDocument(String reference) async {
    try {
      await LocalDocuments.open(reference);
    } on LocalDocumentException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  List<PortfolioAction> _actions(Position position) {
    if (position.kind == AssetKind.debt) {
      return [if (!position.closed) PortfolioAction.debtPayment];
    }
    return [
      if (position.kind.isQuantityBased) PortfolioAction.buy,
      if (position.kind.isQuantityBased && !position.closed)
        PortfolioAction.sell,
      if (position.kind == AssetKind.deposit && !position.closed)
        PortfolioAction.redeemDeposit,
      if (!position.closed) PortfolioAction.value,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final position = widget.store.position(widget.positionId);
        if (position == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Hồ sơ không còn trong danh mục.')),
          );
        }
        final kind = position.kind;
        final debt = kind == AssetKind.debt;
        final money = PortfolioAmounts.formatVnd;
        final activities =
            widget.store.activity
                .where((event) => event.positionId == position.id)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        final actions = _actions(position);
        final details = _details(position);
        return Scaffold(
          appBar: AppBar(
            title: Text(kind.label),
            actions: [
              IconButton(
                tooltip: 'Sửa hồ sơ',
                onPressed: _deleting ? null : () => _edit(position),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Xóa hồ sơ',
                onPressed: _deleting ? null : () => _delete(position),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
              children: [
                Text(
                  position.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                PortfolioSummaryCard(
                  label: debt
                      ? 'Dư nợ gốc hiện tại'
                      : kind == AssetKind.realEstate
                      ? 'Giá trị phần sở hữu'
                      : kind.currentLabel ?? 'Giá trị hiện tại',
                  amount: position.marketValue,
                  icon: kind.icon,
                  rows: {
                    if (position.symbol.isNotEmpty)
                      'Mã tài sản': position.symbol,
                    if (kind.isQuantityBased)
                      'Số lượng nắm giữ':
                          '${position.quantity} ${position.details['unit'] ?? kind.unitLabel}'
                              .trim(),
                    kind.costLabel: money(position.cost),
                    if (!debt)
                      'Lãi / lỗ chưa thực hiện': money(position.profit),
                    if (debt)
                      'Gốc đã trả': money(position.cost - position.marketValue),
                    kind.startLabel: portfolioDate(
                      context,
                      position.acquiredAt,
                    ),
                    'Cập nhật gần nhất': portfolioDate(
                      context,
                      position.updatedAt,
                    ),
                  },
                ),
                if (_error case final message?)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final action in actions)
                          OutlinedButton(
                            onPressed: () => _record(position, action),
                            child: Text(action.label),
                          ),
                      ],
                    ),
                  ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  PortfolioSection(
                    title: 'Thông tin chi tiết',
                    children: [
                      Card(
                        child: Column(
                          children: [
                            for (final item in details.entries)
                              ListTile(
                                dense: true,
                                title: Text(item.key),
                                subtitle: Text(item.value),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (LocalDocuments.available &&
                    position.details.containsKey('attachmentUri'))
                  PortfolioSection(
                    title: 'Chứng từ',
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openDocument(position.details['attachmentUri']!),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Mở tệp'),
                      ),
                    ],
                  ),
                if (activities.isNotEmpty)
                  PortfolioSection(
                    title: 'Lịch sử',
                    children: [
                      for (final activity in activities)
                        Card(
                          child: ListTile(
                            title: Text(activity.type.label),
                            subtitle: Text(
                              [
                                portfolioDate(context, activity.date),
                                if (activity.note.isNotEmpty) activity.note,
                                if (activity.realizedProfit case final profit?)
                                  'Lãi / lỗ thực hiện ${money(profit)}',
                              ].join(' · '),
                            ),
                            trailing: Text(money(activity.amount)),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, String> _details(Position position) {
    final rows = <String, String>{};
    final fields = portfolioFields[position.kind]!.expand(
      (group) => group.fields,
    );
    for (final field in fields) {
      final value = position.details[field.key];
      if (value == null || value.isEmpty) continue;
      rows[field.label] = switch (field.type) {
        PortfolioFieldType.date => switch (DateTime.tryParse(value)) {
          final date? => portfolioDate(context, date),
          null => value,
        },
        PortfolioFieldType.money => PortfolioAmounts.formatVnd(
          int.tryParse(value) ?? 0,
        ),
        _ => value,
      };
    }
    if (position.details['assetId'] case final id?) {
      if (widget.store.position(id) case final asset?) {
        rows['Tài sản liên quan'] = asset.name;
      }
    }
    if (position.details['fullMarketValue'] case final value?) {
      rows['Định giá toàn bộ khi ghi nhận'] = PortfolioAmounts.formatVnd(
        int.tryParse(value) ?? 0,
      );
    }
    if (position.details['currency'] case final currency?) {
      if (position.details['conversionRate'] case final rate?) {
        rows['Đơn vị thanh toán'] =
            '$currency · ${rate.replaceAll('.', ',')} VND / $currency';
      }
    }
    if (position.details['attachmentReference'] case final reference?) {
      rows['Tham chiếu chứng từ'] = reference;
    }
    if (position.details['note'] case final note?) rows['Ghi chú'] = note;
    return rows;
  }
}

class _EditPositionDialog extends StatefulWidget {
  const _EditPositionDialog({required this.store, required this.position});

  final PortfolioStore store;
  final Position position;

  @override
  State<_EditPositionDialog> createState() => _EditPositionDialogState();
}

class _EditPositionDialogState extends State<_EditPositionDialog> {
  final _form = GlobalKey<FormState>();
  late String _name = widget.position.name;
  late String _note = widget.position.details['note'] ?? '';
  late String _reference = widget.position.details['attachmentReference'] ?? '';
  late DateTime? _dueDate = DateTime.tryParse(
    widget.position.details['dueDate'] ?? '',
  );
  String? _error;
  bool _saving = false;

  PortfolioField? get _dueField => portfolioFields[widget.position.kind]!
      .expand((group) => group.fields)
      .where((field) => field.key == 'dueDate')
      .firstOrNull;

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_dueField?.required == true &&
        _dueDate != null &&
        !_dueDate!.isAfter(widget.position.acquiredAt)) {
      setState(() => _error = 'Ngày đáo hạn phải sau ngày ghi nhận.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.updatePositionMetadata(
        positionId: widget.position.id,
        name: _name,
        details: {
          'note': _note,
          'attachmentReference': _reference,
          if (_dueField != null)
            'dueDate': _dueDate == null ? '' : dateInputValue(_dueDate!),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on PortfolioException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Chưa thể lưu hồ sơ. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = _dueField;
    return AlertDialog(
      title: const Text('Sửa thông tin hồ sơ'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Tên hồ sơ'),
                onChanged: (name) => _name = name,
                validator: (name) =>
                    (name ?? '').trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              if (due != null) ...[
                const SizedBox(height: 12),
                PortfolioDateInput(
                  label: due.label,
                  value: _dueDate,
                  required: due.required,
                  onChanged: (date) => setState(() => _dueDate = date),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                onChanged: (note) => _note = note,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _reference,
                decoration: const InputDecoration(
                  labelText: 'Tham chiếu chứng từ',
                ),
                onChanged: (reference) => _reference = reference,
              ),
              if (_error case final message?) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Lưu hồ sơ'),
        ),
      ],
    );
  }
}
