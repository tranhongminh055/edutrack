import 'dart:async';
import 'package:flutter/material.dart';

class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ hai';
      case 2: return 'Thứ ba';
      case 3: return 'Thứ tư';
      case 4: return 'Thứ năm';
      case 5: return 'Thứ sáu';
      case 6: return 'Thứ bảy';
      case 7: return 'Chủ nhật';
      default: return '';
    }
  }

  Widget _buildTimeBox(String digit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(digit, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hourStr = _currentTime.hour.toString().padLeft(2, '0');
    final minuteStr = _currentTime.minute.toString().padLeft(2, '0');
    final secondStr = _currentTime.second.toString().padLeft(2, '0');
    final dateStr = '${_getWeekdayName(_currentTime.weekday)}, ngày ${_currentTime.day} tháng ${_currentTime.month} năm ${_currentTime.year}';

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeBox(hourStr[0]), _buildTimeBox(hourStr[1]), const Text(' : ', style: TextStyle(color: Colors.white, fontSize: 20)),
            _buildTimeBox(minuteStr[0]), _buildTimeBox(minuteStr[1]), const Text(' : ', style: TextStyle(color: Colors.white, fontSize: 20)),
            _buildTimeBox(secondStr[0]), _buildTimeBox(secondStr[1]),
          ],
        ),
        const SizedBox(height: 8),
        Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
      ],
    );
  }
}
