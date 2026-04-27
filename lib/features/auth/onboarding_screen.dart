import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/profile_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  ProfileType _selectedType = ProfileType.personal;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.user?.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome! Let\'s get to know you.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 24),
              const Text('Initial Profile Type:'),
              ListTile(
                title: const Text('Personal'),
                leading: Radio<ProfileType>(
                  value: ProfileType.personal,
                  groupValue: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),
              ListTile(
                title: const Text('Business'),
                leading: Radio<ProfileType>(
                  value: ProfileType.business,
                  groupValue: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: userProvider.loading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await userProvider.completeOnboarding(
                        userId: authProvider.user!.uid,
                        name: _nameController.text.trim(),
                        initialProfileType: _selectedType,
                        email: authProvider.user?.email,
                        phone: authProvider.user?.phoneNumber,
                        photoUrl: authProvider.user?.photoURL,
                        providers: authProvider.linkedProviders,
                      );
                      // Navigator will be handled by the auth wrapper
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: userProvider.loading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Finish Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
