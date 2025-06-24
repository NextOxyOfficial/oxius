# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep Capacitor WebView components
-keep class com.getcapacitor.** { *; }
-keep class com.getcapacitor.annotation.** { *; }
-keepnames class com.getcapacitor.**
-keepclassmembers class * extends com.getcapacitor.Plugin {
   @com.getcapacitor.annotation.CapacitorPlugin <methods>;
}

# Keep WebView JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable

# Keep parameter names for better debugging
-keepattributes LocalVariableTable,LocalVariableTypeTable

# Keep annotations
-keepattributes *Annotation*

# Don't warn about missing classes that might not be used
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn kotlin.jvm.functions.**
#-renamesourcefileattribute SourceFile
