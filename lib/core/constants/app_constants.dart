enum UserRole {
  customer,
  dealer,
  admin,
}

enum ProductCategory {
  all,
  roPurifiers,
  commercialPurifiers,
  spareFilters,
  accessories,
  amcPlans,
}

enum OrderStatus {
  placed,
  confirmed,
  dispatched,
  outForDelivery,
  delivered,
  cancelled,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

enum ServiceType {
  newInstallation,
  filterReplacement,
  tdsCheckRepair,
  amcService,
}

enum ServiceStatus {
  requested,
  assigned,
  inProgress,
  completed,
  cancelled,
}

class AppConstants {
  static const String appName = 'AquaCart';
  static const String appTagline = 'Pure Water, Healthy Living';
  static const String currencySymbol = '₹';

  // Razorpay Test Mode Key (Injected via .env or fallback for test mode)
  static const String defaultRazorpayTestKey = 'rzp_test_1DP5mmOlF5G5ag';

  // Default GST Rate (18% on water purifiers and spare parts)
  static const double gstRate = 0.18;

  // Categories metadata
  static const Map<ProductCategory, String> categoryLabels = {
    ProductCategory.all: 'All Products',
    ProductCategory.roPurifiers: 'RO Purifiers',
    ProductCategory.commercialPurifiers: 'Commercial Plants',
    ProductCategory.spareFilters: 'Filters & Spares',
    ProductCategory.accessories: 'Accessories & Hardware',
    ProductCategory.amcPlans: 'AMC Plans',
  };

  static const Map<ServiceType, String> serviceLabels = {
    ServiceType.newInstallation: 'New Purifier Installation',
    ServiceType.filterReplacement: 'Filter / Membrane Replacement',
    ServiceType.tdsCheckRepair: 'TDS Check & General Repair',
    ServiceType.amcService: 'Annual Maintenance (AMC) Visit',
  };
}
