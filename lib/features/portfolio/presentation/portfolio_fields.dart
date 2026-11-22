import 'package:flutter/material.dart';

import '../domain/portfolio_models.dart';

extension PortfolioKindPresentation on AssetKind {
  IconData get icon => switch (this) {
    AssetKind.stock => Icons.candlestick_chart_outlined,
    AssetKind.etf => Icons.pie_chart_outline,
    AssetKind.bond => Icons.description_outlined,
    AssetKind.fund => Icons.hub_outlined,
    AssetKind.crypto => Icons.currency_bitcoin,
    AssetKind.realEstate => Icons.apartment,
    AssetKind.deposit => Icons.account_balance_outlined,
    AssetKind.foreignCurrency => Icons.currency_exchange,
    AssetKind.metal => Icons.diamond_outlined,
    AssetKind.vehicle => Icons.directions_car_outlined,
    AssetKind.retirement => Icons.elderly,
    AssetKind.insurance => Icons.shield_outlined,
    AssetKind.other => Icons.inventory_2_outlined,
    AssetKind.debt => Icons.credit_card,
  };

  String? get symbolLabel => switch (this) {
    AssetKind.stock => 'Mã cổ phiếu',
    AssetKind.etf => 'Mã ETF',
    AssetKind.bond => 'Mã trái phiếu',
    AssetKind.fund => 'Mã quỹ',
    AssetKind.crypto => 'Mã coin / token',
    AssetKind.foreignCurrency => 'Mã ngoại tệ',
    _ => null,
  };

  String get nameLabel => switch (this) {
    AssetKind.realEstate => 'Tên bất động sản',
    AssetKind.deposit => 'Tên khoản tiền gửi',
    AssetKind.metal => 'Tên vàng / kim loại',
    AssetKind.vehicle => 'Model dòng xe',
    AssetKind.retirement => 'Tên chương trình hưu trí',
    AssetKind.insurance => 'Tên hợp đồng',
    AssetKind.debt => 'Tên khoản vay',
    _ => 'Tên tài sản',
  };

  String get unitLabel => switch (this) {
    AssetKind.stock => 'CP',
    AssetKind.etf || AssetKind.fund => 'CCQ',
    AssetKind.bond => 'Trái phiếu',
    _ => '',
  };

  String get unitPriceLabel => switch (this) {
    AssetKind.stock => 'Giá mua mỗi cổ phiếu',
    AssetKind.etf => 'Giá mua mỗi CCQ',
    AssetKind.bond => 'Giá mua thực tế mỗi trái phiếu',
    AssetKind.fund => 'NAV mua mỗi CCQ',
    AssetKind.crypto => 'Giá mua mỗi coin',
    AssetKind.foreignCurrency => 'Tỷ giá mua thực tế',
    AssetKind.metal => 'Giá mua mỗi đơn vị',
    _ => 'Giá mua',
  };

  String get costLabel => switch (this) {
    AssetKind.deposit => 'Số tiền gửi ban đầu (gốc)',
    AssetKind.debt => 'Số tiền vay ban đầu',
    AssetKind.retirement => 'Tổng số tiền đã đóng góp',
    AssetKind.insurance => 'Tổng phí đã đóng',
    _ => 'Giá mua ban đầu',
  };

  String? get currentLabel => switch (this) {
    AssetKind.deposit => null,
    AssetKind.debt => 'Dư nợ gốc hiện tại',
    AssetKind.insurance => 'Giá trị hoàn lại',
    AssetKind.retirement => 'Tổng giá trị hiện tại (NAV)',
    AssetKind.vehicle => 'Giá trị thanh lý ước tính',
    AssetKind.realEstate => 'Định giá thị trường',
    _ => 'Định giá hiện tại',
  };

  String get startLabel => switch (this) {
    AssetKind.deposit => 'Ngày gửi',
    AssetKind.insurance => 'Ngày hiệu lực',
    AssetKind.debt => 'Ngày giải ngân',
    AssetKind.other => 'Ngày mua / Ngày sở hữu',
    _ => 'Ngày giao dịch',
  };
}

enum PortfolioFieldType {
  text,
  money,
  decimal,
  date,
  choice,
  chips,
  toggle,
  note,
}

