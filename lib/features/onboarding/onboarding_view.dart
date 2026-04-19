import 'package:flutter/material.dart';
import '../auth/login_view.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});
  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  int step = 1;
  final List<Map<String, String>> onboardingData = [
    {
      "image": 'lib/assets/Bottom G.png',
      "text": "Selamat Datang di LogBook App",
      "desc": "Kelola catatan harian Anda dengan mudah dan efisien.",
    },
    {
      "image": 'lib/assets/Screenshot (668).png',
      "text": "Keamanan Terjamin",
      "desc": "Login yang aman untuk menjaga privasi data Anda.",
    },
    {
      "image": 'lib/assets/Screenshot 2026-02-05 060146.png',
      "text": "Pantau Aktivitas",
      "desc": "Riwayat aktivitas tersimpan rapi untuk Anda pantau.",
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              child: Text(
                onboardingData[step - 1]["text"]!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                onboardingData[step - 1]["image"]!,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                onboardingData[step - 1]["desc"]!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step == index + 1 ? Colors.indigo : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(40),
              child: ElevatedButton(
                onPressed: () {
                  if (step < 3) {
                    setState(() {
                      step++;
                    });
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                    );
                  }
                },
                child: Text(step < 3 ? "Lanjut" : "Mulai"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
