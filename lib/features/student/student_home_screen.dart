import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

// هذه شاشة الطالب الرئيسية
// تحتوي على:
// 1) خريطة تعرض موقع الحافلة إن وجدت
// 2) رسالة أعلى الشاشة إذا لا توجد حافلات نشطة
// 3) بطاقة معلومات أسفل الشاشة فيها تفاصيل الرحلة وأزرار التنقل
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // هذا الموقع الافتراضي لفتح الخريطة على مركز الجامعة
  static final LatLng unitenCenter = LatLng(2.9766, 101.7331);

  // هذا المتغير يمنع تكرار رسالة "لا توجد حافلات" بعد إغلاقها
  // يعني إذا المستخدم ضغط إغلاق، تختفي الرسالة ولا ترجع إلا إذا خرج ورجع للصفحة
  bool _bannerDismissed = false;

  // هذا بث مباشر من قاعدة البيانات
  // يجلب أول جلسة قيادتها حالتها نشطة
  // إذا لا توجد جلسة نشطة، يرجع قائمة فارغة
  Stream<QuerySnapshot<Map<String, dynamic>>> _activeSessionStream() {
    return FirebaseFirestore.instance
        .collection('drivingSessions')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم عنصر يبني الواجهة بناءً على التغييرات القادمة من قاعدة البيانات مباشرة
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _activeSessionStream(),
      builder: (context, snapshot) {
        // إذا حصل خطأ أثناء القراءة من قاعدة البيانات نعرض رسالة للمستخدم
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

        // هذا يعني أن البيانات ما زالت قيد التحميل
        final bool loading =
            snapshot.connectionState == ConnectionState.waiting;

        // نحدد هل توجد جلسة نشطة أم لا
        // لازم نتأكد أولًا أن البيانات موجودة ثم نتأكد أن القائمة ليست فارغة
        final bool hasActiveSession =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        // إذا توجد جلسة نشطة نخزن بياناتها هنا
        Map<String, dynamic>? sessionData;
        if (hasActiveSession) {
          sessionData = snapshot.data!.docs.first.data();
        }

        // نحاول استخراج آخر موقع مسجل للحافلة من بيانات الجلسة
        // يجب أن يكون مخزن في قاعدة البيانات كنقطة جغرافية
        LatLng? busPosition;
        if (sessionData != null) {
          final GeoPoint? gp = sessionData['lastLocation'] as GeoPoint?;
          if (gp != null) {
            busPosition = LatLng(gp.latitude, gp.longitude);
          }
        }

        // قيم افتراضية تظهر في بطاقة المعلومات إذا لا توجد حافلة نشطة
        // الهدف: البطاقة تبقى ظاهرة دائمًا لكن البيانات تكون فارغة
        String busName = '__';
        String routeName = '__';
        String currentStop = '__';
        String nextStop = '__';
        String etaText = '__';
        String distanceText = '__';

        // إذا توجد بيانات جلسة، نستخرج المعلومات منها لعرضها في البطاقة
        if (sessionData != null) {
          final String? bn = sessionData['busName'] as String?;
          final String? rn = sessionData['routeName'] as String?;
          final String? cs = sessionData['currentStopName'] as String?;
          final String? ns = sessionData['nextStopName'] as String?;

          // نتأكد من أن النص ليس فارغًا قبل الاعتماد عليه
          if (bn != null && bn.trim().isNotEmpty) busName = bn.trim();
          if (rn != null && rn.trim().isNotEmpty) routeName = rn.trim();
          if (cs != null && cs.trim().isNotEmpty) currentStop = cs.trim();
          if (ns != null && ns.trim().isNotEmpty) nextStop = ns.trim();

          // زمن الوصول المتوقع قد يكون رقم صحيح أو رقم عشري
          // نحوله لصيغة مناسبة للعرض
          final dynamic etaRaw = sessionData['etaMinutes'];
          if (etaRaw is int) {
            etaText = '$etaRaw mins';
          } else if (etaRaw is num) {
            etaText = '${etaRaw.toInt()} mins';
          }

          // المسافة يجب أن تكون رقم
          // نعرضها برقم عشري واحد
          final dynamic distRaw = sessionData['distanceKm'];
          if (distRaw is num) {
            distanceText = '${distRaw.toStringAsFixed(1)} km';
          }
        }

        // واجهة الصفحة الرئيسية للطالب
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
              // الخريطة تأخذ الشاشة كلها بالخلفية
              Positioned.fill(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: unitenCenter,
                    initialZoom: 16,
                  ),
                  children: [
                    // طبقة الخريطة الأساسية من مزود خرائط مفتوح
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.unibus',
                    ),

                    // طبقة العلامات: نضيف علامة للحافلة فقط إذا كانت نشطة ولدينا موقع
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

              // إذا كانت البيانات قيد التحميل نظهر شريط بسيط أعلى الشاشة
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

              // إذا لا توجد حافلة نشطة ولم يغلق المستخدم الرسالة ولم نكن في التحميل
              // نظهر رسالة "لا توجد حافلات نشطة"
              if (!hasActiveSession && !_bannerDismissed && !loading)
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: _NoBusBanner(
                    onClose: () {
                      // عند الإغلاق نخزن أن المستخدم أغلق الرسالة
                      setState(() {
                        _bannerDismissed = true;
                      });
                    },
                  ),
                ),

              // بطاقة المعلومات السفلية تظهر دائمًا
              // إذا لا توجد حافلة ستظهر القيم الافتراضية
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

                    // زر الإشعارات يعمل دائمًا وينقل لصفحة إعدادات الإشعارات
                    onNotificationsTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.studentNotifications,
                      );
                    },

                    // زر الملاحظات يعمل دائمًا وينقل لصفحة الملاحظات
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

// هذا شريط تنبيه أعلى الشاشة يوضح أنه لا توجد حافلات نشطة
// يحتوي على زر إغلاق حتى يتمكن المستخدم من إخفائه
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

// هذه بطاقة المعلومات السفلية
// تعرض تفاصيل الرحلة الحالية مثل اسم الحافلة والمسار والمحطة الحالية والقادمة
// وتحتوي على أزرار للانتقال لصفحات أخرى
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
      // تأخذ عرض الشاشة بالكامل
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
        // يجعل البطاقة تأخذ حجم المحتوى فقط وليس كامل الشاشة
        mainAxisSize: MainAxisSize.min,
        children: [
          // الجزء العلوي: أيقونة + اسم الحافلة + اسم المسار
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

          // بطاقة صغيرة تعرض الموقع الحالي والمحطة القادمة
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

          // بطاقة زمن الوصول والمسافة
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

          // أزرار التنقل
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

// عنصر صغير يعرض عنوان وقيمته تحته
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

// بطاقة صغيرة لعرض قيمة مختصرة مثل زمن الوصول أو المسافة
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
