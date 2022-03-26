import 'tokenizer.dart';

part 'entities.g.dart';

class Entity {
  final String name;
  final List<int> nameCodepoints;
  final List<int> values;
  const Entity(this.name, this.nameCodepoints, this.values);
}

Entity? entityByName(String name) {
  for (var entity in entities) {
    if (entity.name == name) {
      return entity;
    }
  }
  return null;
}

// This must handle the case of '&cent' and '&centerdot;' without needlessly
// consuming 'ere' in the case of '&centere'.
Entity? peekForMatchingEntity(InputManager input) {
  // firstPossible/oneAfterLastPossible limit our search window to
  // entities whose prefix we've already matched.
  var firstPossible = 0;
  var oneAfterLastPossible = entities.length;

  Entity? foundEntity;

  for (int codeOffset = 0; codeOffset < maxEntityLength; codeOffset++) {
    // 1 accounts for the amperstand.
    var offsetInEntity = 1 + codeOffset;
    bool foundMatch = false;
    var actual = input.peek(codeOffset);
    if (actual == endOfFile) {
      return foundEntity;
    }
    int entityIndex = firstPossible;
    // Check all possible entities for a match of current 'actual' char.
    while (entityIndex < oneAfterLastPossible) {
      var entity = entities[entityIndex];
      if (offsetInEntity < entity.nameCodepoints.length &&
          entity.nameCodepoints[offsetInEntity] == actual) {
        if (!foundMatch) {
          // Ignore any entities before this one as they don't prefix match.
          firstPossible = entityIndex;
        }
        foundMatch = true;
        // We found a longer entity:
        if (offsetInEntity == entity.nameCodepoints.length - 1) {
          foundEntity = entity;
        }
        // Not yet matched all chars, keep looking.
        break;
      } else {
        entityIndex += 1;
        if (foundMatch) {
          // Ignore entities after, they've started failing to match prefix.
          oneAfterLastPossible = entityIndex;
          break;
        }
        // Still haven't found first match, keep looking.
      }
    }
    if (oneAfterLastPossible - firstPossible <= 1) {
      // Ran out of entities to possibly match.
      return foundEntity;
    }
    // Still have entities matching this prefix, try the next letter.
  }
  return foundEntity;
}
