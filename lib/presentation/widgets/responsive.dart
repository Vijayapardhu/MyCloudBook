import 'package:flutter/widgets.dart';
import '../../core/theme/tokens.dart';

enum ScreenSize { compact, medium, expanded }

class Responsive {
  static ScreenSize sizeOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < Tokens.bpCompact) return ScreenSize.compact;
    if (w < Tokens.bpMedium) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static bool isCompact(BuildContext context) => sizeOf(context) == ScreenSize.compact;
  static bool isMedium(BuildContext context) => sizeOf(context) == ScreenSize.medium;
  static bool isExpanded(BuildContext context) => sizeOf(context) == ScreenSize.expanded;
}


