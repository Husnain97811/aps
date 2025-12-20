import 'package:aps/config/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final DateTime createdAt = _parseUserCreatedAt(user);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.aBeeZee(fontSize: 18.sp)),
        backgroundColor: AppColors.darkbrown,
      ),
      body: FutureBuilder(
        future: _fetchUserName(user),
        builder: (context, snapshot) {
          final userName = snapshot.data ?? 'User';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileSection(user, userName, createdAt),
              const SizedBox(height: 20),
              _buildAppSettingsSection(),
              const SizedBox(height: 20),
              _buildAboutSection(),
              const SizedBox(height: 30),
              // _buildLogoutButton(context),
            ],
          );
        },
      ),
    );
  }

  Future<String> _fetchUserName(User? user) async {
    if (user == null) return 'User';

    try {
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select('full_name')
              .eq('id', user.id)
              .single();

      return response['full_name'] as String? ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  DateTime _parseUserCreatedAt(User? user) {
    try {
      if (user == null) return DateTime.now();

      final dynamic createdAt = user.createdAt;

      if (createdAt is DateTime) {
        return createdAt;
      } else if (createdAt is String) {
        return DateTime.parse(createdAt);
      }

      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Widget _buildProfileSection(User? user, String userName, DateTime createdAt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Name'),
              subtitle: Text(
                userName,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(
                user?.email ?? 'No email',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Joined'),
              subtitle: Text(
                DateFormat('MMM dd, yyyy').format(createdAt),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: Switch(
                value: true,
                onChanged: null, // Disabled
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Light Theme'),
              trailing: DropdownButton<String>(
                value: 'System',
                items: const [
                  DropdownMenuItem(value: 'System', child: Text('System')),
                  DropdownMenuItem(value: 'Light', child: Text('Light')),
                  DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                ],
                onChanged: null, // Disabled
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Version'),
              subtitle: const Text('2.1.1'),
            ),
            // Subtle self-promotion
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('App Development'),
              subtitle: const Text('Crafted by UH Tech Solution'),
              onTap: () {
                // Could open your portfolio website if needed
              },
            ),

            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () {
                // Add privacy policy navigation
              },
            ),
            // Hidden gem - only visible if scrolled down
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Text(
                  'Custom solutions for your business needs \n          uhtechofficial@gmail.com       ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildLogoutButton(BuildContext context) {
  //   return ElevatedButton.icon(
  //     icon: const Icon(Icons.logout),
  //     label: const Text('Log Out'),
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Colors.red,
  //       foregroundColor: Colors.white,
  //       padding: const EdgeInsets.symmetric(vertical: 16),
  //     ),
  //     onPressed: () async {
  //       await Supabase.instance.client.auth.signOut();
  //       // Add navigation to login screen
  //     },
  //   );
  // }
}
