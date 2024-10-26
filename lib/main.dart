import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RGBImageApp extends StatefulWidget {
  @override
  _RGBImageAppState createState() => _RGBImageAppState();
}

class _RGBImageAppState extends State<RGBImageApp> {
  ui.Image? _image;
  String _rgbValue = 'RGB Değerini görmek için bir piksele tıklayın';
  List<List<String>> _rgbMatrix = [];
  bool isLoading = false;

  Future<void> _loadImage() async {
    // Resim Yüklememizi sağlayan fonksiyon..
    setState(() {
      isLoading = true;
    });
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      setState(() {
        _image = frame.image;
        _extractRgbMatrix(); // Resim yüklendikten sonra RGB matrisini oluşturacak fonksiyon çağırıldı.
        isLoading = false;
      });
    }
  }

  // Tüm piksellerin RGB değerlerini matrise ekleyen fonksiyon
  Future<void> _extractRgbMatrix() async {
    if (_image != null) {
      final ByteData? data =
          await _image!.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data != null) {
        _rgbMatrix.clear(); // Mevcut matris boşaltılır
        for (int y = 0; y < _image!.height; y++) {
          List<String> row = [];
          for (int x = 0; x < _image!.width; x++) {
            final int offset = (y * _image!.width + x) * 4;
            final int r = data.getUint8(offset);
            final int g = data.getUint8(offset + 1);
            final int b = data.getUint8(offset + 2);
            row.add('($x, $y): ($r, $g, $b)'); // X, Y ve RGB değerini kaydettik
          }
          _rgbMatrix.add(row); // Satırı matrise ekledik
        }
        setState(() {});
      }
    }
  }

  // Seçilen pikselin RGB değerini gösteren fonksiyon
  Future<void> _getPixelColor(int x, int y) async {
    if (_image != null) {
      final ByteData? data =
          await _image!.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data != null) {
        final int offset = (y * _image!.width + x) * 4;
        final int r = data.getUint8(offset);
        final int g = data.getUint8(offset + 1);
        final int b = data.getUint8(offset + 2);
        setState(() {
          _rgbValue = 'X: $x, Y: $y, RGB: ($r, $g, $b)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('RGB Değerleri'),
      ),
      body: Row(
        children: [
          // Resim alanı
          Expanded(
            flex: 1,
            child: _image != null
                ? GestureDetector(
                    onTapDown: (details) {
                      final x = details.localPosition.dx.toInt();
                      final y = details.localPosition.dy.toInt();
                      _getPixelColor(x, y);
                    },
                    child: SizedBox(
                      width: _image!.width.toDouble(),
                      height: size.height * 0.6,
                      child: RawImage(image: _image),
                    ),
                  )
                : Center(
                    child: isLoading
                        ? CircularProgressIndicator()
                        : Text('Görüntü Yüklenmedi')),
          ),

          VerticalDivider(width: 1, color: Colors.grey),

          // RGB matris alanı
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _rgbMatrix.isNotEmpty
                    ? Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                10, // 10 hücrelik bir satırda göster
                            childAspectRatio: 1,
                          ),
                          itemCount: _rgbMatrix.length * (_rgbMatrix[0].length),
                          itemBuilder: (context, index) {
                            int rowIndex = index ~/ _rgbMatrix[0].length;
                            int columnIndex = index % _rgbMatrix[0].length;
                            String colorInfo =
                                _rgbMatrix[rowIndex][columnIndex];

                            return Container(
                              margin: EdgeInsets.all(1),
                              padding: EdgeInsets.all(3),
                              color: Colors.grey[300],
                              child: Center(
                                child: AutoSizeText(
                                  colorInfo,
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Text('RGB Matris Henüz Yüklenmedi'),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadImage,
                  child: Text('Görüntü Yükle'),
                ),
                SizedBox(height: 10),
                Text(
                  ("Seçilen Pixelin RGB Kodu: $_rgbValue"),
                  style: TextStyle(color: Colors.red, fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: RGBImageApp()));
