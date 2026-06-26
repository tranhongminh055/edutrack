import 'package:flutter/material.dart';

class ScheduleEvent {
  final String title;
  final String subtitle;
  final int dayOfWeek; // 2 -> Thứ 2, ..., 8 -> Chủ nhật
  final double startHour; // 7.0 -> 7:00 AM
  final double duration; // in hours
  final Color color;

  ScheduleEvent({
    required this.title,
    required this.subtitle,
    required this.dayOfWeek,
    required this.startHour,
    required this.duration,
    this.color = Colors.blue,
  });
}

class ScheduleGrid extends StatefulWidget {
  final List<ScheduleEvent> events;
  
  const ScheduleGrid({super.key, required this.events});

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = ['T2, 22', 'T3, 23', 'T4, 24', 'T5, 25', 'T6, 26', 'T7, 27', 'CN, 28'];
    final hours = ['7sa', '8sa', '9sa', '10sa', '11sa', '12ch', '1ch', '2ch', '3ch', '4ch', '5ch', '6ch'];

    return Container(
      color: Colors.white.withOpacity(0.02),
      child: Column(
        children: [
          // Header row
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
            child: Row(
              children: [
                const SizedBox(width: 60, child: Center(child: Text('Cả ngày', style: TextStyle(color: Colors.white70, fontSize: 12)))),
                ...days.map((d) => Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1)))),
                  child: Center(child: Text(d, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ))),
              ],
            ),
          ),
          // Body
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: 12 * 80.0, // 80px per hour
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time column
                    SizedBox(
                      width: 60,
                      child: Column(
                        children: hours.map((h) => Container(
                          height: 80,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 8, top: 4),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
                          child: Text(h, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        )).toList(),
                      ),
                    ),
                    // Days columns
                    ...List.generate(7, (dayIndex) {
                      // dayIndex 0 = Thứ 2 (dayOfWeek = 2)
                      final dayEvents = widget.events.where((e) => e.dayOfWeek == dayIndex + 2).toList();
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1)))),
                          child: Stack(
                            children: [
                              // Grid lines
                              ...List.generate(12, (i) => Positioned(
                                top: i * 80.0, left: 0, right: 0,
                                child: Container(height: 80, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))))),
                              )),
                              // Events
                              ...dayEvents.map((evt) {
                                final top = (evt.startHour - 7.0) * 80.0;
                                final height = evt.duration * 80.0;
                                return Positioned(
                                  top: top,
                                  left: 2,
                                  right: 2,
                                  height: height,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: evt.color.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                    child: SingleChildScrollView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.edit, size: 12, color: Colors.red.shade800),
                                              const SizedBox(width: 4),
                                              Expanded(child: Text(evt.title, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(evt.subtitle, style: const TextStyle(color: Colors.black87, fontSize: 10, height: 1.3)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
