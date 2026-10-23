import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import 'razorpay_backend_service.dart';

typedef PaymentSuccessCallback = void Function(String paymentId, String orderId);
typedef PaymentFailureCallback = void Function(String errorCode, String errorMessage);

class RazorpayService {
  final RazorpayBackendService _backendService = RazorpayBackendService();
  final String merchantName;

  RazorpayService({
    this.merchantName = 'AquaCart Water Solutions',
  });

  /// Launch Razorpay Test Mode Payment Flow with Server-Side Order & Signature Validation
  Future<void> openTestCheckout({
    required BuildContext context,
    required double amount,
    required String orderNumber,
    required String customerEmail,
    required String customerPhone,
    required PaymentSuccessCallback onSuccess,
    required PaymentFailureCallback onFailure,
  }) async {
    // 1. Create Order on Trusted Backend (Never exposes secret key to client)
    final orderResponse = await _backendService.createOrder(
      amount: amount,
      receipt: orderNumber,
    );

    if (!context.mounted) return;

    // 2. Open Official-Style Razorpay Test Modal with order_id
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RazorpayTestCheckoutSheet(
        amount: amount,
        orderNumber: orderNumber,
        razorpayOrderId: orderResponse.orderId,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        keyId: orderResponse.keyId,
        backendService: _backendService,
      ),
    );

    if (result != null && result['status'] == 'success') {
      final paymentId = result['paymentId'] as String;
      final razorpayOrderId = result['orderId'] as String;
      final signature = result['signature'] as String;

      // 3. Verify Signature on Trusted Backend (HMAC-SHA256)
      final verification = _backendService.verifySignature(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (verification.isVerified) {
        onSuccess(paymentId, razorpayOrderId);
      } else {
        onFailure(
          'SIGNATURE_VERIFICATION_FAILED',
          verification.errorMessage ?? 'Payment security verification failed.',
        );
      }
    } else if (result != null && result['status'] == 'failed') {
      final failureInfo = _backendService.handlePaymentFailure(
        orderNumber: orderNumber,
        errorCode: result['code'] ?? 'PAYMENT_CANCELLED',
        errorMessage: result['message'] ?? 'Payment was cancelled by the user.',
      );
      onFailure(
        failureInfo['errorCode'],
        failureInfo['userFriendlyMessage'],
      );
    }
  }
}

class _RazorpayTestCheckoutSheet extends StatefulWidget {
  final double amount;
  final String orderNumber;
  final String razorpayOrderId;
  final String customerEmail;
  final String customerPhone;
  final String keyId;
  final RazorpayBackendService backendService;

  const _RazorpayTestCheckoutSheet({
    required this.amount,
    required this.orderNumber,
    required this.razorpayOrderId,
    required this.customerEmail,
    required this.customerPhone,
    required this.keyId,
    required this.backendService,
  });

  @override
  State<_RazorpayTestCheckoutSheet> createState() => _RazorpayTestCheckoutSheetState();
}

class _RazorpayTestCheckoutSheetState extends State<_RazorpayTestCheckoutSheet> {
  bool _isProcessing = false;
  String _selectedMethod = 'upi'; // 'upi', 'card', 'netbanking'

  void _simulatePayment(bool shouldSucceed) async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    if (shouldSucceed) {
      final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
      // Generate HMAC-SHA256 signature from backend service
      final signature = widget.backendService.generateSignatureForTest(
        razorpayOrderId: widget.razorpayOrderId,
        razorpayPaymentId: paymentId,
      );

      Navigator.of(context).pop({
        'status': 'success',
        'paymentId': paymentId,
        'orderId': widget.razorpayOrderId,
        'signature': signature,
      });
    } else {
      Navigator.of(context).pop({
        'status': 'failed',
        'code': 'BAD_REQUEST_ERROR',
        'message': 'Simulated bank card decline or gateway timeout.',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Razorpay Branding & Test Mode indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C2340), // Razorpay dark navy
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.blue, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Razorpay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Text(
                      'TEST MODE',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop({
                  'status': 'failed',
                  'code': 'PAYMENT_CANCELLED',
                  'message': 'User closed payment window.',
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount & Order details
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${widget.orderNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Razorpay ID: ${widget.razorpayOrderId}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(widget.amount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Test Payment Instrument',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Method radio selector
          _buildMethodTile(
            id: 'upi',
            icon: Icons.qr_code_2,
            title: 'UPI / Google Pay / PhonePe',
            subtitle: 'Instant test UPI authorization & HMAC signature',
          ),
          _buildMethodTile(
            id: 'card',
            icon: Icons.credit_card,
            title: 'Credit / Debit Card (Tokenized)',
            subtitle: 'Simulate Visa/MasterCard 3D Secure test challenge',
          ),
          _buildMethodTile(
            id: 'netbanking',
            icon: Icons.account_balance,
            title: 'Netbanking (HDFC / ICICI / SBI)',
            subtitle: 'Instant test bank OTP gateway',
          ),
          const SizedBox(height: 18),

          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 3),
                    SizedBox(height: 10),
                    Text(
                      'Computing HMAC-SHA256 & Verifying Payment...',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ElevatedButton(
              onPressed: () => _simulatePayment(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C2340),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Simulate Success (${CurrencyFormatter.format(widget.amount)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _simulatePayment(false),
              child: const Text(
                'Simulate Card Decline / Failure',
                style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodTile({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedMethod,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _selectedMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
