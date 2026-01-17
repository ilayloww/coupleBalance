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
  String get deleteTransactionTitle => 'İşlemi Sil?';

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
  String get partner => 'Partnerim';

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
}
