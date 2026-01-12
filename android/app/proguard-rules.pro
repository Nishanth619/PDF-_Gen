
# Add project specific ProGuard rules here.

# Keep PDF library classes
-keep class com.tom_roush.pdfbox.** { *; }
-dontwarn com.tom_roush.pdfbox.**

# Keep image processing classes
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# Keep camera classes
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep model classes
-keep class com.nishanth.smartpdfconverter.models.** { *; }

# Google ML Kit text recognition missing classes
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# OkHttp missing classes
-dontwarn okhttp3.Call
-dontwarn okhttp3.Dispatcher
-dontwarn okhttp3.OkHttpClient
-dontwarn okhttp3.Request$Builder
-dontwarn okhttp3.Request
-dontwarn okhttp3.Response
-dontwarn okhttp3.ResponseBody

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
-keep class com.google.ads.** { *; }
-dontwarn com.google.ads.**

# In-App Purchase
-keep class com.android.vending.billing.** { *; }

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
