import "dart:async";
import "dart:convert";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:geolocator/geolocator.dart";
import "package:image_picker/image_picker.dart";

// Returns the photo type we accept, or "" when the file is not a JPG, PNG, or WebP.
// A known mime type wins; the file name is only used when there is no mime type.
String photoTypeFor(String mimeType, String fileName) {
  String mime = mimeType.toLowerCase();
  String name = fileName.toLowerCase();
  if (mime.isNotEmpty) {
    if (mime == "image/jpeg" || mime == "image/jpg") {
      return "image/jpeg";
    }
    if (mime == "image/png") {
      return "image/png";
    }
    if (mime == "image/webp") {
      return "image/webp";
    }
    return "";
  }
  if (name.endsWith(".jpg") || name.endsWith(".jpeg")) {
    return "image/jpeg";
  }
  if (name.endsWith(".png")) {
    return "image/png";
  }
  if (name.endsWith(".webp")) {
    return "image/webp";
  }
  return "";
}

class ReportFormPage extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic>? report;
  const ReportFormPage({super.key, this.reportId = "", this.report});
  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  String category = "Furniture";
  String photoType = "image/jpeg";
  String error = "";
  Uint8List? photo;
  double? latitude;
  double? longitude;
  bool busy = false;
  bool deviceBusy = false;
  bool changed = false;
  bool hasPhoto = false;
  Future<Uint8List?>? currentPhoto;
  String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.report != null) {
      final data = widget.report!;
      titleController.text = data["title"];
      descriptionController.text = data["description"];
      locationController.text = data["location"];
      category = data["category"];
      latitude = (data["latitude"] as num).toDouble();
      longitude = (data["longitude"] as num).toDouble();
      hasPhoto = true;
      // Only for the preview; saving never waits for this.
      currentPhoto = loadPhoto(widget.reportId);
    }
    recoverPhoto();
  }

  // Photos are saved in Firestore as base64 text, because Firebase Storage needs a paid plan.
  Future<Uint8List?> loadPhoto(String reportId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("quickfix_photos")
        .doc(reportId)
        .get();
    if (!snapshot.exists) {
      return null;
    }
    return base64Decode(snapshot.data()!["data"]);
  }

  // Recover a photo if Android restarted the app while the camera was open.
  Future<void> recoverPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.files != null && response.files!.isNotEmpty) {
        await usePhoto(response.files!.first);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error =
              "The previous photo could not be restored. Please take it again.";
        });
      }
    }
  }

  Future<void> usePhoto(XFile file) async {
    String mime = "";
    if (file.mimeType != null) {
      mime = file.mimeType!;
    }
    String type = photoTypeFor(mime, file.name);
    if (type.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        error = "Choose a JPG, PNG, or WebP photo.";
      });
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    if (bytes.length > 500 * 1024) {
      setState(() {
        error = "This photo is too large. Take it again or choose a smaller one.";
      });
      return;
    }
    setState(() {
      photo = bytes;
      photoType = type;
      error = "";
      changed = true;
    });
  }

  // CAMERA
  Future<void> pickPhoto(ImageSource source) async {
    setState(() {
      deviceBusy = true;
      error = "";
    });
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
        requestFullMetadata: false,
      );
      if (file != null) {
        await usePhoto(file);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error =
              "Could not open the camera or photo library. Check permissions and try again.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          deviceBusy = false;
        });
      }
    }
  }

  // LOCATION: round coordinates to approximately 100 m precision.
  Future<void> getLocation() async {
    setState(() {
      deviceBusy = true;
      error = "";
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() {
            error = "Turn on your device location services, then try again.";
          });
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            error =
                "Location is blocked. Enable it for QuickFix in your device or browser settings.";
          });
        }
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            error =
                "Location permission is needed to record where you reported the problem.";
          });
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 30),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        latitude = (position.latitude * 1000).round() / 1000;
        longitude = (position.longitude * 1000).round() / 1000;
        changed = true;
      });
    } on TimeoutException {
      if (mounted) {
        setState(() {
          error =
              "Could not get your location in time. Try again near a window or outdoors.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Could not get your location. Please try again.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          deviceBusy = false;
        });
      }
    }
  }

  // CREATE / UPDATE
  Future<void> saveReport() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (photo == null && !hasPhoto) {
      setState(() {
        error = "Please take or choose a photo of the problem.";
      });
      return;
    }
    if (latitude == null || longitude == null) {
      setState(() {
        error = "Tap Record location before submitting your report.";
      });
      return;
    }
    setState(() {
      busy = true;
      error = "";
    });
    final collection = FirebaseFirestore.instance.collection(
      "quickfix_reports",
    );
    final reference = widget.reportId.isEmpty
        ? collection.doc()
        : collection.doc(widget.reportId);
    final photoReference = FirebaseFirestore.instance
        .collection("quickfix_photos")
        .doc(reference.id);
    try {
      Map<String, dynamic> values = {
        "ownerId": userId,
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "location": locationController.text.trim(),
        "category": category,
        "photoPath": "quickfix_photos/${reference.id}",
        "latitude": latitude,
        "longitude": longitude,
        "updatedAt": FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (widget.reportId.isNotEmpty) {
          final current = await transaction.get(reference);
          if (!current.exists ||
              current.data()!["ownerId"] != userId ||
              current.data()!["status"] != "Submitted") {
            throw Exception(
              "This report is no longer pending and cannot be edited.",
            );
          }
          transaction.update(reference, values);
        } else {
          values["status"] = "Submitted";
          values["createdAt"] = FieldValue.serverTimestamp();
          transaction.set(reference, values);
        }
        // The photo is saved in the same transaction, so a report never exists without it.
        if (photo != null) {
          transaction.set(photoReference, {
            "ownerId": userId,
            "contentType": photoType,
            "data": base64Encode(photo!),
            "updatedAt": FieldValue.serverTimestamp(),
          });
        }
      });
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.reportId.isEmpty ? "Report submitted." : "Report updated.",
          ),
        ),
      );
    } on FirebaseException {
      if (mounted) {
        setState(() {
          error = "Could not save the report. Check your connection and try again.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error =
              "Could not save this report. Check your connection and that it is still pending.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  // Ask before leaving a form that has unsaved input.
  void confirmDiscard() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Discard changes?"),
          content: Text("Your changes to this report have not been saved."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("Keep editing"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: Text("Discard"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !busy && !changed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) {
          confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.reportId.isEmpty ? "New report" : "Edit report"),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: formKey,
                onChanged: () {
                  if (!changed) {
                    setState(() {
                      changed = true;
                    });
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "What needs fixing?",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Add a clear photo and enough detail to identify the campus problem.",
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: titleController,
                      enabled: !busy,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: "Problem title",
                        hintText: "Broken chair in Room 204",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a problem title";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      enabled: !busy,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: "Description",
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please describe the problem";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: locationController,
                      enabled: !busy,
                      maxLength: 160,
                      decoration: InputDecoration(
                        labelText: "Campus location",
                        hintText: "Building, floor, and room",
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter the campus location";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(labelText: "Category"),
                      items: [
                        for (String item in [
                          "Furniture",
                          "Electrical",
                          "Plumbing",
                          "Equipment",
                          "Other",
                        ])
                          DropdownMenuItem(value: item, child: Text(item)),
                      ],
                      onChanged: busy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  category = value;
                                  changed = true;
                                });
                              }
                            },
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Problem photo",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (photo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          photo!,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                "Photo preview unavailable. Choose a JPG, PNG, or WebP photo.",
                              ),
                            );
                          },
                        ),
                      ),
                    if (photo == null && hasPhoto)
                      FutureBuilder<Uint8List?>(
                        future: currentPhoto,
                        builder: (context, image) {
                          if (image.connectionState != ConnectionState.done) {
                            return SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (image.hasError || image.data == null) {
                            return Text(
                              "The current photo could not be previewed. It will be kept unless you choose a replacement.",
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  image.data!,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) {
                                    return Text(
                                      "The current photo cannot be displayed.",
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Your existing photo will be kept unless you choose a replacement.",
                              ),
                            ],
                          );
                        },
                      ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: busy || deviceBusy
                              ? null
                              : () {
                                  pickPhoto(ImageSource.camera);
                                },
                          icon: Icon(Icons.camera_alt_outlined),
                          label: Text("Take photo"),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy || deviceBusy
                              ? null
                              : () {
                                  pickPhoto(ImageSource.gallery);
                                },
                          icon: Icon(Icons.photo_library_outlined),
                          label: Text("Choose photo"),
                        ),
                      ],
                    ),
                    Text(
                      "One photo (JPG, PNG, or WebP). It is made smaller automatically. On desktop browsers, Take photo may open a file picker.",
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Approximate location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      latitude == null
                          ? "Record your location while you are near the problem."
                          : "Recorded: ${latitude!.toStringAsFixed(3)}, ${longitude!.toStringAsFixed(3)}",
                    ),
                    TextButton.icon(
                      onPressed: busy || deviceBusy ? null : getLocation,
                      icon: Icon(Icons.my_location),
                      label: Text(
                        latitude == null
                            ? "Record location"
                            : "Record location again",
                      ),
                    ),
                    if (deviceBusy) LinearProgressIndicator(),
                    if (error.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          error,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: busy || deviceBusy ? null : saveReport,
                      icon: Icon(Icons.send_outlined),
                      label: Text(
                        busy
                            ? "Saving report..."
                            : widget.reportId.isEmpty
                            ? "Submit report"
                            : "Save changes",
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
