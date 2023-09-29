import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final eventUrl = 'https://www.facebook.com/events/1225019481413631/';
  final html = await fetchHtml(eventUrl);

  final imageUrl = extractImageUrl(html);
  print('Main Event Image URL: $imageUrl');
}

Future<String> fetchHtml(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to load HTML: ${response.statusCode}');
  }
}

String? extractImageUrl(String html) {
  final RegExp imageRegExp = RegExp(
    r'<meta property="og:image" content="([^"]*)"',
    caseSensitive: false,
    multiLine: true,
  );

  final match = imageRegExp.firstMatch(html);
  if (match != null) {
    final imageUrl = match.group(1);
    return imageUrl;
  } else {
    return 'Image not found';
  }
}
