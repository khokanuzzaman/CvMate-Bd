/// Turns an editable list of skills back into skill names.
///
/// One skill per line. A comma also separates skills, but only outside
/// brackets, so "State Management (Provider, Riverpod, or BLoC)" stays one
/// skill while "Git, Docker" is two. Empty entries and repeats (ignoring
/// case) are dropped; the first spelling is kept.
abstract final class SkillListText {
  static List<String> parse(String text) {
    final names = <String>[];
    final seen = <String>{};
    void add(StringBuffer buffer) {
      final name = buffer.toString().trim();
      buffer.clear();
      if (name.isNotEmpty && seen.add(name.toLowerCase())) {
        names.add(name);
      }
    }

    final current = StringBuffer();
    var depth = 0;
    for (final char in text.split('')) {
      if (char == '\n' || char == '\r') {
        depth = 0;
        add(current);
      } else if (char == ',' && depth == 0) {
        add(current);
      } else {
        if (char == '(' || char == '[' || char == '{') {
          depth++;
        } else if ((char == ')' || char == ']' || char == '}') && depth > 0) {
          depth--;
        }
        current.write(char);
      }
    }
    add(current);
    return names;
  }
}
