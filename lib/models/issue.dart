class Issue {
  final String id;
  final String? orderId;
  final int? basketNumber;
  final String description;
  final String? status; // 'open', 'resolved', 'cancelled'
  final String? severity; // 'low', 'medium', 'high', 'critical'
  final String? reportedBy; // staff_id
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Issue({
    required this.id,
    this.orderId,
    this.basketNumber,
    required this.description,
    this.status,
    this.severity,
    this.reportedBy,
    this.resolvedBy,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] as String,
      orderId: json['order_id'] as String?,
      basketNumber: json['basket_number'] as int?,
      description: json['description'] as String,
      status: json['status'] as String?,
      severity: json['severity'] as String?,
      reportedBy: json['reported_by'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
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
      'order_id': orderId,
      'basket_number': basketNumber,
      'description': description,
      'status': status,
      'severity': severity,
      'reported_by': reportedBy,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isResolved => status == 'resolved';

  bool get isCritical => severity == 'critical' || severity == 'high';

  Issue copyWith({
    String? id,
    String? orderId,
    int? basketNumber,
    String? description,
    String? status,
    String? severity,
    String? reportedBy,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Issue(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      basketNumber: basketNumber ?? this.basketNumber,
      description: description ?? this.description,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      reportedBy: reportedBy ?? this.reportedBy,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
