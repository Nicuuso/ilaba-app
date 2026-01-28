import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/notifications_provider.dart';
import 'package:ilaba/screens/notifications/notifications_center_screen.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

/// Notification bell icon with badge showing unread count
class NotificationBellWidget extends StatelessWidget {
  const NotificationBellWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsProvider>(
      builder: (context, provider, _) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsCenterScreen(),
                  ),
                );
              },
            ),
            // Badge showing unread count
            if (provider.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    provider.unreadCount > 99
                        ? '99+'
                        : '${provider.unreadCount}',
                    style: const TextStyle(
                      color: ILabaColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
