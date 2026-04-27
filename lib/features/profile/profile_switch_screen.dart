import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/profile_model.dart';

class ProfileSwitchScreen extends StatelessWidget {
  const ProfileSwitchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Switch Profile')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircleAvatar(
              radius: 40,
              backgroundImage: authProvider.photoUrl != null ? NetworkImage(authProvider.photoUrl!) : null,
              child: authProvider.photoUrl == null ? const Icon(Icons.person, size: 40) : null,
            ),
          ),
          Text(
            userProvider.userProfile?.name ?? 'User',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: userProvider.profiles.length,
              itemBuilder: (context, index) {
                final profile = userProvider.profiles[index];
                final isSelected = userProvider.selectedProfile?.profileId == profile.profileId;

                return ListTile(
                  title: Text(profile.profileType.name.toUpperCase()),
                  subtitle: Text('ID: ${profile.profileId.substring(0, 8)}...'),
                  leading: Icon(
                    profile.profileType == ProfileType.personal ? Icons.person_outline : Icons.business,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () {
                    userProvider.selectProfile(profile);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          if (userProvider.profiles.length < 2)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text('Add ${userProvider.profiles.any((p) => p.profileType == ProfileType.business) ? 'Personal' : 'Business'} Profile'),
                onPressed: () async {
                  final typeToAdd = userProvider.profiles.any((p) => p.profileType == ProfileType.business)
                      ? ProfileType.personal
                      : ProfileType.business;
                  await userProvider.addProfile(authProvider.user!.uid, typeToAdd);
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
