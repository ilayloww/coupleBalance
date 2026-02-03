import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Couple Balance'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @trackExpensesTogether.
  ///
  /// In en, this message translates to:
  /// **'Track expenses together <3'**
  String get trackExpensesTogether;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authFailed;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @pleaseLinkPartnerFirst.
  ///
  /// In en, this message translates to:
  /// **'Please link a partner first'**
  String get pleaseLinkPartnerFirst;

  /// No description provided for @noPartnerLinked.
  ///
  /// In en, this message translates to:
  /// **'No Partner Linked'**
  String get noPartnerLinked;

  /// No description provided for @linkPartner.
  ///
  /// In en, this message translates to:
  /// **'Link Partner'**
  String get linkPartner;

  /// No description provided for @partnerOwesYou.
  ///
  /// In en, this message translates to:
  /// **'Partner owes you'**
  String get partnerOwesYou;

  /// No description provided for @youOwePartner.
  ///
  /// In en, this message translates to:
  /// **'You owe Partner'**
  String get youOwePartner;

  /// No description provided for @settlementInDays.
  ///
  /// In en, this message translates to:
  /// **'Settlement in {days} days'**
  String settlementInDays(int days);

  /// No description provided for @settleUp.
  ///
  /// In en, this message translates to:
  /// **'Settle Up'**
  String get settleUp;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settleUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle Up?'**
  String get settleUpTitle;

  /// No description provided for @settleUpContent.
  ///
  /// In en, this message translates to:
  /// **'This will archive all current transactions and reset the balance to 0.\n\nAmount: {amount} {currency}\n{payerInfo}'**
  String settleUpContent(String amount, String currency, String payerInfo);

  /// No description provided for @youArePaying.
  ///
  /// In en, this message translates to:
  /// **'You are paying'**
  String get youArePaying;

  /// No description provided for @partnerIsPaying.
  ///
  /// In en, this message translates to:
  /// **'Partner is paying'**
  String get partnerIsPaying;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @settlementComplete.
  ///
  /// In en, this message translates to:
  /// **'Settlement complete! Balance reset.'**
  String get settlementComplete;

  /// No description provided for @selectSettlementDay.
  ///
  /// In en, this message translates to:
  /// **'Select Settlement Day'**
  String get selectSettlementDay;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String day(int day);

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactionsYet;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction?'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteTransactionContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteTransactionContent;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount ({currency})'**
  String amount(String currency);

  /// No description provided for @youPaidSplit.
  ///
  /// In en, this message translates to:
  /// **'You paid, split equally'**
  String get youPaidSplit;

  /// No description provided for @youPaidFull.
  ///
  /// In en, this message translates to:
  /// **'You are owed full amount'**
  String get youPaidFull;

  /// No description provided for @partnerPaidSplit.
  ///
  /// In en, this message translates to:
  /// **'{partnerName} paid, split equally'**
  String partnerPaidSplit(String partnerName);

  /// No description provided for @partnerPaidFull.
  ///
  /// In en, this message translates to:
  /// **'{partnerName} is owed full amount'**
  String partnerPaidFull(String partnerName);

  /// No description provided for @whatIsItFor.
  ///
  /// In en, this message translates to:
  /// **'What is it for?'**
  String get whatIsItFor;

  /// No description provided for @expenseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dinner, Rent'**
  String get expenseHint;

  /// No description provided for @tagFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get tagFood;

  /// No description provided for @tagCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get tagCoffee;

  /// No description provided for @tagGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get tagGroceries;

  /// No description provided for @tagRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get tagRent;

  /// No description provided for @tagTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get tagTransport;

  /// No description provided for @tagDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get tagDate;

  /// No description provided for @tagBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get tagBills;

  /// No description provided for @tagShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get tagShopping;

  /// No description provided for @addReceiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Receipt / Photo'**
  String get addReceiptPhoto;

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get imageSelected;

  /// No description provided for @validAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get validAmountError;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated!'**
  String get profilePictureUpdated;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Error uploading image: {error}'**
  String uploadError(String error);

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @noReceiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'No receipt photo'**
  String get noReceiptPhoto;

  /// No description provided for @youPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get youPaid;

  /// No description provided for @partnerPaid.
  ///
  /// In en, this message translates to:
  /// **'Partner paid'**
  String get partnerPaid;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @unsettled.
  ///
  /// In en, this message translates to:
  /// **'Unsettled'**
  String get unsettled;

  /// No description provided for @linkPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Partner'**
  String get linkPartnerTitle;

  /// No description provided for @contactSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected {name}: {email}.'**
  String contactSelected(String name, String email);

  /// No description provided for @noEmailContact.
  ///
  /// In en, this message translates to:
  /// **'Selected contact has no email address.'**
  String get noEmailContact;

  /// No description provided for @contactPickError.
  ///
  /// In en, this message translates to:
  /// **'Error picking contact: {error}'**
  String contactPickError(String error);

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Cannot access contacts.'**
  String get permissionDenied;

  /// No description provided for @partnerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Partner User not found with this email. Ask them to login once.'**
  String get partnerNotFound;

  /// No description provided for @cannotLinkSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot link with yourself.'**
  String get cannotLinkSelf;

  /// No description provided for @linkPartnerInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your partner\'s Email Address to link accounts. Make sure they have updated their app and logged in at least once.'**
  String get linkPartnerInstruction;

  /// No description provided for @partnerEmail.
  ///
  /// In en, this message translates to:
  /// **'Partner Email'**
  String get partnerEmail;

  /// No description provided for @pickFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Pick from Contacts (Simulation)'**
  String get pickFromContacts;

  /// No description provided for @unlinkPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink Partner?'**
  String get unlinkPartnerTitle;

  /// No description provided for @unlinkWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unlink? You will no longer see shared expenses.'**
  String get unlinkWarning;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @unlinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Unlinked successfully'**
  String get unlinkedSuccess;

  /// No description provided for @unlinkError.
  ///
  /// In en, this message translates to:
  /// **'Error unlinking: {error}'**
  String unlinkError(String error);

  /// No description provided for @partnerProfile.
  ///
  /// In en, this message translates to:
  /// **'Partner Profile'**
  String get partnerProfile;

  /// No description provided for @partnerDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Partner data not found'**
  String get partnerDataNotFound;

  /// No description provided for @defaultPartnerName.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get defaultPartnerName;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @settlementHistory.
  ///
  /// In en, this message translates to:
  /// **'Settlement History'**
  String get settlementHistory;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get errorLoadingHistory;

  /// No description provided for @noPastSettlements.
  ///
  /// In en, this message translates to:
  /// **'No past settlements'**
  String get noPastSettlements;

  /// No description provided for @youPaidPartner.
  ///
  /// In en, this message translates to:
  /// **'You paid Partner'**
  String get youPaidPartner;

  /// No description provided for @partnerPaidYou.
  ///
  /// In en, this message translates to:
  /// **'Partner paid You'**
  String get partnerPaidYou;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String transactionCount(int count);

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options...'**
  String get moreOptions;

  /// No description provided for @whoPaid.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get whoPaid;

  /// No description provided for @howToSplit.
  ///
  /// In en, this message translates to:
  /// **'How to split?'**
  String get howToSplit;

  /// No description provided for @customAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom Amount'**
  String get customAmount;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @partner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partner;

  /// No description provided for @splitEqually.
  ///
  /// In en, this message translates to:
  /// **'Equally'**
  String get splitEqually;

  /// No description provided for @fullAmount.
  ///
  /// In en, this message translates to:
  /// **'Full Amount'**
  String get fullAmount;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @enterAmountOwed.
  ///
  /// In en, this message translates to:
  /// **'Enter amount owed'**
  String get enterAmountOwed;

  /// No description provided for @splitBy.
  ///
  /// In en, this message translates to:
  /// **'Split by'**
  String get splitBy;

  /// No description provided for @byAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get byAmount;

  /// No description provided for @byPercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get byPercentage;

  /// No description provided for @enterPercentage.
  ///
  /// In en, this message translates to:
  /// **'Enter percentage'**
  String get enterPercentage;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// No description provided for @partnerAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'Partner already linked ({partnerInfo})'**
  String partnerAlreadyLinked(String partnerInfo);

  /// No description provided for @partnersTitle.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get partnersTitle;

  /// No description provided for @unlinkPartnerContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unlink {name}?'**
  String unlinkPartnerContent(String name);

  /// No description provided for @noPartnersLinkedYet.
  ///
  /// In en, this message translates to:
  /// **'No partners linked yet.'**
  String get noPartnersLinkedYet;

  /// No description provided for @emailVerification.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// No description provided for @verifyEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address. A verification link has been sent to {email}.'**
  String verifyEmailMessage(String email);

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerificationEmail;

  /// No description provided for @iHaveVerified.
  ///
  /// In en, this message translates to:
  /// **'I have verified'**
  String get iHaveVerified;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccess;

  /// No description provided for @emailNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet.'**
  String get emailNotVerifiedYet;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSent;

  /// No description provided for @checkSpamFolder.
  ///
  /// In en, this message translates to:
  /// **'Please also check your spam folder.'**
  String get checkSpamFolder;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset password'**
  String get enterEmailToReset;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get resetEmailSent;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password entered'**
  String get incorrectPassword;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get weakPassword;

  /// No description provided for @reauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to change password'**
  String get reauthRequired;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email'**
  String get userNotFound;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email is already registered'**
  String get emailAlreadyInUse;

  /// No description provided for @invalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get invalidCredential;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyRequests;

  /// No description provided for @networkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkRequestFailed;

  /// No description provided for @removeAccount.
  ///
  /// In en, this message translates to:
  /// **'Remove Account'**
  String get removeAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. All your data including transactions, settlements, and profile information will be permanently deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @enterEmailToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to confirm'**
  String get enterEmailToConfirm;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get accountDeleted;

  /// No description provided for @requestNotFound.
  ///
  /// In en, this message translates to:
  /// **'Request not found or timed out.'**
  String get requestNotFound;

  /// No description provided for @partnerWantsToSettleUp.
  ///
  /// In en, this message translates to:
  /// **'Partner wants to settle up'**
  String get partnerWantsToSettleUp;

  /// No description provided for @settlementConfirmationDescription.
  ///
  /// In en, this message translates to:
  /// **'Confirming this will clear selected transactions and update your balance.'**
  String get settlementConfirmationDescription;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @requestSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully! Waiting for confirmation...'**
  String get requestSentSuccess;

  /// No description provided for @pendingRequestExists.
  ///
  /// In en, this message translates to:
  /// **'A pending request already exists. Please wait for your partner to respond.'**
  String get pendingRequestExists;

  /// No description provided for @requestSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request. Please try again.'**
  String get requestSendFailed;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @pendingSettlements.
  ///
  /// In en, this message translates to:
  /// **'Pending Settlements'**
  String get pendingSettlements;

  /// No description provided for @requestsWaiting.
  ///
  /// In en, this message translates to:
  /// **'requests waiting'**
  String get requestsWaiting;

  /// No description provided for @waitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for...'**
  String get waitingFor;

  /// No description provided for @settlementRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement Request'**
  String get settlementRequestTitle;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @sendRequestDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will send a request to your partner to confirm the settlement of {amount} {currency}.'**
  String sendRequestDialogContent(String amount, String currency);

  /// No description provided for @noTransactionsToday.
  ///
  /// In en, this message translates to:
  /// **'No transactions for this day'**
  String get noTransactionsToday;

  /// No description provided for @settlementConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Settlement confirmed!'**
  String get settlementConfirmed;

  /// No description provided for @settlementRejected.
  ///
  /// In en, this message translates to:
  /// **'Settlement rejected.'**
  String get settlementRejected;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get genericError;

  /// No description provided for @requestAlreadyStatus.
  ///
  /// In en, this message translates to:
  /// **'This request is already {status}.'**
  String requestAlreadyStatus(Object status);

  /// No description provided for @settleSingleTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle Transaction'**
  String get settleSingleTransactionTitle;

  /// No description provided for @settleSingleTransactionContent.
  ///
  /// In en, this message translates to:
  /// **'Do you want to accept the settlement for \'{note}\'?'**
  String settleSingleTransactionContent(String note);

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editProfile;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @passwordMinLength8.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least 8 characters'**
  String get passwordMinLength8;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordDifferentNote.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from previous used passwords'**
  String get passwordDifferentNote;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @reenterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reenterNewPassword;

  /// No description provided for @passwordCannotBeSame.
  ///
  /// In en, this message translates to:
  /// **'New password cannot be the same as current password'**
  String get passwordCannotBeSame;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get saveExpense;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
