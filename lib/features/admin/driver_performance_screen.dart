import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';

class DriverPerformanceScreen extends StatefulWidget {
  const DriverPerformanceScreen({super.key});

  @override
  State<DriverPerformanceScreen> createState() =>
      _DriverPerformanceScreenState();
}

class _DriverPerformanceScreenState extends State<DriverPerformanceScreen> {
  bool filtersExpanded = false;
  DateTime? selectedDate;
  String? selectedDriverName;
  String? selectedBusId;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatFilterDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '--';
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '--';
    final d = ts.toDate();
    return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  String _formatDateTime(Timestamp? ts) {
    if (ts == null) return '--';
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}";
  }

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours h $minutes min $seconds sec';
    }
    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds sec';
  }

  int _safeTimestampValue(Timestamp? ts) {
    if (ts == null) return 0;
    return ts.millisecondsSinceEpoch;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();

      final String driverName = (data['driverName'] ?? '').toString().trim();
      final String busId = (data['busId'] ?? '').toString().trim();

      final Timestamp? startTime = data['startTime'] as Timestamp?;
      final DateTime? startDate = startTime?.toDate();

      final bool matchesDriver =
          selectedDriverName == null ||
          selectedDriverName!.trim().isEmpty ||
          driverName == selectedDriverName!.trim();

      final bool matchesBus =
          selectedBusId == null ||
          selectedBusId!.trim().isEmpty ||
          busId == selectedBusId!.trim();

      final bool matchesDate =
          selectedDate == null ||
          (startDate != null && _isSameDay(startDate, selectedDate!));

      return matchesDriver && matchesBus && matchesDate;
    }).toList();
  }

  List<String> _extractDriverNames(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Set<String> values = {};

    for (final doc in docs) {
      final data = doc.data();
      final String value = (data['driverName'] ?? '').toString().trim();
      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    final List<String> result = values.toList()..sort();
    return result;
  }

  List<String> _extractBusIds(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Set<String> values = {};

    for (final doc in docs) {
      final data = doc.data();
      final String value = (data['busId'] ?? '').toString().trim();
      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    final List<String> result = values.toList()..sort();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Performance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('driving_sessions')
              .where('status', isEqualTo: 'completed')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to load driver trips\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final driverNames = _extractDriverNames(docs);
            final busIds = _extractBusIds(docs);

            final filteredDocs = _applyFilters(docs);

            filteredDocs.sort((a, b) {
              final aData = a.data();
              final bData = b.data();

              final Timestamp? aStart = aData['startTime'] as Timestamp?;
              final Timestamp? bStart = bData['startTime'] as Timestamp?;

              return _safeTimestampValue(
                bStart,
              ).compareTo(_safeTimestampValue(aStart));
            });

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      filtersExpanded = !filtersExpanded;
                    });
                  },
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
                          filtersExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),

                if (filtersExpanded) ...[
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        _formatFilterDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDriverName,
                        hint: const Text(
                          'Select Driver',
                          style: TextStyle(fontSize: 12),
                        ),
                        isExpanded: true,
                        items: driverNames
                            .map(
                              (driver) => DropdownMenuItem<String>(
                                value: driver,
                                child: Text(driver),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDriverName = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBusId,
                        hint: const Text(
                          'Select Bus',
                          style: TextStyle(fontSize: 12),
                        ),
                        isExpanded: true,
                        items: busIds
                            .map(
                              (bus) => DropdownMenuItem<String>(
                                value: bus,
                                child: Text(bus),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBusId = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          selectedDate = null;
                          selectedDriverName = null;
                          selectedBusId = null;
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                if (filteredDocs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Center(
                      child: Text(
                        'No trips found',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredDocs.map((doc) {
                    final data = doc.data();

                    final String driverName = (data['driverName'] ?? '--')
                        .toString();
                    final String busId = (data['busId'] ?? '--').toString();
                    final String routeName = (data['routeName'] ?? '--')
                        .toString();

                    final Timestamp? startTime =
                        data['startTime'] as Timestamp?;
                    final Timestamp? endTime = data['endTime'] as Timestamp?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: ListTile(
                        title: Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          'Date: ${_formatDate(startTime)}\nBus: $busId   |   Route: $routeName\nStart: ${_formatTime(startTime)}   End: ${_formatTime(endTime)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripDetailsScreen(tripId: doc.id),
                            ),
                          );
                        },
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TripDetailsScreen extends StatelessWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    String formatDateTime(Timestamp? ts) {
      if (ts == null) return '--';
      final d = ts.toDate();
      return "${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}";
    }

    String formatDuration(int totalSeconds) {
      final int hours = totalSeconds ~/ 3600;
      final int minutes = (totalSeconds % 3600) ~/ 60;
      final int seconds = totalSeconds % 60;

      if (hours > 0) {
        return '$hours h $minutes min $seconds sec';
      }
      if (minutes > 0) {
        return '$minutes min $seconds sec';
      }
      return '$seconds sec';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('driving_sessions')
              .doc(tripId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to load trip details\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data?.data();

            if (data == null) {
              return const Center(child: Text('Trip not found'));
            }

            final String driverName = (data['driverName'] ?? '--').toString();
            final String busId = (data['busId'] ?? '--').toString();
            final String busDocId = (data['busDocId'] ?? '--').toString();
            final String routeName = (data['routeName'] ?? '--').toString();
            final String status = (data['status'] ?? '--').toString();

            final Timestamp? createdAt = data['createdAt'] as Timestamp?;
            final Timestamp? startTime = data['startTime'] as Timestamp?;
            final Timestamp? endTime = data['endTime'] as Timestamp?;
            final Timestamp? updatedAt = data['updatedAt'] as Timestamp?;

            final int durationSeconds = (data['durationSeconds'] ?? 0) as int;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trip Summary',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Driver', value: driverName),
                      _DetailRow(label: 'Bus', value: busId),
                      _DetailRow(label: 'Bus Doc ID', value: busDocId),
                      _DetailRow(label: 'Route', value: routeName),
                      _DetailRow(label: 'Status', value: status),
                      _DetailRow(
                        label: 'Created At',
                        value: formatDateTime(createdAt),
                      ),
                      _DetailRow(
                        label: 'Start Time',
                        value: formatDateTime(startTime),
                      ),
                      _DetailRow(
                        label: 'End Time',
                        value: formatDateTime(endTime),
                      ),
                      _DetailRow(
                        label: 'Updated At',
                        value: formatDateTime(updatedAt),
                      ),
                      _DetailRow(
                        label: 'Duration',
                        value: formatDuration(durationSeconds),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
