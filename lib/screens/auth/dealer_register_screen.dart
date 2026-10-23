import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../dealer/dealer_dashboard_screen.dart';

class DealerRegisterScreen extends StatefulWidget {
  const DealerRegisterScreen({super.key});

  @override
  State<DealerRegisterScreen> createState() => _DealerRegisterScreenState();
}

class _DealerRegisterScreenState extends State<DealerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Vikram Patel');
  final _companyController = TextEditingController(text: 'AquaTech Water Solutions Pvt Ltd');
  final _gstController = TextEditingController(text: '29AABCU9603R1ZM');
  final _licenseController = TextEditingController(text: 'TL-BLR-2024-8849');
  final _phoneController = TextEditingController(text: '+91 98220 54321');
  final _emailController = TextEditingController(text: 'dealer@aquatechsolutions.com');
  final _passwordController = TextEditingController(text: 'dealerPass123');

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.registerDealer(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      companyName: _companyController.text.trim(),
      gstNumber: _gstController.text.trim(),
      tradeLicense: _licenseController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dealer account approved! Welcome to AquaCart Wholesale.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DealerDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer Partnership Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // B2B Wholesale Perks Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.dealerGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AquaCart B2B Dealer Program',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Up to 40% wholesale margin on RO purifiers\n• Direct factory dispatch for bulk orders\n• 15-day dealer credit line upon verification\n• Dedicated priority technical support',
                      style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Business Information',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company / Store Registered Name *',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gstController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'GSTIN Number *',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                      validator: (val) => val == null || val.length < 15 ? 'Invalid GSTIN' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: 'Trade License / MSME',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Authorized Contact Person',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Business Contact Phone *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Official Business Email *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Create Dealer Password *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 28),
              AppButton(
                text: 'Submit Application & Enter Portal',
                isLoading: auth.isLoading,
                gradient: AppColors.dealerGradient,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
