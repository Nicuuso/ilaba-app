/// Step 1: Baskets Configuration
/// Configure laundry services per basket (fixed 8kg)
/// - Add/remove baskets
/// - Toggle services: wash, dry, spin, iron
/// - Add plastic bags quantity

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/models/order_models.dart';
import 'package:ilaba/providers/mobile_booking_provider.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class MobileBookingBasketsStep extends StatelessWidget {
  const MobileBookingBasketsStep({Key? key}) : super(key: key);

  /// Helper to get service info from DB services list
  static Map<String, dynamic> _getServiceInfo(
    List<Service> services,
    String serviceType,
    String? tier,
  ) {
    final matching = services
        .where((s) => s.serviceType == serviceType)
        .toList();
    if (matching.isEmpty) {
      return {'name': '', 'price': 0.0, 'description': ''};
    }

    final service = tier != null
        ? matching.firstWhere(
            (s) => s.tier == tier,
            orElse: () => matching.first,
          )
        : matching.first;

    return {'name': service.name, 'price': service.basePrice, 'description': service.description ?? ''};
  }

  /// Helper to get additional dry time info from service modifiers
  static Map<String, dynamic> _getAdditionalDryTimeInfo(
    List<Service> services,
  ) {
    return {
      'price_per_increment': 15.0,
      'minutes_per_increment': 8,
      'max_increments': 3,
    };
  }

  /// Helper to get plastic bags from products
  static double _getPlasticBagsPrice(List<Product> products) {
    final plasticBag = products.firstWhere(
      (p) =>
          p.itemName.toLowerCase().contains('plastic') ||
          p.itemName.toLowerCase().contains('bag'),
      orElse: () => Product(
        id: '',
        itemName: 'Plastic Bags',
        unitPrice: 3.0,
        quantityInStock: 0,
      ),
    );
    return plasticBag.unitPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileBookingProvider>(
      builder: (context, provider, _) {
        final basket = provider.activeBasket;

        return Container(
          color: ILabaColors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with basket info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configure Basket',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1a1a1a)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ILabaColors.burgundy.withOpacity(0.1), ILabaColors.burgundy.withOpacity(0.05)],
                        ),
                        border: Border.all(color: ILabaColors.burgundy.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '8kg per basket',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: ILabaColors.burgundy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Services in Single Column
                Column(
                  children: [
                    // Wash
                    _buildWashSection(context, provider, basket),
                    const SizedBox(height: 16),

                    // Spin
                    _buildSpinSection(context, provider, basket),
                    const SizedBox(height: 16),

                    // Dry
                    _buildDrySection(context, provider, basket),
                    const SizedBox(height: 16),

                    // Additional Dry Time
                    _buildAdditionalDryTimeSection(context, provider),
                    const SizedBox(height: 16),

                    // Iron
                    _buildIronSection(context, provider, basket),
                    // HIDDEN: Plastic Bags option
                    // const SizedBox(height: 16),
                    // _buildPlasticBagsSection(context, provider),
                  ],
                ),
                const SizedBox(height: 24),

                // Order Summary Preview
                _buildOrderSummary(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build basket selector tabs
  /// Build Wash section with options from DB
  Widget _buildWashSection(
    BuildContext context,
    MobileBookingProvider provider,
    Basket basket,
  ) {
    final services = basket.services;
    debugPrint(
      '🧼 WASH: current=${services.wash}, provider.services.count=${provider.services.length}, services=${provider.services.map((s) => '${s.serviceType}/${s.tier}:${s.name}').join(', ')}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🧺 Wash',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ILabaColors.burgundy),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
          children: [
            for (final opt in [
              {'value': 'off', 'label': 'None', 'emoji': '⭕', 'tier': null},
              {
                'value': 'basic',
                'label': 'Basic',
                'emoji': '🌊',
                'tier': 'basic',
              },
              {
                'value': 'premium',
                'label': 'Premium',
                'emoji': '✨',
                'tier': 'premium',
              },
            ])
              _buildServiceButton(
                context,
                provider,
                serviceType: 'wash',
                currentValue: services.wash,
                option: opt,
                onSelected: (value) =>
                    provider.updateBasketService('wash', value),
              ),
          ],
        ),
      ],
    );
  }

  /// Build Spin section
  Widget _buildSpinSection(
    BuildContext context,
    MobileBookingProvider provider,
    Basket basket,
  ) {
    final services = basket.services;
    final spinInfo = _getServiceInfo(provider.services, 'spin', null);

    return GestureDetector(
      onTap: () => provider.updateBasketService('spin', !services.spin),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: services.spin
              ? LinearGradient(
                  colors: [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [ILabaColors.white, ILabaColors.lightGray],
                ),
          border: Border.all(
            color: services.spin
                ? const Color(0xFF0EA5E9).withOpacity(0.2)
                : ILabaColors.lightGray,
            width: services.spin ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: services.spin
              ? [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Icon and name
            Row(
              children: [
                const Text(
                  '🌀',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spinInfo['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: services.spin ? ILabaColors.white : ILabaColors.darkText,
                      ),
                    ),
                    if ((spinInfo['description'] as String).isNotEmpty)
                      Text(
                        spinInfo['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: services.spin
                              ? ILabaColors.white.withOpacity(0.8)
                              : ILabaColors.lightText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ),
            // Right: Price and checkbox
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if ((spinInfo['price'] as double) > 0)
                  Text(
                    '₱${(spinInfo['price'] as double).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: services.spin
                          ? ILabaColors.white.withOpacity(0.95)
                          : ILabaColors.burgundy,
                    ),
                  ),
                SizedBox(
                  height: 32,
                  width: 32,
                  child: Checkbox(
                    value: services.spin,
                    onChanged: (value) =>
                        provider.updateBasketService('spin', value ?? false),
                    activeColor: ILabaColors.burgundy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build Dry section with options from DB
  Widget _buildDrySection(
    BuildContext context,
    MobileBookingProvider provider,
    Basket basket,
  ) {
    final services = basket.services;
    debugPrint(
      '🌬️ DRY: current=${services.dry}, provider.services.count=${provider.services.length}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💨 Dry',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ILabaColors.burgundy),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
          children: [
            for (final opt in [
              {'value': 'off', 'label': 'None', 'emoji': '⭕', 'tier': null},
              {
                'value': 'basic',
                'label': 'Basic',
                'emoji': '💨',
                'tier': 'basic',
              },
              {
                'value': 'premium',
                'label': 'Premium',
                'emoji': '🔥',
                'tier': 'premium',
              },
            ])
              _buildServiceButton(
                context,
                provider,
                serviceType: 'dry',
                currentValue: services.dry,
                option: opt,
                onSelected: (value) =>
                    provider.updateBasketService('dry', value),
              ),
          ],
        ),
      ],
    );
  }

  /// Build Additional Dry Time section
  Widget _buildAdditionalDryTimeSection(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    final dryTimeInfo = _getAdditionalDryTimeInfo(provider.services);
    final pricePerIncrement = dryTimeInfo['price_per_increment'] as double;
    final minutesPerIncrement = dryTimeInfo['minutes_per_increment'] as int;
    final currentMinutes = provider.activeBasket.services.additionalDryMinutes;
    final subtotal = (currentMinutes / minutesPerIncrement) * pricePerIncrement;

    debugPrint(
      '🔧 Additional Dry Time: current=$currentMinutes, increment=$minutesPerIncrement, subtotal=$subtotal',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '⏱️ Additional Dry',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ILabaColors.burgundy),
            ),
            const SizedBox(width: 8),
            Text(
              '@ ₱${pricePerIncrement.toStringAsFixed(0)}/${minutesPerIncrement}min',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: ILabaColors.lightText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ILabaColors.burgundy.withOpacity(0.1), ILabaColors.burgundy.withOpacity(0.05)],
            ),
            border: Border.all(color: ILabaColors.burgundy.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: ILabaColors.burgundy.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentMinutes}min',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: ILabaColors.darkText,
                ),
              ),
              // Subtotal in the middle
              if (subtotal > 0)
                Text(
                  '₱${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ILabaColors.burgundy,
                  ),
                ),
              // Horizontal buttons
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: ILabaColors.burgundy.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: ILabaColors.white),
                      onPressed: currentMinutes > 0
                          ? () {
                              final newVal =
                                  (currentMinutes - minutesPerIncrement)
                                      .clamp(0, double.infinity)
                                      .toInt();
                              debugPrint(
                                '📱 REMOVE dry time: $currentMinutes - $minutesPerIncrement = $newVal',
                              );
                              provider.updateBasketService(
                                'additionalDryMinutes',
                                newVal,
                              );
                            }
                          : null,
                      iconSize: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: ILabaColors.burgundy.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: ILabaColors.white),
                      onPressed: currentMinutes < 24
                          ? () {
                              final newVal = currentMinutes + minutesPerIncrement;
                              debugPrint(
                                '📱 ADD dry time: $currentMinutes + $minutesPerIncrement = $newVal',
                              );
                              provider.updateBasketService(
                                'additionalDryMinutes',
                                newVal,
                              );
                            }
                          : null,
                      iconSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Iron section
  Widget _buildIronSection(
    BuildContext context,
    MobileBookingProvider provider,
    Basket basket,
  ) {
    final ironInfo = _getServiceInfo(provider.services, 'iron', null);
    final ironPrice = ironInfo['price'] as double;
    final currentWeight = basket.services.ironWeightKg;
    final subtotal = currentWeight * ironPrice;

    debugPrint(
      '🔧 Iron: current=$currentWeight, price=$ironPrice, subtotal=$subtotal',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '👔 Iron',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ILabaColors.burgundy),
            ),
            const SizedBox(width: 8),
            Text(
              '@ ₱${ironPrice.toStringAsFixed(0)}/kg',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: ILabaColors.lightText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ILabaColors.burgundy.withOpacity(0.1), ILabaColors.burgundy.withOpacity(0.05)],
            ),
            border: Border.all(color: ILabaColors.burgundy.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: ILabaColors.burgundy.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentWeight}kg',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: ILabaColors.darkText,
                ),
              ),
              // Subtotal in the middle
              if (subtotal > 0)
                Text(
                  '₱${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ILabaColors.burgundy,
                  ),
                ),
              // Horizontal buttons
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: ILabaColors.burgundy.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: ILabaColors.white),
                      onPressed: currentWeight > 0
                          ? () {
                              final newVal = currentWeight == 2 ? 0 : (currentWeight - 1).clamp(0, 8);
                              debugPrint(
                                '📱 REMOVE iron: $currentWeight → $newVal',
                              );
                              provider.updateBasketService(
                                'ironWeightKg',
                                newVal,
                              );
                            }
                          : null,
                      iconSize: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: ILabaColors.burgundy.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: ILabaColors.white),
                      onPressed: currentWeight < 8
                          ? () {
                              final newVal = currentWeight == 0 ? 2 : (currentWeight + 1).clamp(0, 8);
                              debugPrint(
                                '📱 ADD iron: $currentWeight → $newVal',
                              );
                              provider.updateBasketService(
                                'ironWeightKg',
                                newVal,
                              );
                            }
                          : null,
                      iconSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Plastic Bags section
  Widget _buildPlasticBagsSection(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    final bagPrice = _getPlasticBagsPrice(provider.products);
    final quantity = provider.activeBasket.services.plasticBags;
    final subtotal = quantity * bagPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🛍️ Plastic Bags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ILabaColors.burgundy),
            ),
            const SizedBox(width: 8),
            Text(
              '@ ₱${bagPrice.toStringAsFixed(2)}/pc',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: ILabaColors.lightText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ILabaColors.burgundy.withOpacity(0.1), ILabaColors.burgundy.withOpacity(0.05)],
            ),
            border: Border.all(color: ILabaColors.burgundy.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: ILabaColors.burgundy.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${quantity}x',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: ILabaColors.darkText,
                ),
              ),
              // Subtotal in the middle
              if (subtotal > 0)
                Text(
                  '₱${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ILabaColors.burgundy,
                  ),
                ),
              // Horizontal buttons
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: ILabaColors.burgundy.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: ILabaColors.white),
                      onPressed: quantity > 0
                          ? () => provider.updateBasketService(
                                'plasticBags',
                                quantity - 1,
                              )
                          : null,
                      iconSize: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ILabaColors.burgundy, ILabaColors.burgundyDark],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: ILabaColors.burgundy.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: ILabaColors.white),
                      onPressed: () => provider.updateBasketService(
                        'plasticBags',
                        quantity + 1,
                      ),
                      iconSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build individual service button with DB info
  Widget _buildServiceButton(
    BuildContext context,
    MobileBookingProvider provider, {
    required String serviceType,
    required String currentValue,
    required Map<String, dynamic> option,
    required Function(String) onSelected,
  }) {
    final isSelected = currentValue == option['value'];
    final tier = option['tier'] as String?;
    final isOff = option['value'] == 'off';
    final serviceInfo = _getServiceInfo(provider.services, serviceType, tier);

    // Use pink color scheme throughout
    const Color primaryColor = ILabaColors.burgundy;
    const Color secondaryColor = ILabaColors.burgundyDark;

    debugPrint(
      '🔍 ServiceButton: $serviceType/$tier - info=$serviceInfo, services_count=${provider.services.length}',
    );

    return GestureDetector(
      onTap: () {
        debugPrint('📱 SELECT: $serviceType = ${option['value']}');
        onSelected(option['value'] as String);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [ILabaColors.white, ILabaColors.lightGray],
                ),
          border: Border.all(
            color: isSelected
                ? primaryColor.withOpacity(0.2)
                : ILabaColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option['emoji'] as String,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              option['label'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? ILabaColors.white : ILabaColors.lightText,
              ),
              textAlign: TextAlign.center,
            ),
            // Show price only if not "off" and price > 0
            if (!isOff && (serviceInfo['price'] as double) > 0) ...[
              const SizedBox(height: 2),
              Text(
                '₱${(serviceInfo['price'] as double).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? ILabaColors.white.withOpacity(0.9)
                      : ILabaColors.burgundy,
                ),
              ),
            ],
            // Show description if available and not "off"
            if (!isOff && (serviceInfo['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  serviceInfo['description'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected
                        ? ILabaColors.white.withOpacity(0.8)
                        : ILabaColors.lightText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build order summary preview
  Widget _buildOrderSummary(
    BuildContext context,
    MobileBookingProvider provider,
  ) {
    final breakdown = provider.calculateOrderTotal();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ILabaColors.lightGray,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Baskets Subtotal:', style: TextStyle(color: ILabaColors.lightText)),
              Text(
                '₱${breakdown.summary.subtotalBaskets.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (breakdown.summary.staffServiceFee > 0)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Staff Fee:'),
                    Text(
                      '₱${breakdown.summary.staffServiceFee.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('VAT (12%):'),
              Text('₱${breakdown.summary.vatAmount.toStringAsFixed(2)}'),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₱${breakdown.summary.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
