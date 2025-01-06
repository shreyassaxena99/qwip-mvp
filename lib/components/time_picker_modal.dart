import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimePickerModal extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;

  const TimePickerModal({
    Key? key,
    required this.initialTime,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  _TimePickerModalState createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  int selectedHour = 0;
  int selectedMinute = 0;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute -
        (widget.initialTime.minute % 15); // Round to 15-minute intervals
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(
            height: 200, // Set the height of the picker
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: selectedHour),
                    itemExtent: 40.0,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedHour = index;
                      });
                    },
                    children: List<Widget>.generate(24, (index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: selectedMinute ~/ 15),
                    itemExtent: 40.0,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedMinute = index * 15;
                      });
                    },
                    children: List<Widget>.generate(4, (index) {
                      return Center(
                        child: Text(
                          (index * 15).toString().padLeft(2, '0'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onTimeSelected(
                TimeOfDay(hour: selectedHour, minute: selectedMinute),
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
