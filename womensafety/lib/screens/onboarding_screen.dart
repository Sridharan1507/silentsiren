import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:womensafety/main.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Share location to your trusted ones",
          body: "Let your  Trusted ones track your location to know where you are alone",
          image: Image.asset("assets/images/onBoarding1.jpg", height: 250),
        ),
        PageViewModel(
          title: "Travel at night without fear",
          body: "Have a safe ride by letting your loved ones be aware of your location",
          image: Image.asset("assets/images/onBoarding2.jpg", height: 250),
        ),
      ],
      onDone: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  RegisterScreen()));
      },
      onSkip: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  RegisterScreen()));
      },
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Let's go!", style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.black26,
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
