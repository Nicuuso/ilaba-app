class Role {
  final String id;
  final String name;
  final String? description;

  Role({required this.id, required this.name, this.description});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class StaffRole {
  final String staffId;
  final String roleId;

  StaffRole({required this.staffId, required this.roleId});

  factory StaffRole.fromJson(Map<String, dynamic> json) {
    return StaffRole(
      staffId: json['staff_id'] as String,
      roleId: json['role_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'staff_id': staffId, 'role_id': roleId};
  }
}
