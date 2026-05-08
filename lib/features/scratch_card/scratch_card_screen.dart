import 'dart:math';
import 'package:flutter/material.dart';
import 'package:alkirtas/utils/constants/colors.dart';

// ─── Reward model ────────────────────────────────────────────────────────────

class _Reward {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _Reward({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

const _rewards = [
  _Reward(
    label: '20 Points',
    sublabel: 'Fidélité ajoutés à votre compte',
    icon: Icons.stars_rounded,
    color: Color(0xFFE65100),
    bgColor: Color(0xFFFFF3E0),
  ),
  _Reward(
    label: '50 Points',
    sublabel: 'Fidélité ajoutés à votre compte',
    icon: Icons.stars_rounded,
    color: Color(0xFF6A1B9A),
    bgColor: Color(0xFFF3E5F5),
  ),
  _Reward(
    label: 'Points x2',
    sublabel: 'Sur votre prochaine commande',
    icon: Icons.star_rate_rounded,
    color: Color(0xFF0277BD),
    bgColor: Color(0xFFE1F5FE),
  ),
  _Reward(
    label: 'Livraison offerte',
    sublabel: 'Sur votre prochaine commande',
    icon: Icons.local_shipping_rounded,
    color: Color(0xFF1565C0),
    bgColor: Color(0xFFE3F2FD),
  ),
  _Reward(
    label: '-5%',
    sublabel: 'Sur votre prochaine commande',
    icon: Icons.discount_rounded,
    color: Color(0xFF2E7D32),
    bgColor: Color(0xFFE8F5E9),
  ),
  _Reward(
    label: '-10%',
    sublabel: 'Sur votre prochaine commande',
    icon: Icons.discount_rounded,
    color: Color(0xFFC62828),
    bgColor: Color(0xFFFFEBEE),
  ),
];

_Reward _pickReward() {
  final r = Random().nextDouble();
  if (r < 0.35) return _rewards[0]; // 35%
  if (r < 0.60) return _rewards[1]; // 25%
  if (r < 0.75) return _rewards[2]; // 15%
  if (r < 0.88) return _rewards[3]; // 13%
  if (r < 0.95) return _rewards[4]; //  7%
  return _rewards[5]; //  5%
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  late final _Reward _reward = _pickReward();
  final List<Offset?> _points = [];
  bool _isRevealed = false;

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isRevealed) return;
    setState(() => _points.add(d.localPosition));
    if (_points.whereType<Offset>().length > 130) _revealAll();
  }

  void _onPanEnd(DragEndDetails _) {
    if (!_isRevealed) _points.add(null);
  }

  void _revealAll() {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final appColor = AlkColors.AppFirstColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: appColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Grattez & Gagnez',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColor, appColor.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 52, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    'Votre récompense du jour',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Grattez la carte avec votre doigt pour révéler votre cadeau',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 44),

            // ── Scratch card ─────────────────────────────────────────────────
            Center(
              child: Container(
                width: 300,
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: _isRevealed ? null : _onPanUpdate,
                    onPanEnd: _isRevealed ? null : _onPanEnd,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(300, 210),
                        painter: _RewardPainter(reward: _reward),
                        foregroundPainter: _isRevealed
                            ? null
                            : _ScratchOverlayPainter(points: _points),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ── Below card ───────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _isRevealed
                  ? _ClaimSection(reward: _reward)
                  : const _HintText(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Reward painter (draws reward content on canvas) ─────────────────────────

class _RewardPainter extends CustomPainter {
  final _Reward reward;

  const _RewardPainter({required this.reward});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = reward.bgColor,
    );

    final cx = size.width / 2;

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(reward.icon.codePoint),
        style: TextStyle(
          fontSize: 56,
          fontFamily: reward.icon.fontFamily,
          package: reward.icon.fontPackage,
          color: reward.color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final iconTop = size.height / 2 - iconPainter.height / 2 - 28;
    iconPainter.paint(canvas, Offset(cx - iconPainter.width / 2, iconTop));

    final labelPainter = TextPainter(
      text: TextSpan(
        text: reward.label,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: reward.color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);
    final labelTop = iconTop + iconPainter.height + 8;
    labelPainter.paint(canvas, Offset(cx - labelPainter.width / 2, labelTop));

    final subPainter = TextPainter(
      text: TextSpan(
        text: reward.sublabel,
        style: TextStyle(
          fontSize: 12,
          color: reward.color.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width - 32);
    subPainter.paint(
      canvas,
      Offset(cx - subPainter.width / 2, labelTop + labelPainter.height + 4),
    );
  }

  @override
  bool shouldRepaint(_RewardPainter old) => old.reward != reward;
}

// ─── Scratch overlay painter (silver cover with clear holes) ─────────────────

class _ScratchOverlayPainter extends CustomPainter {
  final List<Offset?> points;

  const _ScratchOverlayPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFCFCFCF),
            Color(0xFF9E9E9E),
            Color(0xFFBDBDBD),
            Color(0xFF757575),
            Color(0xFFBDBDBD),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final dotPaint = Paint()..color = Colors.white.withOpacity(0.08);
    for (double x = 12; x < size.width; x += 18) {
      for (double y = 12; y < size.height; y += 18) {
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }

    final tp = TextPainter(
      text: const TextSpan(
        text: 'GRATTEZ ICI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2 - 14),
    );

    final hint = TextPainter(
      text: TextSpan(
        text: '~ avec votre doigt ~',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hint.paint(
      canvas,
      Offset((size.width - hint.width) / 2, size.height / 2 + 6),
    );

    if (points.isNotEmpty) {
      final scratchPaint = Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = 42
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < points.length; i++) {
        if (points[i] == null) continue;
        if (i == 0 || points[i - 1] == null) {
          path.moveTo(points[i]!.dx, points[i]!.dy);
        } else {
          path.lineTo(points[i]!.dx, points[i]!.dy);
        }
      }
      canvas.drawPath(path, scratchPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchOverlayPainter old) => true;
}

// ─── Hint shown before scratching ────────────────────────────────────────────

class _HintText extends StatelessWidget {
  const _HintText();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('hint'),
      children: [
        Icon(Icons.touch_app_rounded, size: 34, color: AlkColors.AppFirstColor),
        const SizedBox(height: 8),
        Text(
          'Grattez avec votre doigt',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
      ],
    );
  }
}

// ─── Dialog entry point ──────────────────────────────────────────────────────

/// Shows the scratch card as a welcome dialog.
/// [uuid] — device UUID for backend tracking.
/// [onClaim] — async callback invoked when user taps "Récupérer". Receives the
///   reward label and returns null on success, or an error message on failure.
Future<void> showScratchCardDialog(
  BuildContext context, {
  required String uuid,
  required Future<String?> Function(String rewardLabel) onClaim,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ScratchCardDialog(uuid: uuid, onClaim: onClaim),
  );
}

class _ScratchCardDialog extends StatefulWidget {
  final String uuid;
  final Future<String?> Function(String rewardLabel) onClaim;

  const _ScratchCardDialog({required this.uuid, required this.onClaim});

  @override
  State<_ScratchCardDialog> createState() => _ScratchCardDialogState();
}

class _ScratchCardDialogState extends State<_ScratchCardDialog> {
  late final _Reward _reward = _pickReward();
  final List<Offset?> _points = [];
  bool _isRevealed = false;
  bool _isClaiming = false;

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isRevealed) return;
    setState(() => _points.add(d.localPosition));
    if (_points.whereType<Offset>().length > 130) _revealAll();
  }

  void _onPanEnd(DragEndDetails _) {
    if (!_isRevealed) _points.add(null);
  }

  void _revealAll() {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);
  }

  Future<void> _claim() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);
    final error = await widget.onClaim(_reward.label);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isClaiming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColor = AlkColors.AppFirstColor;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColor, appColor.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  const Icon(Icons.emoji_events_rounded, size: 44, color: Colors.white),
                  const SizedBox(height: 6),
                  const Text(
                    'Bienvenue sur Alkirtas !',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grattez pour révéler votre cadeau de bienvenue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Scratch card
            Container(
              width: 280,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: _isRevealed ? null : _onPanUpdate,
                  onPanEnd: _isRevealed ? null : _onPanEnd,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(280, 190),
                      painter: _RewardPainter(reward: _reward),
                      foregroundPainter: _isRevealed
                          ? null
                          : _ScratchOverlayPainter(points: _points),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Below card
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _isRevealed
                  ? _DialogClaimSection(
                      reward: _reward,
                      isClaiming: _isClaiming,
                      onClaim: _claim,
                      onClose: () => Navigator.of(context).pop(),
                    )
                  : const _HintText(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DialogClaimSection extends StatelessWidget {
  final _Reward reward;
  final bool isClaiming;
  final VoidCallback onClaim;
  final VoidCallback onClose;

  const _DialogClaimSection({
    required this.reward,
    required this.isClaiming,
    required this.onClaim,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('dialog_claim'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Félicitations !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AlkColors.AppFirstColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vous avez gagné : ${reward.label}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            reward.sublabel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isClaiming ? null : onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: reward.color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              child: isClaiming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Récupérer ma récompense',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClose,
            child: Text('Plus tard', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Claim section shown after reveal ────────────────────────────────────────

class _ClaimSection extends StatelessWidget {
  final _Reward reward;

  const _ClaimSection({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('claim'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            '🎉 Félicitations !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AlkColors.AppFirstColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous avez gagné : ${reward.label}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            reward.sublabel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: reward.color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Récupérer ma récompense',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
