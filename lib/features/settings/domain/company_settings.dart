/// Company settings model matching the original CompanySettings interface.
class CompanySettings {
  final String id;
  final String companyName;
  final String tagline;
  final String phone;
  final String city;
  final String currency;
  final int standardMonthDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanySettings({
    this.id = 'default',
    this.companyName = 'National Roadlines & Transport Co.',
    this.tagline = 'Fleet Logistics, Heavy Cargo & Transport Services',
    this.phone = '+91 98220 54321',
    this.city = 'Transport Nagar, Logistics Hub',
    this.currency = '₹',
    this.standardMonthDays = 30,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) =>
      CompanySettings(
        id: json['id'] as String? ?? 'default',
        companyName: json['company_name'] as String? ?? 'My Company',
        tagline: json['tagline'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        city: json['city'] as String? ?? '',
        currency: json['currency'] as String? ?? '₹',
        standardMonthDays: json['standard_month_days'] as int? ?? 30,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_name': companyName,
    'tagline': tagline,
    'phone': phone,
    'city': city,
    'currency': currency,
    'standard_month_days': standardMonthDays,
  };

  /// For legacy JSON backup compatibility.
  factory CompanySettings.fromLegacyJson(Map<String, dynamic> json) =>
      CompanySettings(
        companyName: json['companyName'] as String? ?? 'My Company',
        tagline: json['tagline'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        city: json['city'] as String? ?? '',
        currency: json['currency'] as String? ?? '₹',
        standardMonthDays: json['standardMonthDays'] as int? ?? 30,
      );

  Map<String, dynamic> toLegacyJson() => {
    'companyName': companyName,
    'tagline': tagline,
    'phone': phone,
    'city': city,
    'currency': currency,
    'standardMonthDays': standardMonthDays,
  };

  CompanySettings copyWith({
    String? id,
    String? companyName,
    String? tagline,
    String? phone,
    String? city,
    String? currency,
    int? standardMonthDays,
  }) =>
      CompanySettings(
        id: id ?? this.id,
        companyName: companyName ?? this.companyName,
        tagline: tagline ?? this.tagline,
        phone: phone ?? this.phone,
        city: city ?? this.city,
        currency: currency ?? this.currency,
        standardMonthDays: standardMonthDays ?? this.standardMonthDays,
      );
}
