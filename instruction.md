# Project Instructions: ValiDate (Personal Warranty Management System)

## 1. Role & Objective
You are an expert Flutter Developer. Your task is to build **ValiDate**, an offline-first mobile application that acts as a digital evidence repository for warranty claims.
**Design Philosophy:** Clean, Minimalist (Material 3). Use strict black/white/gray styling with functional colors (Red/Green/Orange) only for status indicators.

## 2. Tech Stack & Dependencies
* **Framework:** Flutter (Latest Stable)
* **State Management:** `provider`
* **Database:** `hive` & `hive_flutter` (NoSQL, storing objects directly)
* **Camera/Storage:** `image_picker`, `path_provider`, `gallery_saver`
* **OCR:** `google_mlkit_text_recognition` (For scanning dates)
* **Export:** `pdf`, `printing` (For generating claim reports)
* **Icons:** `flutter_lucide` (For that premium, clean look)
* **Formatting:** `intl` (Dates)

## 3. Data Model (`WarrantyItem`)
Create a Hive Model `WarrantyItem` with these exact fields:
* `id` (String): UUID
* `name` (String): e.g., "MacBook Air"
* `storeName` (String): e.g., "Power Mac Center"
* `purchaseDate` (DateTime)
* `warrantyPeriodInMonths` (int)
* `serialNumber` (String): **Critical for compliance.**
* `category` (String): "Gadgets", "Appliances", "Furniture"
* `imagePath` (String): Local file path to the receipt image.
* `isArchived` (bool): Defaults to `false`. Set to `true` if manually archived or deleted.

**Computed Logic:**
* `expiryDate`: `purchaseDate` + `warrantyPeriodInMonths`
* `daysRemaining`: `expiryDate` - `now()`

## 4. App Architecture (5 Functional Screens)

### Screen 1: Dashboard (Home)
* **Purpose:** Overview of *Active* warranties only.
* **Components:**
    * **Status Row:** 3 Cards showing counts for "Total Active", "Expiring Soon" (<30 days), "Safe".
    * **Search Bar:** Filters the list by Item Name.
    * **Main List:** A `ListView` displaying `WarrantyCard` widgets. Sorted by `daysRemaining` (ascending).
* **Logic:** Filter the Hive box: `where((item) => !item.isArchived && item.daysRemaining > 0)`.

### Screen 2: Capture (Add Item)
* **Purpose:** Input and digitization.
* **Components:**
    * **Camera Preview Box:** Tapping opens `ImagePicker`.
    * **OCR Feedback:** If image is picked, run `TextRecognizer`. If a date pattern is found, auto-fill the DateController.
    * **Form Fields:** Name, Store, **Serial Number**, Date, Duration.
* **Logic:** Save image to `ApplicationDocumentsDirectory`. Do NOT save to temporary cache.

### Screen 3: Evidence (Details)
* **Purpose:** Validation and proof presentation.
* **Components:**
    * **Hero Countdown:** Big text: "124 Days Left".
    * **Receipt Viewer:** Thumbnail. Tap to open `InteractiveViewer` (Zoomable) in a dialog.
    * **Data Table:** Displays Serial Number, Store, Purchase Date.
    * **Actions:** "Edit", "Archive/Delete".

### Screen 4: The Archive (History)
* **Purpose:** Storage for expired or deleted items (to keep Dashboard clean).
* **Components:**
    * **List View:** Displays items where `daysRemaining <= 0` OR `isArchived == true`.
    * **Visual Style:** Items here should look "dimmed" or grayed out.
    * **Actions:** "Restore" (move back to dashboard) or "Delete Permanently".

### Screen 5: Settings & Tools (Utility)
* **Purpose:** Compliance and Data Management.
* **Components:**
    * **Storage Stats:** Display "Receipts are using 45MB of space."
    * **Export Data:** A button "Generate Claim Report". Creates a PDF with the item list and images.
    * **Policy View:** A static text section displaying a summary of RA 7394 (Consumer Act).

## 5. Folder Structure
```text
lib/
├── main.dart
├── theme/
│   └── app_theme.dart        # Define the Black/White Material Theme
├── models/
│   └── warranty_item.dart    # Hive Adapter
├── providers/
│   └── warranty_provider.dart # Filtering Logic (Active vs Archive)
├── services/
│   ├── ocr_service.dart      # ML Kit logic
│   └── pdf_service.dart      # PDF generation logic
├── screens/
│   ├── dashboard_screen.dart
│   ├── capture_screen.dart
│   ├── details_screen.dart
│   ├── archive_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── warranty_card.dart
    ├── status_badge.dart
    └── receipt_thumbnail.dart