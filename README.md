Implementing an HTML parser in Dart.

Next
* DocTypes
* Comments
* Entities


Failures by first expected token:
grep expected  test_expectations.txt | awk '{print $2}' | tr ',' ' ' | awk '{print $1}' | sort -r | uniq -c
      1 [["StartTag"
     39 [["Comment"
    124 [["Character"