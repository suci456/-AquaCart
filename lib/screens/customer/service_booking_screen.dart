import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/service_card.dart';

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

  final List<String> _slots = [
    'Morning (9AM-1PM)',
    'Afternoon (1PM-5PM)',
    'Evening (5PM-8PM)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _modelController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  void _bookService() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final serviceProv = Provider.of<ServiceProvider>(context, listen: false);

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final address = auth.user.addresses.isNotEmpty
        ? auth.user.addresses.first
        : MockDataService.defaultAddress;

    await serviceProv.bookNewService(
      user: auth.user,
      serviceType: _selectedType,
      purifierBrandModel: _modelController.text.trim(),
      issueDescription: _issueController.text.trim(),
      preferredDate: _selectedDate,
      preferredSlot: _selectedSlot,
      address: address,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service request booked! A technician will be assigned shortly.'),
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
    final myRequests = serviceProv.getRequestsForUser(auth.user.uid);

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
            Tab(text: 'Service Requests (${myRequests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Book New Service Form
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
                          'Doorstep service by verified & background-checked Califnco technicians with genuine spare parts.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Select Service Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                // Service type cards
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
                const Text('Purifier Brand / Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. AquaPure Alkaline RO, Kent Grand Plus, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Issue Details / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _issueController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Describe issue (water leakage, low flow, taste change, TDS level)...',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Preferred Service Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
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
          // Tab 2: Service Requests History
          myRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handyman_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 14),
                      const Text('No service requests yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myRequests.length,
                  itemBuilder: (ctx, index) {
                    return ServiceCard(request: myRequests[index]);
                  },
                ),
        ],
      ),
    );
  }
}
