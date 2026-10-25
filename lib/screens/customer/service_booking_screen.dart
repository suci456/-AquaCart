import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/user_model.dart';
import '../../models/service_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/service_card.dart';
import '../../widgets/maps_address_picker_sheet.dart';

class ServiceBookingScreen extends StatefulWidget {
  const ServiceBookingScreen({super.key});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ServiceType _selectedType = ServiceType.filterReplacement;
  final _modelController = TextEditingController(text: 'AquaPure Alkaline RO 12L');
  final _issueController = TextEditingController(text: 'Taste alteration noticed, TDS level reading 350 ppm.');
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = 'Morning (9AM-1PM)';
  bool _isSubmitting = false;
  late UserAddress _serviceAddress;

  final List<String> _slots = [
    'Morning (9AM-1PM)',
    'Afternoon (1PM-5PM)',
    'Evening (5PM-8PM)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _serviceAddress = (auth.user?.addresses.isNotEmpty ?? false)
        ? auth.user!.addresses.first
        : MockDataService.defaultAddress;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _modelController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  void _pickAddressOnMap() async {
    final updated = await MapsAddressPickerSheet.show(
      context,
      initialAddress: _serviceAddress,
    );
    if (updated != null) {
      setState(() => _serviceAddress = updated);
    }
  }

  void _bookService() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final serviceProv = Provider.of<ServiceProvider>(context, listen: false);
    final notifProv = Provider.of<NotificationProvider>(context, listen: false);

    final currentUser = auth.user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book a service')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final newRequest = await serviceProv.bookNewService(
      user: currentUser,
      serviceType: _selectedType,
      purifierBrandModel: _modelController.text.trim(),
      issueDescription: _issueController.text.trim(),
      preferredDate: _selectedDate,
      preferredSlot: _selectedSlot,
      address: _serviceAddress,
    );

    // Trigger instant FCM notification
    notifProv.notifyServiceBooked(newRequest);

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Service request ${newRequest.requestNumber} booked successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    // Switch to history tab
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final serviceProv = Provider.of<ServiceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final myRequests = serviceProv.getRequestsForUser(auth.user?.uid ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purifier Care & Service'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Book New Service'),
            Tab(text: 'My Requests (${myRequests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: BOOK NEW SERVICE FORM ──────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Certified doorstep service by background-verified Califnco technicians with genuine OEM filters & 100% genuine parts warranty.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Service Address with Map Pin Integration ─────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    TextButton.icon(
                      onPressed: _pickAddressOnMap,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Pin on Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.place, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _serviceAddress.label,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _serviceAddress.fullAddress,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_serviceAddress.latitude != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '📍 GPS Coordinates: ${_serviceAddress.latitude!.toStringAsFixed(4)}° N, ${_serviceAddress.longitude!.toStringAsFixed(4)}° E',
                                style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Service Type Selection ───────────────────────────────────
                const Text('Select Service Requirement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                ...ServiceType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            type == ServiceType.newInstallation
                                ? Icons.build_circle_outlined
                                : type == ServiceType.filterReplacement
                                    ? Icons.filter_alt_outlined
                                    : type == ServiceType.tdsCheckRepair
                                        ? Icons.speed_outlined
                                        : Icons.workspace_premium_outlined,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppConstants.serviceLabels[type] ?? type.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Radio<ServiceType>(
                            value: type,
                            groupValue: _selectedType,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Purifier Brand / Model
                const Text('Purifier Brand / Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. AquaPure Alkaline RO 12L, Kent Grand Plus, etc.',
                  ),
                ),
                const SizedBox(height: 16),

                // Issue Details
                const Text('Issue Details / Symptoms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                TextField(
                  controller: _issueController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Describe issue (water leakage, low flow, taste change, TDS level)...',
                  ),
                ),
                const SizedBox(height: 16),

                // Date Picker
                const Text('Preferred Service Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.formatDateOnly(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Icon(Icons.calendar_month, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Slot
                const Text('Preferred Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: _slots.map((slot) {
                    final isSelected = _selectedSlot == slot;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            slot.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          onSelected: (_) => setState(() => _selectedSlot = slot),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: 'Confirm Service Booking',
                  isLoading: _isSubmitting,
                  gradient: AppColors.aquaGradient,
                  onPressed: _bookService,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── TAB 2: SERVICE REQUESTS HISTORY ───────────────────────────────
          myRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handyman_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 14),
                      const Text('No service requests yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Book your purifier installation or filter replacement', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _tabController.animateTo(0),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Book Service Now', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myRequests.length,
                  itemBuilder: (ctx, index) {
                    final req = myRequests[index];
                    return ServiceCard(request: req);
                  },
                ),
        ],
      ),
    );
  }
}
