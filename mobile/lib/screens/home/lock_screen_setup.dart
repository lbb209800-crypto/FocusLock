import '../../language.dart';
import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../models/lock_screen.dart';

class LockScreenSetup extends StatefulWidget {
  const LockScreenSetup({Key? key}) : super(key: key);

  @override
  State<LockScreenSetup> createState() => _LockScreenSetupState();
}

class _LockScreenSetupState extends State<LockScreenSetup> {
  final _aiService = AiService();
  final _moodController = TextEditingController();
  bool _isGenerating = false;
  LockScreenData? _generatedLockScreen;

  Future<void> _generateLockScreen() async {
    if (_moodController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter your mood or situation', '기분이나 상황을 입력해주세요'))),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final lockScreen = await _aiService.generateLockScreen(
        _moodController.text,
      );

      if (!mounted) return;

      setState(() {
        _generatedLockScreen = lockScreen;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('Error', '오류')}: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Create Your Lock Screen', '나만의 잠금 화면 만들기'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Tell AI your mood or current situation', 'AI에게 기분이나 현재 상황을 알려주세요'),
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFA0AEC0),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _moodController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  context.tr('e.g., I need to focus on work, feeling stressed, celebrating...', '예: 공부에 집중하고 싶어요, 스트레스를 받고 있어요...'),
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateLockScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: const Color(0xFF6366F1)
                    .withOpacity(0.5),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      context.tr('Generate Lock Screen', '잠금 화면 생성'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
          if (_generatedLockScreen != null)
            _buildPreview(_generatedLockScreen!),
        ],
      ),
    );
  }

  Widget _buildPreview(LockScreenData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Preview', '미리보기'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFA0AEC0),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${context.tr('Code', '코드')}: ${data.bioCode}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6366F1),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('Lock screen saved!', '잠금 화면 저장 기능은 준비 중이에요'))),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.tr('Apply Lock Screen', '잠금 화면 적용'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
