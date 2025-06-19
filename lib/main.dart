import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Fungsi untuk mengambil daftar artikel berita dari NewsAPI
Future<List<Article>> fetchArticles() async {
  // PENTING: Ganti 'YOUR_API_KEY' dengan API Key Anda dari newsapi.org
  const String apiKey = '827cb53e7edb4debabb75e240f4ea477';
  const String url = 'https://newsapi.org/v2/top-headlines?sources=techcrunch&apiKey=$apiKey';

  // Lakukan request HTTP GET
  final response = await http.get(Uri.parse(url));

  // Periksa apakah server merespons dengan status 200 OK
  if (response.statusCode == 200) {
    // Jika berhasil,urai JSON.
    // Body respons berisi struktur JSON: { "status": "ok", "totalResults": ..., "articles": [...] }
    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final List<dynamic> articlesJson = jsonResponse['articles'];

    // Jika daftar 'articles' ada dan tidak kosong, ubah setiap item JSON menjadi objek Article.
    if (articlesJson != null) {
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Format respons tidak valid: Daftar artikel tidak ditemukan.');
    }
  } else {
    // Jika server tidak merespons dengan OK, tampilkan error.
    // Coba periksa apakah API Key Anda sudah benar.
    throw Exception('Gagal memuat berita. Status code: ${response.statusCode}');
  }
}

// Model class untuk merepresentasikan satu artikel berita
class Article {
  final String title;
  final String? description; // Deskripsi bisa jadi null
  final String? urlToImage;  // URL gambar bisa jadi null

  const Article({
    required this.title,
    this.description,
    this.urlToImage,
  });

  // Factory constructor untuk membuat instance Article dari JSON
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String,
      description: json['description'] as String?,
      urlToImage: json['urlToImage'] as String?,
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
  // Menggunakan Future yang akan menampung List dari Article
  late Future<List<Article>> futureArticles;

  @override
  void initState() {
    super.initState();
    // Memanggil fungsi fetchArticles saat state diinisialisasi
    futureArticles = fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechCrunch News',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TechCrunch Top Headlines'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        // Menggunakan FutureBuilder untuk menangani state dari Future
        body: Center(
          child: FutureBuilder<List<Article>>(
            future: futureArticles,
            builder: (context, snapshot) {
              // Jika Future selesai dan memiliki data
              if (snapshot.hasData) {
                // Tampilkan data dalam ListView
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Article article = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tampilkan gambar jika URL ada
                            if (article.urlToImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  article.urlToImage!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  // Widget yang ditampilkan saat gambar sedang dimuat
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  // Widget yang ditampilkan jika terjadi error saat memuat gambar
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                                  },
                                ),
                              ),
                            const SizedBox(height: 12),
                            // Tampilkan judul berita
                            Text(
                              article.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Tampilkan deskripsi jika ada
                            if (article.description != null)
                              Text(
                                article.description!,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                // Jika Future selesai dengan error, tampilkan pesan error
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              // Selama Future berjalan, tampilkan loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
