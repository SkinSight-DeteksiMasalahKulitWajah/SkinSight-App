# ProGuard / R8 rules for SkinSight

# Kotlin coroutines / standard library (from origin/dev)
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit (Vision, Face Detection, Common, Internal)
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.datatransport.** { *; }
-keep class com.google.firebase.components.** { *; }
-keep class com.google_mlkit_face_detection.** { *; }
-keep class com.google_mlkit_commons.** { *; }

-keepclassmembers class * {
    @com.google.mlkit.** <methods>;
    @com.google.android.gms.** <methods>;
}

-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn com.google_mlkit_face_detection.**
-dontwarn com.google_mlkit_commons.**

# TensorFlow Lite / LiteRT
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }
-keep class com.google.ai.edge.litert.** { *; }
-keep class com.hugocornellier.flutter_litert.** { *; }

-dontwarn org.tensorflow.lite.**
-dontwarn com.google.ai.edge.litert.**
-dontwarn com.hugocornellier.flutter_litert.**
