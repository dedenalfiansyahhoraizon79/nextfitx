import 'package:flutter/material.dart';
import '../../../common/colo_extension.dart';
import '../../../common_widget/setting_row.dart';

class OtherSection extends StatelessWidget {
  final List otherArr;
  final Function(String)? onItemPressed;

  const OtherSection({
    super.key,
    required this.otherArr,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Other",
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
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: otherArr.length,
            itemBuilder: (context, index) {
              var iObj = otherArr[index] as Map? ?? {};
              return SettingRow(
                icon: iObj["image"].toString(),
                title: iObj["name"].toString(),
                onPressed: () {
                  onItemPressed?.call(iObj["tag"].toString());
                },
              );
            },
          )
        ],
      ),
    );
  }
}
