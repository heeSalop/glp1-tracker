import 'package:flutter/material.dart';

/// Zones available for injection site rotation
const List<String> kInjectionSites = [
  'Left Abdomen',
  'Right Abdomen',
  'Left Upper Arm',
  'Right Upper Arm',
  'Left Thigh',
  'Right Thigh',
  'Left Buttock',
  'Right Buttock',
];

/// Returns a color based on how recently a site was used
Color siteColor(DateTime? lastUsed) {
  if (lastUsed == null) return const Color(0xFF2ECC71); // never used = green
  final days = DateTime.now().difference(lastUsed).inDays;
  if (days < 7) return const Color(0xFFE74C3C);   // < 1 week = red
  if (days < 14) return const Color(0xFFE67E22);  // 1-2 weeks = orange
  if (days < 28) return const Color(0xFFF1C40F);  // 2-4 weeks = yellow
  return const Color(0xFF2ECC71);                  // > 4 weeks = green
}

class BodyMapWidget extends StatefulWidget {
  final Map<String, DateTime?> siteLastUsed;
  final String? selectedSite;
  final ValueChanged<String> onSiteTapped;

  const BodyMapWidget({
    super.key,
    required this.siteLastUsed,
    required this.onSiteTapped,
    this.selectedSite,
  });

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFF2ECC71), 'Safe'),
              const SizedBox(width: 12),
              _legend(const Color(0xFFF1C40F), '2-4 wks'),
              const SizedBox(width: 12),
              _legend(const Color(0xFFE67E22), '1-2 wks'),
              const SizedBox(width: 12),
              _legend(const Color(0xFFE74C3C), '< 1 wk'),
            ],
          ),
        ),

        // Body diagram with tappable zones
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  // Body outline
                  CustomPaint(
                    size: Size(w, h),
                    painter: _BodyOutlinePainter(),
                  ),
                  // Tappable zones overlaid as positioned buttons
                  ..._buildZones(w, h),
                ],
              );
            },
          ),
        ),

        // Site grid list
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kInjectionSites.map((site) {
              final color = siteColor(widget.siteLastUsed[site]);
              final isSelected = widget.selectedSite == site;
              return GestureDetector(
                onTap: () => widget.onSiteTapped(site),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.35)
                        : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.4),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(site, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildZones(double w, double h) {
    // Zones defined as fractions of body area (centered layout)
    // Body is centered horizontally in a ~60% width column
    final bw = w * 0.55; // body width
    final bx = (w - bw) / 2; // body left edge
    final torsoTop = h * 0.22;
    final torsoH = h * 0.28;
    final legTop = torsoTop + torsoH;

    final zoneData = <Map<String, dynamic>>[
      // Abdomen zones (center torso)
      {
        'site': 'Right Abdomen', // mirrored (body's right = viewer's left)
        'rect': Rect.fromLTWH(bx, torsoTop + torsoH * 0.15, bw * 0.44, torsoH * 0.55),
      },
      {
        'site': 'Left Abdomen',
        'rect': Rect.fromLTWH(bx + bw * 0.56, torsoTop + torsoH * 0.15, bw * 0.44, torsoH * 0.55),
      },
      // Upper arm zones
      {
        'site': 'Right Upper Arm',
        'rect': Rect.fromLTWH(bx - bw * 0.22, torsoTop, bw * 0.18, torsoH * 0.5),
      },
      {
        'site': 'Left Upper Arm',
        'rect': Rect.fromLTWH(bx + bw * 1.04, torsoTop, bw * 0.18, torsoH * 0.5),
      },
      // Buttock zones
      {
        'site': 'Right Buttock',
        'rect': Rect.fromLTWH(bx, torsoTop + torsoH * 0.6, bw * 0.44, torsoH * 0.4),
      },
      {
        'site': 'Left Buttock',
        'rect': Rect.fromLTWH(bx + bw * 0.56, torsoTop + torsoH * 0.6, bw * 0.44, torsoH * 0.4),
      },
      // Thigh zones
      {
        'site': 'Right Thigh',
        'rect': Rect.fromLTWH(bx + bw * 0.05, legTop, bw * 0.38, h * 0.2),
      },
      {
        'site': 'Left Thigh',
        'rect': Rect.fromLTWH(bx + bw * 0.57, legTop, bw * 0.38, h * 0.2),
      },
    ];

    return zoneData.map((z) {
      final site = z['site'] as String;
      final rect = z['rect'] as Rect;
      final color = siteColor(widget.siteLastUsed[site]);
      final isSelected = widget.selectedSite == site;

      return Positioned(
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: GestureDetector(
          onTap: () => widget.onSiteTapped(site),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.55)
                  : color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.6),
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

class _BodyOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A4A)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF4A4A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;
    final bw = w * 0.55;
    final bx = (w - bw) / 2;

    // Head
    final headR = bw * 0.18;
    final headCenter = Offset(w / 2, h * 0.1);
    canvas.drawCircle(headCenter, headR, paint);
    canvas.drawCircle(headCenter, headR, strokePaint);

    // Neck
    final neckPath = Path()
      ..addRect(Rect.fromLTWH(
          w / 2 - bw * 0.07, h * 0.18, bw * 0.14, h * 0.04));
    canvas.drawPath(neckPath, paint);
    canvas.drawPath(neckPath, strokePaint);

    // Torso (tapered)
    final torsoTop = h * 0.22;
    final torsoH = h * 0.28;
    final torsoPath = Path()
      ..moveTo(bx + bw * 0.05, torsoTop)
      ..lineTo(bx + bw * 0.95, torsoTop)
      ..lineTo(bx + bw * 0.85, torsoTop + torsoH)
      ..lineTo(bx + bw * 0.15, torsoTop + torsoH)
      ..close();
    canvas.drawPath(torsoPath, paint);
    canvas.drawPath(torsoPath, strokePaint);

    // Left arm (screen left = body right)
    final laPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx - bw * 0.23, torsoTop, bw * 0.19, torsoH * 0.75),
          const Radius.circular(8)));
    canvas.drawPath(laPath, paint);
    canvas.drawPath(laPath, strokePaint);

    // Right arm (screen right = body left)
    final raPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx + bw * 1.04, torsoTop, bw * 0.19, torsoH * 0.75),
          const Radius.circular(8)));
    canvas.drawPath(raPath, paint);
    canvas.drawPath(raPath, strokePaint);

    // Left leg (screen left)
    final legTop = torsoTop + torsoH;
    final leftLegPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx + bw * 0.06, legTop - 2, bw * 0.38, h * 0.32),
          const Radius.circular(8)));
    canvas.drawPath(leftLegPath, paint);
    canvas.drawPath(leftLegPath, strokePaint);

    // Right leg (screen right)
    final rightLegPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx + bw * 0.56, legTop - 2, bw * 0.38, h * 0.32),
          const Radius.circular(8)));
    canvas.drawPath(rightLegPath, paint);
    canvas.drawPath(rightLegPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
