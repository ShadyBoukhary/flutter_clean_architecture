import '../pages/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

class HomePageButton extends StatelessWidget {
  final String text;
  HomePageButton({@required this.text});

  @override
  Widget build(BuildContext context) {
    // use a common controller assuming HomePageButton is always a child of Home
<<<<<<< HEAD
    final controller =
=======
    HomeController controller =
>>>>>>> 5a48f590c2e82682b6324085c66f3285102a48cd
        FlutterCleanArchitecture.getController<HomeController>(context);
    return GestureDetector(
      onTap: controller.buttonPressed,
      child: Container(
        height: 50.0,
        alignment: FractionalOffset.center,
        decoration: BoxDecoration(
          color: Color.fromRGBO(230, 38, 39, 1.0),
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.4),
        ),
      ),
    );
  }
}
