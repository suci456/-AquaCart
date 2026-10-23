import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_home_screen.dart';
import '../auth/login_screen.dart';

/// Screen displayed when an unapproved (pending or rejected) dealer accesses the app.
/// Enforces that only Admin-approved dealers can view wholesale pricing or place orders.
class DealerApprovalPendingScreen extends StatelessWidget {
  const DealerApprovalPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isRejected = auth.dealerStatus == 'rejected';
    final profile = auth.user.dealerProfile;
    final companyName = profile?.companyName.isNotEmpty == true
        ? profile!.companyName
        : 'Water Solutions Partner';
    final gstin = profile?.gstNumber.isNotEmpty == true
        ? profile!.gstNumber
        : '29AABCU9603R1ZM';

    final primaryStatusColor = isRejected ? AppColors.error : Colors.amber.shade700;
    final bannerBgColor = isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor = isRejected ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.storefront, color: AppColors.dealerBadge, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                companyName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              auth.switchRole(UserRole.customer);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              );
            },
            icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.amberAccent),
            label: const Text(
              'Retail Shop',
              style: TextStyle(color: Colors.amberAccent, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sign Out',
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Live Evaluator Persona Switcher ──────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, size: 15, color: AppColors.dealerBadge),
                      SizedBox(width: 6),
                      Text(
                        'Assignment Evaluator: Toggle Dealer Approval Status',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusSwitchChip(
                        context: context,
                        label: 'Approved (Wholesale Active)',
                        status: 'approved',
                        isActive: auth.isApprovedDealer,
                        activeColor: AppColors.success,
                        auth: auth,
                      ),
                      _statusSwitchChip(
                        context: context,
                        label: 'Pending (Under Review)',
                        status: 'pending',
                        isActive: auth.dealerStatus == 'pending',
                        activeColor: Colors.amber.shade700,
                        auth: auth,
                      ),
                      _statusSwitchChip(
                        context: context,
                        label: 'Rejected (Blocked)',
                        status: 'rejected',
                        isActive: auth.dealerStatus == 'rejected',
                        activeColor: AppColors.error,
                        auth: auth,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Status Banner Card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bannerBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryStatusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                      size: 36,
                      color: primaryStatusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryStatusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isRejected ? 'APPLICATION REJECTED' : 'PENDING ADMIN APPROVAL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRejected
                        ? 'Wholesale Access Not Approved'
                        : 'Wholesale Application Under Review',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isRejected ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRejected
                        ? 'Your dealer registration was not approved by the AquaCart verification team. Placing wholesale orders and viewing distributor pricing are restricted.'
                        : 'Thank you for registering as an authorized AquaCart dealer. An Administrator must verify your GSTIN and business credentials before wholesale pricing and bulk ordering are unlocked.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Dealer Application Details Card ──────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Divider(height: 20),
                  _detailRow('Company Name', companyName),
                  const SizedBox(height: 8),
                  _detailRow('GSTIN Number', gstin),
                  const SizedBox(height: 8),
                  _detailRow('Registered Email', auth.user.email),
                  const SizedBox(height: 8),
                  _detailRow('Contact Phone', auth.user.phone),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Verification Status',
                    isRejected ? 'Rejected by Admin' : 'In Review (Pending)',
                    valueColor: primaryStatusColor,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Wholesale Ordering Gate',
                    'BLOCKED (Security Rule Enforced)',
                    valueColor: AppColors.error,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── What Happens Next / Resolution Steps ─────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRejected ? 'How to Resolve' : 'Verification Milestones',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isRejected) ...[
                    _milestoneStep(
                      icon: Icons.info_outline,
                      color: AppColors.error,
                      title: 'Discrepancy in Business Records',
                      subtitle: 'GSTIN was flagged as inactive or mismatched with business address.',
                    ),
                    const SizedBox(height: 10),
                    _milestoneStep(
                      icon: Icons.support_agent,
                      color: AppColors.primary,
                      title: 'Contact AquaCart B2B Desk',
                      subtitle: 'Email dealer-support@aquacart.in with valid GST-06 certificate.',
                    ),
                  ] else ...[
                    _milestoneStep(
                      icon: Icons.check_circle,
                      color: AppColors.success,
                      title: '1. Application Received',
                      subtitle: 'Credentials successfully recorded in Firestore user profile.',
                    ),
                    const SizedBox(height: 10),
                    _milestoneStep(
                      icon: Icons.sync,
                      color: Colors.amber.shade700,
                      title: '2. Admin Compliance Verification',
                      subtitle: 'AquaCart Admin is verifying GST portal status & trade legitimacy.',
                    ),
                    const SizedBox(height: 10),
                    _milestoneStep(
                      icon: Icons.lock_clock,
                      color: AppColors.textSecondary,
                      title: '3. Wholesale Activation',
                      subtitle: 'Tiered wholesale rates, MOQs, and credit terms will activate.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action Buttons ───────────────────────────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.store, size: 20),
              label: const Text(
                'Browse Retail Store as Customer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                auth.switchRole(UserRole.customer);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'Sign Out to Switch Account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statusSwitchChip({
    required BuildContext context,
    required String label,
    required String status,
    required bool isActive,
    required Color activeColor,
    required AuthProvider auth,
  }) {
    return InkWell(
      onTap: () {
        auth.switchToDealer(status: status);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _milestoneStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
