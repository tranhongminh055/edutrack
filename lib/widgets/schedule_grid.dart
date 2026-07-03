import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

enum ScheduleViewMode { day, week, month }

class ScheduleGrid extends StatefulWidget {
  final List<ScheduleEvent> events;
  
  const ScheduleGrid({super.key, required this.events});

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  ScheduleViewMode _viewMode = ScheduleViewMode.week;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {
      if (_viewMode == ScheduleViewMode.day) {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      } else if (_viewMode == ScheduleViewMode.week) {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
      }
    });
  }

  void _prev() {
    setState(() {
      if (_viewMode == ScheduleViewMode.day) {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      } else if (_viewMode == ScheduleViewMode.week) {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
      }
    });
  }

  void _today() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  DateTime _getMonday(DateTime date) {
    int dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  String _getDateRangeString() {
    if (_viewMode == ScheduleViewMode.day) {
      return DateFormat('dd/MM/yyyy').format(_selectedDate);
    } else if (_viewMode == ScheduleViewMode.week) {
      DateTime monday = _getMonday(_selectedDate);
      DateTime sunday = monday.add(const Duration(days: 6));
      return '${DateFormat('dd/MM').format(monday)} - ${DateFormat('dd/MM/yyyy').format(sunday)}';
    } else {
      return 'Tháng ${DateFormat('MM/yyyy').format(_selectedDate)}';
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _prev,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                  child: const Icon(Icons.chevron_left, color: Colors.white70, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _next,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                  child: const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _today,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Hôm nay', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(_getDateRangeString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Row(
            children: [
              _buildViewBtn('Ngày', ScheduleViewMode.day),
              _buildViewBtn('Tuần', ScheduleViewMode.week),
              _buildViewBtn('Tháng', ScheduleViewMode.month),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewBtn(String text, ScheduleViewMode mode) {
    bool isActive = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  final List<String> hours = ['7sa', '8sa', '9sa', '10sa', '11sa', '12ch', '1ch', '2ch', '3ch', '4ch', '5ch', '6ch'];
  
  Widget _buildTimeColumn() {
    return SizedBox(
      width: 60,
      child: Column(
        children: hours.map((h) => Container(
          height: 80,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(right: 8, top: 4),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
          child: Text(h, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        )).toList(),
      ),
    );
  }

  Widget _buildGridLinesAndEvents(List<ScheduleEvent> events, int dayOfWeekFilter) {
    final dayEvents = events.where((e) => e.dayOfWeek == dayOfWeekFilter).toList();
    return Stack(
      children: [
        ...List.generate(12, (i) => Positioned(
          top: i * 80.0, left: 0, right: 0,
          child: Container(
            height: 80, 
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))))
          ),
        )),
        ...dayEvents.map((evt) {
          final top = (evt.startHour - 7.0) * 80.0;
          final height = evt.duration * 80.0;
          return Positioned(
            top: top, left: 2, right: 2, height: height,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: evt.color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
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
    );
  }

  Widget _buildDayGrid() {
    final dayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    final weekdayIndex = _selectedDate.weekday - 1; // 0 for Monday
    
    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
          child: Row(
            children: [
              const SizedBox(width: 60, child: Center(child: Text('Cả ngày', style: TextStyle(color: Colors.white70, fontSize: 12)))),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
                  child: Center(
                    child: Text('${dayNames[weekdayIndex]}, ${_selectedDate.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              height: 12 * 80.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeColumn(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
                      child: _buildGridLinesAndEvents(widget.events, _selectedDate.weekday + 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekGrid() {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    DateTime monday = _getMonday(_selectedDate);

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
          child: Row(
            children: [
              const SizedBox(width: 60, child: Center(child: Text('Cả ngày', style: TextStyle(color: Colors.white70, fontSize: 12)))),
              ...List.generate(7, (i) {
                DateTime dt = monday.add(Duration(days: i));
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
                    child: Center(
                      child: Text('${days[i]}, ${dt.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // Body
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              height: 12 * 80.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeColumn(),
                  ...List.generate(7, (dayIndex) {
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
                        child: _buildGridLinesAndEvents(widget.events, dayIndex + 2),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    DateTime firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    int startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    
    // We will render a 6x7 grid (42 cells)
    List<Widget> dayCells = [];
    
    // Previous month filler days
    DateTime prevMonth = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    int daysInPrevMonth = DateTime(_selectedDate.year, _selectedDate.month, 0).day;
    
    for (int i = startingWeekday - 1; i > 0; i--) {
      dayCells.add(_buildMonthCell(daysInPrevMonth - i + 1, isCurrentMonth: false, weekday: startingWeekday - i));
    }
    
    // Current month days
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime dt = DateTime(_selectedDate.year, _selectedDate.month, i);
      dayCells.add(_buildMonthCell(i, isCurrentMonth: true, weekday: dt.weekday));
    }
    
    // Next month filler days
    int remainingCells = 42 - dayCells.length;
    for (int i = 1; i <= remainingCells; i++) {
      DateTime dt = DateTime(_selectedDate.year, _selectedDate.month + 1, i);
      dayCells.add(_buildMonthCell(i, isCurrentMonth: false, weekday: dt.weekday));
    }

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
          child: Row(
            children: days.map((d) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(d, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )).toList(),
          ),
        ),
        // Grid
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            children: dayCells,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCell(int day, {required bool isCurrentMonth, required int weekday}) {
    // weekday is 1 for Mon, 7 for Sun
    // csvDayOfWeek is 2 for Mon, 8 for Sun -> csvDayOfWeek = weekday + 1
    final csvDayOfWeek = weekday + 1;
    final dayEvents = widget.events.where((e) => e.dayOfWeek == csvDayOfWeek).toList();
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        color: isCurrentMonth ? Colors.transparent : Colors.black.withValues(alpha: 0.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.toString(),
            style: TextStyle(
              color: isCurrentMonth ? Colors.white : Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (isCurrentMonth)
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: dayEvents.map((e) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: e.color,
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.02),
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: _viewMode == ScheduleViewMode.day
                ? _buildDayGrid()
                : _viewMode == ScheduleViewMode.week
                    ? _buildWeekGrid()
                    : _buildMonthGrid(),
          ),
        ],
      ),
    );
  }
}
