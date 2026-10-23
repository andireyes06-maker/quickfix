import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "../brand_mark.dart";
import "report_form_page.dart";
import "report_details_page.dart";

// The first word of the student's name, or "there" when the account has no name.
String firstNameOf(String? displayName) {
  if (displayName == null) {
    return "there";
  }
  String name = displayName.trim();
  if (name.isEmpty) {
    return "there";
  }
  return name.split(" ")[0];
}

// The friendly line under the greeting on My Reports.
String openReportsLine(int count) {
  if (count == 0) {
    return "No open reports right now.";
  }
  if (count == 1) {
    return "1 open report. Thanks for helping our campus.";
  }
  return "$count open reports. Thanks for helping our campus.";
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int tab = 0;
  String filter = "All";
  String userId = FirebaseAuth.instance.currentUser!.uid;
  Stream<QuerySnapshot<Map<String, dynamic>>>? reports;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  void loadReports() {
    setState(() {
      reports = FirebaseFirestore.instance
          .collection("quickfix_reports")
          .where("ownerId", isEqualTo: userId)
          .snapshots();
    });
  }

  // One color per status, so every screen shows a status the same way.
  Color statusColor(String status) {
    if (status == "Under Review") {
      return Color(0xFFB45309);
    }
    if (status == "In Progress") {
      return Colors.blue.shade800;
    }
    if (status == "Resolved") {
      return Colors.green.shade800;
    }
    return Colors.grey.shade700;
  }

  // One icon per category, so reports are easier to tell apart in the list.
  IconData categoryIcon(String category) {
    if (category == "Furniture") {
      return Icons.chair_outlined;
    }
    if (category == "Electrical") {
      return Icons.electrical_services;
    }
    if (category == "Plumbing") {
      return Icons.plumbing;
    }
    if (category == "Equipment") {
      return Icons.devices_other;
    }
    return Icons.build_outlined;
  }

  // A new report has no server time for a moment, so there is no date to show yet.
  String shortDate(Timestamp? value) {
    if (value == null) {
      return "";
    }
    final date = value.toDate().toLocal();
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 28),
            SizedBox(width: 10),
            Text("QuickFix"),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Sign out",
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Could not sign out. Please try again."),
                  ),
                );
              }
            },
          ),
        ],
      ),
      // The header, the count tiles, and the list all use the same snapshot.
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reports,
        builder: (context, snapshot) {
          final docs = snapshot.hasData ? snapshot.data!.docs : [];
          int submitted = 0;
          int underReview = 0;
          int inProgress = 0;
          for (final item in docs) {
            String status = item.data()["status"];
            if (status == "Submitted") {
              submitted++;
            }
            if (status == "Under Review") {
              underReview++;
            }
            if (status == "In Progress") {
              inProgress++;
            }
          }
          int openCount = submitted + underReview + inProgress;
          final items = docs.where((item) {
            String status = item.data()["status"];
            if (tab == 1) {
              return status == "Resolved";
            }
            return status != "Resolved" &&
                (filter == "All" || filter == status);
          }).toList();
          items.sort((a, b) {
            Timestamp? first = a.data()["createdAt"];
            Timestamp? second = b.data()["createdAt"];
            if (first == null && second == null) {
              return 0;
            }
            // A report that was just created has no server time yet, so show it first.
            if (first == null) {
              return -1;
            }
            if (second == null) {
              return 1;
            }
            return second.compareTo(first);
          });
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Color(0xFF1F3A5F),
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab == 0
                          ? "Hello, ${firstNameOf(FirebaseAuth.instance.currentUser!.displayName)}"
                          : "Report history",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      tab == 1
                          ? "Your resolved campus maintenance reports."
                          : snapshot.hasData
                          ? openReportsLine(openCount)
                          : "Loading your reports...",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    if (tab == 0)
                      Text(
                        "Demo: status changes are simulated.",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              if (tab == 0)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          for (String status in [
                            "Submitted",
                            "Under Review",
                            "In Progress",
                          ])
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Semantics(
                                  button: true,
                                  selected: filter == status,
                                  child: Material(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: filter == status
                                            ? Color(0xFF1F3A5F)
                                            : Color(0xFFDFE5EE),
                                        width: filter == status ? 2 : 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        setState(() {
                                          filter = filter == status
                                              ? "All"
                                              : status;
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 4,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              status == "Submitted"
                                                  ? "$submitted"
                                                  : status == "Under Review"
                                                  ? "$underReview"
                                                  : "$inProgress",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F3A5F),
                                              ),
                                            ),
                                            // Shrinks only when large text would break the word.
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF44516A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 760),
                    child: snapshot.hasError
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Could not load your reports."),
                                TextButton(
                                  onPressed: loadReports,
                                  child: Text("Try again"),
                                ),
                              ],
                            ),
                          )
                        : !snapshot.hasData
                        ? Center(child: CircularProgressIndicator())
                        : items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tab == 0
                                        ? Icons.assignment_outlined
                                        : Icons.task_alt,
                                    size: 64,
                                    color: Color(0xFF1F3A5F),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    tab == 1
                                        ? "No resolved reports yet"
                                        : filter == "All"
                                        ? "You are all caught up"
                                        : "No $filter reports",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    tab == 1
                                        ? "Resolved reports will appear in your history."
                                        : filter == "All"
                                        ? "No open reports right now. Use New report if something needs fixing."
                                        : "Reports that reach this status will show up here.",
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final report = items[index].data();
                              return Card(
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: Color(0xFFE6ECF5),
                                    child: Icon(
                                      categoryIcon(report["category"]),
                                      color: Color(0xFF1F3A5F),
                                    ),
                                  ),
                                  title: Text(
                                    report["title"],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 6),
                                      Text(report["location"]),
                                      SizedBox(height: 8),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        children: [
                                          Text(
                                            report["status"],
                                            style: TextStyle(
                                              color: statusColor(
                                                report["status"],
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (shortDate(
                                            report["createdAt"],
                                          ).isNotEmpty)
                                            Text(
                                              shortDate(report["createdAt"]),
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return ReportDetailsPage(
                                            reportId: items[index].id,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton.extended(
              backgroundColor: Color(0xFFF2B134),
              foregroundColor: Color(0xFF1F3A5F),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ReportFormPage();
                    },
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text("New report"),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        selectedItemColor: Color(0xFF1F3A5F),
        onTap: (index) {
          setState(() {
            tab = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: "My reports",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
    );
  }
}
