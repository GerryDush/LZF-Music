# 忽略 Google Play Core 相关的缺失类警告
-dontwarn com.google.android.play.core.**
-ignorewarnings

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# audio_service
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**

# audio_session
-keep class com.ryanheise.audio_session.** { *; }
-dontwarn com.ryanheise.audio_session.**

# media_kit
-keep class com.alexmercerind.** { *; }
-dontwarn com.alexmercerind.**

# media3
-keep class androidx.media3.** { *; }
-keepclassmembers class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Media
-keep class androidx.media.** { *; }
-keep interface androidx.media.** { *; }

# MediaSession
-keep class android.support.v4.media.** { *; }
-keep interface android.support.v4.media.** { *; }

# Attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Native
-keepclasseswithmembernames class * {
    native <methods>;
}