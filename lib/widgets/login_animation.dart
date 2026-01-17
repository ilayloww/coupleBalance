import 'package:flutter/material.dart';
import 'package:rive/rive.dart'; // v0.14.1

class LoginAnimation extends StatefulWidget {
  final Function(
    SMIBool? isFocus,
    SMIBool? isPrivateField,
    SMIBool? isPrivateFieldShow,
    SMITrigger? successTrigger,
    SMITrigger? failTrigger,
    SMINumber? numLook,
  )
  onInit;

  const LoginAnimation({super.key, required this.onInit});

  @override
  State<LoginAnimation> createState() => _LoginAnimationState();
}

class _LoginAnimationState extends State<LoginAnimation> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: 300,
      child: RiveAnimation.asset(
        'assets/animations/teddy.riv',
        fit: BoxFit.contain,
        onInit: (artboard) {
          StateMachineController? controller;

          // Try standard names first, then fallback
          controller = StateMachineController.fromArtboard(
            artboard,
            'State Machine 1',
          );
          controller ??= StateMachineController.fromArtboard(artboard, 'Login');

          if (controller == null && artboard.stateMachines.isNotEmpty) {
            controller = StateMachineController.fromArtboard(
              artboard,
              artboard.stateMachines.first.name,
            );
          }

          if (controller != null) {
            artboard.addController(controller);
            widget.onInit(
              controller.findInput<bool>('isFocus') as SMIBool?,
              controller.findInput<bool>('isPrivateField') as SMIBool?,
              controller.findInput<bool>('isPrivateFieldShow') as SMIBool?,
              controller.findInput<bool>('successTrigger') as SMITrigger?,
              controller.findInput<bool>('failTrigger') as SMITrigger?,
              controller.findInput<double>('numLook') as SMINumber?,
            );
          }
        },
      ),
    );
  }
}
