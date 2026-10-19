/// Lowercase hex of [bytes], e.g. `hex([0x23, 0x08], sep: ' ')` -> `"23 08"`.
String hex(List<int> bytes, {String sep = ''}) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(sep);
