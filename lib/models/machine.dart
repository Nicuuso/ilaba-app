class Machine {
  final String id;
  final String machineName;
  final String machineType; // 'wash', 'dry', 'iron'
  final String? status; // 'available', 'running', 'maintenance'
  final DateTime? lastServicedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Machine({
    required this.id,
    required this.machineName,
    required this.machineType,
    this.status,
    this.lastServicedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as String,
      machineName: json['machine_name'] as String,
      machineType: json['machine_type'] as String,
      status: json['status'] as String?,
      lastServicedAt: json['last_serviced_at'] != null
          ? DateTime.parse(json['last_serviced_at'] as String)
          : null,
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
      'machine_name': machineName,
      'machine_type': machineType,
      'status': status,
      'last_serviced_at': lastServicedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isAvailable => status == 'available';

  Machine copyWith({
    String? id,
    String? machineName,
    String? machineType,
    String? status,
    DateTime? lastServicedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Machine(
      id: id ?? this.id,
      machineName: machineName ?? this.machineName,
      machineType: machineType ?? this.machineType,
      status: status ?? this.status,
      lastServicedAt: lastServicedAt ?? this.lastServicedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