class PortfolioField {
  const PortfolioField(
    this.key,
    this.label, {
    this.type = PortfolioFieldType.text,
    this.choices = const [],
    this.required = false,
    this.when,
    this.whenValue = 'Có',
  });

  final String key;
  final String label;
  final PortfolioFieldType type;
  final List<String> choices;
  final bool required;
  final String? when;
  final String whenValue;

  bool isVisible(Map<String, String> values) =>
      when == null || values[when] == whenValue;
}

class PortfolioFieldGroup {
  const PortfolioFieldGroup(this.title, this.fields);

  final String title;
  final List<PortfolioField> fields;
}

const _money = PortfolioFieldType.money;
const _decimal = PortfolioFieldType.decimal;
const _date = PortfolioFieldType.date;
const _choice = PortfolioFieldType.choice;
const _chips = PortfolioFieldType.chips;
const _toggle = PortfolioFieldType.toggle;
const _note = PortfolioFieldType.note;
const _brokers = ['SSI', 'TCBS', 'VPS', 'VNDirect', 'Khác'];
const _paymentCycles = [
  'Hàng tháng',
  'Hàng quý',
  '6 tháng',
  'Hàng năm',
  'Khác',
];
const _financingFields = [
  PortfolioField('hasDebt', 'Có khoản vay liên quan', type: _toggle),
  PortfolioField(
    'lender',
    'Ngân hàng / Bên cho vay',
    required: true,
    when: 'hasDebt',
  ),
  PortfolioField(
    'originalPrincipal',
    'Gốc vay ban đầu',
    type: _money,
    required: true,
    when: 'hasDebt',
  ),
  PortfolioField(
    'outstandingPrincipal',
    'Dư nợ hiện tại',
    type: _money,
    required: true,
    when: 'hasDebt',
  ),
  PortfolioField(
    'loanRate',
    'Lãi suất (% / năm)',
    type: _decimal,
    when: 'hasDebt',
  ),
  PortfolioField(
    'loanPayment',
    'Khoản trả mỗi kỳ',
    type: _money,
    when: 'hasDebt',
  ),
  PortfolioField(
    'loanDueDate',
    'Kỳ trả tiếp theo',
    type: _date,
    when: 'hasDebt',
  ),
];

