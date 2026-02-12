import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final TextEditingController nameController = TextEditingController();

  String? selectedBus;
  String? selectedRoute;

  final List<_BusItem> buses = const [
    _BusItem(id: 'Bus A', status: 'Available'),
    _BusItem(id: 'Bus B', status: 'Available'),
    _BusItem(id: 'Bus C', status: 'In Use'),
    _BusItem(id: 'Bus D', status: 'Available'),
    _BusItem(id: 'Bus E', status: 'Maintenance'),
  ];

  final List<String> routes = const [
    'Main Campus Loop',
    'Hostel Loop',
    'Admin Block Route',
  ];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  bool get canStart =>
      nameController.text.trim().isNotEmpty &&
      selectedBus != null &&
      selectedRoute != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
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
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          children: [
            const SizedBox(height: 8),

            // ✅ أيقونة و welcome مثل الصورة
            Center(
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.navigation_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Welcome, Driver',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Select your bus and route to start\ntracking',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 18),

            // ✅ Driver Name
            const Text(
              'Driver Name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter driver name',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Select Bus
            const Text(
              'Select Bus',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            ...buses.map((b) {
              final bool isSelected = selectedBus == b.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BusTile(
                  bus: b,
                  selected: isSelected,
                  onTap: () => setState(() => selectedBus = b.id),
                ),
              );
            }),

            const SizedBox(height: 8),

            // ✅ Select Route dropdown
            const Text(
              'Select Route',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedRoute,
                  hint: const Text('Select Route...'),
                  isExpanded: true,
                  items: routes
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRoute = v),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ✅ Start Tracking button (رمادي لو ناقص شي)
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: canStart
                    ? () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.driverTrackingActive,
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Tracking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE3E7EF),
                  disabledForegroundColor: Colors.black38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusItem {
  final String id;
  final String status;

  const _BusItem({required this.id, required this.status});
}

class _BusTile extends StatelessWidget {
  final _BusItem bus;
  final bool selected;
  final VoidCallback onTap;

  const _BusTile({
    required this.bus,
    required this.selected,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Available':
        return const Color(0xFF1F9D55);
      case 'In Use':
        return const Color(0xFF6B7280);
      case 'Maintenance':
        return const Color(0xFFF59E0B);
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _statusColor(bus.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.cardBorder,
            width: selected ? 1.4 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 5),
              color: Color(0x0F000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.primaryBlue : Colors.black26,
              size: 18,
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.directions_bus,
              color: AppTheme.primaryBlue,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bus.id,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              bus.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
