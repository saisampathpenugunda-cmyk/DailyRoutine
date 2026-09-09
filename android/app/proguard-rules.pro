# Preserve generic signatures for Gson's TypeToken
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Keep Gson TypeToken and subclasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * extends com.google.gson.reflect.TypeToken { *; }

# Keep FlutterLocalNotificationsPlugin classes and models
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Avoid warnings for desugared Java 8+ APIs
-dontwarn java.time.**
