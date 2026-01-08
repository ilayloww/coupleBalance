import 'dart:io';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../services/localization_service.dart';
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
  File? _imageFile;
  ThemeMode? _selectedThemeMode;
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Initialize local state from services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeService = Provider.of<ThemeService>(context, listen: false);
      final localizationService = Provider.of<LocalizationService>(
        context,
        listen: false,
      );
      setState(() {
        _selectedThemeMode = themeService.themeMode;
        _selectedLocale = localizationService.locale;
      });
    });
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
          _photoUrl = doc.data()?['photoUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    try {
      if (user != null) {
        String? newPhotoUrl = _photoUrl;

        // Upload new image if selected
        if (_imageFile != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');

          await storageRef.putFile(_imageFile!);
          newPhotoUrl = await storageRef.getDownloadURL();
        }

        // Update Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _nameController.text.trim(),
          if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
          'photoBase64': FieldValue.delete(),
        }, SetOptions(merge: true));

        // Update local state helpers
        if (newPhotoUrl != null) {
          setState(() => _photoUrl = newPhotoUrl);
        }

        // Apply Theme Change
        if (_selectedThemeMode != null && mounted) {
          Provider.of<ThemeService>(
            context,
            listen: false,
          ).setThemeMode(_selectedThemeMode!);
        }

        // Apply Language Change
        if (_selectedLocale != null && mounted) {
          Provider.of<LocalizationService>(
            context,
            listen: false,
          ).setLocale(_selectedLocale!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileUpdated),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
          ), // Fallback string as we might not have 'errorSaving' key
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myProfile),
        // Remove hardcoded colors, let Theme handle it
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_photoUrl != null
                              ? CachedNetworkImageProvider(_photoUrl!)
                              : null as ImageProvider?),
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
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.displayName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: user?.email,
              readOnly: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.email,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 32),

            _ThemeSelector(
              currentMode: _selectedThemeMode ?? ThemeMode.system,
              onChanged: (mode) => setState(() => _selectedThemeMode = mode),
            ),
            const SizedBox(height: 16),
            _LanguageSelector(
              currentLocale: _selectedLocale ?? const Locale('en'),
              onChanged: (locale) => setState(() => _selectedLocale = locale),
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
                    : Text(
                        AppLocalizations.of(context)!.saveProfile,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
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
                label: Text(
                  AppLocalizations.of(context)!.logout,
                  style: const TextStyle(color: Colors.red),
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
          AppLocalizations.of(context)!.appearance,
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
                label: AppLocalizations.of(context)!.system,
                icon: Icons.brightness_auto,
                isSelected: currentMode == ThemeMode.system,
                onTap: () => onChanged(ThemeMode.system),
              ),
              _ThemeOption(
                label: AppLocalizations.of(context)!.light,
                icon: Icons.light_mode,
                isSelected: currentMode == ThemeMode.light,
                onTap: () => onChanged(ThemeMode.light),
              ),
              _ThemeOption(
                label: AppLocalizations.of(context)!.dark,
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

class _LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  const _LanguageSelector({
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.language,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: currentLocale,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Row(
                    children: [
                      const Text('🇺🇸 '),
                      Text(AppLocalizations.of(context)!.english),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: const Locale('tr'),
                  child: Row(
                    children: [
                      const Text('🇹🇷 '),
                      Text(AppLocalizations.of(context)!.turkish),
                    ],
                  ),
                ),
              ],
              onChanged: (locale) {
                if (locale != null) {
                  onChanged(locale);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
