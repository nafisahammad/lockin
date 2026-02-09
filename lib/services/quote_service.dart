import 'dart:convert';

import 'package:flutter/services.dart';

class QuoteService {
  static const _path = 'assets/data/quotes.json';

  Future<List<String>> loadQuotes() async {
    final raw = await rootBundle.loadString(_path);
    final data = jsonDecode(raw);
    if (data is List) {
      return data.whereType<String>().toList();
    }
    return [];
  }
}
