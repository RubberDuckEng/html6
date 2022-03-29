Implementing an HTML parser in Dart.

All remaining tokenizer failures are lack of doubleEscaped=true
support in the test harness.

Questions
* When should the TreeBuilder use qName comparison vs. tagName?

Tests to upstream
* Entities in Attributes (no tests yet)