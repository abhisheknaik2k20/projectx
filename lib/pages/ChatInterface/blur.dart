import 'package:flutter/material.dart';
import 'dart:ui';

class FrostedGlassBox extends StatelessWidget {
  const FrostedGlassBox({Key? key, required this.theChild}) : super(key: key);

  final theChild;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: theChild,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.13)),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ]),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
              ),
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }
}
