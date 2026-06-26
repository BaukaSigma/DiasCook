import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Кеш загруженных изображений чтобы не грузить каждый раз
final Map<String, Uint8List> _imageCache = {};

class FirestoreImage extends StatefulWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  const FirestoreImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  State<FirestoreImage> createState() => _FirestoreImageState();
}

class _FirestoreImageState extends State<FirestoreImage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initValues();
    _load();
  }

  void _initValues() {
    final url = widget.imageUrl;
    if (url.startsWith('firestore_image:')) {
      final docId = url.replaceFirst('firestore_image:', '');
      if (_imageCache.containsKey(docId)) {
        _bytes = _imageCache[docId];
        _loading = false;
      } else {
        _bytes = null;
        _loading = true;
      }
    } else {
      _bytes = null;
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(FirestoreImage old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) {
      _initValues();
      _load();
    }
  }

  Future<void> _load() async {
    final url = widget.imageUrl;
    if (!url.startsWith('firestore_image:')) {
      return;
    }
    final docId = url.replaceFirst('firestore_image:', '');
    if (_imageCache.containsKey(docId)) {
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('product_images').doc(docId).get();
      final dataUrl = doc.data()?['data']?.toString() ?? '';
      if (dataUrl.contains(',')) {
        final bytes = base64Decode(dataUrl.split(',').last);
        _imageCache[docId] = bytes;
        if (mounted && widget.imageUrl == url) {
          setState(() {
            _bytes = bytes;
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted && widget.imageUrl == url) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;

    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: Image.memory(bytes, height: widget.height, width: widget.width, fit: widget.fit),
        );
      } catch (_) {
        return Container(
          height: widget.height, width: widget.width,
          color: Colors.grey.shade200,
          child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
        );
      }
    }

    if (url.startsWith('firestore_image:')) {
      if (_loading) {
        return Container(
          height: widget.height, width: widget.width,
          color: Colors.grey.shade100,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      if (_bytes != null) {
        return Image.memory(_bytes!, height: widget.height, width: widget.width, fit: widget.fit);
      }
      return Container(
        height: widget.height, width: widget.width,
        color: Colors.grey.shade200,
        child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
      );
    }

    if (url.startsWith('http')) {
      return Image.network(url, height: widget.height, width: widget.width, fit: widget.fit,
          errorBuilder: (_, __, ___) => Container(
            height: widget.height, width: widget.width,
            color: Colors.grey.shade200,
            child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
          ));
    }

    return Image.asset(
      url.replaceFirst('assets/assets/', 'assets/'),
      height: widget.height, width: widget.width, fit: widget.fit,
    );
  }
}
