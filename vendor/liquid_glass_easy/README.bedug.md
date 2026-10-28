# Bedug patch of liquid_glass_easy 5.0.0

Source: https://pub.dev/packages/liquid_glass_easy/versions/5.0.0 (MIT; see LICENSE).
Only the runtime library, shaders, license and package manifest are vendored.

The animated navigation bar converts global pointer positions to the gesture
overlay's local coordinates before calculating the tab fraction. This preserves
the package's held lift, refraction, stretch and release when RotatedBox turns
the bar into the iPhone Duo rail. A pan recognizer shares the same drag lifecycle
so users can also start dragging without waiting for the hold threshold.

Regression coverage lives in ../../test/liquid_glass_test.dart. Remove this local
copy and restore the hosted dependency once an upstream version handles rotated
coordinates and immediate dragging. Do not edit the shared pub cache.
