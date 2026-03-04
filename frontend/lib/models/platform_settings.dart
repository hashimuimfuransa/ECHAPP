class PlatformSettings {
  final String id;
  final String key;
  final PaymentInfo paymentInfo;
  final PlatformInfo platformInfo;

  PlatformSettings({
    required this.id,
    required this.key,
    required this.paymentInfo,
    required this.platformInfo,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      id: json['_id'] ?? '',
      key: json['key'] ?? 'general',
      paymentInfo: PaymentInfo.fromJson(json['paymentInfo'] ?? {}),
      platformInfo: PlatformInfo.fromJson(json['platformInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'paymentInfo': paymentInfo.toJson(),
      'platformInfo': platformInfo.toJson(),
    };
  }
}

class PaymentInfo {
  final MobilePaymentInfo mtnMomo;
  final MobilePaymentInfo airtelMoney;
  final BankTransferInfo bankTransfer;
  final ContactSupport contactSupport;

  PaymentInfo({
    required this.mtnMomo,
    required this.airtelMoney,
    required this.bankTransfer,
    required this.contactSupport,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      mtnMomo: MobilePaymentInfo.fromJson(json['mtn_momo'] ?? {}),
      airtelMoney: MobilePaymentInfo.fromJson(json['airtel_money'] ?? {}),
      bankTransfer: BankTransferInfo.fromJson(json['bank_transfer'] ?? {}),
      contactSupport: ContactSupport.fromJson(json['contactSupport'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mtn_momo': mtnMomo.toJson(),
      'airtel_money': airtelMoney.toJson(),
      'bank_transfer': bankTransfer.toJson(),
      'contactSupport': contactSupport.toJson(),
    };
  }
}

class MobilePaymentInfo {
  final String accountName;
  final String accountNumber;
  final String merchantCode;
  final bool enabled;

  MobilePaymentInfo({
    required this.accountName,
    required this.accountNumber,
    required this.merchantCode,
    required this.enabled,
  });

  factory MobilePaymentInfo.fromJson(Map<String, dynamic> json) {
    return MobilePaymentInfo(
      accountName: json['accountName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      merchantCode: json['merchantCode'] ?? '',
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountName': accountName,
      'accountNumber': accountNumber,
      'merchantCode': merchantCode,
      'enabled': enabled,
    };
  }
}

class BankTransferInfo {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String swiftCode;
  final bool enabled;

  BankTransferInfo({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.swiftCode,
    required this.enabled,
  });

  factory BankTransferInfo.fromJson(Map<String, dynamic> json) {
    return BankTransferInfo(
      bankName: json['bankName'] ?? '',
      accountName: json['accountName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      swiftCode: json['swiftCode'] ?? '',
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'swiftCode': swiftCode,
      'enabled': enabled,
    };
  }
}

class ContactSupport {
  final String phone;
  final String email;
  final String whatsapp;

  ContactSupport({
    required this.phone,
    required this.email,
    required this.whatsapp,
  });

  factory ContactSupport.fromJson(Map<String, dynamic> json) {
    return ContactSupport(
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'whatsapp': whatsapp,
    };
  }
}

class PlatformInfo {
  final String name;
  final String description;
  final String contactEmail;
  final String contactPhone;

  PlatformInfo({
    required this.name,
    required this.description,
    required this.contactEmail,
    required this.contactPhone,
  });

  factory PlatformInfo.fromJson(Map<String, dynamic> json) {
    return PlatformInfo(
      name: json['name'] ?? 'Excellence Coaching Hub',
      description: json['description'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
    };
  }
}
