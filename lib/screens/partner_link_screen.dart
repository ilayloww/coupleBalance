import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../utils/input_sanitizer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class PartnerLinkScreen extends StatefulWidget {
  final String? initialPartnerId;

  const PartnerLinkScreen({super.key, this.initialPartnerId});

  @override
  State<PartnerLinkScreen> createState() => _PartnerLinkScreenState();
}

class _PartnerLinkScreenState extends State<PartnerLinkScreen> {
  final _partnerIdController = TextEditingController();
  bool _isLoading = false;
  String? _myPartnerId;
  final _focusNode = FocusNode();
  bool _hasAttemptedAutoLink = false;
  bool _hasAttemptedIdGeneration = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.initialPartnerId != null) {
      _partnerIdController.text = widget.initialPartnerId!.replaceAll('-', '');
    }
  }

  Future<void> _checkAutoActions(AuthService authService) async {
    // 1. Generate/Get Partner ID if missing
    if (authService.currentUserModel != null &&
        authService.currentUserModel!.partnerId == null &&
        !_hasAttemptedIdGeneration) {
      _hasAttemptedIdGeneration = true;
      // Use a microtask/postFrame to avoid build-time setState
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() => _isLoading = true);
        final id = await authService.generatePartnerId();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _myPartnerId = id;
          });
        }
      });
    } else if (authService.currentUserModel?.partnerId != null) {
      // If we have it, ensure local state matches
      if (_myPartnerId != authService.currentUserModel!.partnerId) {
        // Update local state without rebuilding everything?
        // It's safe to set this here if we are careful, but better in postFrame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _myPartnerId != authService.currentUserModel!.partnerId) {
            setState(() {
              _myPartnerId = authService.currentUserModel!.partnerId;
            });
          }
        });
      }
    }

    // 2. Auto-Link if initialPartnerId provided
    if (widget.initialPartnerId != null &&
        !_hasAttemptedAutoLink &&
        authService.currentUserModel != null) {
      _hasAttemptedAutoLink = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _linkPartner();
      });
    }
  }

  Future<void> _linkPartner() async {
    // Original _linkPartner logic...
    // But we need to make sure we use the passed context or provider correctly.
    // Since we are taking this method from the existing code, I'll assume I'm keeping the body mostly same
    // but I need to make sure I don't paste the WHOLE file here.
    // I will call the ORIGINAL _linkPartner logic via the tool, but I am replacing lines 20-200.
    // So I need to provide the implementation of _linkPartner inside this replacement chunk.

    final partnerIdInput = _partnerIdController.text.trim().toUpperCase();
    if (partnerIdInput.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final currentUserModel = authService.currentUserModel;

      if (currentUser == null || currentUserModel == null) {
        // Should not happen if we waited for loading, but safety first
        return;
      }

      String formattedPartnerId = partnerIdInput;
      if (partnerIdInput.length == 8) {
        formattedPartnerId =
            '${partnerIdInput.substring(0, 4)}-${partnerIdInput.substring(4)}';
      }

      if (formattedPartnerId == _myPartnerId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.matchesOwnId)),
        );
        return;
      }

      // 1. Find partner by ID via Cloud Function (no direct user doc read)
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('lookupPartnerByCode');
      late final Map<String, dynamic> partnerData;

      try {
        final result = await callable.call({'partnerId': formattedPartnerId});
        partnerData = Map<String, dynamic>.from(result.data as Map);
      } on FirebaseFunctionsException catch (e) {
        if (!mounted) return;
        if (e.code == 'not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.partnerNotFound),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
        }
        return;
      }

      final partnerUid = partnerData['uid'] as String;
      final partnerDisplayName = partnerData['displayName'] as String;
      final partnerEmail = partnerData['email'] as String;

      // 2. Check if already linked
      if (currentUserModel.partnerUids.contains(partnerUid)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.partnerAlreadyLinked(partnerDisplayName),
            ),
          ),
        );
        return;
      }

      // 3. Check for existing pending request
      final existingRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('fromUid', isEqualTo: currentUser.uid)
          .where('toUid', isEqualTo: partnerUid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequests.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.requestAlreadySent),
          ),
        );
        return;
      }

      // 4. Create Friend Request
      final String fromName = (currentUserModel.displayName.isNotEmpty
          ? currentUserModel.displayName
          : (currentUser.displayName ?? currentUser.email ?? 'Unknown'));

      await FirebaseFirestore.instance.collection('friend_requests').add({
        'fromUid': currentUser.uid,
        'fromEmail': InputSanitizer.sanitizeAndTruncate(
          currentUserModel.email ?? currentUser.email ?? '',
          320,
        ),
        'fromName': InputSanitizer.sanitizeAndTruncate(fromName, 100),
        'toUid': partnerUid,
        'toEmail': InputSanitizer.sanitizeAndTruncate(partnerEmail, 320),
        'toName': InputSanitizer.sanitizeAndTruncate(partnerDisplayName, 100),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.friendRequestSent),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _QrScanScreen()),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _partnerIdController.text = result.replaceAll('-', '');
      });
    }
  }

  void _shareMyId() async {
    if (_myPartnerId != null) {
      // ignore: deprecated_member_use
      await Share.share(
        'Let\'s track expenses together on Couple Balance! Tap here to connect: https://couple-balance-app.web.app/invite.html?partnerId=$_myPartnerId',
      );
    }
  }

  void _copyMyId() {
    if (_myPartnerId != null) {
      Clipboard.setData(ClipboardData(text: _myPartnerId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.idCopied)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assuming dark theme based on requirements description
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // If loading or no user model yet, show loading
        if (authService.isLoading || authService.currentUserModel == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            ),
          );
        }

        // Run checks (non-blocking)
        _checkAutoActions(authService);

        return Scaffold(
          backgroundColor: const Color(0xFF121212), // Dark background
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.linkPartnerTitle,
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.connectWithPartnerTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.connectWithPartnerSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Partner ID Input
                  // Partner ID Header & Scan Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.partnerIdLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _onScanQr,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.qr_code_scanner,
                              color: Color(0xFF00E676),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.scan,
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Segmented Input Boxes
                  GestureDetector(
                    onTap: () {
                      // Ensure keyboard opens and cursor is at end
                      FocusScope.of(context).requestFocus(_focusNode);
                      final textLength = _partnerIdController.text.length;
                      _partnerIdController.selection =
                          TextSelection.fromPosition(
                            TextPosition(offset: textLength),
                          );
                    },
                    child: Container(
                      color: Colors.transparent, // Hit test target
                      child: Stack(
                        children: [
                          // Visual Layer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ...List.generate(
                                4,
                                (index) => _buildInputBox(index),
                              ),
                              const Text(
                                "-",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ...List.generate(
                                4,
                                (index) => _buildInputBox(index + 4),
                              ),
                            ],
                          ),
                          // Input Layer (Hidden but active for keyboard)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: TextField(
                                focusNode: _focusNode,
                                controller: _partnerIdController,
                                maxLength: 8,
                                keyboardType: TextInputType.visiblePassword,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: const TextStyle(
                                  color: Colors.transparent,
                                ),
                                cursorColor: Colors.transparent,
                                cursorWidth: 0,
                                showCursor: false,
                                enableInteractiveSelection: false,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  counterText: '',
                                  fillColor: Colors.transparent,
                                  filled: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9]'),
                                  ),
                                  UpperCaseTextFormatter(),
                                ],
                                onChanged: (val) {
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Link Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || _partnerIdController.text.isEmpty)
                          ? null
                          : _linkPartner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF00E676,
                        ), // Bright Green
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              AppLocalizations.of(context)!.linkAccounts,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppLocalizations.of(context)!.orShareYourId,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // My ID Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.myUniqueId,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _myPartnerId != null
                              ? QrImageView(
                                  data: _myPartnerId!,
                                  version: QrVersions.auto,
                                  size: 160.0,
                                  backgroundColor: Colors.white,
                                )
                              : const SizedBox(
                                  height: 160,
                                  width: 160,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        // ID Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _myPartnerId ??
                                    AppLocalizations.of(context)!.generating,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _copyMyId,
                                child: Icon(
                                  Icons.copy,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Send Invite Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _shareMyId,
                            icon: const Icon(Icons.ios_share, size: 20),
                            label: Text(
                              AppLocalizations.of(context)!.sendInvite,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _partnerIdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildInputBox(int index) {
    final text = _partnerIdController.text;
    final char = index < text.length ? text[index] : '';
    final isFocused = _focusNode.hasFocus && index == text.length;

    return Container(
      width: 40,
      height: 56, // "Boxes' height might be more"
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF00E676)
              : Colors.white.withValues(alpha: 0.3),
          width: isFocused ? 2 : 1,
        ),
      ),
      child: Text(
        char,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _QrScanScreen extends StatefulWidget {
  const _QrScanScreen();

  @override
  State<_QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<_QrScanScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.scanQrCode),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              setState(() {
                _isScanned = true;
              });
              Navigator.pop(context, barcode.rawValue);
              break; // Only need one
            }
          }
        },
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
