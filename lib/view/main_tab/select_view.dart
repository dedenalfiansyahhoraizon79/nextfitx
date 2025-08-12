import 'package:nextfitx/common_widget/round_button.dart';
import 'package:flutter/material.dart';
import '../body_composition/body_composition_view.dart';
import '../meal/meal_view.dart';
import '../workout/workout_view.dart';
import '../sleep/sleep_view.dart';
import '../intermittent_fasting/intermittent_fasting_view.dart';
import '../workout_academy/workout_academy_view.dart';

class SelectView extends StatelessWidget {
  const SelectView({super.key});

  @override
  Widget build(BuildContext context) {
    // var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoundButton(
                title: "🎓 Workout Academy",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutAcademyView(),
                    ),
                  );
                }),
            const SizedBox(
              height: 15,
            ),
            RoundButton(
                title: "Body Composition",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BodyCompositionView(),
                    ),
                  );
                }),
            const SizedBox(
              height: 15,
            ),
            RoundButton(
                title: "Meal Diary",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MealView(),
                    ),
                  );
                }),
            const SizedBox(
              height: 15,
            ),
            RoundButton(
                title: "Workout Record",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutView(),
                    ),
                  );
                }),
            const SizedBox(
              height: 15,
            ),
            RoundButton(
                title: "Sleep Record",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SleepView(),
                    ),
                  );
                }),
            const SizedBox(
              height: 15,
            ),
            RoundButton(
                title: "Intermittent Fasting",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IntermittentFastingView(),
                    ),
                  );
                })
          ],
        ),
      ),
    );
  }
}
