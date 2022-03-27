import 'package:html6/html6.dart';
import 'package:test/test.dart';

void main() {
  test('basic empty', () {
    var empty = HTMLParser().parse('');
    expect(empty.firstChild, isNull);
    expect(empty.lastChild, isNull);
    expect(empty.parent, isNull);
  });

  // test('basic space', () {
  //   var doc = parse(' ');
  // });

  // test('basic non-space', () {
  //   var doc = parse('a');
  // });
}
