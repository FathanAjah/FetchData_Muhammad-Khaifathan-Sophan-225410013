import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<List<Article>> fetchArticles() async {
  const String url = 'https://newsdata.io/api/1/latest?apikey=pub_c08a559bda424f82b1731554de38ebb6&language=id&category=technology,top,sports,lifestyle&timezone=Asia/Jakarta';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

    final List<dynamic> resultsJson = jsonResponse['results'];

    return resultsJson.map((json) => Article.fromJson(json)).toList();
  } else {
    throw Exception('Gagal memuat berita. Status code: ${response.statusCode}');
  }
}

class Article {
  final String title;
  final String? description;
  final String? imageUrl;

  const Article({
    required this.title,
    this.description,
    this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Article>> futureArticles;

  @override
  void initState() {
    super.initState();
    futureArticles = fetchArticles();
  }

  // Fungsi untuk refresh data
  Future<void> _refresh() async {
    setState(() {
      futureArticles = fetchArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gens NEWS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple[700],
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Gens NEWS'),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Center(
            child: FutureBuilder<List<Article>>(
              future: futureArticles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (snapshot.hasData) {
                  final articles = snapshot.data!;
                  return ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      Article article = articles[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        elevation: 4,
                        clipBehavior: Clip.antiAlias, // Agar gambar sesuai dengan lengkungan Card
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tampilkan gambar jika URL ada
                            if (article.imageUrl != null)
                              Image.network(
                                article.imageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  // Tampilkan placeholder jika gambar gagal dimuat
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported,
                                        size: 50, color: Colors.grey),
                                  );
                                },
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (article.description != null)
                                    Text(
                                      article.description!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey[800]),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                // Tampilan default jika tidak ada data
                return const Text("Tidak ada berita yang ditemukan.");
              },
            ),
          ),
        ),
      ),
    );
  }
}