const portfolioFields = <AssetKind, List<PortfolioFieldGroup>>{
  AssetKind.stock: [
    PortfolioFieldGroup('Tài khoản chứng khoán', [
      PortfolioField(
        'institution',
        'Công ty chứng khoán',
        type: _chips,
        choices: _brokers,
      ),
      PortfolioField(
        'exchange',
        'Sàn niêm yết',
        type: _chips,
        choices: ['HOSE', 'HNX', 'UPCoM', 'Khác'],
      ),
    ]),
  ],
  AssetKind.etf: [
    PortfolioFieldGroup('Thông tin ETF', [
      PortfolioField(
        'institution',
        'Tài khoản chứng khoán',
        type: _chips,
        choices: _brokers,
      ),
      PortfolioField('manager', 'Công ty quản lý quỹ'),
      PortfolioField('benchmark', 'Chỉ số tham chiếu'),
    ]),
  ],
  AssetKind.bond: [
    PortfolioFieldGroup('Thông tin trái phiếu', [
      PortfolioField('issuer', 'Tổ chức phát hành'),
      PortfolioField(
        'bondType',
        'Phân loại trái phiếu',
        type: _chips,
        choices: ['Doanh nghiệp', 'Ngân hàng', 'Chính phủ', 'Khác'],
      ),
      PortfolioField(
        'faceValue',
        'Mệnh giá mỗi trái phiếu',
        type: _money,
        required: true,
      ),
    ]),
    PortfolioFieldGroup('Lãi suất và đáo hạn', [
      PortfolioField(
        'interestType',
        'Loại lãi suất',
        type: _chips,
        choices: ['Cố định', 'Thả nổi'],
      ),
      PortfolioField(
        'annualRate',
        'Lãi suất (% / năm)',
        type: _decimal,
        required: true,
      ),
      PortfolioField(
        'paymentCycle',
        'Kỳ trả lãi',
        type: _choice,
        choices: _paymentCycles,
      ),
      PortfolioField('nextPayment', 'Kỳ thanh toán tới', type: _date),
      PortfolioField('issueDate', 'Ngày phát hành', type: _date),
      PortfolioField('dueDate', 'Ngày đáo hạn', type: _date, required: true),
      PortfolioField('guarantor', 'Tổ chức bảo lãnh / tài sản bảo đảm'),
    ]),
  ],
  AssetKind.fund: [
    PortfolioFieldGroup('Thông tin quỹ đầu tư', [
      PortfolioField(
        'fundType',
        'Phân loại quỹ',
        type: _chips,
        choices: [
          'Quỹ cổ phiếu',
          'Quỹ trái phiếu',
          'Quỹ cân bằng',
          'Quỹ mở',
          'Khác',
        ],
      ),
      PortfolioField(
        'institution',
        'Nền tảng mua quỹ',
        type: _chips,
        choices: ['TCInvest', 'Fmarket', 'VNDirect', 'SSI', 'Khác'],
      ),
    ]),
  ],
  AssetKind.crypto: [
    PortfolioFieldGroup('Nơi lưu trữ', [
      PortfolioField(
        'storageType',
        'Hình thức lưu trữ',
        type: _chips,
        choices: ['Sàn giao dịch', 'Ví cá nhân'],
      ),
      PortfolioField(
        'institution',
        'Sàn giao dịch',
        type: _chips,
        choices: ['Binance', 'OKX', 'Bybit', 'Coinbase', 'Khác'],
        when: 'storageType',
        whenValue: 'Sàn giao dịch',
      ),
      PortfolioField(
        'wallet',
        'Tên ví',
        when: 'storageType',
        whenValue: 'Ví cá nhân',
      ),
      PortfolioField('network', 'Blockchain / Mạng'),
      PortfolioField('transactionHash', 'Mã giao dịch (TxID / Hash)'),
    ]),
  ],
  AssetKind.realEstate: [
    PortfolioFieldGroup('Thông tin bất động sản', [
      PortfolioField(
        'propertyType',
        'Loại bất động sản',
        type: _chips,
        choices: [
          'Nhà phố',
          'Căn hộ',
          'Đất nền',
          'Shophouse',
          'Văn phòng',
          'BĐS nghỉ dưỡng',
          'Khác',
        ],
        required: true,
      ),
      PortfolioField('address', 'Địa chỉ', required: true),
      PortfolioField('province', 'Tỉnh / Thành phố'),
      PortfolioField('district', 'Quận / Huyện'),
      PortfolioField('area', 'Diện tích (m²)', type: _decimal),
      PortfolioField('bedrooms', 'Số phòng ngủ', type: _decimal),
      PortfolioField('bathrooms', 'Số phòng tắm', type: _decimal),
      PortfolioField('legalStatus', 'Tình trạng pháp lý'),
      PortfolioField('ownershipPercent', 'Tỷ lệ sở hữu (%)', type: _decimal),
    ]),
    PortfolioFieldGroup('Cho thuê và khoản vay', [
      PortfolioField('renting', 'Đang cho thuê', type: _toggle),
      PortfolioField(
        'rentIncome',
        'Tiền thuê hàng tháng',
        type: _money,
        required: true,
        when: 'renting',
      ),
      PortfolioField(
        'rentCosts',
        'Chi phí vận hành hàng tháng',
        type: _money,
        when: 'renting',
      ),
      ..._financingFields,
    ]),
  ],
  AssetKind.deposit: [
    PortfolioFieldGroup('Ngân hàng và kỳ hạn', [
      PortfolioField('institution', 'Ngân hàng lưu ký', required: true),
      PortfolioField(
        'annualRate',
        'Lãi suất (% / năm)',
        type: _decimal,
        required: true,
      ),
      PortfolioField(
        'term',
        'Kỳ hạn gửi',
        type: _chips,
        choices: [
          '1 tháng',
          '3 tháng',
          '6 tháng',
          '12 tháng',
          '24 tháng',
          'Khác',
        ],
      ),
      PortfolioField(
        'dueDate',
        'Ngày kết thúc kỳ hạn',
        type: _date,
        required: true,
      ),
      PortfolioField(
        'payout',
        'Hình thức nhận lãi',
        type: _choice,
        choices: ['Cuối kỳ', 'Hàng tháng', 'Trả trước'],
      ),
      PortfolioField(
        'renewal',
        'Phương thức tái tục',
        type: _choice,
        choices: ['Không tái tục', 'Tái tục gốc', 'Tái tục gốc và lãi'],
      ),
      PortfolioField('purpose', 'Mục đích gửi'),
    ]),
  ],
  AssetKind.foreignCurrency: [
    PortfolioFieldGroup('Nơi lưu trữ', [
      PortfolioField(
        'storageType',
        'Hình thức lưu trữ',
        type: _chips,
        choices: ['Tiền mặt', 'Tài khoản ngân hàng', 'Ví ngoại tệ', 'Khác'],
      ),
      PortfolioField('institution', 'Ngân hàng / Nơi lưu trữ'),
    ]),
  ],
  AssetKind.metal: [
    PortfolioFieldGroup('Loại vàng và nơi lưu trữ', [
      PortfolioField(
        'metalType',
        'Loại tài sản',
        type: _chips,
        choices: [
          'Vàng SJC',
          'Vàng nhẫn 9999',
          'Vàng trang sức',
          'Bạc',
          'Bạch kim',
          'Khác',
        ],
        required: true,
      ),
      PortfolioField(
        'institution',
        'Thương hiệu phát hành',
        type: _chips,
        choices: ['SJC', 'DOJI', 'PNJ', 'Bảo Tín Minh Châu', 'Mi Hồng', 'Khác'],
      ),
      PortfolioField(
        'unit',
        'Đơn vị',
        type: _chips,
        choices: ['Lượng', 'Chỉ', 'Gram', 'Oz'],
        required: true,
      ),
      PortfolioField(
        'storageType',
        'Nơi lưu trữ',
        type: _chips,
        choices: ['Tại nhà', 'Két sắt', 'Ngân hàng', 'Đơn vị lưu ký', 'Khác'],
      ),
    ]),
  ],
  AssetKind.vehicle: [
    PortfolioFieldGroup('Thông tin xe', [
      PortfolioField('brand', 'Hãng xe', required: true),
      PortfolioField('trim', 'Phiên bản'),
      PortfolioField('modelYear', 'Năm sản xuất', type: _decimal),
      PortfolioField('plate', 'Biển kiểm soát'),
      PortfolioField('valuationDate', 'Ngày thẩm định', type: _date),
      PortfolioField('valuationSource', 'Nguồn tham chiếu'),
    ]),
    PortfolioFieldGroup('Chi phí sở hữu và khoản vay', [
      PortfolioField('annualInsurance', 'Bảo hiểm mỗi năm', type: _money),
      PortfolioField('annualMaintenance', 'Bảo dưỡng mỗi năm', type: _money),
      PortfolioField(
        'annualRoadFees',
        'Đăng kiểm & phí đường bộ mỗi năm',
        type: _money,
      ),
      ..._financingFields,
    ]),
  ],
  AssetKind.retirement: [
    PortfolioFieldGroup('Thông tin chương trình', [
      PortfolioField('institution', 'Tổ chức quản lý quỹ', required: true),
      PortfolioField(
        'retirementType',
        'Loại hình hưu trí',
        type: _chips,
        choices: [
          'Hưu trí tự nguyện',
          'BHXH bổ sung',
          'Doanh nghiệp tài trợ',
          'Niên kim an sinh',
        ],
      ),
    ]),
    PortfolioFieldGroup('Đóng góp và mục tiêu', [
      PortfolioField('contribution', 'Mức đóng góp mỗi kỳ', type: _money),
      PortfolioField(
        'paymentCycle',
        'Chu kỳ đóng góp',
        type: _choice,
        choices: _paymentCycles,
      ),
      PortfolioField('dueDate', 'Kỳ đóng tiếp theo', type: _date),
      PortfolioField('retireAge', 'Tuổi nghỉ hưu dự kiến', type: _decimal),
      PortfolioField('target', 'Số tiền mục tiêu', type: _money),
      PortfolioField(
        'annualRate',
        'Lợi suất kỳ vọng (% / năm)',
        type: _decimal,
      ),
    ]),
  ],
  AssetKind.insurance: [
    PortfolioFieldGroup('Thông tin hợp đồng', [
      PortfolioField(
        'insuranceType',
        'Loại bảo hiểm',
        type: _chips,
        choices: [
          'Nhân thọ',
          'Sức khỏe',
          'Bảo hiểm xe',
          'Bảo hiểm nhà',
          'Liên kết đầu tư',
          'Bảo hiểm tai nạn',
          'Khác',
        ],
        required: true,
      ),
      PortfolioField('institution', 'Công ty bảo hiểm', required: true),
      PortfolioField('policyNumber', 'Số hợp đồng', required: true),
      PortfolioField(
        'status',
        'Tình trạng hợp đồng',
        type: _choice,
        choices: ['Đang hiệu lực', 'Đã đáo hạn', 'Đã chấm dứt'],
      ),
      PortfolioField('insured', 'Người được bảo hiểm'),
      PortfolioField(
        'insuredRelation',
        'Mối quan hệ',
        type: _chips,
        choices: ['Bản thân', 'Vợ / Chồng', 'Con', 'Cha / Mẹ', 'Khác'],
      ),
      PortfolioField('birthDate', 'Ngày sinh', type: _date),
      PortfolioField('maturityDate', 'Ngày đáo hạn', type: _date),
    ]),
    PortfolioFieldGroup('Đóng phí và quyền lợi', [
      PortfolioField(
        'premium',
        'Phí bảo hiểm mỗi kỳ',
        type: _money,
        required: true,
      ),
      PortfolioField(
        'paymentCycle',
        'Tần suất đóng phí',
        type: _choice,
        choices: _paymentCycles,
      ),
      PortfolioField('dueDate', 'Ngày đóng tiếp theo', type: _date),
      PortfolioField('premiumTerm', 'Thời hạn đóng phí'),
      PortfolioField('paymentMethod', 'Phương thức thanh toán'),
      PortfolioField(
        'coverage',
        'Số tiền bảo hiểm chính',
        type: _money,
        required: true,
      ),
      PortfolioField('policyValue', 'Giá trị tài khoản hợp đồng', type: _money),
      PortfolioField('beneficiary', 'Người thụ hưởng'),
      PortfolioField('benefits', 'Quyền lợi bổ sung', type: _note),
    ]),
  ],
  AssetKind.other: [
    PortfolioFieldGroup('Loại tài sản và sở hữu', [
      PortfolioField(
        'category',
        'Loại tài sản',
        type: _chips,
        choices: [
          'Tài sản số',
          'Tên miền',
          'Đồ sưu tầm',
          'Bản quyền / License',
          'Tài sản trí tuệ',
          'Thiết bị giá trị cao',
          'Tác phẩm nghệ thuật',
          'Tài sản kinh doanh',
          'Khác',
        ],
        required: true,
      ),
      PortfolioField('description', 'Mô tả ngắn', type: _note),
      PortfolioField('itemCount', 'Số lượng', type: _decimal),
      PortfolioField('source', 'Nguồn sở hữu'),
      PortfolioField('referenceId', 'Mã tài sản / Domain ID'),
      PortfolioField('valuationDate', 'Ngày định giá', type: _date),
      PortfolioField('valuationSource', 'Nguồn định giá'),
      PortfolioField(
        'domain',
        'Tên miền',
        when: 'category',
        whenValue: 'Tên miền',
      ),
      PortfolioField(
        'registrar',
        'Nhà đăng ký',
        when: 'category',
        whenValue: 'Tên miền',
      ),
      PortfolioField(
        'dueDate',
        'Ngày hết hạn',
        type: _date,
        when: 'category',
        whenValue: 'Tên miền',
      ),
      PortfolioField(
        'renewalFee',
        'Phí gia hạn / năm',
        type: _money,
        when: 'category',
        whenValue: 'Tên miền',
      ),
      PortfolioField('website', 'Website / URL tham chiếu'),
    ]),
    PortfolioFieldGroup('Thu nhập và chi phí duy trì', [
      PortfolioField('hasIncome', 'Tài sản tạo thu nhập', type: _toggle),
      PortfolioField(
        'recurringIncome',
        'Thu nhập định kỳ',
        type: _money,
        required: true,
        when: 'hasIncome',
      ),
      PortfolioField(
        'incomeCycle',
        'Chu kỳ thu nhập',
        type: _choice,
        choices: _paymentCycles,
        when: 'hasIncome',
      ),
      PortfolioField('incomeSource', 'Nguồn thu nhập', when: 'hasIncome'),
      PortfolioField(
        'nextIncome',
        'Ngày nhận tiếp theo',
        type: _date,
        when: 'hasIncome',
      ),
      PortfolioField('hasExpenses', 'Có chi phí duy trì', type: _toggle),
      PortfolioField(
        'recurringCost',
        'Chi phí định kỳ',
        type: _money,
        required: true,
        when: 'hasExpenses',
      ),
      PortfolioField(
        'costCycle',
        'Chu kỳ chi phí',
        type: _choice,
        choices: _paymentCycles,
        when: 'hasExpenses',
      ),
    ]),
  ],
  AssetKind.debt: [
    PortfolioFieldGroup('Loại khoản nợ và bên cho vay', [
      PortfolioField(
        'loanType',
        'Loại khoản nợ',
        type: _chips,
        choices: [
          'Vay ngân hàng',
          'Vay mua nhà',
          'Vay mua xe',
          'Vay tiêu dùng',
          'Vay cá nhân',
          'Thẻ tín dụng',
          'Vay kinh doanh',
          'Khác',
        ],
        required: true,
      ),
      PortfolioField(
        'institution',
        'Ngân hàng / Tổ chức / Người cho vay',
        required: true,
      ),
      PortfolioField('contractNumber', 'Mã hợp đồng vay'),
      PortfolioField('firstPayment', 'Ngày bắt đầu trả nợ', type: _date),
      PortfolioField('maturityDate', 'Ngày đáo hạn', type: _date),
    ]),
    PortfolioFieldGroup('Lãi suất và thanh toán', [
      PortfolioField(
        'annualRate',
        'Lãi suất hiện tại (% / năm)',
        type: _decimal,
        required: true,
      ),
      PortfolioField(
        'rateType',
        'Loại lãi suất',
        type: _chips,
        choices: ['Cố định', 'Thả nổi'],
      ),
      PortfolioField(
        'referenceRate',
        'Lãi suất tham chiếu (%)',
        type: _decimal,
        when: 'rateType',
        whenValue: 'Thả nổi',
      ),
      PortfolioField(
        'margin',
        'Biên độ cộng thêm (%)',
        type: _decimal,
        when: 'rateType',
        whenValue: 'Thả nổi',
      ),
      PortfolioField(
        'rateCycle',
        'Chu kỳ điều chỉnh',
        type: _chips,
        choices: ['3 tháng', '6 tháng', '12 tháng'],
        when: 'rateType',
        whenValue: 'Thả nổi',
      ),
      PortfolioField(
        'nextRateDate',
        'Điều chỉnh tiếp theo',
        type: _date,
        when: 'rateType',
        whenValue: 'Thả nổi',
      ),
      PortfolioField(
        'paymentMethod',
        'Phương thức trả nợ',
        type: _choice,
        choices: [
          'Dư nợ giảm dần',
          'Gốc đều',
          'Trả góp cố định',
          'Chỉ trả lãi',
          'Thanh toán linh hoạt',
        ],
      ),
      PortfolioField('payment', 'Khoản thanh toán mỗi kỳ', type: _money),
      PortfolioField(
        'paymentCycle',
        'Chu kỳ thanh toán',
        type: _choice,
        choices: _paymentCycles,
      ),
      PortfolioField('dueDate', 'Ngày thanh toán tiếp theo', type: _date),
      PortfolioField(
        'beforeDue',
        'Nhắc thanh toán trước',
        type: _chips,
        choices: ['1 ngày', '3 ngày', '7 ngày'],
      ),
    ]),
    PortfolioFieldGroup('Tài sản bảo đảm và điều khoản', [
      PortfolioField('secured', 'Có tài sản bảo đảm', type: _toggle),
      PortfolioField(
        'collateralKind',
        'Loại tài sản bảo đảm',
        type: _chips,
        choices: ['Bất động sản', 'Xe ô tô', 'Tiền gửi', 'Chứng khoán', 'Khác'],
        when: 'secured',
      ),
      PortfolioField('collateral', 'Tên tài sản bảo đảm', when: 'secured'),
      PortfolioField(
        'collateralValue',
        'Giá trị định giá',
        type: _money,
        when: 'secured',
      ),
      PortfolioField(
        'prepaymentFee',
        'Phí trả nợ trước hạn (%)',
        type: _decimal,
      ),
      PortfolioField(
        'annualManagementFee',
        'Phí quản lý / bảo hiểm hàng năm',
        type: _money,
      ),
      PortfolioField('terms', 'Ghi chú điều khoản', type: _note),
    ]),
  ],
};
