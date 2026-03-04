class PlatformSettings {
  final String id;
  final String key;
  final PaymentInfo paymentInfo;
  final PlatformInfo platformInfo;
  final UserManagementSettings userManagement;
  final ContentModerationSettings contentModeration;
  final NotificationSettings notifications;
  final AppearanceSettings appearance;
  final DataManagementSettings dataManagement;

  PlatformSettings({
    required this.id,
    required this.key,
    required this.paymentInfo,
    required this.platformInfo,
    required this.userManagement,
    required this.contentModeration,
    required this.notifications,
    required this.appearance,
    required this.dataManagement,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      id: json['_id'] ?? '',
      key: json['key'] ?? 'general',
      paymentInfo: PaymentInfo.fromJson(json['paymentInfo'] ?? {}),
      platformInfo: PlatformInfo.fromJson(json['platformInfo'] ?? {}),
      userManagement: UserManagementSettings.fromJson(json['userManagement'] ?? {}),
      contentModeration: ContentModerationSettings.fromJson(json['contentModeration'] ?? {}),
      notifications: NotificationSettings.fromJson(json['notifications'] ?? {}),
      appearance: AppearanceSettings.fromJson(json['appearance'] ?? {}),
      dataManagement: DataManagementSettings.fromJson(json['dataManagement'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'paymentInfo': paymentInfo.toJson(),
      'platformInfo': platformInfo.toJson(),
      'userManagement': userManagement.toJson(),
      'contentModeration': contentModeration.toJson(),
      'notifications': notifications.toJson(),
      'appearance': appearance.toJson(),
      'dataManagement': dataManagement.toJson(),
    };
  }

  PlatformSettings copyWith({
    String? id,
    String? key,
    PaymentInfo? paymentInfo,
    PlatformInfo? platformInfo,
    UserManagementSettings? userManagement,
    ContentModerationSettings? contentModeration,
    NotificationSettings? notifications,
    AppearanceSettings? appearance,
    DataManagementSettings? dataManagement,
  }) {
    return PlatformSettings(
      id: id ?? this.id,
      key: key ?? this.key,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      platformInfo: platformInfo ?? this.platformInfo,
      userManagement: userManagement ?? this.userManagement,
      contentModeration: contentModeration ?? this.contentModeration,
      notifications: notifications ?? this.notifications,
      appearance: appearance ?? this.appearance,
      dataManagement: dataManagement ?? this.dataManagement,
    );
  }
}

class NotificationSettings {
  final bool enabled;
  final bool email;
  final bool push;

  NotificationSettings({
    required this.enabled,
    required this.email,
    required this.push,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      email: json['email'] ?? true,
      push: json['push'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'email': email,
      'push': push,
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? email,
    bool? push,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      email: email ?? this.email,
      push: push ?? this.push,
    );
  }
}

class AppearanceSettings {
  final String theme;

  AppearanceSettings({
    required this.theme,
  });

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    return AppearanceSettings(
      theme: json['theme'] ?? 'Light',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
    };
  }

  AppearanceSettings copyWith({
    String? theme,
  }) {
    return AppearanceSettings(
      theme: theme ?? this.theme,
    );
  }
}

class DataManagementSettings {
  final bool autoSync;
  final int syncInterval;

  DataManagementSettings({
    required this.autoSync,
    required this.syncInterval,
  });

  factory DataManagementSettings.fromJson(Map<String, dynamic> json) {
    return DataManagementSettings(
      autoSync: json['autoSync'] ?? true,
      syncInterval: json['syncInterval'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSync': autoSync,
      'syncInterval': syncInterval,
    };
  }

  DataManagementSettings copyWith({
    bool? autoSync,
    int? syncInterval,
  }) {
    return DataManagementSettings(
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
    );
  }
}

class UserManagementSettings {
  final bool allowRegistration;
  final bool requireEmailVerification;
  final String defaultUserRole;

  UserManagementSettings({
    required this.allowRegistration,
    required this.requireEmailVerification,
    required this.defaultUserRole,
  });

  factory UserManagementSettings.fromJson(Map<String, dynamic> json) {
    return UserManagementSettings(
      allowRegistration: json['allowRegistration'] ?? true,
      requireEmailVerification: json['requireEmailVerification'] ?? true,
      defaultUserRole: json['defaultUserRole'] ?? 'Student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowRegistration': allowRegistration,
      'requireEmailVerification': requireEmailVerification,
      'defaultUserRole': defaultUserRole,
    };
  }

  UserManagementSettings copyWith({
    bool? allowRegistration,
    bool? requireEmailVerification,
    String? defaultUserRole,
  }) {
    return UserManagementSettings(
      allowRegistration: allowRegistration ?? this.allowRegistration,
      requireEmailVerification: requireEmailVerification ?? this.requireEmailVerification,
      defaultUserRole: defaultUserRole ?? this.defaultUserRole,
    );
  }
}

class ContentModerationSettings {
  final bool requireManualCourseApproval;
  final bool autoFilterSpam;
  final bool allowCommentsOnCourses;

  ContentModerationSettings({
    required this.requireManualCourseApproval,
    required this.autoFilterSpam,
    required this.allowCommentsOnCourses,
  });

  factory ContentModerationSettings.fromJson(Map<String, dynamic> json) {
    return ContentModerationSettings(
      requireManualCourseApproval: json['requireManualCourseApproval'] ?? true,
      autoFilterSpam: json['autoFilterSpam'] ?? true,
      allowCommentsOnCourses: json['allowCommentsOnCourses'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requireManualCourseApproval': requireManualCourseApproval,
      'autoFilterSpam': autoFilterSpam,
      'allowCommentsOnCourses': allowCommentsOnCourses,
    };
  }

  ContentModerationSettings copyWith({
    bool? requireManualCourseApproval,
    bool? autoFilterSpam,
    bool? allowCommentsOnCourses,
  }) {
    return ContentModerationSettings(
      requireManualCourseApproval: requireManualCourseApproval ?? this.requireManualCourseApproval,
      autoFilterSpam: autoFilterSpam ?? this.autoFilterSpam,
      allowCommentsOnCourses: allowCommentsOnCourses ?? this.allowCommentsOnCourses,
    );
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

  PaymentInfo copyWith({
    MobilePaymentInfo? mtnMomo,
    MobilePaymentInfo? airtelMoney,
    BankTransferInfo? bankTransfer,
    ContactSupport? contactSupport,
  }) {
    return PaymentInfo(
      mtnMomo: mtnMomo ?? this.mtnMomo,
      airtelMoney: airtelMoney ?? this.airtelMoney,
      bankTransfer: bankTransfer ?? this.bankTransfer,
      contactSupport: contactSupport ?? this.contactSupport,
    );
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

  MobilePaymentInfo copyWith({
    String? accountName,
    String? accountNumber,
    String? merchantCode,
    bool? enabled,
  }) {
    return MobilePaymentInfo(
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      merchantCode: merchantCode ?? this.merchantCode,
      enabled: enabled ?? this.enabled,
    );
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

  BankTransferInfo copyWith({
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? swiftCode,
    bool? enabled,
  }) {
    return BankTransferInfo(
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      swiftCode: swiftCode ?? this.swiftCode,
      enabled: enabled ?? this.enabled,
    );
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

  ContactSupport copyWith({
    String? phone,
    String? email,
    String? whatsapp,
  }) {
    return ContactSupport(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
    );
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

  PlatformInfo copyWith({
    String? name,
    String? description,
    String? contactEmail,
    String? contactPhone,
  }) {
    return PlatformInfo(
      name: name ?? this.name,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }
}
