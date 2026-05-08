## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Keep native methods
-keepclassmembers class * {
    native <methods>;
}

## For image_cropper and other image libraries
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

## For cached_network_image
-keep class com.tekartik.sqflite.** { *; }

## Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

## Keep Serializable implementations
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

## Prevent obfuscation of model classes (if using reflection or Gson)
# Add your model packages here
# -keep class com.oxius.app.models.** { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

## flutter_callkit_incoming
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
# Keep WorkManager Worker subclasses used by flutter_callkit_incoming at runtime
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
# Keep ConnectionService subclasses (referenced by name in manifest merge)
-keep class * extends android.telecom.ConnectionService { *; }
-keep class * extends android.telecom.Connection { *; }
-dontwarn com.hiennv.flutter_callkit_incoming.**

## flutter_local_notifications — channel / notification classes referenced by name
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

## Agora RTC Engine — JNI bridge and reflection-loaded classes
-keep class io.agora.** { *; }
-dontwarn io.agora.**

## OkHttp / WebSocket (used by Django Channels WebSocket client inside flutter_background_service)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

## Keep all plugin classes
-keep class io.flutter.plugins.** { *; }
