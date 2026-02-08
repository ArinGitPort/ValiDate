# Keep ML Kit text recognition classes
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep all ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
