// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Couple Balance';

  @override
  String get welcomeBack => 'Tekrar Hoşgeldin!';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get trackExpensesTogether => 'Harcamaları birlikte takip edin <3';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get dontHaveAccount => 'Hesabın yok mu? Kayıt Ol';

  @override
  String get alreadyHaveAccount => 'Zaten hesabın var mı? Giriş Yap';

  @override
  String get authFailed => 'Kimlik doğrulama başarısız';

  @override
  String get unexpectedError => 'Beklenmeyen bir hata oluştu';

  @override
  String get enterEmail => 'Lütfen e-posta adresinizi girin';

  @override
  String get enterDisplayName => 'Lütfen isminizi girin';

  @override
  String get tooManyRequests =>
      'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';

  @override
  String waitToResend(Object seconds) {
    return '${seconds}sn sonra tekrar deneyin';
  }

  @override
  String get validEmail => 'Lütfen geçerli bir e-posta girin';

  @override
  String get enterPassword => 'Lütfen şifrenizi girin';

  @override
  String get passwordMinLength => 'Şifre en az 6 karakter olmalıdır';

  @override
  String get recentTransactions => 'Son İşlemler';

  @override
  String get pleaseLinkPartnerFirst => 'Lütfen önce bir partner bağlayın';

  @override
  String get noPartnerLinked => 'Partner Bağlı Değil';

  @override
  String get linkPartner => 'Partner Bağla';

  @override
  String get partnerOwesYou => 'Partner sana borçlu';

  @override
  String get youOwePartner => 'Partnerine borçlusun';

  @override
  String settlementInDays(int days) {
    return 'Hesap kesimine $days gün';
  }

  @override
  String get settleUp => 'Hesaplaş';

  @override
  String get history => 'Geçmiş';

  @override
  String get settleUpTitle => 'Hesaplaşılsın mı?';

  @override
  String settleUpContent(String amount, String currency, String payerInfo) {
    return 'Bu işlem mevcut tüm harcamaları arşivleyecek ve bakiyeyi sıfırlayacaktır.\n\nTutar: $amount $currency\n$payerInfo';
  }

  @override
  String get youArePaying => 'Ödemeyi sen yapıyorsun';

  @override
  String get partnerIsPaying => 'Ödemeyi partnerin yapıyor';

  @override
  String get cancel => 'İptal';

  @override
  String get confirm => 'Onayla';

  @override
  String get settlementComplete => 'Hesaplaşma tamamlandı! Bakiye sıfırlandı.';

  @override
  String get selectSettlementDay => 'Hesap Kesim Gününü Seç';

  @override
  String day(int day) {
    return '$day. Gün';
  }

  @override
  String get noTransactionsYet => 'Henüz işlem yok.';

  @override
  String get deleteTransactionTitle => 'İşlemi Sil';

  @override
  String get deleteTransactionContent =>
      'Bu öğeyi silmek istediğinizden emin misiniz?';

  @override
  String get delete => 'Sil';

  @override
  String get addExpense => 'Harcama Ekle';

  @override
  String amount(String currency) {
    return 'Tutar ($currency)';
  }

  @override
  String get youPaidSplit => 'Sen ödedin, eşit bölüş';

  @override
  String get youPaidFull => 'Tamamını sen geri alacaksın';

  @override
  String partnerPaidSplit(String partnerName) {
    return '$partnerName ödedi, eşit bölüş';
  }

  @override
  String partnerPaidFull(String partnerName) {
    return 'Tamamını $partnerName geri alacak';
  }

  @override
  String get whatIsItFor => 'Ne için?';

  @override
  String get expenseHint => 'Örn. Akşam Yemeği, Kira';

  @override
  String get tagFood => 'Yemek';

  @override
  String get tagCoffee => 'Kahve';

  @override
  String get tagGroceries => 'Market';

  @override
  String get tagRent => 'Kira';

  @override
  String get tagTransport => 'Ulaşım';

  @override
  String get tagDate => 'Date';

  @override
  String get tagBills => 'Faturalar';

  @override
  String get tagShopping => 'Alışveriş';

  @override
  String get addReceiptPhoto => 'Fiş / Fotoğraf Ekle';

  @override
  String get imageSelected => 'Görsel seçildi';

  @override
  String get validAmountError => 'Lütfen geçerli bir tutar girin';

  @override
  String get gallery => 'Galeri';

  @override
  String get camera => 'Kamera';

  @override
  String get profilePictureUpdated => 'Profil fotoğrafı güncellendi!';

  @override
  String uploadError(String error) {
    return 'Görsel yükleme hatası: $error';
  }

  @override
  String get profileUpdated => 'Profil başarıyla güncellendi';

  @override
  String get myProfile => 'Profilim';

  @override
  String get displayName => 'Görünen Ad';

  @override
  String get appearance => 'Görünüm';

  @override
  String get system => 'Sistem';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get saveProfile => 'Profili Kaydet';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get language => 'Dil';

  @override
  String get english => 'İngilizce';

  @override
  String get turkish => 'Türkçe';

  @override
  String get details => 'Detaylar';

  @override
  String get noReceiptPhoto => 'Fiş fotoğrafı yok';

  @override
  String get youPaid => 'Sen ödedin';

  @override
  String get partnerPaid => 'Partner ödedi';

  @override
  String get date => 'Tarih';

  @override
  String get status => 'Durum';

  @override
  String get settled => 'Ödendi';

  @override
  String get unsettled => 'Ödenmedi';

  @override
  String get linkPartnerTitle => 'Partner Bağla';

  @override
  String contactSelected(String name, String email) {
    return 'Seçilen $name: $email.';
  }

  @override
  String get noEmailContact => 'Seçilen kişinin e-posta adresi yok.';

  @override
  String contactPickError(String error) {
    return 'Kişi seçme hatası: $error';
  }

  @override
  String get permissionDenied => 'İzin reddedildi. Kişilere erişilemiyor.';

  @override
  String get partnerNotFound =>
      'Bu e-posta ile partner bulunamadı. Lütfen bir kez giriş yapmalarını söyleyin.';

  @override
  String get cannotLinkSelf => 'Kendini partner olarak ekleyemezsin.';

  @override
  String get linkPartnerInstruction =>
      'Hesapları bağlamak için partnerinin E-posta adresini gir. Uygulamayı güncellediklerinden ve en az bir kez giriş yaptıklarından emin ol.';

  @override
  String get partnerEmail => 'Partner E-posta';

  @override
  String get pickFromContacts => 'Rehberden Seç (Simülasyon)';

  @override
  String get unlinkPartnerTitle => 'Bağlantıyı Kes?';

  @override
  String get unlinkWarning =>
      'Bağlantıyı kesmek istediğine emin misin? Artık ortak harcamaları göremeyeceksin.';

  @override
  String get unlink => 'Bağlantıyı Kes';

  @override
  String get unlinkedSuccess => 'Bağlantı başarıyla kesildi';

  @override
  String unlinkError(String error) {
    return 'Bağlantı kesme hatası: $error';
  }

  @override
  String get partnerProfile => 'Partner Profili';

  @override
  String get partnerDataNotFound => 'Partner verisi bulunamadı';

  @override
  String get defaultPartnerName => 'Partner';

  @override
  String get noEmail => 'E-posta Yok';

  @override
  String get settlementHistory => 'Hesaplaşma Geçmişi';

  @override
  String get errorLoadingHistory => 'Geçmiş yüklenirken hata';

  @override
  String get noPastSettlements => 'Geçmiş hesaplaşma yok';

  @override
  String get youPaidPartner => 'Sen Partnerine ödedin';

  @override
  String get partnerPaidYou => 'Partnerin sana ödedi';

  @override
  String transactionCount(int count) {
    return '$count işlem';
  }

  @override
  String get moreOptions => 'Diğer seçenekler...';

  @override
  String get whoPaid => 'Kim ödedi?';

  @override
  String get howToSplit => 'Nasıl bölünecek?';

  @override
  String get customAmount => 'Özel Tutar';

  @override
  String get me => 'Ben';

  @override
  String get partner => 'Partner';

  @override
  String get splitEqually => 'Eşit';

  @override
  String get fullAmount => 'Tamamı';

  @override
  String get custom => 'Özel';

  @override
  String get enterAmountOwed => 'Borçlanılan tutarı girin';

  @override
  String get splitBy => 'Bölüşüm Tipi';

  @override
  String get byAmount => 'Tutar';

  @override
  String get byPercentage => 'Yüzde';

  @override
  String get enterPercentage => 'Yüzde girin';

  @override
  String get percentage => 'Yüzde';

  @override
  String get themeColor => 'Tema Rengi';

  @override
  String partnerAlreadyLinked(String partnerInfo) {
    return 'Partner zaten bağlı ($partnerInfo)';
  }

  @override
  String get partnersTitle => 'Partnerler';

  @override
  String unlinkPartnerContent(String name) {
    return '$name ile bağlantıyı kesmek istediğine emin misin?';
  }

  @override
  String get noPartnersLinkedYet => 'Henüz bağlı partner yok.';

  @override
  String get emailVerification => 'E-posta Doğrulama';

  @override
  String verifyEmailMessage(String email) {
    return 'Lütfen e-posta adresinizi doğrulayın. $email adresine bir doğrulama bağlantısı gönderildi.';
  }

  @override
  String get resendVerificationEmail => 'Doğrulama E-postasını Tekrar Gönder';

  @override
  String get iHaveVerified => 'Doğruladım';

  @override
  String get emailVerifiedSuccess => 'E-posta başarıyla doğrulandı!';

  @override
  String get emailNotVerifiedYet => 'E-posta henüz doğrulanmadı.';

  @override
  String get verificationEmailSent => 'Doğrulama e-postası gönderildi!';

  @override
  String get checkSpamFolder => 'Lütfen spam klasörünüzü de kontrol edin.';

  @override
  String get forgotPassword => 'Şifremi Unuttum?';

  @override
  String get resetPassword => 'Şifre Sıfırla';

  @override
  String get enterEmailToReset => 'Şifrenizi sıfırlamak için e-postanızı girin';

  @override
  String get sendResetLink => 'Sıfırlama Bağlantısı Gönder';

  @override
  String get resetEmailSent => 'Şifre sıfırlama e-postası gönderildi!';

  @override
  String get changePassword => 'Şifre Değiştir';

  @override
  String get currentPassword => 'Mevcut Şifre';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get confirmNewPassword => 'Yeni Şifre (Tekrar)';

  @override
  String get passwordUpdated => 'Şifre başarıyla güncellendi';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get invalidEmail => 'Lütfen geçerli bir e-posta girin';

  @override
  String get error => 'Hata';

  @override
  String get incorrectPassword => 'Girdiğiniz şifre yanlış';

  @override
  String get weakPassword => 'Şifre çok zayıf';

  @override
  String get passwordMustContainUppercase =>
      'Şifre en az bir büyük harf içermelidir';

  @override
  String get passwordMustContainNumber => 'Şifre en az bir rakam içermelidir';

  @override
  String get reauthRequired =>
      'Şifrenizi değiştirmek için lütfen tekrar giriş yapın';

  @override
  String get userNotFound => 'Bu e-posta ile kayıtlı hesap bulunamadı';

  @override
  String get emailAlreadyInUse => 'Bu e-posta zaten kullanımda';

  @override
  String get invalidCredential => 'E-posta veya şifre hatalı';

  @override
  String get networkRequestFailed =>
      'Ağ hatası. Lütfen bağlantınızı kontrol edin.';

  @override
  String get removeAccount => 'Hesabımı Sil';

  @override
  String get deleteAccountTitle => 'Hesabı Sil';

  @override
  String get deleteAccountWarning =>
      'Bu işlem geri alınamaz. İşlemler, hesaplaşmalar ve profil bilgileri dahil tüm verileriniz kalıcı olarak silinecektir.';

  @override
  String get enterEmailToConfirm => 'Onaylamak için e-postanızı girin';

  @override
  String get deleteForever => 'Kalıcı Olarak Sil';

  @override
  String get accountDeleted => 'Hesap başarıyla silindi.';

  @override
  String get areYouSure => 'Emin misiniz?';

  @override
  String get deleteAccountDescription =>
      'Bu işlem geri alınamaz. Tüm paylaşılan harcamalarınız, geçmişiniz ve bağlı hesaplarınız sunucularımızdan kalıcı olarak silinecektir.';

  @override
  String get typeDeleteToConfirm => 'Onaylamak için aşağıya DELETE yazın';

  @override
  String get deleteConfirmationKeyword => 'DELETE';

  @override
  String get partnerNotifiedInfo =>
      'Partneriniz, ortak defterin kapatıldığına dair bilgilendirilecektir.';

  @override
  String get deleteMyAccount => 'Hesabımı Sil';

  @override
  String get goBack => 'Geri Dön';

  @override
  String get requestNotFound => 'İstek bulunamadı veya zaman aşımına uğradı.';

  @override
  String get partnerWantsToSettleUp => 'Partnerin hesaplaşmak istiyor';

  @override
  String get settlementConfirmationDescription =>
      'Onayladığında seçilen işlemler temizlenecek ve bakiyen güncellenecektir.';

  @override
  String get goHome => 'Ana Sayfa';

  @override
  String get requestSentSuccess => 'İstek gönderildi! Onay bekleniyor...';

  @override
  String get pendingRequestExists =>
      'Bekleyen bir istek zaten var. Lütfen partnerinin yanıt vermesini bekle.';

  @override
  String get requestSendFailed => 'İstek gönderilemedi. Lütfen tekrar dene.';

  @override
  String get sendRequest => 'İstek Gönder';

  @override
  String get pendingSettlements => 'Bekleyen Hesaplaşmalar';

  @override
  String get requestsWaiting => 'istek bekliyor';

  @override
  String get waitingFor => 'Bekleniyor...';

  @override
  String get settlementRequestTitle => 'Hesaplaşma İsteği';

  @override
  String get reject => 'Reddet';

  @override
  String sendRequestDialogContent(String amount, String currency) {
    return 'Bu işlem, partnerine $amount $currency tutarındaki hesaplaşmayı onaylaması için bir istek gönderecektir.';
  }

  @override
  String get noTransactionsToday => 'Bugün için işlem yok';

  @override
  String get settlementConfirmed => 'Hesaplaşma onaylandı!';

  @override
  String get settlementRejected => 'Hesaplaşma reddedildi.';

  @override
  String get genericError => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String requestAlreadyStatus(Object status) {
    return 'Bu istek zaten $status.';
  }

  @override
  String get settleSingleTransactionTitle => 'İşlemi Öde';

  @override
  String settleSingleTransactionContent(String note) {
    return '\'$note\' işlemi için hesaplaşmayı onaylıyor musun?';
  }

  @override
  String get goodMorning => 'Günaydın';

  @override
  String get goodAfternoon => 'Tünaydın';

  @override
  String get goodEvening => 'İyi Akşamlar';

  @override
  String get goodNight => 'İyi Geceler';

  @override
  String get settings => 'Ayarlar';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get editProfile => 'Düzenle';

  @override
  String get done => 'Tamam';

  @override
  String get passwordMinLength8 => 'En az 8 karakter içermeli';

  @override
  String get updatePassword => 'Şifreyi Güncelle';

  @override
  String get passwordDifferentNote =>
      'Yeni şifreniz öncekilerden farklı olmalı';

  @override
  String get enterCurrentPassword => 'Mevcut şifreyi girin';

  @override
  String get enterNewPassword => 'Yeni şifreyi girin';

  @override
  String get reenterNewPassword => 'Yeni şifreyi tekrar girin';

  @override
  String get passwordCannotBeSame => 'Yeni şifre mevcut şifre ile aynı olamaz';

  @override
  String get saveExpense => 'Harcamayı Kaydet';

  @override
  String get tagCustom => 'Özel';

  @override
  String get customCategoryHint => 'Kategori adı girin';

  @override
  String get enterCategoryError => 'Lütfen kategori adı girin';

  @override
  String get expensesSummary => 'Harcama Özeti';

  @override
  String get items => 'öğe';

  @override
  String get pending => 'Bekliyor';

  @override
  String get dueToday => 'Son gün bugün';

  @override
  String get paysYou => 'sana ödüyor';

  @override
  String get youPay => 'Sen ödüyorsun';

  @override
  String get confirmSettlement => 'Hesaplaşmayı Onayla';

  @override
  String get filterAllTime => 'Tüm Zamanlar';

  @override
  String get filterThisYear => 'Bu Yıl';

  @override
  String get filterLastYear => 'Geçen Yıl';

  @override
  String get splitDetails => 'Bölüşüm Detayları';

  @override
  String get receipt => 'Fiş';

  @override
  String get time => 'Saat';

  @override
  String get category => 'Kategori';

  @override
  String get paidByYou => 'Sen ödedin';

  @override
  String paidByPartner(String name) {
    return '$name ödedi';
  }

  @override
  String get paidFullAmount => 'Tamamını ödedi (borç yok)';

  @override
  String get owesYou => 'Sana borçlu';

  @override
  String get youOwe => 'Sen borçlusun';

  @override
  String get you => 'Sen';

  @override
  String owePartner(String name) {
    return '$name alacaklı';
  }

  @override
  String get today => 'BUGÜN';

  @override
  String get yesterday => 'DÜN';

  @override
  String get searchTransactionHint => 'İsim veya kategori ara';

  @override
  String get noTransactionsFound => 'İşlem bulunamadı';

  @override
  String get calendar => 'Takvim';

  @override
  String transactionsForDate(String date) {
    return '$date İşlemleri';
  }

  @override
  String get total => 'Toplam';

  @override
  String get transaction => 'İşlem';

  @override
  String get connectWithPartnerTitle => 'Partnerinle\nBağlan';

  @override
  String get connectWithPartnerSubtitle =>
      'Hesapları bağlamak için partnerinin benzersiz ID\'sini gir veya QR kodunu tara.';

  @override
  String get partnerIdLabel => 'Partner ID';

  @override
  String get scan => 'TARA';

  @override
  String get orShareYourId => 'Veya ID\'ni paylaş';

  @override
  String get myUniqueId => 'BENZERSİZ ID\'M';

  @override
  String get generating => 'Oluşturuluyor...';

  @override
  String get idCopied => 'ID kopyalandı';

  @override
  String get sendInvite => 'Davet Gönder';

  @override
  String get scanQrCode => 'QR Kod Tara';

  @override
  String get matchesOwnId => 'Kendi ID\'nizle eşleşiyor.';

  @override
  String get requestAlreadySent => 'İstek zaten gönderildi! Onay bekleyin.';

  @override
  String get friendRequestSent => 'Arkadaşlık isteği gönderildi!';

  @override
  String inviteMessage(String id) {
    return 'Couple Balance ile harcamaları birlikte takip edelim! ID\'m: $id';
  }

  @override
  String get dashboard => 'Panel';

  @override
  String get totalBalance => 'TOPLAM BAKİYE';

  @override
  String youAreOwedAmount(String amount) {
    return 'Sana $amount borçlu';
  }

  @override
  String youOweAmount(String partner, String amount) {
    return '$partner kişisine $amount borçlusun';
  }

  @override
  String get allTransactions => 'Tüm İşlemler';
}
