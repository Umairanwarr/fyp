import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TimeLineTileWidget extends StatefulWidget {
  final String text;
  final bool isfirst;
  final bool islast;

  TimeLineTileWidget({
    Key? key,
    required this.isfirst,
    required this.islast,
    required this.text,
  }) : super(key: key);

  @override
  _TimeLineTileWidgetState createState() => _TimeLineTileWidgetState();
}

class _TimeLineTileWidgetState extends State<TimeLineTileWidget> {
  bool isReached = false;

  void toggleReached() {
    setState(() {
      isReached = !isReached;
    });

    // Show a dialog when the state changes to 'reached'
    if (isReached) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Status"),
            content: Text("You've reached!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TimelineTile(
      alignment: TimelineAlign.start,
      isFirst: widget.isfirst,
      isLast: widget.islast,
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
      endChild: GestureDetector(
        onTap: toggleReached,
        child: Container(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.all(4),
              margin: EdgeInsets.all(4),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isReached ? Colors.green : Colors.white,
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.text),
            ),
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
