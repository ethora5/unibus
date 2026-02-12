import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

class FeedbackCenterScreen extends StatefulWidget {
  const FeedbackCenterScreen({super.key});

  @override
  State<FeedbackCenterScreen> createState() => _FeedbackCenterScreenState();
}

class _FeedbackCenterScreenState extends State<FeedbackCenterScreen> {
  bool filtersExpanded = false;

  final List<_FeedbackItem> items = const [
    _FeedbackItem(
      priority: 'Low',
      status: 'Resolved',
      message:
          'The driver was very respectful\nand cooperative. Excellent\nservice!',
      bus: 'Bus A',
      driver: 'John\nSmith',
      date: '2025-12-\n07',
    ),
    _FeedbackItem(
      priority: 'High',
      status: 'Pending',
      message:
          'The bus was 15 minutes late at\nthe library stop. Please review\nthe schedule.',
      bus: 'Bus B',
      driver: 'Sarah',
      date: '2025-12-\n08',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Complaints Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.roleSelection,
            (_) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            const SizedBox(height: 12),

            // ✅ Filters bar (زي اللي في الصورة)
            InkWell(
              onTap: () => setState(() => filtersExpanded = !filtersExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: Colors.black54, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      filtersExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),

            if (filtersExpanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Text(
                  'Filter options will be added later.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 14),

            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeedbackCard(item: e),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackItem {
  final String priority;
  final String status;
  final String message;
  final String bus;
  final String driver;
  final String date;

  const _FeedbackItem({
    required this.priority,
    required this.status,
    required this.message,
    required this.bus,
    required this.driver,
    required this.date,
  });
}

class _FeedbackCard extends StatelessWidget {
  final _FeedbackItem item;

  const _FeedbackCard({required this.item});

  Color _priorityBg() {
    if (item.priority == 'High') return const Color(0xFFFEE2E2);
    return const Color(0xFFEAF1FF);
  }

  Color _priorityText() {
    if (item.priority == 'High') return const Color(0xFFDC2626);
    return const Color(0xFF2563EB);
  }

  Color _statusText() {
    if (item.status == 'Resolved') return const Color(0xFF1F9D55);
    return const Color(0xFFF59E0B);
  }

  IconData _statusIcon() {
    if (item.status == 'Resolved') return Icons.check_circle_outline;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 5),
            color: Color(0x0F000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Priority + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _priorityBg(),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  item.priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _priorityText(),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(_statusIcon(), size: 16, color: _statusText()),
                  const SizedBox(width: 6),
                  Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _statusText(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            item.message,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ Bus / Driver / Date table-ish
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Bus',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  'Driver',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  'Date',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.bus,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.driver,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
