import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String? authId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime birthdate;      // NOW REQUIRED
  final String gender;            // NOW REQUIRED: 'male', 'female', 'other'
  final String? address;
  final String phoneNumber;       // NOW REQUIRED
  final String? emailAddress;
  final int? loyaltyPoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;      // NEW

  User({
    required this.id,
    this.authId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.birthdate,
    required this.gender,
    this.address,
    required this.phoneNumber,
    this.emailAddress,
    this.loyaltyPoints,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle null birthdate and gender gracefully (for legacy data)
    DateTime? parsedBirthdate;
    if (json['birthdate'] != null && json['birthdate'].toString().isNotEmpty) {
      try {
        parsedBirthdate = DateTime.parse(json['birthdate'] as String);
      } catch (e) {
        debugPrint('⚠️ Failed to parse birthdate: ${json['birthdate']}');
      }
    }

    return User(
      id: json['id'] as String,
      authId: json['auth_id'] as String?,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String,
      birthdate: parsedBirthdate ?? DateTime(1990, 1, 1), // Fallback date
      gender: json['gender'] as String? ?? 'other', // Fallback to 'other'
      address: json['address'] as String?,
      phoneNumber: json['phone_number'] as String,
      emailAddress: json['email_address'] as String?,
      loyaltyPoints: json['loyalty_points'] as int?,
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
      'loyalty_points': loyaltyPoints,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
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
    int? loyaltyPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
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
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
