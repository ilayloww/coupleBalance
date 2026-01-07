import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc.data()?['displayName'] ?? '';
          _photoUrl =
              doc.data()?['photoUrl'] ??
              doc.data()?['photoBase64']; // Fallback temporarily if needed, but user said delete older. Let's stick to photoUrl primarily, but maybe keep 'photoBase64' check just for reading old data if it wasn't deleted yet? User said "I will delete older photos now", implying manual deletion or he doesn't care. I'll stick to photoUrl mostly but reading old field doesn't hurt.
          // Actually, let's just look at 'photoUrl'.
          _photoUrl = doc.data()?['photoUrl'];
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    // High quality as requested
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (!mounted) return;

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final user = Provider.of<AuthService>(
          context,
          listen: false,
        ).currentUser;
        if (user == null) return;

        final file = File(pickedFile.path);

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        try {
          // Explicitly wait for upload to complete
          await storageRef.putFile(file);
        } catch (e) {
          throw 'Upload failed: $e';
        }

        String downloadUrl;
        try {
          downloadUrl = await storageRef.getDownloadURL();
        } catch (e) {
          throw 'Getting URL failed: $e';
        }

        // Store URL in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'photoUrl': downloadUrl,
          'photoBase64': FieldValue.delete(), // Cleanup old field
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _photoUrl = downloadUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        // Remove hardcoded colors, let Theme handle it
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isLoading ? null : _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundImage: _photoUrl != null
                        ? CachedNetworkImageProvider(_photoUrl!)
                        : null,
                    child: _photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 70,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.pinkAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: user?.email,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 32),

            _ThemeSelector(
              currentMode: themeService.themeMode,
              onChanged: (mode) => themeService.setThemeMode(mode),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close profile screen first
                  Provider.of<AuthService>(context, listen: false).signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onChanged;

  const _ThemeSelector({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _ThemeOption(
                label: 'System',
                icon: Icons.brightness_auto,
                isSelected: currentMode == ThemeMode.system,
                onTap: () => onChanged(ThemeMode.system),
              ),
              _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode,
                isSelected: currentMode == ThemeMode.light,
                onTap: () => onChanged(ThemeMode.light),
              ),
              _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode,
                isSelected: currentMode == ThemeMode.dark,
                onTap: () => onChanged(ThemeMode.dark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.pinkAccent
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.pinkAccent
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
