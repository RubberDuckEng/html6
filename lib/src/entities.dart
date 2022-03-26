import 'tokenizer.dart';

part 'entities.g.dart';

class Entity {
  final String name;
  final List<int> nameCodepoints;
  final List<int> values;
  const Entity(this.name, this.nameCodepoints, this.values);
}

Entity? findMatchingEntity(InputManager input, StringBuffer consumed) {
  var firstPossible = 0;
  var oneAfterLastPossible = entities.length;
  for (int codeOffset = 0; codeOffset < maxEntityLength; codeOffset++) {
    // 1 accounts for the amperstand.
    var offsetInEntity = 1 + codeOffset;
    bool foundMatch = false;
    if (input.isEndOfFile) {
      return null;
    }
    var actual = input.getNextCodePoint();
    consumed.writeCharCode(actual);
    int entityIndex = firstPossible;
    while (entityIndex < oneAfterLastPossible) {
      var entity = entities[entityIndex];
      if (offsetInEntity < entity.nameCodepoints.length &&
          entity.nameCodepoints[offsetInEntity] == actual) {
        foundMatch = true;
        // We found matching entity;
        if (offsetInEntity == entity.nameCodepoints.length - 1) {
          return entity;
        }
        // Not yet matched all chars, keep looking.
        break;
      } else {
        entityIndex += 1;
        if (foundMatch) {
          oneAfterLastPossible = entityIndex;
          break;
        }
        // Still haven't found first match, keep looking.
      }
      if (oneAfterLastPossible - firstPossible <= 1) {
        // Ran out of entities to possibly match.
        return null;
      }
    }
    // No match, give up.
  }
  return null;
}
