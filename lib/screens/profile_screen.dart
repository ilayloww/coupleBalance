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
import '../config/theme.dart';
import '../screens/partner_list_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/delete_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _photoUrl;
  File? _imageFile;
  ThemeMode? _selectedThemeMode;
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    if (!_isEditing) return; // Only pick image in edit mode
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

    if (mounted) {
      if (_selectedThemeMode != null) {
        Provider.of<ThemeService>(
          context,
          listen: false,
        ).setThemeMode(_selectedThemeMode!);
      }
      if (_selectedLocale != null) {
        Provider.of<LocalizationService>(
          context,
          listen: false,
        ).setLocale(_selectedLocale!);
      }
    }

    try {
      if (user != null) {
        String? newPhotoUrl = _photoUrl;

        if (_imageFile != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');

          await storageRef.putFile(_imageFile!);
          newPhotoUrl = await storageRef.getDownloadURL();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _nameController.text.trim(),
          if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
          'photoBase64': FieldValue.delete(),
        }, SetOptions(merge: true));

        if (newPhotoUrl != null) {
          setState(() => _photoUrl = newPhotoUrl);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false; // Exit edit mode
        });
      }
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF05100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.language,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.english,
                  style: const TextStyle(color: Colors.white),
                ),
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                trailing: _selectedLocale?.languageCode == 'en'
                    ? const Icon(Icons.check, color: AppTheme.emeraldPrimary)
                    : null,
                onTap: () {
                  setState(() => _selectedLocale = const Locale('en'));
                  Provider.of<LocalizationService>(
                    context,
                    listen: false,
                  ).setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.turkish,
                  style: const TextStyle(color: Colors.white),
                ),
                leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
                trailing: _selectedLocale?.languageCode == 'tr'
                    ? const Icon(Icons.check, color: AppTheme.emeraldPrimary)
                    : null,
                onTap: () {
                  setState(() => _selectedLocale = const Locale('tr'));
                  Provider.of<LocalizationService>(
                    context,
                    listen: false,
                  ).setLocale(const Locale('tr'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF05100A), // Deep dark green/black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.myProfile, // "Profile"
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            child: Text(
              _isEditing ? l10n.done : l10n.editProfile,
              style: const TextStyle(
                color: AppTheme.emeraldPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.emeraldPrimary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Avatar Section
                  GestureDetector(
                    onTap: () {
                      if (_isEditing) _pickImage();
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.emeraldPrimary.withValues(
                                alpha: 0.5,
                              ),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emeraldPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_photoUrl != null
                                      ? CachedNetworkImageProvider(_photoUrl!)
                                      : null as ImageProvider?),
                            child: _photoUrl == null && _imageFile == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white54,
                                  )
                                : null,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.emeraldPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  if (_isEditing)
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.displayName,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                      ),
                    )
                  else
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? l10n.noEmail,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Settings Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.settings, // "Settings"
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings List
                  _SettingsTile(
                    icon: Icons.favorite,
                    title: l10n.partnersTitle, // "Partners"
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PartnerListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.lock,
                    title: l10n.changePassword,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.language,
                    title: l10n.language,
                    trailingText: _selectedLocale?.languageCode == 'tr'
                        ? 'Türkçe'
                        : 'English',
                    onTap: _showLanguageSelector,
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    // Placeholder for Notifications
                    icon: Icons.notifications,
                    title: l10n.notifications,
                    onTap: () {
                      // Implement notification settings or toggle
                    },
                  ),

                  const SizedBox(height: 32),

                  // Logout & Delete
                  _SettingsTile(
                    icon: Icons.logout,
                    iconColor: Colors.redAccent,
                    title: l10n.logout,
                    textColor: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).signOut();
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.delete_forever,
                    iconColor: Colors.redAccent,
                    title: l10n.deleteAccountTitle,
                    textColor: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeleteAccountScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "Version 2.4.0 (Build 152)",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final String? trailingText;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05), // Glassy background
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.emeraldPrimary).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.emeraldPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    trailingText!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
