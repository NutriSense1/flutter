import 'package:flutter/material.dart';
import 'fade_slide.dart';

/// Renders children with staggered FadeSlide entrance delays.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration initialDelay;
  final Duration itemDelay;
  final Duration duration;
  final Offset beginOffset;
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredList({
    super.key,
    required this.children,
    this.initialDelay = Duration.zero,
    this.itemDelay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 480),
    this.beginOffset = const Offset(0.0, 0.06),
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++)
          FadeSlide(
            delay: initialDelay + (itemDelay * i),
            duration: duration,
            beginOffset: beginOffset,
            child: children[i],
          ),
      ],
    );
  }
}
