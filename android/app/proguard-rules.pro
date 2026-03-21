# ProGuard configuration for OkHttp3 (needed for image_cropper)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

-keep class okio.** { *; }
-keep interface okio.** { *; }
-dontwarn okio.**

# Keep image_cropper classes
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Keep native methods (used by libs)
-keepclasseswithmembernames class * {
    native <methods>;
}
