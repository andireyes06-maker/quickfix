import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "report_form_page.dart";
import "report_details_page.dart";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QuickFix"),
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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab == 0 ? "My reports" : "Report history",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      tab == 0
                          ? "Report a problem. Track the progress."
                          : "Your resolved campus maintenance reports.",
                    ),
                  ],
                ),
              ),
              if (tab == 0)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (String status in [
                        "All",
                        "Submitted",
                        "Under Review",
                        "In Progress",
                      ])
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: filter == status,
                            onSelected: (selected) {
                              setState(() {
                                filter = status;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: reports,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
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
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data!.docs.where((item) {
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
                      if (first == null || second == null) {
                        return 0;
                      }
                      return second.compareTo(first);
                    });
                    if (items.isEmpty) {
                      return Center(
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
                                color: Colors.indigo,
                              ),
                              SizedBox(height: 16),
                              Text(
                                tab == 0
                                    ? "No reports here yet"
                                    : "No resolved reports yet",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                tab == 0
                                    ? "Use New report to tell us what needs fixing."
                                    : "Resolved reports will appear in your history.",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final report = items[index].data();
                        return Card(
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.shade50,
                              child: Icon(
                                Icons.build_outlined,
                                color: Colors.indigo,
                              ),
                            ),
                            title: Text(
                              report["title"],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 6),
                                Text(report["location"]),
                                SizedBox(height: 8),
                                Text(
                                  report["status"],
                                  style: TextStyle(
                                    color: report["status"] == "Resolved"
                                        ? Colors.green.shade800
                                        : Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
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
        selectedItemColor: Colors.indigo,
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
