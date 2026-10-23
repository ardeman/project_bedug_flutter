import 'package:dbus/dbus.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/linux_desktop.dart';

const _portalInterface = 'org.freedesktop.portal.Settings';
const _appearanceNamespace = 'org.freedesktop.appearance';
const _accentKey = 'accent-color';

/// The desktop accent color on GNOME and KDE, read from the XDG settings
/// portal and updated live when the user changes it. Null when the desktop
/// sets none, the portal is missing, or the app isn't on GNOME or KDE.
final systemAccentProvider = StreamProvider<Color?>((ref) {
  if (currentLinuxDesktop == LinuxDesktop.other) return Stream.value(null);
  return _watchPortalAccent();
});

Stream<Color?> _watchPortalAccent() async* {
  final client = DBusClient.session();
  try {
    final portal = DBusRemoteObject(
      client,
      name: 'org.freedesktop.portal.Desktop',
      path: DBusObjectPath('/org/freedesktop/portal/desktop'),
    );
    final changes = DBusRemoteObjectSignalStream(
      object: portal,
      interface: _portalInterface,
      name: 'SettingChanged',
      signature: DBusSignature('ssv'),
    );
    yield accentFromPortalValue(await _readAccent(portal));
    await for (final signal in changes) {
      if (signal.values[0].asString() == _appearanceNamespace &&
          signal.values[1].asString() == _accentKey) {
        yield accentFromPortalValue(signal.values[2]);
      }
    }
  } on Exception {
    // No session bus or no portal: fall back to the brand accent.
    yield null;
  } finally {
    await client.close();
  }
}

Future<DBusValue> _readAccent(DBusRemoteObject portal) async {
  final args = [DBusString(_appearanceNamespace), DBusString(_accentKey)];
  try {
    final result = await portal.callMethod(
      _portalInterface,
      'ReadOne',
      args,
      replySignature: DBusSignature('v'),
    );
    return result.returnValues.first;
  } on DBusMethodResponseException {
    // Portals older than version 2 only have the deprecated Read.
    final result = await portal.callMethod(
      _portalInterface,
      'Read',
      args,
      replySignature: DBusSignature('v'),
    );
    return result.returnValues.first;
  }
}

/// Parses the portal's accent value: an sRGB `(ddd)` struct in 0–1, possibly
/// wrapped in variants. Out-of-range channels mean "no accent set".
Color? accentFromPortalValue(DBusValue value) {
  var inner = value;
  while (inner is DBusVariant) {
    inner = inner.value;
  }
  if (inner is! DBusStruct || inner.children.length != 3) return null;
  final channels = <double>[];
  for (final child in inner.children) {
    if (child is! DBusDouble || child.value < 0 || child.value > 1) {
      return null;
    }
    channels.add(child.value);
  }
  return Color.from(
    alpha: 1,
    red: channels[0],
    green: channels[1],
    blue: channels[2],
  );
}
