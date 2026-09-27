import 'package:flutter/widgets.dart';

/// Corner radii (logical px) from `doc/design/DESIGN_TOKENS.md`.
abstract final class AppRadii {
  static const double card = 20; // doc: 18–20
  static const double button = 15; // doc: 14–16
  static const double input = 12;
  static const double iconTile = 12; // doc: 11–12
  static const double pill = 999; // full
  static const double artboard = 34; // device corner

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(input),
  );
  static const BorderRadius iconTileRadius = BorderRadius.all(
    Radius.circular(iconTile),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
