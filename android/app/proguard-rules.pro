# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Keep font assets (Material Icons)
-keep class **.R$* { *; }
-keepclassmembers class **.R$* { public static <fields>; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Prevent stripping of annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
