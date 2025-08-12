// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../services/photo_service.dart';
import 'comparison_view.dart';

class PhotoProgressView extends StatefulWidget {
  const PhotoProgressView({super.key});

  @override
  State<PhotoProgressView> createState() => _PhotoProgressViewState();
}

class _PhotoProgressViewState extends State<PhotoProgressView> {
  final PhotoService _photoService = PhotoService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, List<Map<String, dynamic>>> _photosByDate = {};

  final Map<String, String> _photoTypes = {
    'front': 'Front View',
    'back': 'Back View',
    'left': 'Left Side',
    'right': 'Right Side',
  };

  @override
  void initState() {
    super.initState();
    _verifyAndLoadData();
  }

  Future<void> _verifyAndLoadData() async {
    setState(() => _isLoading = true);
    try {
      await _photoService.verifyConnection();
      await _loadPhotos();
    } catch (e) {
      print('Error in initialization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPhotos() async {
    try {
      print('Starting to load photos...');
      final photos = await _photoService.getProgressPhotos();
      print('Loaded ${photos.length} photos');

      // Group photos by date
      final groupedPhotos = <String, List<Map<String, dynamic>>>{};
      for (var photo in photos) {
        final timestamp = photo['uploadedAt'] as DateTime?;
        if (timestamp != null) {
          final dateStr = DateFormat('d MMMM yyyy').format(timestamp);
          groupedPhotos.putIfAbsent(dateStr, () => []).add(photo);
        }
      }

      if (mounted) {
        setState(() {
          _photosByDate = groupedPhotos;
        });
      }
      print('Photos grouped by date: ${groupedPhotos.keys.length} dates');
    } catch (e) {
      print('Error loading photos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPhotoTypeDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select Photo Type",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                ..._photoTypes.entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _takePhoto(entry.key);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.primaryColor2,
                                foregroundColor: TColor.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(entry.value),
                            ),
                          ),
                        ))
                    ,
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _takePhoto(String photoType) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          await _photoService.uploadProgressPhoto(File(image.path), photoType);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadPhotos();
        } catch (e) {
          print('Error uploading photo: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload photo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPhotoItem(Map<String, dynamic> photo) {
    final String? url = photo['url'] as String?;
    final String? photoType = photo['photoType'] as String?;

    if (url == null || url.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(right: 10),
        width: 120,
        decoration: BoxDecoration(
          color: TColor.lightGray,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image,
                color: TColor.gray,
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                'Invalid URL',
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 120,
      decoration: BoxDecoration(
        color: TColor.lightGray,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              url,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                final double progress =
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : 0.0;

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        color: TColor.primaryColor1,
                      ),
                      const SizedBox(height: 8),
                      if (progress > 0)
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                print('Stack trace: $stackTrace');
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: TColor.gray,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Failed to load',
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          error.toString(),
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (photoType != null && photoType.isNotEmpty)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _photoTypes[photoType] ?? photoType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leadingWidth: 0,
        leading: const SizedBox(),
        title: Text(
          "Progress Photo",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: _verifyAndLoadData, // Refresh photos
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                Icons.refresh,
                color: TColor.gray,
                size: 20,
              ),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: TColor.primaryColor1))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: Container(
                          width: double.maxFinite,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: const Color(0xffFFE5E5),
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    color: TColor.white,
                                    borderRadius: BorderRadius.circular(30)),
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                child: Image.asset(
                                  "assets/img/date_notifi.png",
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Reminder!",
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        "Next Photos Fall On July 08",
                                        style: TextStyle(
                                            color: TColor.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ]),
                              ),
                              Container(
                                  height: 60,
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.close,
                                        color:
                                            TColor.gray.withValues(alpha: 0.5),
                                        size: 15,
                                      )))
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: Container(
                          width: double.maxFinite,
                          padding: const EdgeInsets.all(20),
                          height: media.width * 0.4,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                TColor.primaryColor2.withValues(alpha: 0.4),
                                TColor.primaryColor1.withValues(alpha: 0.4)
                              ]),
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    Text(
                                      "Track Your Progress Each\nMonth With Photo",
                                      style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: 110,
                                      height: 35,
                                      child: RoundButton(
                                          title: "Learn More",
                                          fontSize: 12,
                                          onPressed: () {}),
                                    )
                                  ]),
                              Image.asset(
                                "assets/img/progress_each_photo.png",
                                width: media.width * 0.35,
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 15),
                        decoration: BoxDecoration(
                          color: TColor.primaryColor2.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Compare my Photo",
                              style: TextStyle(
                                  color: TColor.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            SizedBox(
                              width: 100,
                              height: 25,
                              child: RoundButton(
                                title: "Compare",
                                type: RoundButtonType.bgGradient,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ComparisonView(),
                                    ),
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Gallery",
                              style: TextStyle(
                                  color: TColor.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            TextButton(
                                onPressed: () {},
                                child: Text(
                                  "See more",
                                  style: TextStyle(
                                      color: TColor.gray.withValues(alpha: 0.5),
                                      fontSize: 12),
                                ))
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  // Photos grouped by date
                  if (_photosByDate.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "No photos yet. Take your first progress photo!",
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _photosByDate.length,
                      itemBuilder: (context, index) {
                        final date = _photosByDate.keys.elementAt(index);
                        final photos = _photosByDate[date] ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                date,
                                style: TextStyle(
                                  color: TColor.gray,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: photos.length,
                                itemBuilder: (context, photoIndex) {
                                  return _buildPhotoItem(photos[photoIndex]);
                                },
                              ),
                            ),
                            SizedBox(height: 15),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: InkWell(
        onTap: _showPhotoTypeDialog,
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.secondaryG),
              borderRadius: BorderRadius.circular(27.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
              ]),
          alignment: Alignment.center,
          child: Icon(
            Icons.photo_camera,
            size: 20,
            color: TColor.white,
          ),
        ),
      ),
    );
  }
}
