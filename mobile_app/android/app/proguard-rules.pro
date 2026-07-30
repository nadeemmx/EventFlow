# Play Core (needed by Flutter deferred components)
-keep class com.google.android.play.core.** { *; }

# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Razorpay
-keep class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.** { *; }

# Dio / Retrofit
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Hive
-keep class com.hive.** { *; }

# Model classes (data classes used by JSON serialization)
-keep class com.eventflow.eventflow_app.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Gson TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep generic signatures
-keepclassmembers class * {
    public <methods>;
    private <methods>;
}

# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Dont obfuscate
-dontobfuscate
