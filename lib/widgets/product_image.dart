import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/product_model.dart';

/// Smart product image widget.
/// Priority: localAssetImage (AI-generated) -> imageUrl (network CDN) -> icon fallback
class ProductImage extends StatelessWidget {
  final ProductModel product;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.product,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget;

    if (product.hasLocalAsset) {
      imageWidget = Image.asset(
        product.localAssetImage!,
        fit: fit,
        height: height,
        width: width ?? double.infinity,
        errorBuilder: (ctx, err, stack) => _networkFallback(),
      );
    } else {
      imageWidget = _networkFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _networkFallback() {
    return Image.network(
      product.imageUrl,
      fit: fit,
      height: height,
      width: width ?? double.infinity,
      loadingBuilder: (ctx, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _shimmerPlaceholder();
      },
      errorBuilder: (ctx, err, stack) => _iconFallback(),
    );
  }

  Widget _shimmerPlaceholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: AppColors.primary.withOpacity(0.05),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _iconFallback() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: AppColors.primary.withOpacity(0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_rounded, size: 48, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 6),
          Text('AquaCart', style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.5), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Small thumbnail version for cart, order history, etc.
class ProductImageThumb extends StatelessWidget {
  final ProductModel? product;
  final String? imageUrl;
  final String? localAsset;
  final double size;
  final double radius;

  const ProductImageThumb({
    super.key,
    this.product,
    this.imageUrl,
    this.localAsset,
    this.size = 60,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final String? assetPath = localAsset ?? product?.localAssetImage;
    final String netUrl = imageUrl ?? product?.imageUrl ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.background,
        child: assetPath != null && assetPath.isNotEmpty
            ? Image.asset(assetPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _netImage(netUrl, size))
            : _netImage(netUrl, size),
      ),
    );
  }

  Widget _netImage(String url, double s) {
    if (url.isEmpty) return _fallback(s);
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback(s));
  }

  Widget _fallback(double s) => Center(
    child: Icon(Icons.water_drop_rounded, size: s * 0.45, color: AppColors.primary),
  );
}
