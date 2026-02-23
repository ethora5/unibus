import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

// هذي شاشة الطالب الرئيسية
// فيها خريطة + رسالة إذا ما فيه باص شغال + كارد معلومات تحت
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // هذا موقع يونيتن الافتراضي عشان الخريطة تفتح عليه
  static final LatLng unitenCenter = LatLng(2.9766, 101.7331);

  // هذا متغير عشان إذا اليوزر ضغط X على رسالة "مافي باص"
  // نخلي الرسالة تختفي وما ترجع إلا إذا رجع فتح الصفحة من جديد
  bool _bannerDismissed = false;

  // هذا ستريم من فايرستور: يجيب لنا أول جلسة فيها status = active
  // إذا ما فيه ولا جلسة active، يرجع لنا ليست فاضية
  Stream<QuerySnapshot<Map<String, dynamic>>> _activeSessionStream() {
    return FirebaseFirestore.instance
        .collection('drivingSessions')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // هنا نستخدم StreamBuilder عشان نسمع للتغييرات بالفايرستور لايف
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _activeSessionStream(),
      builder: (context, snapshot) {
        // إذا صار خطأ بالقراءة من فايرستور نعرض الخطأ على الشاشة
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Live Bus Tracking'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Text(
                'في مشكلة بالاتصال: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // هذا يعني الداتا للحين قاعده تتحمل من فايرستور
        final bool loading =
            snapshot.connectionState == ConnectionState.waiting;

        // هنا نحدد هل فيه جلسة active ولا لا
        // لازم snapshot.hasData أول، وبعدها نشوف docs فاضية ولا لا
        final bool hasActiveSession =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        // إذا فيه session فعّال نحفظ الداتا هنا
        Map<String, dynamic>? sessionData;
        if (hasActiveSession) {
          sessionData = snapshot.data!.docs.first.data();
        }

        // نجهز موقع الباص إذا كان موجود بالفايرستور (lastLocation)
        LatLng? busPosition;
        if (sessionData != null) {
          // lastLocation لازم يكون GeoPoint داخل فايرستور
          final GeoPoint? gp = sessionData['lastLocation'] as GeoPoint?;
          if (gp != null) {
            busPosition = LatLng(gp.latitude, gp.longitude);
          }
        }

        // هذي القيم الافتراضية اللي تطلع إذا ما فيه باص شغال
        // يعني الكارد تحت يطلع بس بياناته تكون __
        String busName = '__';
        String routeName = '__';
        String currentStop = '__';
        String nextStop = '__';
        String etaText = '__';
        String distanceText = '__';

        // إذا فيه sessionData (يعني فيه باص شغال) نعبي القيم من الداتابيس
        if (sessionData != null) {
          final String? bn = sessionData['busName'] as String?;
          final String? rn = sessionData['routeName'] as String?;
          final String? cs = sessionData['currentStopName'] as String?;
          final String? ns = sessionData['nextStopName'] as String?;

          // نتأكد إن النص مو فاضي قبل نحطه
          if (bn != null && bn.trim().isNotEmpty) busName = bn.trim();
          if (rn != null && rn.trim().isNotEmpty) routeName = rn.trim();
          if (cs != null && cs.trim().isNotEmpty) currentStop = cs.trim();
          if (ns != null && ns.trim().isNotEmpty) nextStop = ns.trim();

          // etaMinutes ممكن يكون int أو num
          final dynamic etaRaw = sessionData['etaMinutes'];
          if (etaRaw is int) {
            etaText = '$etaRaw mins';
          } else if (etaRaw is num) {
            etaText = '${etaRaw.toInt()} mins';
          }

          // distanceKm لازم يكون رقم
          final dynamic distRaw = sessionData['distanceKm'];
          if (distRaw is num) {
            distanceText = '${distRaw.toStringAsFixed(1)} km';
          }
        }

        // واجهة الشاشة
        return Scaffold(
          appBar: AppBar(
            title: const Text('Live Bus Tracking'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              // الخريطة تاخذ كل الشاشة
              Positioned.fill(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: unitenCenter,
                    initialZoom: 16,
                  ),
                  children: [
                    // هذا مصدر الخريطة من OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.unibus',
                    ),

                    // هذا يحط ماركر للباص بس إذا فيه باص شغال وعندنا موقع
                    MarkerLayer(
                      markers: [
                        if (hasActiveSession && busPosition != null)
                          Marker(
                            point: busPosition,
                            width: 46,
                            height: 46,
                            child: const Icon(
                              Icons.location_on,
                              size: 46,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // إذا الداتابيس للحين تتحمل نطلع رسالة صغيرة فوق
              if (loading)
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Text(
                      'Loading database...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              // إذا ما فيه باص شغال، نطلع رسالة "No active buses right now"
              // وتظل لين اليوزر يضغط X
              if (!hasActiveSession && !_bannerDismissed && !loading)
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: _NoBusBanner(
                    onClose: () {
                      setState(() {
                        _bannerDismissed = true;
                      });
                    },
                  ),
                ),

              // هذا الكارد تحت يطلع دايم حتى لو ما فيه باص
              // إذا ما فيه باص بيكون كله __
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: _BottomInfoCard(
                    busName: busName,
                    routeName: routeName,
                    currentLocation: currentStop,
                    nextStop: nextStop,
                    etaText: etaText,
                    distanceText: distanceText,
                    // هذي الأزرار لازم تكون شغالة دايم حسب طلبك
                    onNotificationsTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.studentNotifications,
                      );
                    },
                    onFeedbackTap: () {
                      Navigator.pushNamed(context, AppRoutes.studentFeedback);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// هذا بانر فوق يقول ما فيه باصات شغالة
class _NoBusBanner extends StatelessWidget {
  final VoidCallback onClose;

  const _NoBusBanner({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'No active buses right now',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 18, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// هذا الكارد الأبيض تحت اللي فيه معلومات الباص + أزرار
class _BottomInfoCard extends StatelessWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onFeedbackTap;

  final String busName;
  final String routeName;
  final String currentLocation;
  final String nextStop;
  final String etaText;
  final String distanceText;

  const _BottomInfoCard({
    required this.onNotificationsTap,
    required this.onFeedbackTap,
    required this.busName,
    required this.routeName,
    required this.currentLocation,
    required this.nextStop,
    required this.etaText,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // نخليه ياخذ عرض الشاشة كله بدون مسافات
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            spreadRadius: 0,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        // نخلي الكارد ياخذ قد اللي يحتاجه بس
        mainAxisSize: MainAxisSize.min,
        children: [
          // هذا الجزء العلوي فيه اسم الباص والروت
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.navigation_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      busName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Route: $routeName',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // هذا الجزء فيه Current Location و Next Stop
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LabelValue(
                    label: 'Current Location',
                    value: currentLocation,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabelValue(label: 'Next Stop', value: nextStop),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // هذا الجزء فيه ETA والمسافة
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'ETA to Next\nStop',
                  value: etaText,
                  isGreen: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  title: 'Distance',
                  value: distanceText,
                  isGreen: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // هذا صف الأزرار، ولازم يكون شغال دايم حسب طلبك
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNotificationsTap,
                  icon: const Icon(Icons.notifications_none, size: 18),
                  label: const Text('Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFeedbackTap,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Feedback'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

// هذا ويدجت صغير يعرض عنوان وقيمته تحت بعض
class _LabelValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
}

// هذا كارد صغير للـ ETA والمسافة
class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isGreen;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.isGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGreen ? const Color(0xFFEAF7EE) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
