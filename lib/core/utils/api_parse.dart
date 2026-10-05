/// Small helpers so every new screen reads server JSON the same forgiving
/// way (the API sometimes returns a bare list, sometimes `{data: [...]}`
/// or `{results: [...]}`).
class ApiParse {
  ApiParse._();

  static List<Map<String, dynamic>> list(dynamic raw) {
    dynamic l = raw;
    if (raw is Map) {
      l = raw['data'] ?? raw['results'] ?? raw['items'] ?? const [];
      if (l is Map) l = l['results'] ?? l['items'] ?? const [];
    }
    if (l is! List) return const [];
    return l
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Map<String, dynamic> map(dynamic raw) {
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  static double d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String s(dynamic v, [String fallback = '']) {
    final t = v?.toString().trim();
    return (t == null || t.isEmpty) ? fallback : t;
  }

  static bool b(dynamic v) =>
      v == true || v?.toString().toLowerCase() == 'true' || v?.toString() == '1';

  static DateTime? date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

class Fmt {
  Fmt._();

  /// 1234567 -> ₹12,34,567 (Indian grouping)
  static String money(num v, {bool compact = false}) {
    if (compact) {
      if (v.abs() >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
      if (v.abs() >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
      if (v.abs() >= 1000) return '₹${(v / 1000).toStringAsFixed(1)} K';
    }
    final neg = v < 0;
    final s = v.abs().round().toString();
    String out;
    if (s.length <= 3) {
      out = s;
    } else {
      final last3 = s.substring(s.length - 3);
      var rest = s.substring(0, s.length - 3);
      final parts = <String>[];
      while (rest.length > 2) {
        parts.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) parts.insert(0, rest);
      out = '${parts.join(',')},$last3';
    }
    return '${neg ? '-' : ''}₹$out';
  }

  static String pct(num v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}%';

  static String date(DateTime? t) {
    if (t == null) return '';
    String two(int x) => x.toString().padLeft(2, '0');
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${two(t.day)} ${m[t.month - 1]} ${t.year}';
  }

  static String ago(DateTime? t) {
    if (t == null) return 'never';
    final d = DateTime.now().difference(t);
    if (d.inDays >= 30) return '${d.inDays ~/ 30} mo ago';
    if (d.inDays >= 1) return '${d.inDays} d ago';
    if (d.inHours >= 1) return '${d.inHours} h ago';
    return 'today';
  }
}
