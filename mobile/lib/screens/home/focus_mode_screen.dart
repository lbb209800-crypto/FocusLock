import '../../language.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({Key? key}) : super(key: key);

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  int _selectedMinutes = 5;
  bool _isActive = false;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startFocusMode() {
    setState(() {
      _isActive = true;
      _remainingSeconds = _selectedMinutes * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isActive = false;
          _showFocusComplete();
        }
      });
    });
  }

  void _stopFocusMode() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = 0;
    });
  }

  void _showFocusComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          context.tr('Focus Complete!', '집중 완료!'),
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          context.tr('Great job! You completed your focus session.', '잘했어요! 집중 시간을 완료했어요.'),
          style: TextStyle(color: Color(0xFFA0AEC0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('OK', '확인'),
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('Focus Mode', '집중 모드'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Lock your phone for 3-5 minutes to stay focused', '3분 또는 5분 타이머로 집중해보세요'),
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFA0AEC0),
            ),
          ),
          const SizedBox(height: 48),
          if (!_isActive)
            _buildModeSelector()
          else
            _buildActiveTimer(),
          const SizedBox(height: 48),
          if (!_isActive)
            ElevatedButton(
              onPressed: _startFocusMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.tr('Start Focus Mode', '집중 시작'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _stopFocusMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.tr('Stop Focus Mode', '집중 종료'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Select Duration', '집중 시간 선택'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [3, 5].map((minutes) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMinutes = minutes;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedMinutes == minutes
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedMinutes == minutes
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Text(
                    context.tr('$minutes min', '$minutes분'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActiveTimer() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              _formatTime(_remainingSeconds),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('Stay Focused!', '집중하고 있어요!'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
