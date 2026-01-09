class Staff {
  final String id;
  final String? authId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime birthdate;
  final String gender; // 'male', 'female', 'other'
  final String address;
  final String phoneNumber;
  final String emailAddress;
  final bool isActive;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Staff({
    required this.id,
    this.authId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.birthdate,
    required this.gender,
    required this.address,
    required this.phoneNumber,
    required this.emailAddress,
    this.isActive = true,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as String,
      authId: json['auth_id'] as String?,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String,
      birthdate: DateTime.parse(json['birthdate'] as String),
      gender: json['gender'] as String,
      address: json['address'] as String,
      phoneNumber: json['phone_number'] as String,
      emailAddress: json['email_address'] as String,
      isActive: json['is_active'] as bool? ?? true,
      updatedBy: json['updated_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'birthdate': birthdate.toIso8601String().split('T')[0],
      'gender': gender,
      'address': address,
      'phone_number': phoneNumber,
      'email_address': emailAddress,
      'is_active': isActive,
      'updated_by': updatedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String getDisplayName() {
    return '$firstName $lastName';
  }

  Staff copyWith({
    String? id,
    String? authId,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? birthdate,
    String? gender,
    String? address,
    String? phoneNumber,
    String? emailAddress,
    bool? isActive,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      isActive: isActive ?? this.isActive,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
