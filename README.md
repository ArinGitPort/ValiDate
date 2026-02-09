# ValiDate: Personal Warranty Vault

**ValiDate** is a robust, offline-first Flutter application designed to help users track, manage, and preserve warranty information for their purchases. It serves as a digital vault for receipts and warranty cards, ensuring consumers can easily avail of their rights under the Consumer Act of the Philippines (RA 7394).

---

## 🚀 Key Features

### 1. 📶 Offline-First Architecture
*   **Works Everywhere**: Use the app completely offline. View your warranties, add new items, or edit details without an internet connection.
*   **Smart Sync**: Changes made offline are queued and automatically synchronized with the cloud (Supabase) once connectivity is restored.
*   **Local Caching**: Images and data are stored locally on your device for instant loading, with background downloading for remote assets.

### 2. 🛡️ Comprehensive Warranty Management
*   **Expiry Tracking**: Visual countdowns (Days Remaining) and automatic status updates (Active, Expiring Soon, Expired).
*   **Digital Archive**: Capture and store photos of receipts and products.
*   **Search & Sort**: Quickly find items by name or store; sort by purchase date or expiry.

### 3. 🔐 Secure & User-Friendly Authentication
*   **Supabase Auth**: Secure Email/Password login.
*   **Offline Access**: Persistent sessions allow previously logged-in users to access the app immediately, even without internet.
*   **Friendly Error Handling**: Clear, human-readable messages for network issues (e.g., "No internet connection") instead of technical errors.

### 4. 📂 Data Compliance & Export
*   **PDF Reports**: Generate professional warranty reports for insurance or compliance purposes.
*   **Backup & Restore**: Export your data to JSON for local backup.
*   **Consumer Rights**: Built-in reference to **RA 7394 (Consumer Act of the Philippines)** to educate users on their warranty rights.

### 5. 🔔 Notifications
*   **Smart Alerts**: Receive local notifications 7 days before an item expires.

---

## 🛠️ Technology Stack

*   **Framework**: Flutter
*   **Backend**: Supabase (PostgreSQL, Auth, Storage)
*   **Local Database**: SQLite (`sqflite`) for robust offline data persistence.
*   **State Management**: `Provider`
*   **Connectivity**: `connectivity_plus` for detecting network state.
*   **Image Handling**: `image_picker`, `gallery_saver`, and custom caching logic.

---

## 📖 How It Works

1.  **Capture**: User takes a photo of a receipt and enters warranty details.
2.  **Store (Local)**: Data is immediately saved to the device's SQLite database and displayed in the UI.
3.  **Sync (Background)**:
    *   If **Online**: Data is uploaded to Supabase immediately.
    *   If **Offline**: Data is added to a "Sync Queue". The `OfflineSyncService` waits for internet connection to retry uploads automatically.
4.  **Retrieve**: When logging in on a new device, the app downloads your full history from the cloud.

---

## 📦 Dependencies

*   `supabase_flutter`: Backend services.
*   `sqflite` & `path`: Local SQL database.
*   `provider`: State management.
*   `flutter_lucide`: Modern, clean iconography.
*   `pdf` & `printing`: Document generation.
*   `connectivity_plus`: Network monitoring.
*   `cached_network_image` (custom implementation): Optimized image loading.