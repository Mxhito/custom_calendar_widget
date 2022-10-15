import 'package:flutter/material.dart';

import '/model/event_model.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen(
      {Key? key,
      required this.selectedDateTime,
      required this.daysEvents,
      required this.callBack})
      : super(key: key);

  final DateTime selectedDateTime;

  //Map of events for current day
  final Map<DateTime, List<Events>> daysEvents;

  final Function callBack;

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descpController;
  late TimeOfDay _timeOfDay;

  final _timeController = FixedExtentScrollController(initialItem: 24);

  final TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
  final TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 30);
  final Duration interval = const Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Hello');
    _descpController = TextEditingController(text: 'y`all');
    _timeOfDay = TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descpController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final times = _getTimeSlots(startTime, endTime, interval)
        .toList()
        .map((e) => e.to24hours());

    final String selectedDayTimeTitle =
        widget.selectedDateTime.toString().split(' ')[0];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(selectedDayTimeTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.daysEvents[widget.selectedDateTime] == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'No Events',
                        style: TextStyle(fontSize: 28),
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Add an events?\n'
                        'Tap the "+ Add Evetn" button to write them down!',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.daysEvents[widget.selectedDateTime]?.length,
                  itemBuilder: (BuildContext context, index) {
                    final item =
                        widget.daysEvents[widget.selectedDateTime]![index];
                    return Dismissible(
                      key: Key(item.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        child: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 50.0,
                        ),
                      ),
                      onDismissed: (direction) {
                        widget.daysEvents[widget.selectedDateTime]
                            ?.remove(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('dismissed'),
                          ),
                        );
                        widget.callBack();
                      },
                      child: ListTile(
                        leading: const Icon(Icons.check),
                        title: Text(
                          item.toString().split('/')[0],
                          style: const TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(
                          item.toString().split('/')[1],
                          style: const TextStyle(fontSize: 18),
                        ),
                        trailing: Text(
                          item.toString().split('/')[2],
                          style: const TextStyle(fontSize: 18),
                        ),
                        dense: true,
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _showEventDialog(_titleController, _descpController, times);
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add event',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  //Generator of time
  Iterable<TimeOfDay> _getTimeSlots(
      TimeOfDay startTime, TimeOfDay endTime, Duration interval) sync* {
    var hour = startTime.hour;
    var minute = startTime.minute;

    do {
      yield TimeOfDay(hour: hour, minute: minute);
      minute += interval.inMinutes;
      while (minute >= 60) {
        minute -= 60;
        hour++;
      }
    } while (hour < endTime.hour ||
        (hour == endTime.hour && minute <= endTime.minute));
  }

  _showEventDialog(TextEditingController titleController,
      TextEditingController descpController, Iterable<String> times) async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Event'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: 'Enter Title'),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: descpController,
                  decoration:
                      const InputDecoration(hintText: 'Enter Description'),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${_timeOfDay.to24hours()}',
                    ),
                    TextButton(
                      child: const Text('Select'),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Time picker'),
                            content: _showTimePicker(context, times),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Back'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _timeOfDay = times
                                        .toList()[_timeController.selectedItem]
                                        .toTimeOfDay();
                                    Navigator.pop(context);
                                  });
                                },
                                child: const Text('Ok'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  titleController.clear();
                  descpController.clear();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.isEmpty &&
                      descpController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Please enter fields!'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    setState(() {
                      if (widget.daysEvents[widget.selectedDateTime] == null) {
                        widget.daysEvents[widget.selectedDateTime] = [
                          Events(
                            eventTitle: titleController.text,
                            eventDescp: descpController.text,
                            eventTime: _timeOfDay.to24hours(),
                          )
                        ];
                      } else {
                        widget.daysEvents[widget.selectedDateTime]?.add(
                          Events(
                            eventTitle: titleController.text,
                            eventDescp: descpController.text,
                            eventTime: _timeOfDay.to24hours(),
                          ),
                        );
                      }
                    });
                    widget.callBack();

                    _timeOfDay = TimeOfDay.now();
                    //titleController.clear();
                    //descpController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _showTimePicker(BuildContext context, Iterable<String> times) {
    return SizedBox(
      height: 100,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40.0,
        physics: const FixedExtentScrollPhysics(),
        useMagnifier: true,
        magnification: 1.5,
        controller: _timeController,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: times.length,
          builder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                times.toList()[index],
                style: const TextStyle(color: Colors.black),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension TimeOfDayConverter on TimeOfDay? {
  String to24hours() {
    final hour = this?.hour.toString().padLeft(2, '0');
    final minute = this?.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

extension StringConverter on String {
  TimeOfDay toTimeOfDay() {
    final hour = int.parse(split(':')[0]);
    final minute = int.parse(split(':')[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }
}
