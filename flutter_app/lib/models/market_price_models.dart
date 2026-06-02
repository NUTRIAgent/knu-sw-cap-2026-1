class IngredientPriceModel {
  final int? ingredientId;
  final String ingredientName;
  final String? kamisItemCode;
  final double pricePerGram;
  final int? originalPrice;
  final String? originalUnit;
  final String? marketName;
  final String? marketType;
  final DateTime baseDate;
  final double? dayChangeRate;
  final double? weekChangeRate;
  final double? monthChangeRate;

  const IngredientPriceModel({
    this.ingredientId,
    required this.ingredientName,
    this.kamisItemCode,
    required this.pricePerGram,
    this.originalPrice,
    this.originalUnit,
    this.marketName,
    this.marketType,
    required this.baseDate,
    this.dayChangeRate,
    this.weekChangeRate,
    this.monthChangeRate,
  });

  factory IngredientPriceModel.fromJson(Map<String, dynamic> json) {
    return IngredientPriceModel(
      ingredientId: json['ingredientId'] as int?,
      ingredientName: json['ingredientName'] as String,
      kamisItemCode: json['kamisItemCode'] as String?,
      pricePerGram: (json['pricePerGram'] as num).toDouble(),
      originalPrice: json['originalPrice'] as int?,
      originalUnit: json['originalUnit'] as String?,
      marketName: json['marketName'] as String?,
      marketType: json['marketType'] as String?,
      baseDate: DateTime.parse(json['baseDate'] as String),
      dayChangeRate: (json['dayChangeRate'] as num?)?.toDouble(),
      weekChangeRate: (json['weekChangeRate'] as num?)?.toDouble(),
      monthChangeRate: (json['monthChangeRate'] as num?)?.toDouble(),
    );
  }

  String get displayPrice {
    if (originalPrice != null && originalUnit != null) {
      return '${_formatNumber(originalPrice!)}원 / $originalUnit';
    }
    return '${_formatNumber((pricePerGram * 1000).round())}원 / 1kg';
  }

  String get displayDate {
    return '${baseDate.month}/${baseDate.day} ${baseDate.hour}시 기준';
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
