import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/booking_state_provider.dart';
import 'package:ilaba/widgets/custom_text_field.dart';
import 'package:ilaba/models/pos_types.dart';

class BookingBasketsScreen extends StatefulWidget {
  const BookingBasketsScreen({Key? key}) : super(key: key);

  @override
  State<BookingBasketsScreen> createState() => _BookingBasketsScreenState();
}

class _BookingBasketsScreenState extends State<BookingBasketsScreen> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingStateNotifier>(
      builder: (context, state, _) {
        if (state.baskets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No baskets added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<BookingStateNotifier>().addBasket();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Basket'),
                  ),
                ],
              ),
            ),
          );
        }

        final activeBasket = state.baskets[state.activeBasketIndex];
        _notesController.text = activeBasket.notes;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Laundry Baskets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Basket tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...List.generate(state.baskets.length, (index) {
                        final isActive = state.activeBasketIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onLongPress: state.baskets.length > 1
                                ? () {
                                    context
                                        .read<BookingStateNotifier>()
                                        .deleteBasket(index);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.blue
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  context
                                      .read<BookingStateNotifier>()
                                      .setActiveBasketIndex(index);
                                },
                                child: Text(
                                  state.baskets[index].name,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<BookingStateNotifier>().addBasket();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Weight control
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Weight:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${activeBasket.weightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _CompactButton(
                        icon: Icons.remove,
                        onPressed: () {
                          if (activeBasket.weightKg > 0) {
                            context
                                .read<BookingStateNotifier>()
                                .updateActiveBasket(
                                  activeBasket.copyWith(
                                    weightKg: activeBasket.weightKg - 0.5,
                                  ),
                                );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _CompactButton(
                        icon: Icons.add,
                        onPressed: () {
                          context.read<BookingStateNotifier>().updateActiveBasket(
                                activeBasket.copyWith(
                                  weightKg: activeBasket.weightKg + 0.5,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Services section - Expandable list
                const Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Service items - vertical list with full width
                _ServiceListItem(
                  title: 'Wash',
                  count: activeBasket.washCount,
                  isPremium: activeBasket.washPremium,
                  services: state.services,
                  serviceType: 'wash',
                  onIncrement: () {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(
                              washCount: activeBasket.washCount + 1),
                        );
                  },
                  onDecrement: () {
                    if (activeBasket.washCount > 0) {
                      context.read<BookingStateNotifier>().updateActiveBasket(
                            activeBasket.copyWith(
                                washCount: activeBasket.washCount - 1),
                          );
                    }
                  },
                  onPremiumChanged: (value) {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(washPremium: value),
                        );
                  },
                  hasPremium: true,
                  disabled: activeBasket.weightKg == 0,
                  weight: activeBasket.weightKg,
                ),
                const SizedBox(height: 8),

                _ServiceListItem(
                  title: 'Dry',
                  count: activeBasket.dryCount,
                  isPremium: activeBasket.dryPremium,
                  services: state.services,
                  serviceType: 'dry',
                  onIncrement: () {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(
                              dryCount: activeBasket.dryCount + 1),
                        );
                  },
                  onDecrement: () {
                    if (activeBasket.dryCount > 0) {
                      context.read<BookingStateNotifier>().updateActiveBasket(
                            activeBasket.copyWith(
                                dryCount: activeBasket.dryCount - 1),
                          );
                    }
                  },
                  onPremiumChanged: (value) {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(dryPremium: value),
                        );
                  },
                  hasPremium: true,
                  disabled: activeBasket.weightKg == 0,
                  weight: activeBasket.weightKg,
                ),
                const SizedBox(height: 8),

                _ServiceListItem(
                  title: 'Spin',
                  count: activeBasket.spinCount,
                  isPremium: false,
                  services: state.services,
                  serviceType: 'spin',
                  onIncrement: () {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(
                              spinCount: activeBasket.spinCount + 1),
                        );
                  },
                  onDecrement: () {
                    if (activeBasket.spinCount > 0) {
                      context.read<BookingStateNotifier>().updateActiveBasket(
                            activeBasket.copyWith(
                                spinCount: activeBasket.spinCount - 1),
                          );
                    }
                  },
                  onPremiumChanged: null,
                  hasPremium: false,
                  disabled: activeBasket.weightKg == 0,
                  weight: activeBasket.weightKg,
                ),
                const SizedBox(height: 8),

                _ServiceListItem(
                  title: 'Iron',
                  count: activeBasket.iron ? 1 : 0,
                  isPremium: false,
                  services: state.services,
                  serviceType: 'iron',
                  onIncrement: () {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(iron: !activeBasket.iron),
                        );
                  },
                  onDecrement: () {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(iron: false),
                        );
                  },
                  onPremiumChanged: null,
                  hasPremium: false,
                  disabled: activeBasket.weightKg == 0,
                  isToggle: true,
                  weight: activeBasket.weightKg,
                ),
                const SizedBox(height: 8),

                _ServiceListItem(
                  title: 'Fold',
                  count: activeBasket.fold ? 1 : 0,
                  isPremium: false,
                  services: state.services,
                  serviceType: 'fold',
                  onIncrement: () {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(fold: !activeBasket.fold),
                        );
                  },
                  onDecrement: () {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(fold: false),
                        );
                  },
                  onPremiumChanged: null,
                  hasPremium: false,
                  disabled: activeBasket.weightKg == 0,
                  isToggle: true,
                  weight: activeBasket.weightKg,
                ),

                const SizedBox(height: 20),

                // Special notes
                CustomTextField(
                  controller: _notesController,
                  hintText: 'Special Notes (Optional)',
                  maxLines: 2,
                  onChanged: (value) {
                    context.read<BookingStateNotifier>().updateActiveBasket(
                          activeBasket.copyWith(notes: value),
                        );
                  },
                ),

                const SizedBox(height: 20),

                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Weight: ${activeBasket.weightKg} kg',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (activeBasket.washCount > 0)
                        Text(
                          'Wash: ${activeBasket.washCount}x${activeBasket.washPremium ? " (Premium)" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (activeBasket.dryCount > 0)
                        Text(
                          'Dry: ${activeBasket.dryCount}x${activeBasket.dryPremium ? " (Premium)" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (activeBasket.spinCount > 0)
                        Text(
                          'Spin: ${activeBasket.spinCount}x',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (activeBasket.iron)
                        const Text(
                          'Iron: ✓',
                          style: TextStyle(fontSize: 12),
                        ),
                      if (activeBasket.fold)
                        const Text(
                          'Fold: ✓',
                          style: TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Est. Duration:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${context.read<BookingStateNotifier>().calculateBasketDuration(activeBasket)} min',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact button for weight control
class _CompactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CompactButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Service list item widget - full width, spacious design
class _ServiceListItem extends StatelessWidget {
  final String title;
  final int count;
  final bool isPremium;
  final List<LaundryService> services;
  final String serviceType;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Function(bool)? onPremiumChanged;
  final bool hasPremium;
  final bool disabled;
  final bool isToggle;
  final double weight;

  const _ServiceListItem({
    required this.title,
    required this.count,
    required this.isPremium,
    required this.services,
    required this.serviceType,
    required this.onIncrement,
    required this.onDecrement,
    this.onPremiumChanged,
    required this.hasPremium,
    required this.disabled,
    this.isToggle = false,
    required this.weight,
  });

  /// Get base service price per kg from services list
  double _getBasePrice() {
    try {
      final service = services.firstWhere(
        (s) => s.serviceType == serviceType && !s.name.toLowerCase().contains('premium'),
      );
      return service.ratePerKg;
    } catch (e) {
      // If base service not found, try to get any service of this type
      try {
        final service = services.firstWhere(
          (s) => s.serviceType == serviceType,
        );
        return service.ratePerKg;
      } catch (e) {
        return 0;
      }
    }
  }

  /// Get premium service price per kg from services list
  double _getPremiumPrice() {
    try {
      final service = services.firstWhere(
        (s) => s.serviceType == serviceType && s.name.toLowerCase().contains('premium'),
      );
      return service.ratePerKg;
    } catch (e) {
      return _getBasePrice(); // fallback to base price if premium not found
    }
  }

  /// Get base duration from services list
  int _getBaseDuration() {
    try {
      final service = services.firstWhere(
        (s) => s.serviceType == serviceType,
      );
      return service.baseDurationMinutes;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = _getBasePrice();
    final premiumPrice = _getPremiumPrice();
    final baseDuration = _getBaseDuration();
    final currentPrice = isPremium ? premiumPrice : basePrice;
    final totalDuration = baseDuration * count;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled ? Colors.grey[300]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Title row with price and duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: disabled ? Colors.grey[600] : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₱${currentPrice.toStringAsFixed(0)}/kg',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: disabled ? Colors.grey[600] : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${totalDuration}m',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: disabled ? Colors.grey[600] : Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Controls and premium row
          Row(
            children: [
              // Count display
              Text(
                isToggle ? (count > 0 ? '✓' : 'Off') : '${count}x',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: disabled ? Colors.grey[600] : Colors.blue,
                ),
              ),

              const SizedBox(width: 12),

              // Buttons
              if (!isToggle)
                Row(
                  children: [
                    _ControlButton(
                      icon: Icons.remove,
                      onPressed: disabled ? null : onDecrement,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    _ControlButton(
                      icon: Icons.add,
                      onPressed: disabled ? null : onIncrement,
                      size: 28,
                    ),
                  ],
                )
              else
                _ControlButton(
                  icon: count > 0 ? Icons.check : Icons.add,
                  onPressed: disabled ? null : onIncrement,
                  size: 28,
                  isActive: count > 0,
                ),

              const Spacer(),

              // Premium checkbox
              if (hasPremium)
                GestureDetector(
                  onTap: disabled ? null : () => onPremiumChanged?.call(!isPremium),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isPremium,
                          onChanged: disabled
                              ? null
                              : (value) {
                                  onPremiumChanged?.call(value ?? false);
                                },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 13,
                          color: disabled ? Colors.grey[600] : Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Control button for service increment/decrement
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    this.onPressed,
    this.size = 28,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onPressed == null
              ? Colors.grey[300]
              : isActive
                  ? Colors.green
                  : Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: onPressed == null ? Colors.grey[600] : Colors.white,
        ),
      ),
    );
  }
}
