# UI Instructions: ValiDate Frontend

## 1. Design Philosophy
**Style:** Native Mobile (iOS/Android Hybrid).
**Vibe:** Professional, Clean, "Black & White" (Zinc/Slate aesthetic).
**Typography:** `GoogleFonts.manrope` (Round, clean, modern).
**Icons:** `flutter_lucide` (Stroke icons, no filled Material icons).

## 2. Navigation Architecture (Docked Layout)
**Widget:** `MainLayout.dart`
* **Scaffold:**
    * **Body:** `IndexedStack` (Home, Archive, Settings).
    * **FAB:** `FloatingActionButton` (Center Docked).
        * **Color:** Black background, White icon.
        * **Shape:** CircleBorder.
        * **Icon:** `LucideIcons.scanLine` (Size 28).
    * **Bottom Bar:** `BottomAppBar`
        * **Shape:** `CircularNotchedRectangle` (Creates the "bite").
        * **NotchMargin:** 8.0.
        * **Items:** Dashboard, Archive | (Spacer) | Reports, Settings.

## 3. Screen Specifications

### A. Dashboard (Home)
* **Scrolling:** Use `CustomScrollView` with `Slivers`.
* **Header:** `SliverAppBar`
    * **Expanded Height:** 120.0.
    * **Title:** "My Vault" (Black, Bold).
    * **Behavior:** Large title collapses into a small toolbar title on scroll.
* **List:** `SliverList`
    * **Padding:** EdgeInsets.all(16).
    * **Items:** `WarrantyCard` widgets.

### B. Warranty Card Widget
* **Layout:** `Container` with `Row`.
* **Styling:**
    * **Border:** 1px Solid Grey (`Colors.grey.shade300`).
    * **Radius:** `BorderRadius.circular(16)`.
    * **Background:** White.
    * **Shadow:** None (Flat design).
* **Content:**
    * **Left:** 60x60 Image Thumbnail (Clipped Rect).
    * **Middle:** Column [Name (Bold), Store (Grey Small), Serial (Monospace)].
    * **Right:** `StatusBadge` (Pill shape container).
        * **Green:** > 30 Days.
        * **Orange:** < 30 Days.
        * **Red:** Expired.

### C. Add Item Screen (The Form)
* **Presentation:** Push as `MaterialPageRoute` (Full Screen) from the Camera logic.
* **Layout:**
    * **Top Header:** 250px high container showing the **Captured Image**.
        * **Overlay:** Black gradient at bottom for text visibility.
        * **Button:** Small "Retake" button in top-right.
    * **Body:** Scrollable Form.
    * **Fields:** Use `InputDecorator` style.
        * Labels should be outside the text field (Top Left).
        * Fields should have `FillColor: Colors.grey.shade50` and `BorderRadius: 12`.
    * **Action:** "Save Warranty" button (Full width, Height 54, Black).

### D. Details Screen
* **Hero Animation:** The image from the card should "fly" to the top of this screen.
* **Visuals:** Large Receipt Image at top.
* **Content:**
    * **Countdown:** Huge Text "12 Days Left" (Size 32, Bold).
    * **Table:** Simple rows: `Icon | Label | Value`.
* **Actions:** Two buttons at bottom (Outlined "Edit", Red Text "Delete").

## 4. The "Camera First" Workflow UI
**FAB Action:**
1.  User taps FAB.
2.  **Show Loading Overlay:** A black semi-transparent modal with a white `CircularProgressIndicator` and text "Scanning Receipt...".
3.  **Transition:** `Navigator.push` to Add Item Screen.

## 5. Theme Data (`app_theme.dart`)
* **Primary Color:** Black (`#000000`).
* **Scaffold Background:** `#F4F4F5` (Zinc-100).
* **Card Color:** White.
* **Divider Color:** `#E4E4E7` (Zinc-200).
* **Text Theme:**
    * `displayLarge`: Manrope, Bold, Black.
    * `bodyMedium`: Manrope, Regular, Zinc-900.
    * `labelSmall`: Manrope, Medium, Zinc-500.