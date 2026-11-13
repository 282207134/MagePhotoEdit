import 'package:flutter/material.dart';

const ink = Color(0xff161718);
const panel = Color(0xff2b2b2e);
const pink = Color(0xffff0566);
const muted = Color(0xff77777c);
const palette = <Color>[
  Colors.white,
  Colors.black,
  pink,
  Color(0xffb41999),
  Color(0xff7136df),
  Color(0xff4674e6),
  Color(0xff00d7d5),
  Color(0xffffb72e),
];

Widget art(
  String name, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) => Image.asset(
  'assets/images/$name.png',
  fit: fit,
  width: width,
  height: height,
  errorBuilder: (_, error, stack) => const ColoredBox(
    color: panel,
    child: Center(child: Icon(Icons.broken_image_outlined)),
  ),
);

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.hint,
    this.onChanged,
    this.initial = '',
  });
  final String hint, initial;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    child: TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff515155), fontSize: 14),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xffb4b4b9),
          size: 24,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

class ChoiceStrip extends StatelessWidget {
  const ChoiceStrip(
    this.items, {
    super.key,
    required this.selected,
    required this.onSelected,
    this.small = false,
    this.padding = 0,
  });
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool small;
  final double padding;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: small ? 32 : 34,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: padding),
      itemCount: items.length,
      separatorBuilder: (_, i) => SizedBox(width: small ? 8 : 10),
      itemBuilder: (_, i) {
        final active = selected == items[i];
        return Center(
          child: InkWell(
            onTap: () => onSelected(items[i]),
            borderRadius: BorderRadius.circular(5),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: small ? 8 : 16,
                vertical: small ? 4 : 7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: active ? pink : const Color(0xff48484c),
                ),
              ),
              child: Text(
                items[i],
                style: TextStyle(
                  fontSize: small ? 11 : 13,
                  color: active ? pink : const Color(0xffd1d1d5),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader(
    this.title, {
    super.key,
    this.onBack,
    this.onDone,
    this.cancel = false,
  });
  final String title;
  final VoidCallback? onBack, onDone;
  final bool cancel;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 70,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            tooltip: cancel ? 'Cancel' : 'Back',
            icon: Icon(
              cancel ? Icons.close : Icons.arrow_back_ios_new,
              size: 22,
            ),
            onPressed:
                onBack ??
                () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 48,
            child: onDone == null
                ? null
                : IconButton(
                    tooltip: 'Apply',
                    onPressed: onDone,
                    icon: const Icon(Icons.check, size: 25),
                  ),
          ),
        ],
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.text, {
    super.key,
    required this.onPressed,
    this.icon,
  });
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: pink,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
      minimumSize: const Size(0, 50),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        if (icon != null) ...[const SizedBox(width: 6), Icon(icon, size: 18)],
      ],
    ),
  );
}

void tell(BuildContext context, String message) => ScaffoldMessenger.of(context)
    .showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );

class SelectionBorder extends StatelessWidget {
  const SelectionBorder({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      child,
      Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _Corners())),
      ),
    ],
  );
}

class _Corners extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, p);
    p
      ..color = Colors.white
      ..strokeWidth = 2;
    for (final c in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final dx = c.dx == 0 ? 18.0 : -18.0;
      final dy = c.dy == 0 ? 18.0 : -18.0;
      canvas.drawLine(c, c.translate(dx, 0), p);
      canvas.drawLine(c, c.translate(0, dy), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Checkerboard extends StatelessWidget {
  const Checkerboard({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _Checker(), size: Size.infinite);
}

class _Checker extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    const step = 14.0;
    final p = Paint();
    for (var y = 0; y < s.height / step; y++) {
      for (var x = 0; x < s.width / step; x++) {
        p.color = (x + y).isEven
            ? const Color(0xff323335)
            : const Color(0xff202123);
        canvas.drawRect(Rect.fromLTWH(x * step, y * step, step, step), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
