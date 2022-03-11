import 'package:html6/html6.dart';
import 'package:test/test.dart';

void main() {
  test('basic', () {
    var parent = Node();
    expect(parent.parent, isNull);
    expect(parent.firstChild, isNull);
    expect(parent.lastChild, isNull);
    expect(parent.nextSibling, isNull);
    expect(parent.previousSibling, isNull);

    var child1 = Node();
    parent.appendChild(child1);
    expect(parent.parent, isNull);
    expect(parent.firstChild, equals(child1));
    expect(parent.lastChild, equals(child1));
    expect(parent.nextSibling, isNull);
    expect(parent.previousSibling, isNull);
    expect(child1.parent, parent);
    expect(child1.firstChild, isNull);
    expect(child1.lastChild, isNull);
    expect(child1.nextSibling, isNull);
    expect(child1.previousSibling, isNull);

    var child2 = Node();
    parent.appendChild(child2);
    expect(parent.parent, isNull);
    expect(parent.firstChild, equals(child1));
    expect(parent.lastChild, equals(child2));
    expect(parent.nextSibling, isNull);
    expect(parent.previousSibling, isNull);
    expect(child1.parent, parent);
    expect(child1.firstChild, isNull);
    expect(child1.lastChild, isNull);
    expect(child1.nextSibling, child2);
    expect(child1.previousSibling, isNull);
    expect(child2.parent, parent);
    expect(child2.firstChild, isNull);
    expect(child2.lastChild, isNull);
    expect(child2.nextSibling, isNull);
    expect(child2.previousSibling, child1);

    var parent2 = Node();
    parent2.appendChild(child1);
    expect(parent2.parent, isNull);
    expect(parent2.firstChild, equals(child1));
    expect(parent2.lastChild, equals(child1));
    expect(parent2.nextSibling, isNull);
    expect(parent2.previousSibling, isNull);
    expect(child1.parent, parent2);
    expect(child1.firstChild, isNull);
    expect(child1.lastChild, isNull);
    expect(child1.nextSibling, isNull);
    expect(child1.previousSibling, isNull);
    expect(parent.parent, isNull);
    expect(parent.firstChild, equals(child2));
    expect(parent.lastChild, equals(child2));
    expect(parent.nextSibling, isNull);
    expect(parent.previousSibling, isNull);
    expect(child2.parent, parent);
    expect(child2.firstChild, isNull);
    expect(child2.lastChild, isNull);
    expect(child2.nextSibling, isNull);
    expect(child2.previousSibling, isNull);
  });

  test('cycles disallowed', () {
    expect(() {
      var parent = Node();
      parent.appendChild(parent);
    }, throwsException);

    var parent = Node();
    var child = Node();
    parent.appendChild(child);
    expect(() {
      child.appendChild(parent);
    }, throwsException);
  });
}
