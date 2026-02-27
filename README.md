<div align="center">
  <img src="assets/icon.jpg" alt="Couple Balance Logo" width="120" />
  <h1>Couple Balance</h1>
  <p><strong>Simplify shared expenses and keep your relationship balanced.</strong></p>
</div>

---

**Couple Balance** is a modern, intuitive expense tracker designed specifically for couples. Forget complicated spreadsheets or generic group splitting apps; Couple Balance focuses on the 1-on-1 dynamic, letting you quickly log expenses, see who paid for what, and keep a running total of your shared balance effortlessly.

Whether it's a dinner date, grocery run, or monthly rent, Couple Balance ensures you and your partner stay on the same page financially without the awkward math.

## ✨ Key Features

- **👫 1-on-1 Focus** — Specifically tailored for couples managing a shared financial pool.
- **⏱️ Real-time Balance** — Instantly see exactly who owes whom, synchronized across devices.
- **✂️ Flexible Splitting Options**
  - **Equal Split:** Classic 50/50 sharing.
  - **Full Amount:** One person pays the full cost for both.
  - **Custom Split:** Split by specific percentages or exact amounts.
- **🧾 Comprehensive Expense Logging**
  - Attach receipt images directly to your transactions.
  - Use smart categories (Food, Coffee, Groceries, Rent, Utilities, etc.)
  - Add specific notes and dates.
- **🔗 Seamless Partner Linking** — Connect accounts securely in seconds using QR Codes or Deep Links.
- **🤝 Advanced Settlement System** — Settle up your balances safely. The app maintains a detailed archive of past settlements powered by secure server-side Cloud Functions.
- **📅 Calendar View** — Visualize your spending habits and financial activity on an interactive monthly calendar.
- **🔔 Push Notifications** — Get instantly notified when your partner adds an expense or requests a settlement.
- **🌍 Multi-language & Theming** — Full localization support (English & Turkish) and dark/light modes.

## 📱 Screenshots

| Home & Balance | Add an Expense | Calendar View |
|:---:|:---:|:---:|
| <img src="assets/screenshots/home.png" width="250" alt="Home Screen"> | <img src="assets/screenshots/add_expense.png" width="250" alt="Add Expense"> | <img src="assets/screenshots/calendar.png" width="250" alt="Calendar View"> |

*(Note: Add actual screenshot images to `assets/screenshots/` to display them here)*

## 🛠️ Tech Stack & Architecture

Built with modern mobile development standards focusing on performance, clean architecture, and reactive state management.

### **Frontend**
- **Framework:** [Flutter](https://flutter.dev/) (SDK ^3.10.4)
- **State Management:** Provider pattern
- **Localization:** `intl` & `flutter_localizations`
- **UI & UX:** `table_calendar`, `flutter_slidable`, `cached_network_image`, `cupertino_icons`
- **Utilities:** `shared_preferences`, `dio`, `image_picker`, `qr_flutter`, `mobile_scanner`

### **Backend (Firebase)**
- **Authentication:** Firebase Auth (Email/Password, Secure login)
- **Database:** Cloud Firestore (Real-time NoSQL document database)
- **Storage:** Firebase Cloud Storage (For storing receipt images and profiles)
- **Serverless Logic:** Cloud Functions (For atomic, secure settlement transactions)
- **Notifications:** Firebase Cloud Messaging (FCM)

### **Project Structure (`lib/`)**
The application adheres to a clean, modular structure:
- `/config`: Theme data, app constants, and Firebase options.
- `/l10n`: Localization files (`.arb`) for multi-language support.
- `/models`: Data classes (`User`, `Transaction`, `Settlement`).
- `/screens`: UI views (Home, Add Expense, Profile, Calendar, etc.).
- `/services`: Business logic and external API integrations (Auth, Firestore, Notifications, Deep Links).
- `/utils`: Helper functions and formatters.
- `/viewmodels`: Provider models connecting `/services` and `/screens`.
- `/widgets`: Reusable customized UI components.

## 🚀 Getting Started

To run this project locally, follow these steps:

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.10.4 or higher)
- A Firebase Project with Auth, Firestore, Storage, and Functions enabled.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/coupleBalance.git
   cd coupleBalance
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Follow the [FlutterFire CLI documentation](https://firebase.flutter.dev/docs/cli/) to configure your project.
   - Alternatively, place your generated `google-services.json` inside `android/app/` and your `GoogleService-Info.plist` inside `ios/Runner/`.

4. **Deploy Cloud Functions (Required for Settlements):**
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

5. **Run the App:**
   ```bash
   flutter run
   ```

## 🔐 Security & Testing

- **Server-Side Verification:** Important actions like balance settlements are processed via Firebase Cloud Functions to prevent client-side manipulation (TOCTOU vulnerabilities).
- **Unit & Mock Testing:** Comprehensive testing environment set up using `flutter_test`, `firebase_auth_mocks`, and `fake_cloud_firestore`. Run tests via: `flutter test`.

---

<p align="center">Made with ❤️ for a balanced life.</p>
