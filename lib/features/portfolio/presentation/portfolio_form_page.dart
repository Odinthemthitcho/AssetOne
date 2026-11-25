import 'package:flutter/material.dart';

import '../../../core/attachments/local_documents.dart';
import '../data/portfolio_store.dart';
import '../domain/portfolio_models.dart';
import 'portfolio_fields.dart';
import 'portfolio_inputs.dart';

class PortfolioFormPage extends StatefulWidget {
  const PortfolioFormPage({super.key, required this.store, required this.kind});

  final PortfolioStore store;
  final AssetKind kind;

  @override
  State<PortfolioFormPage> createState() => _PortfolioFormPageState();
}

class _PortfolioFormPageState extends State<PortfolioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, String>{};
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String? _account;
  LocalDocument? _document;
  bool _selectingDocument = false;
  bool _saving = false;
  String? _error;

  AssetKind get kind => widget.kind;
  List<PortfolioFieldGroup> get groups => portfolioFields[kind]!;
  bool get _quantified => kind.isQuantityBased;
  String _value(String key) => _values[key]?.trim() ?? '';
  int _money(String key) => PortfolioAmounts.parseVnd(_value(key)) ?? 0;
  String? _decimal(String key) => PortfolioAmounts.parseDecimal(_value(key));
  DateTime? _storedDate(String key) => DateTime.tryParse(_value(key));
  String get _currency => _values['currency'] ?? 'VND';
  String get _operation => _values['operation'] ?? 'Đã sở hữu';
  bool get _newPurchase => _operation == 'Mua' || _operation == 'Gửi tiền';
  bool get _usesFinancing => _value('hasDebt') == 'Có';
  bool get _isRealEstate => kind == AssetKind.realEstate;
  bool get _canUseCash =>
      kind != AssetKind.debt &&
      kind != AssetKind.insurance &&
      kind != AssetKind.retirement;
  bool get _canHaveFees =>
      kind != AssetKind.debt &&
      kind != AssetKind.deposit &&
      kind != AssetKind.insurance &&
      kind != AssetKind.retirement;
  bool get _costCanBeZero =>
      kind == AssetKind.insurance ||
      kind == AssetKind.retirement ||
      (!_newPurchase && _quantified);

  String get _unit => kind == AssetKind.metal
      ? _value('unit')
      : (kind.unitLabel.isEmpty
            ? _value('symbol').toUpperCase()
            : kind.unitLabel);

  void _selectDepositTerm(String? term) {
    if (term == null) return;
    final months = int.tryParse(term.split(' ').first);
    if (months == null) return;
    final lastDay = DateTime(_date.year, _date.month + months + 1, 0);
    final day = _date.day < lastDay.day ? _date.day : lastDay.day;
    _values['dueDate'] = dateInputValue(
      DateTime(lastDay.year, lastDay.month, day),
    );
  }

  void _set(String key, String? value) {
    setState(() {
      if (value == null) {
        _values.remove(key);
      } else {
        _values[key] = value;
      }
      if (kind == AssetKind.deposit) {
        if (key == 'term') _selectDepositTerm(value);
        if (key == 'dueDate') _values.remove('term');
      }
      _error = null;
    });
  }

  int _sourceVnd(String key) {
    if (_currency == 'VND') return _money(key);
    return PortfolioAmounts.product(
      _decimal(key) ?? '0',
      _decimal('conversionRate') ?? '0',
    );
  }

  int get _tradeAmount {
    if (!_quantified) return _sourceVnd('cost');
    final quantity = _decimal('quantity') ?? '0';
    if (_currency == 'VND') {
      return PortfolioAmounts.product(quantity, _money('unitPrice').toString());
    }
    return PortfolioAmounts.product(
      quantity,
      _decimal('unitPrice') ?? '0',
      _decimal('conversionRate') ?? '0',
    );
  }

  int get _cost => _tradeAmount + _money('fee') + _money('tax');

  int _ownedShare(int total) => _isRealEstate
      ? PortfolioAmounts.ownedShare(
          total,
          _decimal('ownershipPercent') ?? '100',
        )
      : total;

  int get _current {
    if (kind == AssetKind.deposit) return _cost;
    if (kind == AssetKind.insurance) return _sourceVnd('current');
    return _value('current').isEmpty ? _tradeAmount : _sourceVnd('current');
  }

  int get _depositInterest {
    final end = _storedDate('dueDate');
    final rate = _decimal('annualRate');
    if (end == null || rate == null) return 0;
    final startDay = DateTime.utc(_date.year, _date.month, _date.day);
    final endDay = DateTime.utc(end.year, end.month, end.day);
    final dayCount = endDay.difference(startDay).inDays;
    if (dayCount <= 0) return 0;
    return PortfolioAmounts.simpleInterest(_cost, rate, dayCount);
  }

  Widget _text(
    String key,
    String label, {
    PortfolioFieldType type = PortfolioFieldType.text,
    bool required = false,
    bool positive = false,
    String? suffix,
    String? hint,
  }) {
    return TextFormField(
      key: ValueKey(key),
      initialValue: _values[key],
      keyboardType: portfolioKeyboard(type),
      textInputAction: type == PortfolioFieldType.note
          ? TextInputAction.newline
          : TextInputAction.next,
      minLines: type == PortfolioFieldType.note ? 2 : 1,
      maxLines: type == PortfolioFieldType.note ? 4 : 1,
      textCapitalization: key == 'symbol'
          ? TextCapitalization.characters
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        hintText: hint,
      ),
      validator: (text) {
        final error = validatePortfolioText(
          text,
          type,
          required: required,
          positive: positive,
        );
        if (error != null) return error;
        if (key == 'ownershipPercent') {
          if (_decimal(key) case final percent?) {
            final portion = PortfolioDecimal.parse(percent);
            if (!portion.isPositive ||
                portion.compareTo(PortfolioDecimal.parse('100')) > 0) {
              return 'Nhập tỷ lệ lớn hơn 0% và tối đa 100%';
            }
          }
        }
        return null;
      },
      onChanged: (text) => _set(key, text),
    );
  }

  Widget _options(
    String key,
    String label,
    List<String> options, {
    bool required = false,
    bool wrap = false,
    String? initialValue,
  }) {
    final current = _values[key] ?? initialValue;
    if (!wrap) {
      return DropdownButtonFormField<String>(
        key: ValueKey(key),
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        validator: (selected) =>
            required && selected == null ? 'Vui lòng chọn một mục' : null,
        onChanged: (selected) => _set(key, selected),
      );
    }
    return FormField<String>(
      key: ValueKey(key),
      initialValue: current,
      validator: (_) =>
          required && current == null ? 'Vui lòng chọn một mục' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: current == option,
                  onSelected: (selected) {
                    final next = selected
                        ? option
                        : (required ? current : null);
                    field.didChange(next);
                    _set(key, next);
                  },
                ),
            ],
          ),
          if (field.errorText case final message?)
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  Widget _extra(PortfolioField spec) => switch (spec.type) {
    PortfolioFieldType.date => PortfolioDateInput(
      key: ValueKey(spec.key),
      label: spec.label,
      required: spec.required,
      value: _storedDate(spec.key),
      onChanged: (date) =>
          _set(spec.key, date == null ? null : dateInputValue(date)),
    ),
    PortfolioFieldType.choice || PortfolioFieldType.chips => _options(
      spec.key,
      spec.label,
      spec.choices,
      required: spec.required,
      wrap: spec.type == PortfolioFieldType.chips,
    ),
    PortfolioFieldType.toggle => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(spec.label),
      value: _value(spec.key) == 'Có',
      onChanged: (enabled) => _set(spec.key, enabled ? 'Có' : null),
    ),
    _ => _text(
      spec.key,
      spec.label,
      type: spec.type,
      required: spec.required,
      suffix: spec.type == PortfolioFieldType.money ? '₫' : null,
      hint: spec.key == 'ownershipPercent' ? '100% nếu bỏ trống' : null,
    ),
  };

  List<String> get _operations => [
    'Đã sở hữu',
    if (kind == AssetKind.deposit) 'Gửi tiền' else if (_canUseCash) 'Mua',
    if (kind == AssetKind.foreignCurrency) 'Nhận',
    if (kind == AssetKind.crypto || kind == AssetKind.foreignCurrency)
      'Chuyển vào',
    if (kind == AssetKind.crypto) ...['Airdrop', 'Staking Reward'],
  ];

  String? _dateError() {
    if (_date.isAfter(DateUtils.dateOnly(DateTime.now()))) {
      return '${kind.startLabel} phải là hôm nay hoặc một ngày trước đó.';
    }
    final issueDate = _storedDate('issueDate');
    if (issueDate != null && issueDate.isAfter(_date)) {
      return 'Ngày phát hành phải trước hoặc trùng ngày giao dịch.';
    }
    for (final key in [
      if (kind == AssetKind.deposit || kind == AssetKind.bond) 'dueDate',
      'maturityDate',
      'firstPayment',
      'nextPayment',
    ]) {
      final date = _storedDate(key);
      if (date != null && !date.isAfter(_date)) {
        final label = groups
            .expand((group) => group.fields)
            .firstWhere((field) => field.key == key)
            .label;
        return '$label phải sau ${kind.startLabel.toLowerCase()}.';
      }
    }
    if (kind == AssetKind.insurance &&
        (_storedDate('birthDate')?.isAfter(_date) ?? false)) {
      return 'Ngày sinh phải trước hoặc trùng ngày hiệu lực.';
    }
    return null;
  }

  Map<String, String> _details() {
    final values = <String, String>{};
    for (final spec in groups.expand((group) => group.fields)) {
      final raw = _value(spec.key);
      if (!spec.isVisible(_values) || raw.isEmpty) continue;
      values[spec.key] = switch (spec.type) {
        PortfolioFieldType.money => _money(spec.key).toString(),
        PortfolioFieldType.decimal => _decimal(spec.key)!,
        _ => raw,
      };
    }
    if (values['dueDate'] == null) {
      if (values['maturityDate'] case final maturity?) {
        values['dueDate'] = maturity;
      }
    }
    if (_value('note').isNotEmpty) values['note'] = _value('note');
    if (_document case final document?) {
      values['attachmentReference'] = document.name;
      values['attachmentUri'] = document.reference;
    } else if (_value('attachmentReference').isNotEmpty) {
      values['attachmentReference'] = _value('attachmentReference');
    }
    if (_currency != 'VND') {
      values['currency'] = _currency;
      values['conversionRate'] = _decimal('conversionRate')!;
      if (_quantified) values['originalUnitPrice'] = _decimal('unitPrice')!;
    }
    return values;
  }

  int get _attachmentLimit => switch (kind) {
    AssetKind.deposit || AssetKind.retirement => 15,
    AssetKind.insurance || AssetKind.other || AssetKind.debt => 25,
    _ => 10,
  };

  Future<void> _pickDocument() async {
    if (_selectingDocument || _saving) return;
    setState(() {
      _selectingDocument = true;
      _error = null;
    });
    try {
      final file = await LocalDocuments.pick(
        maxBytes: _attachmentLimit * 1024 * 1024,
      );
      if (file != null && mounted) setState(() => _document = file);
    } on LocalDocumentException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _selectingDocument = false);
    }
  }

  Widget _documentInput() {
    final document = _document;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document?.name ?? 'Đính kèm chứng từ (tùy chọn)'),
            const SizedBox(height: 4),
            Text('PDF, PNG hoặc JPG, tối đa $_attachmentLimit MB'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _selectingDocument ? null : _pickDocument,
                  icon: const Icon(Icons.attach_file),
                  label: Text(document == null ? 'Chọn tệp' : 'Đổi tệp'),
                ),
                if (document != null)
                  TextButton(
                    onPressed: _selectingDocument
                        ? null
                        : () => setState(() => _document = null),
                    child: const Text('Bỏ tệp'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PositionFinancing? _financing() {
    if (!_usesFinancing) return null;
    return PositionFinancing(
      lender: _value('lender'),
      originalPrincipal: _money('originalPrincipal'),
      outstandingPrincipal: _money('outstandingPrincipal'),
      details: {
        'institution': _value('lender'),
        'annualRate': ?_decimal('loanRate'),
        if (_value('loanPayment').isNotEmpty)
          'payment': _money('loanPayment').toString(),
        if (_value('loanDueDate').isNotEmpty) 'dueDate': _value('loanDueDate'),
      },
    );
  }

  Future<void> _save() async {
    if (_saving || _selectingDocument) return;
    if (!_formKey.currentState!.validate()) {
      setState(
        () => _error = 'Kiểm tra các trường bắt buộc đang được đánh dấu.',
      );
      return;
    }
    final dateError = _dateError();
    if (dateError != null) {
      setState(() => _error = dateError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final symbol = _value('symbol').toUpperCase();
      final name = _value('name').isEmpty ? symbol : _value('name');
      final details = _details();
      final account = _newPurchase && !_usesFinancing ? _account : null;
      await widget.store.createPosition(
        kind: kind,
        name: name,
        symbol: symbol,
        quantity: _quantified ? _decimal('quantity')! : '1',
        cost: _cost,
        marketValue: _current,
        accountId: account,
        date: _date,
        details: details,
        debitAccount: account != null,
        operationLabel: _operations.length > 1 ? _operation : '',
        financing: _financing(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on PortfolioException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Chưa thể lưu tài sản. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceType = _currency == 'VND'
        ? PortfolioFieldType.money
        : PortfolioFieldType.decimal;
    final isDebt = kind == AssetKind.debt;
    final amountText = _quantified
        ? kind.unitPriceLabel
        : _isRealEstate
        ? 'Giá mua toàn bộ bất động sản'
        : kind.costLabel;
    return Scaffold(
      appBar: AppBar(title: Text('Thêm ${kind.label}')),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PortfolioSection(
                      title: 'Thông tin ${kind.label}',
                      children: [
                        if (kind.symbolLabel case final label?)
                          _text('symbol', label, required: true),
                        _text(
                          'name',
                          kind.nameLabel,
                          required: kind.symbolLabel == null,
                        ),
                        if (_operations.length > 1)
                          _options(
                            'operation',
                            'Loại giao dịch',
                            _operations,
                            initialValue: _operation,
                            required: true,
                            wrap: true,
                          ),
                      ],
                    ),
                    for (final group in groups)
                      PortfolioSection(
                        title: group.title,
                        children: [
                          for (final spec in group.fields)
                            if (spec.isVisible(_values)) _extra(spec),
                        ],
                      ),
                    PortfolioSection(
                      title: isDebt
                          ? 'Thông tin khoản vay'
                          : 'Giá trị và giao dịch',
                      children: [
                        PortfolioDateInput(
                          label: kind.startLabel,
                          required: true,
                          value: _date,
                          onChanged: (date) => setState(() {
                            _date = date!;
                            if (kind == AssetKind.deposit) {
                              _selectDepositTerm(_values['term']);
                            }
                            _error = null;
                          }),
                        ),
                        if (_quantified)
                          _text(
                            'quantity',
                            'Số lượng',
                            type: PortfolioFieldType.decimal,
                            required: true,
                            positive: true,
                            suffix: _unit.isEmpty ? null : _unit,
                          ),
                        if (kind == AssetKind.crypto || kind == AssetKind.other)
                          _options(
                            'currency',
                            'Đơn vị tiền thanh toán',
                            kind == AssetKind.crypto
                                ? ['VND', 'USDT', 'USD']
                                : ['VND', 'USD', 'EUR'],
                            initialValue: _currency,
                            required: true,
                            wrap: true,
                          ),
                        if (_currency != 'VND')
                          _text(
                            'conversionRate',
                            'Tỷ giá quy đổi sang VND',
                            type: PortfolioFieldType.decimal,
                            required: true,
                            positive: true,
                            suffix: 'VND / $_currency',
                          ),
                        _text(
                          _quantified ? 'unitPrice' : 'cost',
                          amountText,
                          type: sourceType,
                          required: !_costCanBeZero || _quantified,
                          positive: !_costCanBeZero,
                          suffix: _currency == 'VND' ? '₫' : _currency,
                        ),
                        if (_canHaveFees)
                          _text(
                            'fee',
                            kind == AssetKind.crypto
                                ? 'Phí mạng lưới / sàn giao dịch'
                                : 'Phí giao dịch / chi phí phát sinh',
                            type: PortfolioFieldType.money,
                            suffix: '₫',
                          ),
                        if (_quantified && kind != AssetKind.crypto)
                          _text(
                            'tax',
                            'Thuế & phí khác',
                            type: PortfolioFieldType.money,
                            suffix: '₫',
                          ),
                        if (kind.currentLabel case final label?)
                          _text(
                            'current',
                            _isRealEstate
                                ? 'Định giá toàn bộ bất động sản'
                                : label,
                            type: sourceType,
                            required: isDebt || kind == AssetKind.retirement,
                            suffix: _currency == 'VND' ? '₫' : _currency,
                          ),
                        if (_newPurchase &&
                            !_usesFinancing &&
                            widget.store.accounts.isNotEmpty)
                          PortfolioAccountInput(
                            accounts: widget.store.accounts,
                            value: _account,
                            label: 'Trừ tiền từ tài khoản',
                            onChanged: (account) => setState(() {
                              _account = account;
                              _error = null;
                            }),
                          ),
                      ],
                    ),
                    _summary(),
                    const SizedBox(height: 24),
                    PortfolioSection(
                      title: 'Ghi chú và chứng từ',
                      children: [
                        _text(
                          'note',
                          'Ghi chú (tùy chọn)',
                          type: PortfolioFieldType.note,
                        ),
                        if (LocalDocuments.available)
                          _documentInput()
                        else
                          _text(
                            'attachmentReference',
                            'Tham chiếu chứng từ (tùy chọn)',
                            hint: 'Ví dụ: số hợp đồng hoặc biên lai',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error case final message?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _saving || _selectingDocument ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text('Thêm ${kind.label}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    final isDebt = kind == AssetKind.debt;
    final isDeposit = kind == AssetKind.deposit;
    try {
      final formatter = PortfolioAmounts.formatVnd;
      return PortfolioSummaryCard(
        label: isDebt
            ? 'Dư nợ hiện tại'
            : isDeposit
            ? 'Giá trị đáo hạn dự kiến'
            : 'Tổng vốn đầu tư',
        amount: isDebt
            ? _current
            : isDeposit
            ? _cost + _depositInterest
            : _ownedShare(_cost),
        rows: {
          if (_quantified)
            'Số lượng':
                '${_value('quantity').isEmpty ? '0' : _value('quantity')} $_unit'
                    .trim(),
          if (_quantified) 'Giá trị giao dịch': formatter(_tradeAmount),
          if (_canHaveFees)
            'Tổng phí và thuế': formatter(_money('fee') + _money('tax')),
          if (_isRealEstate)
            'Giá trị phần sở hữu': formatter(_ownedShare(_current))
          else if (!isDeposit && !isDebt)
            kind.currentLabel!: formatter(_current),
          if (isDebt) 'Gốc vay ban đầu': formatter(_cost),
          if (isDeposit) 'Gốc tiền gửi': formatter(_cost),
          if (isDeposit)
            'Lãi dự kiến (365 ngày / năm)': formatter(_depositInterest),
        },
      );
    } on FormatException catch (error) {
      return Text(error.message);
    }
  }
}
