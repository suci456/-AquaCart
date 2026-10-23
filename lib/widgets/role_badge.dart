import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool isCompact;

  const RoleBadge({
    super.key,
    required this.role,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (role) {
      case UserRole.customer:
        bg = AppColors.primary.withOpacity(0.12);
        fg = AppColors.primary;
        label = 'Customer';
        icon = Icons.person_outline;
        break;
      case UserRole.dealer:
        bg = AppColors.dealerBadge.withOpacity(0.15);
        fg = AppColors.dealerBadge;
        label = 'Dealer Wholesale (B2B)';
        icon = Icons.storefront_outlined;
        break;
      case UserRole.admin:
        bg = AppColors.adminBadge.withOpacity(0.15);
        fg = AppColors.adminBadge;
        label = 'Admin Console';
        icon = Icons.admin_panel_settings_outlined;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 13 : 16, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
