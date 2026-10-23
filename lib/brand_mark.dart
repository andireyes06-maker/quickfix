import "package:flutter/material.dart";

// The QuickFix pin-and-wrench logo as a rounded tile. Decorative: the word
// "QuickFix" next to it already names the app, so screen readers skip the image.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          "assets/brand/quickfix-mark.png",
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
