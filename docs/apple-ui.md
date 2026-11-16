# Apple UI (iOS and macOS)

Rules for UI on the Apple path. The platform overview and detection rules are in `AGENTS.md`.

## Liquid Glass

- `Scaffold` uses `extendBody: true` and `extendBodyBehindAppBar: true` so content scrolls behind the glass bars.
- All glass comes from [`liquid_glass_easy`](https://pub.dev/packages/liquid_glass_easy); don't hand-build it from `BackdropFilter`. Glass that floats over content (nav bar, app bar capsule, buttons, badges) is a refracting `LiquidGlassLens` or a package component (`LiquidGlassTabBar`, `LiquidGlassButton`), tinted with `glassTintOf(ctx)` from `lib/core/design/liquid_glass.dart`. Glass that scrolls with a list (prayer cards) or may render on Skia (the method picker on other platforms) is `LiquidGlassLite`: the package advises against lenses inside scrollables, and Skia can't refract.
- The nav bar (`GlassNavBar`, a `LiquidGlassTabBar`) floats in a `Stack` over the page, not in `bottomNavigationBar`. It is `64` tall plus a bottom margin (`52` with a smaller icon and margin in windows under `500` tall, such as a phone in landscape), so lists end with enough padding to scroll clear of it. On iPhone Duo, where the system keeps the status items in a vertical bar on one side (an inset on that side only), it becomes a vertical glass rail in that bar (`GlassNavBar.railSideOf`), and tabs keep clear of the bar with `SideBarSafeArea`. A page with a dark backdrop under the bar (the prayer-times hero) wraps it in `GlassNavBackdropRegion`, so the tabs and their selection pill turn white over it and back to the text color and grey pill over the page.
- A tab's top bar is `GlassTopBar` (the title in a glass capsule over a scroll edge on Apple, centered when it fits and otherwise in the room beside the back button and actions, the accent `AppBar` elsewhere) with `extendBodyBehindAppBar: PlatformCapabilities.isApple`. Prayer times has its own collapsing sliver bar. The scaffold sets the page's bottom padding to `GlassNavBar.occupiedHeight`, so lists and `SafeArea` keep clear of the floating nav bar.
- Glass card: `Material(color: Colors.transparent)` → `LiquidGlassLite(shape: continuousRoundedRectangle(cornerRadius: AppRadii.lg))` with a white tint (alpha ~0.62 light, ~0.07 dark). `GlassCard` in `lib/core/design/liquid_glass.dart` builds it, and falls back to a Material `Card` elsewhere.
- No Material widgets on Apple paths, including ink ripples, `ListTile`, `Divider` and Material spinners or scrollbars. Use `GlassIconButton` or `LiquidGlassButton` for buttons (`GlassPillButton` inside scrolling glass), `LiquidGlassSwitch` for switches, `showGlassMenu` (`lib/core/widgets/glass_menu.dart`) instead of `DropdownButton`, `ToggleButtons` or popup menus, and `PlatformListTile`, `GlassPressable`, `Hairline` and `AdaptiveSpinner` from `lib/core/design/glass_controls.dart`. The settings rows in `settings_screen.dart` show the pattern.
- Glass follows the system's Liquid Glass style and accessibility through `GlassAccessibility` (`lib/core/design/glass_accessibility.dart`, fed by a native event channel in `ios/Runner/AppDelegate.swift` and `macos/Runner/MainFlutterWindow.swift`): the Clear-to-Tinted amount moves tints from clear to opaque, Increase Contrast makes them opaque, and Reduce Transparency makes them the solid `colorScheme.surface`. Take tints from `glassTintOf` (floating glass), `glassCardTintOf` (cards) or `glassSheetTintOf` (sheets), never a raw white or black alpha, and pick icon colors over glass from how light the tinted glass is, not a fixed white.
- Floating glass buttons (`LiquidGlassButton`, `GlassIconButton`) take `touch: glassButtonTouchOf(ctx)`, so they squeeze under a press and stretch after a drag like system glass, and stay rigid with Reduce Motion.
- Don't give a lens an `Opacity` of zero to hide it; also set `visibility: false` so it stops reading the backdrop.
- Full-screen blur overlay (sheet, modal): push a `PageRouteBuilder(opaque: false, barrierColor: Colors.transparent)` whose page is a tap-to-dismiss `Scaffold(backgroundColor: Colors.black38)` with the glass panel aligned to the bottom.
- Decorative layers (gradients, blur) stacked above tappable controls are wrapped in `IgnorePointer`, or they swallow taps on the app bar icons.
- On iOS/macOS the prayer-times app bar icons are round `LiquidGlassButton`s with Material `Icons.*`. Their color moves from white (over the accent hero) to `onSurface` as the bar collapses.
- Apple sliver app bars: the collapsed height and action offsets account for the Dynamic Island in portrait, landscape layouts respect horizontal safe-area cutouts, and the expanded header uses compact sizing so collapsing never overflows a `RenderFlex`.

## macOS window and nav bar

- Keep the window chrome in `macos/Runner/MainFlutterWindow.swift`: `titleVisibility = .hidden`, `titlebarAppearsTransparent = true`, `.fullSizeContentView`, `isMovableByWindowBackground = true`, `isOpaque = false` with a clear background and a corner radius on the Flutter view, and traffic-light buttons repositioned at an explicit top/left inset, updated on every resize.
- The nav bar's selection pill can be tapped or dragged between tabs on every Apple platform; `LiquidGlassTabBar` handles it.

## Sheets

- Native, non-blur Apple sheets are fine where native behavior is wanted: the calculation method picker (`lib/core/widgets/calculation_method_picker.dart`) uses `showCupertinoSheet` on iOS/macOS, `M3EBottomSheet` on Material paths and a liquid-glass route on other desktop paths.
- Guard every sheet against opening twice; repeated taps while it opens stack a second sheet. Keep an open flag and reset it in `finally`.

