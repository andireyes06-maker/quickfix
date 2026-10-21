import "dart:typed_data";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:flutter/material.dart";
import "report_form_page.dart";

class ReportDetailsPage extends StatefulWidget {
  final String reportId;
  const ReportDetailsPage({super.key, required this.reportId});
  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  bool busy = false;
  String error = "";
  String photoPath = "";
  Future<Uint8List?>? photo;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? reportStream;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  void loadReport() {
    setState(() {
      reportStream = FirebaseFirestore.instance
          .collection("quickfix_reports")
          .doc(widget.reportId)
          .snapshots();
    });
  }

  String formatDate(Timestamp? value) {
    if (value == null) {
      return "Saving...";
    }
    final date = value.toDate().toLocal();
    return "${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // SIMULATE: only advance one step; this is a student project demo.
  Future<void> advanceStatus() async {
    setState(() {
      busy = true;
      error = "";
    });
    try {
      final reference = FirebaseFirestore.instance
          .collection("quickfix_reports")
          .doc(widget.reportId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final current = await transaction.get(reference);
        if (!current.exists) {
          throw Exception("This report no longer exists.");
        }
        List<String> statuses = [
          "Submitted",
          "Under Review",
          "In Progress",
          "Resolved",
        ];
        int index = statuses.indexOf(current.data()!["status"]);
        if (index < 0 || index == statuses.length - 1) {
          return;
        }
        transaction.update(reference, {
          "status": statuses[index + 1],
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Could not update the status. Please try again.";
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

  // DELETE: confirm first, then recheck the status inside the transaction.
  void confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Delete report?"),
          content: Text("This will delete the pending report and its photo."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteReport();
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteReport() async {
    setState(() {
      busy = true;
      error = "";
    });
    String path = "";
    try {
      final reference = FirebaseFirestore.instance
          .collection("quickfix_reports")
          .doc(widget.reportId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final current = await transaction.get(reference);
        if (!current.exists || current.data()!["status"] != "Submitted") {
          throw Exception("Only pending reports can be deleted.");
        }
        path = current.data()!["photoPath"];
        transaction.delete(reference);
      });
      String message = "Report deleted.";
      try {
        await FirebaseStorage.instance.ref(path).delete();
      } catch (e) {
        message =
            "Report deleted. Its photo could not be removed; please check Storage for cleanup.";
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Could not delete this report. It may no longer be pending.";
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: Text("Report details")),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: reportStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Could not load this report."),
                    TextButton(onPressed: loadReport, child: Text("Try again")),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.data!.exists) {
              return Center(child: Text("This report has been deleted."));
            }
            final report = snapshot.data!.data()!;
            String path = report["photoPath"];
            if (path != photoPath) {
              photoPath = path;
              photo = FirebaseStorage.instance
                  .ref(path)
                  .getData(5 * 1024 * 1024);
            }
            List<String> statuses = [
              "Submitted",
              "Under Review",
              "In Progress",
              "Resolved",
            ];
            int current = statuses.indexOf(report["status"]);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 680),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        report["title"],
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(report["category"])),
                          Chip(label: Text(report["status"])),
                        ],
                      ),
                      SizedBox(height: 16),
                      FutureBuilder<Uint8List?>(
                        future: photo,
                        builder: (context, image) {
                          if (image.hasError) {
                            return Column(
                              children: [
                                Text("The photo could not be loaded."),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      photo = FirebaseStorage.instance
                                          .ref(photoPath)
                                          .getData(5 * 1024 * 1024);
                                    });
                                  },
                                  child: Text("Retry photo"),
                                ),
                              ],
                            );
                          }
                          if (image.connectionState != ConnectionState.done) {
                            return SizedBox(
                              height: 180,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (image.data == null) {
                            return Text("Photo unavailable.");
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              image.data!,
                              height: 260,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Text(
                                  "Photo format cannot be displayed.",
                                );
                              },
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24),
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(report["description"]),
                      SizedBox(height: 24),
                      Text(
                        "Location",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(report["location"]),
                      Text(
                        "Approximate coordinates: ${(report['latitude'] as num).toStringAsFixed(3)}, ${(report['longitude'] as num).toStringAsFixed(3)}",
                      ),
                      SizedBox(height: 16),
                      Text("Submitted: ${formatDate(report['createdAt'])}"),
                      Text("Last update: ${formatDate(report['updatedAt'])}"),
                      SizedBox(height: 24),
                      Text(
                        "Report progress",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      for (int index = 0; index < statuses.length; index++)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                index <= current
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: index <= current
                                    ? Colors.indigo
                                    : Colors.grey,
                              ),
                              SizedBox(width: 10),
                              Text(statuses[index]),
                            ],
                          ),
                        ),
                      SizedBox(height: 16),
                      if (report["status"] == "Submitted") ...[
                        Text("Pending reports can still be edited or deleted."),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: busy
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return ReportFormPage(
                                          reportId: widget.reportId,
                                          report: report,
                                        );
                                      },
                                    ),
                                  );
                                },
                          icon: Icon(Icons.edit_outlined),
                          label: Text("Edit report"),
                        ),
                        TextButton.icon(
                          onPressed: busy ? null : confirmDelete,
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          label: Text(
                            "Delete report",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      if (report["status"] != "Resolved")
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Project demonstration",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Simulate the next status for this report. This does not notify maintenance staff. Editing and deletion stop once the report is under review.",
                                ),
                                TextButton(
                                  onPressed: busy ? null : advanceStatus,
                                  child: Text("Simulate next status"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (busy) LinearProgressIndicator(),
                      if (error.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            error,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
