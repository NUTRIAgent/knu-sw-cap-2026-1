import 'package:flutter/material.dart';
import 'package:flutter_app/services/price_alert_service.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/services/local_notification_service.dart';

class PriceAlertScreen extends StatefulWidget {
  final String jwt;
  const PriceAlertScreen({super.key, required this.jwt});

  @override
  State<PriceAlertScreen> createState() => _PriceAlertScreenState();
}

class _PriceAlertScreenState extends State<PriceAlertScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await PriceAlertService.getMyAlerts(widget.jwt);
    if (mounted) setState(() { _alerts = items; _loading = false; });
  }

  Future<void> _unfollow(String kamisItemCode, String name) async {
    final ok = await PriceAlertService.unfollow(kamisItemCode, widget.jwt);
    if (!mounted) return;
    if (ok) {
      setState(() => _alerts.removeWhere((a) => a['kamisItemCode'] == kamisItemCode));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name 알림을 해제했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('가격 변동 알림',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          TextButton(
            onPressed: _sendDemoNotification,
            child: Text('테스트',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _alerts.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _alerts.length,
                    itemBuilder: (context, i) => _buildCard(_alerts[i]),
                  ),
                ),
    );
  }

  Future<void> _sendDemoNotification() async {
    if (_alerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('팔로우한 재료가 없습니다')),
      );
      return;
    }
    final name = _alerts.first['kamisItemName'] as String? ?? '양파';
    await LocalNotificationService.show(
      '📊 $name 가격 변동',
      '▲ 5.3% 변동 (1,200원 → 1,264원)',
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('설정된 알림이 없어요',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('KAMIS 식재료 상세 화면에서\n팔로우 버튼을 눌러보세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> alert) {
    final kamisItemCode = alert['kamisItemCode'] as String? ?? '';
    final name = alert['kamisItemName'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppTheme.aiGradient.createShader(b),
            child: const Icon(Icons.notifications_active_rounded, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => _unfollow(kamisItemCode, name),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('해제',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }
}
