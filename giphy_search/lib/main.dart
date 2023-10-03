import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Giphy Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Giphy Search'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List _gifs = [];
  int _offset = 0;
  bool _isLoading = false;
  Timer _debounce = Timer(Duration.zero, () {});

  Future searchGifs(String query) async {
    if (_isLoading) return; // prevent loading when it's already loading

    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse(
          'https://api.giphy.com/v1/gifs/search?api_key=A9OgJaBI060BU7Uh63a9JOMAXTzyaiDQ&q=$query&limit=25&offset=$_offset');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _gifs.addAll(data['data']);
          _offset += 25;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        // You can show error message here
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // You can show error message here
    }
  }

  @override
  void dispose() {
    _debounce.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Search Gifs'),
              onChanged: (value) {
                if (_debounce.isActive) _debounce.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      _gifs = [];
                      _offset = 0;
                    });
                    searchGifs(value);
                  }
                });
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: _gifs.length + (_isLoading ? 1 : 0), // +1 for loading indicator
              itemBuilder: (BuildContext context, int index) {
                if (index == _gifs.length) {
                  return Center(child: CircularProgressIndicator());
                }

                if (index == _gifs.length - 1) {
                  searchGifs(_controller.text);
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  child: CachedNetworkImage(
                    imageUrl: _gifs[index]['images']['downsized']['url'],
                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

