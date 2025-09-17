# Keep all Vosk classes
-keep class org.vosk.** { *; }

# Keep JNA (Java Native Access)
-keep class com.sun.jna.** { *; }
-dontwarn com.sun.jna.**

# Ignore AWT (not present on Android)
-dontwarn java.awt.**
