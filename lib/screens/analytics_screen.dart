import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db_helper.dart';
import '../utils/app_strings.dart';

class AnalyticsScreen extends StatefulWidget {
  final int tripId;

  const AnalyticsScreen({super.key, required this.tripId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, double> data = {};
  String mode = "category";

  Map<int, String> memberNames = {};
  Map<int, String> tripNames = {};

  int touchedIndex = -1;

  final List<Color> colors = [
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFFF44336),
    const Color(0xFF00BCD4),
    const Color(0xFFFFC107),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 🔥 TOTAL
  double get total => data.values.fold(0, (sum, e) => sum + e);

  /// 🔥 LOAD DATA
  Future<void> _loadData() async {
    final db = DBHelper.instance;

    final expenses = await db.getAll("expenses");
    final members = await db.getAll("members");
    final trips = await db.getAll("trips");

    memberNames = {for (var m in members) m["id"]: m["name"]};
    tripNames = {for (var t in trips) t["id"]: t["name"]};

    Map<String, double> temp = {};

    for (var e in expenses) {
      double amt = (e["amount"] as num).toDouble();

      if (mode == "category") {
        String key = e["category"] ?? "Other";
        temp[key] = (temp[key] ?? 0) + amt;
      } else if (mode == "members") {
        String name = memberNames[e["addedBy"]] ?? "Unknown";
        temp[name] = (temp[name] ?? 0) + amt;
      } else {
        String name = tripNames[e["tripId"]] ?? "Trip";
        temp[name] = (temp[name] ?? 0) + amt;
      }
    }

    setState(() {
      data = temp;
    });
  }

  /// 🔥 LEGEND (PRO STYLE)
  Widget _buildLegend() {
    return Column(
      children: data.entries.toList().asMap().entries.map((entry) {
        int index = entry.key;
        var e = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.key)),
              Text(
                "₹${e.value.toInt()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 🔥 PIE CHART
  Widget _buildChart() {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            // swapAnimationDuration: const Duration(milliseconds: 500),
            // swapAnimationCurve: Curves.easeInOut,
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                setState(() {
                  touchedIndex =
                      response?.touchedSection?.touchedSectionIndex ?? -1;
                });
              },
            ),
            sections: data.entries.toList().asMap().entries.map((entry) {
              int index = entry.key;
              var e = entry.value;

              final isTouched = index == touchedIndex;

              return PieChartSectionData(
                value: e.value,
                color: colors[index % colors.length],
                radius: isTouched ? 85 : 70,
                title: isTouched ? "₹${e.value.toInt()}" : "",
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),

        /// 🔥 CENTER TEXT
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.get("total"),
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              "₹${total.toInt()}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get("analytics")),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [Colors.grey.shade900, Colors.grey.shade900]
                  : [Colors.teal, Colors.teal],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: data.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: 300),
                  Center(child: Text(AppStrings.get("no_data"))),
                ],
              )
            : ListView(
                children: [
                  const SizedBox(height: 10),

                  /// 🔥 TOGGLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text(AppStrings.get("category")),
                        selected: mode == "category",
                        onSelected: (_) {
                          setState(() => mode = "category");
                          _loadData();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(AppStrings.get("members")),
                        selected: mode == "members",
                        onSelected: (_) {
                          setState(() => mode = "members");
                          _loadData();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(AppStrings.get("trips")),
                        selected: mode == "trips",
                        onSelected: (_) {
                          setState(() => mode = "trips");
                          _loadData();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// 🔥 CHART CARD
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Expense Overview",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(height: 240, child: _buildChart()),
                        const SizedBox(height: 10),
                        _buildLegend(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
