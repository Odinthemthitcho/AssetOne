import 'package:flutter/material.dart';

import '../domain/portfolio_models.dart';
import 'portfolio_fields.dart';

String dateInputValue(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String portfolioDate(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatCompactDate(date);

Future<DateTime?> pickPortfolioDate(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900),
    lastDate: DateTime(2200, 12, 31),
  );
}

class PortfolioDateInput extends StatelessWidget {
  const PortfolioDateInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      validator: (_) => required && value == null ? 'Vui lòng chọn ngày' : null,
      builder: (field) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: field.errorText,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          suffixIcon: !required && value != null
              ? IconButton(
                  tooltip: 'Bỏ ngày',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    field.didChange(null);
                    onChanged(null);
                  },
                )
              : null,
        ),
        child: InkWell(
          onTap: () async {
            final next = await pickPortfolioDate(
              context,
              initialDate: value ?? DateTime.now(),
            );
            if (next == null || !context.mounted) return;
            field.didChange(next);
            onChanged(next);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              value == null ? 'Chọn ngày' : portfolioDate(context, value!),
            ),
          ),
        ),
      ),
    );
  }
}

class PortfolioAccountInput extends StatelessWidget {
  const PortfolioAccountInput({
    super.key,
    required this.accounts,
    required this.value,
    required this.onChanged,
    this.label = 'Tài khoản tiền (tùy chọn)',
  });

  final List<CashAccount> accounts;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: accounts.any((account) => account.id == value) ? value : '',
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('Không dùng tài khoản tiền'),
        ),
        for (final account in accounts)
          DropdownMenuItem(
            value: account.id,
            child: Text(
              '${account.name} · ${PortfolioAmounts.formatVnd(account.balance)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) => onChanged(id == '' ? null : id),
    );
  }
}

class PortfolioSection extends StatelessWidget {
  const PortfolioSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < children.length; index++) ...[
            if (index != 0) const SizedBox(height: 12),
            children[index],
          ],
        ],
      ),
    );
  }
}

class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    this.rows = const {},
    this.icon = Icons.receipt_long_outlined,
  });

  final String label;
  final int amount;
  final Map<String, String> rows;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              PortfolioAmounts.formatVnd(amount),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (rows.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              for (final detail in rows.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          detail.key,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(detail.value, textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

TextInputType portfolioKeyboard(PortfolioFieldType type) => switch (type) {
  PortfolioFieldType.money => TextInputType.number,
  PortfolioFieldType.decimal => const TextInputType.numberWithOptions(
    decimal: true,
  ),
  PortfolioFieldType.note => TextInputType.multiline,
  _ => TextInputType.text,
};

String? validatePortfolioText(
  String? input,
  PortfolioFieldType type, {
  bool required = false,
  bool positive = false,
}) {
  final text = (input ?? '').trim();
  if (text.isEmpty) return required ? 'Vui lòng nhập thông tin' : null;
  if (type == PortfolioFieldType.money) {
    final amount = PortfolioAmounts.parseVnd(text);
    if (amount == null || amount < 0 || (positive && amount == 0)) {
      return positive
          ? 'Nhập số tiền VND lớn hơn 0'
          : 'Nhập số tiền VND từ 0 trở lên';
    }
  }
  if (type == PortfolioFieldType.decimal) {
    final amount = PortfolioAmounts.parseDecimal(text);
    if (amount == null ||
        amount.startsWith('-') ||
        (positive && amount == '0')) {
      return positive ? 'Nhập một số lớn hơn 0' : 'Nhập một số từ 0 trở lên';
    }
  }
  return null;
}
