import 'package:emojis/emojis.dart';
import 'package:test/test.dart';

void main() {
  test('check emojis are loaded', () async {
    var emojis = await Emoji.emojis;
    expect(emojis, isNotEmpty);
  });
}
