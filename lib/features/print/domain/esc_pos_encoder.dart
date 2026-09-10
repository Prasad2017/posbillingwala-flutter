import 'dart:convert';
import 'dart:typed_data';

/// Minimal ESC/POS builder for 58mm/80mm thermal printers.
class EscPosEncoder {
  EscPosEncoder({this.charsPerLine = 32});

  /// 32 ≈ 58mm (2"), 48 ≈ 80mm (3").
  final int charsPerLine;
  final BytesBuilder _bytes = BytesBuilder();

  List<int> get bytes => _bytes.toBytes();

  void raw(List<int> data) => _bytes.add(data);

  void init() {
    raw(const [0x1B, 0x40]); // ESC @
  }

  void alignLeft() => raw(const [0x1B, 0x61, 0x00]);
  void alignCenter() => raw(const [0x1B, 0x61, 0x01]);
  void alignRight() => raw(const [0x1B, 0x61, 0x02]);

  void bold(bool on) => raw([0x1B, 0x45, on ? 0x01 : 0x00]);

  void text(
    String value, {
    bool boldStyle = false,
    bool center = false,
  }) {
    if (center) {
      alignCenter();
    } else {
      alignLeft();
    }
    bold(boldStyle);
    final encoded = latin1.encode(_sanitize(value));
    raw(encoded);
    raw(const [0x0A]);
    bold(false);
    alignLeft();
  }

  void line(String left, String right) {
    final space = charsPerLine - left.length - right.length;
    final gap = space > 1 ? ' ' * space : ' ';
    text('$left$gap$right');
  }

  void separator([String char = '-']) {
    text(char * charsPerLine);
  }

  void feed([int lines = 2]) {
    for (var i = 0; i < lines; i++) {
      raw(const [0x0A]);
    }
  }

  void cut() {
    // Partial cut where supported.
    raw(const [0x1D, 0x56, 0x01]);
  }

  String _sanitize(String value) {
    return value
        .replaceAll('₹', 'Rs.')
        .replaceAll('—', '-')
        .replaceAll('•', '*')
        .replaceAll(RegExp(r'[^\x20-\x7E\n]'), '?');
  }
}
