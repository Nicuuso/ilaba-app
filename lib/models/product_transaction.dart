class ProductTransaction {
  final String id;
  final String productId;
  final String? staffId;
  final String? orderId;
  final String? changeType; // 'add', 'remove', 'consume', 'adjust'
  final double quantity;
  final String? reason;
  final DateTime? createdAt;

  ProductTransaction({
    required this.id,
    required this.productId,
    this.staffId,
    this.orderId,
    this.changeType,
    required this.quantity,
    this.reason,
    this.createdAt,
  });

  factory ProductTransaction.fromJson(Map<String, dynamic> json) {
    return ProductTransaction(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      staffId: json['staff_id'] as String?,
      orderId: json['order_id'] as String?,
      changeType: json['change_type'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      reason: json['reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'staff_id': staffId,
      'order_id': orderId,
      'change_type': changeType,
      'quantity': quantity,
      'reason': reason,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
