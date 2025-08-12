import 'package:nextfitx/common/colo_extension.dart';
import 'package:nextfitx/view/on_boarding/on_boarding_view.dart';
import 'package:flutter/material.dart';

class StartedView extends StatefulWidget {
  const StartedView({super.key});

  @override
  State<StartedView> createState() => _StartedViewState();
}

class _StartedViewState extends State<StartedView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white,
      body: Container(
        width: media.width,
        height: media.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: TColor.primaryG,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Logo aplikasi
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: TColor.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Image.asset(
                  "assets/img/logofix.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Nama aplikasi
            Text(
              "nextfitX",
              style: TextStyle(
                color: TColor.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Everybody Can Train",
              style: TextStyle(
                color: TColor.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),

            const Spacer(),

            // Get Started Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: TColor.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnBoardingView(),
                          ),
                        );
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: TColor.primaryG,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(Rect.fromLTRB(
                                    0, 0, bounds.width, bounds.height));
                              },
                              child: Text(
                                "Get Started",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: TColor.primaryG,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
