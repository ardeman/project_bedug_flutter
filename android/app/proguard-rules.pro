# shared_preferences_android 2.5.0 calls its Kotlin API from Dart through
# Pigeon JNI and ships no keep rules, so R8 strips or renames what Dart looks
# up by name in release builds: the plugin's classes and the Kotlin types the
# `jni` package uses to await suspend functions.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
