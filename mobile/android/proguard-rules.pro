# Keep Google ML Kit Face Detection classes that may be accessed reflectively.
# This rule is relevant when R8/ProGuard minification is enabled for release builds.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-keepclassmembers class * {
    @com.google.mlkit.** <methods>;
}
