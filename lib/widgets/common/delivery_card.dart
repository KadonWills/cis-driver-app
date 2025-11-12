import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_theme.dart';
import '../../models/delivery_model.dart';
import '../../core/utils/app_icons.dart';
import 'package:intl/intl.dart';

class DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine card color and gradient based on delivery status
    Color cardColor;
    List<List<dynamic>> statusIcon;
    Color iconColor;
    
    if (delivery.status == DeliveryStatus.delivered) {
      cardColor = AppTheme.deliveryCardYellow;
      statusIcon = AppIcons.checkmarkCircle;
      iconColor = AppTheme.accentColor;
    } else if (delivery.status == DeliveryStatus.inTransit || 
               delivery.status == DeliveryStatus.pickedUp) {
      cardColor = AppTheme.deliveryCardPink;
      statusIcon = AppIcons.car;
      iconColor = AppTheme.accentColor;
    } else if (delivery.status == DeliveryStatus.assigned) {
      cardColor = AppTheme.deliveryCardPink.withOpacity(0.7);
      statusIcon = AppIcons.clock;
      iconColor = AppTheme.accentColor;
    } else {
      cardColor = AppTheme.primaryBackground;
      statusIcon = AppIcons.clock;
      iconColor = AppTheme.textSecondary;
    }

    final cardContent = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            cardColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: iconColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: isHorizontal
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${delivery.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                              icon: statusIcon,
                              size: 14,
                              color: iconColor,
                          ),
                            const SizedBox(width: 6),
                          Text(
                            delivery.statusDisplayText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                            ),
                          ),
                        ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(delivery.requestedDeliveryTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HugeIcon(
                  icon: AppIcons.box,
                    size: 32,
                    color: iconColor,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${delivery.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                        icon: statusIcon,
                        size: 14,
                        color: iconColor,
                    ),
                      const SizedBox(width: 6),
                    Text(
                      delivery.status == DeliveryStatus.delivered
                          ? 'Received'
                          : delivery.statusDisplayText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                      ),
                    ),
                  ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(
                    delivery.actualDeliveryTime ?? delivery.requestedDeliveryTime,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  child: HugeIcon(
                    icon: AppIcons.box,
                      size: 24,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

