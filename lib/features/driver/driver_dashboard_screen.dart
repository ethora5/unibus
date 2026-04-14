import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';
import 'driver_schedule_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final TextEditingController nameController = TextEditingController();

  String? selectedBus;
  String? selectedBusDocId;

  static const String routeName = 'UNITEN Internal Shuttle Bus';

  bool isLoadingDriver = true;
  String? driverError;

  @override
  void initState() {
    super.initState();
    _loadCurrentDriverData();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (_) => false,
      );
    }
  }

  Future<void> _loadCurrentDriverData() async {
    setState(() {
      isLoadingDriver = true;
      driverError = null;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || currentUser.email == null) {
        throw Exception('No logged-in driver found.');
      }

      final String email = currentUser.email!.trim();

      final QuerySnapshot<Map<String, dynamic>> driverQuery =
          await FirebaseFirestore.instance
              .collection('drivers')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (driverQuery.docs.isEmpty) {
        throw Exception('Driver data not found in database.');
      }

      final Map<String, dynamic> driverData = driverQuery.docs.first.data();

      final String driverName =
          (driverData['name'] as String?)?.trim().isNotEmpty == true
          ? (driverData['name'] as String).trim()
          : 'Driver';

      nameController.text = driverName;
    } catch (e) {
      driverError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingDriver = false;
        });
      }
    }
  }

  bool get canStart =>
      nameController.text.trim().isNotEmpty &&
      selectedBus != null &&
      selectedBusDocId != null;

  void _openScheduleImage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DriverScheduleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          children: [
            const SizedBox(height: 8),

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

            Center(
              child: Text(
                'Welcome ${nameController.text}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),

            const Center(
              child: Text(
                'Select your bus to start tracking',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Driver Name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            if (isLoadingDriver)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading driver data...',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (driverError != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD6D6)),
                ),
                child: Text(
                  driverError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              TextField(
                controller: nameController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Driver name',
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
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

            const Text(
              'Route',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alt_route,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      routeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openScheduleImage,
                    child: const Text('View Schedule'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Select Bus',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('buses')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD6D6)),
                    ),
                    child: const Text(
                      'Failed to load buses.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Text(
                      'No buses found.',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;

                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data();
                  final status =
                      (data['status'] as String?)?.trim().toLowerCase() ?? '';
                  return status == 'available' || status == 'in_use';
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Text(
                      'No available or in-use buses found.',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }

                final buses = filteredDocs.map((doc) {
                  final data = doc.data();

                  return _BusItem(
                    docId: doc.id,
                    id: (data['name'] as String?)?.trim().isNotEmpty == true
                        ? (data['name'] as String).trim()
                        : doc.id,
                    status:
                        (data['status'] as String?)?.trim().toLowerCase() ??
                        'available',
                  );
                }).toList();

                return Column(
                  children: buses.map((b) {
                    final bool isSelected = selectedBusDocId == b.docId;
                    final bool isAvailable = b.status == 'available';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BusTile(
                        bus: b,
                        selected: isSelected,
                        onTap: isAvailable
                            ? () {
                                setState(() {
                                  selectedBus = b.id;
                                  selectedBusDocId = b.docId;
                                });
                              }
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: canStart
                    ? () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.driverTrackingActive,
                          arguments: {
                            'driverName': nameController.text.trim(),
                            'busId': selectedBus,
                            'busDocId': selectedBusDocId,
                            'routeName': routeName,
                          },
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
  final String docId;
  final String id;
  final String status;

  const _BusItem({required this.docId, required this.id, required this.status});
}

class _BusTile extends StatelessWidget {
  final _BusItem bus;
  final bool selected;
  final VoidCallback? onTap;

  const _BusTile({
    required this.bus,
    required this.selected,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF1F9D55);
      case 'in_use':
        return const Color(0xFF6B7280);
      default:
        return Colors.black54;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'in_use':
        return 'In Use';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _statusColor(bus.status);
    final String statusLabel = _statusLabel(bus.status);
    final bool isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: isDisabled ? 0.85 : 1,
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
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
