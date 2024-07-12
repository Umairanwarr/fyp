import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TimeLineTileWidget extends StatelessWidget {
  String text;
  bool isfirst;
  bool islast;
  TimeLineTileWidget({
    super.key,
    required this.isfirst,
    required this.islast,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return TimelineTile(
      alignment: TimelineAlign.start,
      isFirst: isfirst,
      isLast: islast,
      indicatorStyle: IndicatorStyle(
        width: 20,
        color: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 4),
        indicator: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
      endChild: Container(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(4),
            margin: EdgeInsets.all(4),
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border.all(), borderRadius: BorderRadius.circular(8)),
            child: Text(text),
          ),
        ),
      ),
      beforeLineStyle: LineStyle(
        color: Colors.teal,
        thickness: 6,
      ),
    );
  }
}
