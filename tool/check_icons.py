"""Check launcher asset sizes, formats and platform wiring without extra packages."""
from pathlib import Path
import json
import struct
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]


def png(path: Path, width: int, color_type: int | None = None) -> None:
    data = path.read_bytes()
    assert data[:12] == b'\x89PNG\r\n\x1a\n\x00\x00\x00\r', path
    w, h, depth, color = struct.unpack('>IIBB', data[16:26])
    assert (w, h, depth) == (width, width, 8), path
    assert color_type is None or color == color_type, path
    assert len(data) > 100, path


source = root / 'AppStore/icon.png'
png(source, 1024, 2)  # opaque RGB, square; no pre-masked alpha corners
icon_set = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
entries = json.loads((icon_set / 'Contents.json').read_text())['images']
for entry in entries:
    width = float(entry['size'].split('x')[0])
    png(icon_set / entry['filename'], round(width * int(entry['scale'][0])), 2)
assert (icon_set / 'Icon-App-1024x1024@1x.png').read_bytes() == source.read_bytes()

for name, size in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    png(root / f'android/app/src/main/res/mipmap-{name}/ic_launcher.png', size, 2)
png(root / 'android/app/src/main/res/drawable/ic_launcher_foreground.png', 432, 6)
ns = {'android': 'http://schemas.android.com/apk/res/android'}
icon_xml = root / 'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml'
icon = ET.parse(icon_xml).getroot()
assert icon.tag == 'adaptive-icon'
foreground = icon.find('foreground')
background = icon.find('background')
assert foreground is not None and foreground.get('{%s}drawable' % ns['android']) == '@drawable/ic_launcher_foreground'
assert background is not None and background.get('{%s}drawable' % ns['android']) == '@color/ic_launcher_background'
assert 'name="ic_launcher_background"' in (root / 'android/app/src/main/res/values/ic_launcher_background.xml').read_text()
assert 'android:icon="@mipmap/ic_launcher"' in (root / 'android/app/src/main/AndroidManifest.xml').read_text()

ico = (root / 'windows/runner/resources/app_icon.ico').read_bytes()
reserved, kind, count = struct.unpack_from('<HHH', ico)
assert (reserved, kind, count) == (0, 1, 7)
sizes = {16, 24, 32, 48, 64, 128, 256}
for index in range(count):
    w, h, _, _, _, _, length, offset = struct.unpack_from('<BBBBHHII', ico, 6 + index * 16)
    size = w or 256
    assert size == (h or 256) and size in sizes
    sizes.remove(size)
    assert ico[offset:offset + 8] == b'\x89PNG\r\n\x1a\n'
    assert offset + length <= len(ico)
assert not sizes
print(f'Icon audit passed: source RGB, {len(entries)} iOS, 5 Android legacy, adaptive, 7 Windows ICO sizes')
