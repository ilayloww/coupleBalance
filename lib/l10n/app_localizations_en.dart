// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Couple Balance';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get createAccount => 'Create Account';

  @override
  String get trackExpensesTogether => 'Track expenses together <3';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get enterDisplayName => 'Please enter your display name';

  @override
  String get tooManyRequests => 'Too many attempts. Please try again later.';

  @override
  String waitToResend(Object seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get validEmail => 'Please enter a valid email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get pleaseLinkPartnerFirst => 'Please link a partner first';

  @override
  String get noPartnerLinked => 'No Partner Linked';

  @override
  String get linkPartner => 'Link Partner';

  @override
  String get partnerOwesYou => 'Partner owes you';

  @override
  String get youOwePartner => 'You owe Partner';

  @override
  String settlementInDays(int days) {
    return 'Settlement in $days days';
  }

  @override
  String get settleUp => 'Settle Up';

  @override
  String get history => 'History';

  @override
  String get settleUpTitle => 'Settle Up?';

  @override
  String settleUpContent(String amount, String currency, String payerInfo) {
    return 'This will archive all current transactions and reset the balance to 0.\n\nAmount: $amount $currency\n$payerInfo';
  }

  @override
  String get youArePaying => 'You are paying';

  @override
  String get partnerIsPaying => 'Partner is paying';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get settlementComplete => 'Settlement complete! Balance reset.';

  @override
  String get selectSettlementDay => 'Select Settlement Day';

  @override
  String day(int day) {
    return 'Day $day';
  }

  @override
  String get noTransactionsYet => 'No transactions yet.';

  @override
  String get deleteTransactionTitle => 'Delete Transaction';

  @override
  String get deleteTransactionContent =>
      'Are you sure you want to delete this item?';

  @override
  String get delete => 'Delete';

  @override
  String get addExpense => 'Add Expense';

  @override
  String amount(String currency) {
    return 'Amount ($currency)';
  }

  @override
  String get youPaidSplit => 'You paid, split equally';

  @override
  String get youPaidFull => 'You are owed full amount';

  @override
  String partnerPaidSplit(String partnerName) {
    return '$partnerName paid, split equally';
  }

  @override
  String partnerPaidFull(String partnerName) {
    return '$partnerName is owed full amount';
  }

  @override
  String get whatIsItFor => 'What is it for?';

  @override
  String get expenseHint => 'e.g. Dinner, Rent';

  @override
  String get tagFood => 'Food';

  @override
  String get tagCoffee => 'Coffee';

  @override
  String get tagGroceries => 'Groceries';

  @override
  String get tagRent => 'Rent';

  @override
  String get tagTransport => 'Transport';

  @override
  String get tagDate => 'Date';

  @override
  String get tagBills => 'Bills';

  @override
  String get tagShopping => 'Shopping';

  @override
  String get addReceiptPhoto => 'Add Receipt / Photo';

  @override
  String get imageSelected => 'Image selected';

  @override
  String get validAmountError => 'Please enter a valid amount';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get profilePictureUpdated => 'Profile picture updated!';

  @override
  String uploadError(String error) {
    return 'Error uploading image: $error';
  }

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get myProfile => 'My Profile';

  @override
  String get displayName => 'Display Name';

  @override
  String get appearance => 'Appearance';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get details => 'Details';

  @override
  String get noReceiptPhoto => 'No receipt photo';

  @override
  String get youPaid => 'You paid';

  @override
  String get partnerPaid => 'Partner paid';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get settled => 'Settled';

  @override
  String get unsettled => 'Unsettled';

  @override
  String get linkPartnerTitle => 'Link Partner';

  @override
  String contactSelected(String name, String email) {
    return 'Selected $name: $email.';
  }

  @override
  String get noEmailContact => 'Selected contact has no email address.';

  @override
  String contactPickError(String error) {
    return 'Error picking contact: $error';
  }

  @override
  String get permissionDenied => 'Permission denied. Cannot access contacts.';

  @override
  String get partnerNotFound =>
      'Partner User not found with this email. Ask them to login once.';

  @override
  String get cannotLinkSelf => 'You cannot link with yourself.';

  @override
  String get linkPartnerInstruction =>
      'Enter your partner\'s Email Address to link accounts. Make sure they have updated their app and logged in at least once.';

  @override
  String get partnerEmail => 'Partner Email';

  @override
  String get pickFromContacts => 'Pick from Contacts (Simulation)';

  @override
  String get unlinkPartnerTitle => 'Unlink Partner?';

  @override
  String get unlinkWarning =>
      'Are you sure you want to unlink? You will no longer see shared expenses.';

  @override
  String get unlink => 'Unlink';

  @override
  String get unlinkedSuccess => 'Unlinked successfully';

  @override
  String unlinkError(String error) {
    return 'Error unlinking: $error';
  }

  @override
  String get partnerProfile => 'Partner Profile';

  @override
  String get partnerDataNotFound => 'Partner data not found';

  @override
  String get defaultPartnerName => 'Partner';

  @override
  String get noEmail => 'No Email';

  @override
  String get settlementHistory => 'Settlement History';

  @override
  String get errorLoadingHistory => 'Error loading history';

  @override
  String get noPastSettlements => 'No past settlements';

  @override
  String get youPaidPartner => 'You paid Partner';

  @override
  String get partnerPaidYou => 'Partner paid You';

  @override
  String transactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get moreOptions => 'More options...';

  @override
  String get whoPaid => 'Who paid?';

  @override
  String get howToSplit => 'How to split?';

  @override
  String get customAmount => 'Custom Amount';

  @override
  String get me => 'Me';

  @override
  String get partner => 'Partner';

  @override
  String get splitEqually => 'Equally';

  @override
  String get fullAmount => 'Full Amount';

  @override
  String get custom => 'Custom';

  @override
  String get enterAmountOwed => 'Enter amount owed';

  @override
  String get splitBy => 'Split by';

  @override
  String get byAmount => 'Amount';

  @override
  String get byPercentage => 'Percentage';

  @override
  String get enterPercentage => 'Enter percentage';

  @override
  String get percentage => 'Percentage';

  @override
  String get themeColor => 'Theme Color';

  @override
  String partnerAlreadyLinked(String name) {
    return 'Partner already linked ($name)';
  }

  @override
  String get partnersTitle => 'Partners';

  @override
  String unlinkPartnerContent(String name) {
    return 'Are you sure you want to unlink $name?';
  }

  @override
  String get noPartnersLinkedYet => 'No partners linked yet.';

  @override
  String get emailVerification => 'Email Verification';

  @override
  String verifyEmailMessage(String email) {
    return 'Please verify your email address. A verification link has been sent to $email.';
  }

  @override
  String get resendVerificationEmail => 'Resend Verification Email';

  @override
  String get iHaveVerified => 'I have verified';

  @override
  String get emailVerifiedSuccess => 'Email verified successfully!';

  @override
  String get emailNotVerifiedYet => 'Email not verified yet.';

  @override
  String get verificationEmailSent => 'Verification email sent!';

  @override
  String get checkSpamFolder => 'Please also check your spam folder.';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterEmailToReset => 'Enter your email to reset password';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetEmailSent => 'Password reset email sent!';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordUpdated => 'Password updated successfully';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get error => 'Error';

  @override
  String get incorrectPassword => 'Incorrect password entered';

  @override
  String get weakPassword => 'Password is too weak';

  @override
  String get passwordMustContainUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordMustContainNumber =>
      'Password must contain at least one number';

  @override
  String get reauthRequired => 'Please log in again to change password';

  @override
  String get userNotFound => 'No account found with this email';

  @override
  String get emailAlreadyInUse => 'Email is already registered';

  @override
  String get invalidCredential => 'Incorrect email or password';

  @override
  String get networkRequestFailed =>
      'Network error. Please check your connection.';

  @override
  String get removeAccount => 'Remove Account';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'This action is irreversible. All your data including transactions, settlements, and profile information will be permanently deleted.';

  @override
  String get enterEmailToConfirm => 'Enter your email to confirm';

  @override
  String get deleteForever => 'Delete Forever';

  @override
  String get accountDeleted => 'Account deleted successfully.';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get deleteAccountDescription =>
      'This action cannot be undone. All your shared expenses, history, and linked accounts will be permanently deleted from our servers.';

  @override
  String get typeDeleteToConfirm => 'To confirm, type DELETE below';

  @override
  String get deleteConfirmationKeyword => 'DELETE';

  @override
  String get partnerNotifiedInfo =>
      'Your partner will be notified that the shared ledger has been closed.';

  @override
  String get deleteMyAccount => 'Delete My Account';

  @override
  String get goBack => 'Go Back';

  @override
  String get requestNotFound => 'Request not found or timed out.';

  @override
  String get partnerWantsToSettleUp => 'Partner wants to settle up';

  @override
  String get settlementConfirmationDescription =>
      'Confirming this will clear selected transactions and update your balance.';

  @override
  String get goHome => 'Go Home';

  @override
  String get requestSentSuccess =>
      'Request sent successfully! Waiting for confirmation...';

  @override
  String get pendingRequestExists =>
      'A pending request already exists. Please wait for your partner to respond.';

  @override
  String get requestSendFailed => 'Failed to send request. Please try again.';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get pendingSettlements => 'Pending Settlements';

  @override
  String get requestsWaiting => 'requests waiting';

  @override
  String get waitingFor => 'Waiting for...';

  @override
  String get settlementRequestTitle => 'Settlement Request';

  @override
  String get reject => 'Reject';

  @override
  String sendRequestDialogContent(String amount, String currency) {
    return 'This will send a request to your partner to confirm the settlement of $amount $currency.';
  }

  @override
  String get noTransactionsToday => 'No transactions for this day';

  @override
  String get settlementConfirmed => 'Settlement confirmed!';

  @override
  String get settlementRejected => 'Settlement rejected.';

  @override
  String get genericError => 'An error occurred. Please try again.';

  @override
  String requestAlreadyStatus(Object status) {
    return 'This request is already $status.';
  }

  @override
  String get settleSingleTransactionTitle => 'Settle Transaction';

  @override
  String settleSingleTransactionContent(String note) {
    return 'Do you want to accept the settlement for \'$note\'?';
  }

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get goodNight => 'Good Night';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get editProfile => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get passwordMinLength8 => 'Must contain at least 8 characters';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordDifferentNote =>
      'Your new password must be different from previous used passwords';

  @override
  String get enterCurrentPassword => 'Enter current password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get reenterNewPassword => 'Re-enter new password';

  @override
  String get passwordCannotBeSame =>
      'New password cannot be the same as current password';

  @override
  String get saveExpense => 'Save Expense';

  @override
  String get tagCustom => 'Custom';

  @override
  String get customCategoryHint => 'Enter category name';

  @override
  String get enterCategoryError => 'Please enter a category name';

  @override
  String get expensesSummary => 'Expenses Summary';

  @override
  String get items => 'items';

  @override
  String get pending => 'Pending';

  @override
  String get dueToday => 'Due today';

  @override
  String get paysYou => 'pays You';

  @override
  String get youPay => 'You pay';

  @override
  String get confirmSettlement => 'Confirm Settlement';

  @override
  String get filterAllTime => 'All Time';

  @override
  String get filterThisYear => 'This Year';

  @override
  String get filterLastYear => 'Last Year';

  @override
  String get splitDetails => 'Split Details';

  @override
  String get receipt => 'Receipt';

  @override
  String get time => 'Time';

  @override
  String get category => 'Category';

  @override
  String get paidByYou => 'Paid by You';

  @override
  String paidByPartner(String name) {
    return 'Paid by $name';
  }

  @override
  String get paidFullAmount => 'Paid full amount';

  @override
  String get owesYou => 'Owes you';

  @override
  String get youOwe => 'You owe';

  @override
  String get you => 'You';

  @override
  String owePartner(String name) {
    return 'You owe $name';
  }

  @override
  String get today => 'TODAY';

  @override
  String get yesterday => 'YESTERDAY';

  @override
  String get searchTransactionHint => 'Search by name or category';

  @override
  String get noTransactionsFound => 'No transactions found';

  @override
  String get calendar => 'Calendar';

  @override
  String transactionsForDate(String date) {
    return 'Transactions for $date';
  }

  @override
  String get total => 'Total';

  @override
  String get transaction => 'Transaction';

  @override
  String get connectWithPartnerTitle => 'Connect with\nyour partner';

  @override
  String get connectWithPartnerSubtitle =>
      'Enter your partner\'s unique ID or scan their QR code to link accounts.';

  @override
  String get partnerIdLabel => 'Partner ID';

  @override
  String get scan => 'SCAN';

  @override
  String get orShareYourId => 'Or share your ID';

  @override
  String get myUniqueId => 'MY UNIQUE ID';

  @override
  String get generating => 'Generating...';

  @override
  String get idCopied => 'ID copied to clipboard';

  @override
  String get sendInvite => 'Send Invite';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get matchesOwnId => 'Matches your own ID.';

  @override
  String get requestAlreadySent => 'Request already sent! Wait for approval.';

  @override
  String get friendRequestSent => 'Friend request sent!';

  @override
  String inviteMessage(String id) {
    return 'Let\'s track expenses together with Couple Balance! My ID is: $id';
  }

  @override
  String get dashboard => 'Dashboard';

  @override
  String get totalBalance => 'TOTAL BALANCE';

  @override
  String youAreOwedAmount(String amount) {
    return 'You are owed $amount';
  }

  @override
  String youOweAmount(String partner, String amount) {
    return 'You owe $partner $amount';
  }

  @override
  String get allTransactions => 'All Transactions';

  @override
  String get linkAccounts => 'Link Accounts';

  @override
  String youPaidAmount(String amount, String currency) {
    return 'You paid $amount $currency';
  }

  @override
  String partnerPaidAmount(String partner, String amount, String currency) {
    return '$partner paid $amount $currency';
  }

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String settleTransactionQuestion(String amount, String currency) {
    return 'Do you want to settle this transaction of $amount $currency?';
  }

  @override
  String get settle => 'Settle';

  @override
  String get save => 'Save';

  @override
  String get enterNote => 'Enter note';
}
