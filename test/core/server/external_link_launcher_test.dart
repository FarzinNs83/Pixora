import 'package:flutter_test/flutter_test.dart';
import 'package:pixora/core/server/external_link_launcher.dart';

void main() {
  test('only HTTPS and support email URLs can leave the desktop WebView', () {
    expect(isSafeExternalUrl('https://github.com/example/project'), isTrue);
    expect(isSafeExternalUrl('mailto:support@example.org'), isTrue);
    expect(isSafeExternalUrl('http://github.com/example/project'), isFalse);
    expect(isSafeExternalUrl('file:///C:/private.txt'), isFalse);
    expect(isSafeExternalUrl('https://user:pass@example.org'), isFalse);
    expect(isSafeExternalUrl('javascript:alert(1)'), isFalse);
  });
}
