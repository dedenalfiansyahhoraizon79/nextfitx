import 'package:flutter/material.dart';
import '../../../common/colo_extension.dart';
import '../../../common_widget/setting_row.dart';

class AccountSection extends StatelessWidget {
  final List accountArr;
  final Function(String)? onItemPressed;
  const AccountSection({super.key, required this.accountArr, this.onItemPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: accountArr.length,
            itemBuilder: (context, index) {
              var iObj = accountArr[index] as Map? ?? {};
              return SettingRow(
                icon: iObj["image"].toString(),
                title: iObj["name"].toString(),
                onPressed: () {
                  if (onItemPressed != null) {
                    onItemPressed!(iObj["tag"].toString());
                  }
                },
              );
            },
          )
        ],
      ),
    );
  }
}
