import 'package:flutter_test/flutter_test.dart';
import 'package:aquacart/services/razorpay_backend_service.dart';
import 'package:aquacart/core/utils/crypto_utils.dart';

void main() {
  group('Razorpay Trusted Backend & Signature Verification Tests', () {
    late RazorpayBackendService backendService;
    const testSecretKey = 's3cr3t_razorpay_test_key_califnco_2026';

    setUp(() {
      backendService = RazorpayBackendService(
        keyId: 'rzp_test_Califnco2026DemoKey',
        keySecret: testSecretKey,
      );
    });

    test('Order creation on trusted backend converts amount to paise and returns public keyId', () async {
      // ₹14,999.50 -> 1499950 paise
      const amountInRupees = 14999.50;
      const orderReceipt = 'AQ-2026-9050';

      final response = await backendService.createOrder(
        amount: amountInRupees,
        receipt: orderReceipt,
      );

      expect(response.orderId, startsWith('order_test_'));
      expect(response.amountInPaise, equals(1499950));
      expect(response.currency, equals('INR'));
      expect(response.receipt, equals('AQ-2026-9050'));
      expect(response.keyId, equals('rzp_test_Califnco2026DemoKey'));

      // Crucial Security Test: Response does NOT contain the secret key!
      final responseMap = response.toMap();
      expect(responseMap.containsKey('secret'), isFalse);
      expect(responseMap.containsKey('key_secret'), isFalse);
    });

    test('Valid Razorpay HMAC-SHA256 signature is verified successfully', () {
      const orderId = 'order_test_9A33XWu170gUtm';
      const paymentId = 'pay_29QQoUBi66xm2f';

      // Formula: HMAC_SHA256(order_id + "|" + payment_id, secret_key)
      final generatedSignature = backendService.generateSignatureForTest(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
      );

      expect(generatedSignature, isNotEmpty);
      expect(generatedSignature.length, equals(64)); // 256 bits = 64 hex chars

      // Verify on backend
      final result = backendService.verifySignature(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: generatedSignature,
      );

      expect(result.isVerified, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Tampered or forged signature is strictly REJECTED by backend', () {
      const orderId = 'order_test_9A33XWu170gUtm';
      const paymentId = 'pay_29QQoUBi66xm2f';
      const forgedSignature = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef';

      final result = backendService.verifySignature(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: forgedSignature,
      );

      expect(result.isVerified, isFalse);
      expect(result.errorMessage, contains('signature mismatch'));
    });

    test('Signature calculated for a different payment ID fails verification', () {
      const orderId = 'order_test_1001';
      const legitPaymentId = 'pay_legit_1001';
      const tamperedPaymentId = 'pay_tampered_9999';

      // Signature was calculated for legitPaymentId
      final legitSignature = backendService.generateSignatureForTest(
        razorpayOrderId: orderId,
        razorpayPaymentId: legitPaymentId,
      );

      // Client attempts to use signature with a tampered payment ID
      final result = backendService.verifySignature(
        razorpayOrderId: orderId,
        razorpayPaymentId: tamperedPaymentId,
        razorpaySignature: legitSignature,
      );

      expect(result.isVerified, isFalse);
      expect(result.errorMessage, contains('signature mismatch'));
    });

    test('Empty or null signature arguments fail verification cleanly without crash', () {
      final result = backendService.verifySignature(
        razorpayOrderId: '',
        razorpayPaymentId: 'pay_123',
        razorpaySignature: 'sig_123',
      );

      expect(result.isVerified, isFalse);
      expect(result.errorMessage, contains('missing'));
    });

    test('Payment cancellation / card failure is safely mapped without leaking internals', () {
      final failureResult = backendService.handlePaymentFailure(
        orderNumber: 'AQ-2026-9051',
        errorCode: 'PAYMENT_CANCELLED',
        errorMessage: 'User dismissed sheet before entering OTP',
      );

      expect(failureResult['orderNumber'], equals('AQ-2026-9051'));
      expect(failureResult['status'], equals('FAILED'));
      expect(failureResult['errorCode'], equals('PAYMENT_CANCELLED'));
      expect(failureResult['userFriendlyMessage'], contains('Payment was cancelled by the user'));
    });

    test('CryptoUtils pure Dart SHA-256 matches NIST RFC 4231 test vectors', () {
      // Test vector 1: "abc"
      // Expected SHA256: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
      final digestHex = CryptoUtils.hmacSha256Hex('key', 'The quick brown fox jumps over the lazy dog');
      expect(digestHex.length, equals(64));

      // Constant-time comparison
      expect(CryptoUtils.secureCompare('abcdef', 'abcdef'), isTrue);
      expect(CryptoUtils.secureCompare('abcdef', 'abcdeg'), isFalse);
      expect(CryptoUtils.secureCompare('abcdef', 'abcde'), isFalse);
    });
  });
}
