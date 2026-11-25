import 'package:flutter/material.dart';

import '../data/portfolio_store.dart';
import '../domain/portfolio_models.dart';
import 'portfolio_inputs.dart';
import 'portfolio_fields.dart';

enum PortfolioAction {
  buy('Mua thêm'),
  sell('Bán'),
  value('Cập nhật định giá'),
  debtPayment('Ghi nhận trả nợ'),
  redeemDeposit('Tất toán tiền gửi');

  const PortfolioAction(this.label);

  final String label;
}

class PortfolioActionPage extends StatefulWidget {
  const PortfolioActionPage({
    super.key,
    required this.store,
    required this.position,
    required this.action,
  });

  final PortfolioStore store;
  final Position position;
  final PortfolioAction action;

  @override
  State<PortfolioActionPage> createState() => _PortfolioActionPageState();
}

class _PortfolioActionPageState extends State<PortfolioActionPage> {
  final _form = GlobalKey<FormState>();
  final _values = <String, String>{};
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String? _account;
  bool _saving = false;
  String? _error;

  PortfolioAction get action => widget.action;
  Position get position => widget.position;
  bool get _trade =>
      action == PortfolioAction.buy || action == PortfolioAction.sell;
  int _vnd(String key) => PortfolioAmounts.parseVnd(_values[key] ?? '') ?? 0;
  String _decimal(String key) =>
      PortfolioAmounts.parseDecimal(_values[key] ?? '') ?? '0';

  Widget _text(
    String key,
    String label,
    PortfolioFieldType type, {
    bool required = false,
    bool positive = false,
  }) {
    return TextFormField(
      key: ValueKey(key),
      decoration: InputDecoration(
        labelText: label,
        suffixText: type == PortfolioFieldType.money ? '₫' : null,
      ),
      keyboardType: portfolioKeyboard(type),
      textInputAction: TextInputAction.next,
      validator: (value) => validatePortfolioText(
        value,
        type,
        required: required,
        positive: positive,
      ),
      onChanged: (value) => setState(() {
        _values[key] = value;
        _error = null;
      }),
    );
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_date.isAfter(DateUtils.dateOnly(DateTime.now()))) {
      setState(() => _error = 'Ngày ghi nhận không được ở trong tương lai.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = _values['note']?.trim() ?? '';
      switch (action) {
        case PortfolioAction.buy:
        case PortfolioAction.sell:
          await widget.store.trade(
            positionId: position.id,
            buy: action == PortfolioAction.buy,
            quantity: _decimal('qty'),
            unitPrice: _vnd('price').toString(),
            fee: _vnd('fee'),
            accountId: _account,
            date: _date,
            note: note,
          );
        case PortfolioAction.value:
          await widget.store.revalue(
            positionId: position.id,
            marketValue: _vnd('value'),
            date: _date,
          );
        case PortfolioAction.debtPayment:
          await widget.store.payDebt(
            positionId: position.id,
            principal: _vnd('principal'),
            interest: _vnd('interest'),
            fee: _vnd('fee'),
            accountId: _account,
            date: _date,
            note: note,
          );
        case PortfolioAction.redeemDeposit:
          await widget.store.redeemDeposit(
            positionId: position.id,
            interest: _vnd('interest'),
            accountId: _account,
            date: _date,
            note: note,
          );
      }
      if (mounted) Navigator.pop(context, true);
    } on PortfolioException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Chưa thể lưu giao dịch. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const money = PortfolioFieldType.money;
    return Scaffold(
      appBar: AppBar(title: Text(action.label)),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PortfolioSummaryCard(
                      label: position.name,
                      amount: position.marketValue,
                      icon: position.kind.icon,
                      rows: {if (_trade) 'Số lượng nắm giữ': position.quantity},
                    ),
                    const SizedBox(height: 20),
                    PortfolioSection(
                      title: action.label,
                      children: [
                        PortfolioDateInput(
                          label: 'Ngày ghi nhận',
                          value: _date,
                          required: true,
                          onChanged: (date) => setState(() {
                            _date = date!;
                            _error = null;
                          }),
                        ),
                        if (_trade) ...[
                          _text(
                            'qty',
                            'Số lượng',
                            PortfolioFieldType.decimal,
                            required: true,
                            positive: true,
                          ),
                          _text(
                            'price',
                            'Đơn giá (VND)',
                            money,
                            required: true,
                            positive: true,
                          ),
                          _text('fee', 'Tổng phí và thuế', money),
                        ],
                        if (action == PortfolioAction.value)
                          _text(
                            'value',
                            position.kind == AssetKind.realEstate
                                ? 'Giá trị phần sở hữu (VND)'
                                : 'Tổng định giá mới (VND)',
                            money,
                            required: true,
                          ),
                        if (action == PortfolioAction.debtPayment) ...[
                          _text(
                            'principal',
                            'Tiền gốc đã trả',
                            money,
                            required: true,
                          ),
                          _text('interest', 'Tiền lãi đã trả', money),
                          _text('fee', 'Phí thanh toán', money),
                        ],
                        if (action == PortfolioAction.redeemDeposit)
                          _text('interest', 'Lãi thực nhận', money),
                        if (action != PortfolioAction.value &&
                            widget.store.accounts.isNotEmpty)
                          PortfolioAccountInput(
                            accounts: widget.store.accounts,
                            value: _account,
                            label:
                                action == PortfolioAction.sell ||
                                    action == PortfolioAction.redeemDeposit
                                ? 'Nhận tiền vào tài khoản'
                                : 'Trừ tiền từ tài khoản',
                            onChanged: (account) => setState(() {
                              _account = account;
                              _error = null;
                            }),
                          ),
                        if (action != PortfolioAction.value)
                          _text(
                            'note',
                            'Ghi chú (tùy chọn)',
                            PortfolioFieldType.note,
                          ),
                      ],
                    ),
                    if (_trade ||
                        action == PortfolioAction.debtPayment ||
                        action == PortfolioAction.redeemDeposit)
                      _summary(),
                    if (_error case final message?)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          message,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
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
          child: SizedBox(
            width: 620,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu giao dịch'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    try {
      if (action == PortfolioAction.redeemDeposit) {
        return PortfolioSummaryCard(
          label: 'Tổng tiền nhận',
          amount: position.cost + _vnd('interest'),
          rows: {'Gốc tiền gửi': PortfolioAmounts.formatVnd(position.cost)},
        );
      }
      if (action == PortfolioAction.debtPayment) {
        return PortfolioSummaryCard(
          label: 'Tổng tiền trả',
          amount: _vnd('principal') + _vnd('interest') + _vnd('fee'),
          rows: {
            'Dư nợ sau khi trả': PortfolioAmounts.formatVnd(
              position.marketValue - _vnd('principal'),
            ),
          },
        );
      }
      final gross = PortfolioAmounts.product(
        _decimal('qty'),
        _vnd('price').toString(),
      );
      final fees = _vnd('fee');
      final buy = action == PortfolioAction.buy;
      return PortfolioSummaryCard(
        label: buy ? 'Tổng tiền mua' : 'Tiền bán sau phí',
        amount: buy ? gross + fees : gross - fees,
        rows: {
          'Giá trị giao dịch': PortfolioAmounts.formatVnd(gross),
          'Tổng phí và thuế': PortfolioAmounts.formatVnd(fees),
        },
      );
    } on FormatException {
      return const SizedBox.shrink();
    }
  }
}
