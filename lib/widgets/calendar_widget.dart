import 'package:flutter/material.dart';

import '/screens/events_list_screen.dart';
import '/services/calendar_service.dart';
import '/model/calendar_model.dart';
import '/model/event_model.dart';

enum CalendarViews { dates, months, year }

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({Key? key}) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentDateTime;
  late DateTime _selectedDateTime;
  late List<Calendar> _sequentialDates;

  int? midYear;

  CalendarViews _currentView = CalendarViews.dates;

  Map<DateTime, List<Events>> daysEvents = {};

  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDateTime = DateTime(now.year, now.month);
    _selectedDateTime = DateTime(now.year, now.month, now.day);
    _getCalendarDates(); //_sequentialDates init
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() => _getCalendarDates());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width + 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple, width: 2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: (_currentView == CalendarViews.dates)
          ? _datesView(context)
          : (_currentView == CalendarViews.months)
              ? _showMonthsList()
              : _yearsView(midYear ?? _currentDateTime.year),
    );
  }

  //dates view
  Widget _datesView(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 70,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6.0), topRight: Radius.circular(6.0)),
            color: Colors.purple,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toggleButton(false),
              InkWell(
                onTap: () =>
                    setState(() => _currentView = CalendarViews.months),
                child: Text(
                  '${_monthNames[_currentDateTime.month - 1]} ${_currentDateTime.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ),
              _toggleButton(true),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _getWeekDays(context, _weekDays),
        ),
        const Divider(
          color: Colors.black,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _calendarBody(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //calendar dates of week
  List<Widget> _getWeekDays(BuildContext context, List<String> weekDays) {
    return weekDays
        .map(
          (e) => SizedBox(
            height: 32,
            width: MediaQuery.of(context).size.width / 7 - 16, // 16 is padding
            child: Center(
              child: Text(
                e,
                style: e == 'Sat' || e == 'Sun'
                    ? const TextStyle(color: Colors.red)
                    : null,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        )
        .toList();
  }

  //next/
  //prev month buttons
  Widget _toggleButton(bool next) {
    return IconButton(
      onPressed: () {
        if (_currentView == CalendarViews.dates) {
          setState(() => (next) ? _getNextMonth() : _getPrevMonth());
        } else if (_currentView == CalendarViews.year) {
          if (next) {
            midYear =
                (midYear == null) ? _currentDateTime.year + 9 : midYear! + 9;
          } else {
            midYear =
                (midYear == null) ? _currentDateTime.year - 9 : midYear! - 9;
          }
          setState(() {});
        }
      },
      icon: Icon(
        next ? Icons.chevron_right : Icons.chevron_left,
        size: 28,
        color: Colors.white,
      ),
    );
  }

  //calendar
  Widget _calendarBody() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: _sequentialDates.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (BuildContext context, index) {
            final calendar = _sequentialDates[index];
            final defaultDaysStyle = TextStyle(
                color: (calendar.thisMonth)
                    ? (calendar.date.weekday == DateTime.sunday ||
                            calendar.date.weekday == DateTime.saturday)
                        ? Colors.red
                        : Colors.black
                    : (calendar.date.weekday == DateTime.sunday ||
                            calendar.date.weekday == DateTime.saturday)
                        ? Colors.red.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5));
            final eventsCount = daysEvents[calendar.date]?.length ?? 0;

            if (calendar.date == today) {
              return _getDateWidget(
                calendar: calendar,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(50),
                ),
                textStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                eventsCount: eventsCount,
              );
            } else if (calendar.date == _selectedDateTime) {
              return _getDateWidget(
                calendar: calendar,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.purple, width: 3),
                ),
                textStyle: const TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold),
                eventsCount: eventsCount,
              );
            }
            return _getDateWidget(
              calendar: calendar,
              textStyle: defaultDaysStyle,
              eventsCount: eventsCount,
            );
          },
        ),
      ),
    );
  }

  //rebuilt calendar if events screen changed
  void callBack() {
    setState(() {});
  }

  //paterns of dates (with/without events, today, selected day)
  Widget _getDateWidget(
      {required Calendar calendar,
      BoxDecoration? decoration,
      TextStyle? textStyle,
      int eventsCount = 0}) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () {
        if (_selectedDateTime != calendar.date) {
          if (calendar.nextMonth) {
            _getNextMonth();
          } else if (calendar.prevMonth) {
            _getPrevMonth();
          }
          setState(() => _selectedDateTime = calendar.date);
        }
        // move to events day
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return EventsListScreen(
                selectedDateTime: _selectedDateTime,
                daysEvents: daysEvents,
                callBack: callBack,
              );
            },
          ),
        );
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: decoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${calendar.date.day}',
              style: textStyle,
            ),
            const SizedBox(height: 4),
            Visibility(
              visible: eventsCount != 0,
              child: Container(
                height: 17,
                width: 17,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  eventsCount.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //get next month calendar
  void _getNextMonth() {
    if (_currentDateTime.month == 12) {
      _currentDateTime = DateTime(_currentDateTime.year + 1, 1);
    } else {
      _currentDateTime =
          DateTime(_currentDateTime.year, _currentDateTime.month + 1);
    }
    _getCalendarDates();
  }

  //get previous month calendar
  void _getPrevMonth() {
    if (_currentDateTime.month == 1) {
      _currentDateTime = DateTime(_currentDateTime.year - 1, 12);
    } else {
      _currentDateTime =
          DateTime(_currentDateTime.year, _currentDateTime.month - 1);
    }
    _getCalendarDates();
  }

  //get calendar for current month
  void _getCalendarDates() {
    _sequentialDates = CalendarService().getMonthCalendar(
        _currentDateTime.month, _currentDateTime.year,
        startWeekDay: StartWeekDay.monday);
  }

  //show months list
  Widget _showMonthsList() {
    return Column(
      children: <Widget>[
        InkWell(
          onTap: () => setState(() => _currentView = CalendarViews.year),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              '${_currentDateTime.year}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple),
            ),
          ),
        ),
        const Divider(
          color: Colors.white,
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _monthNames.length,
            itemBuilder: (context, index) => ListTile(
              onTap: () {
                _currentDateTime = DateTime(_currentDateTime.year, index + 1);
                _getCalendarDates();
                setState(() => _currentView = CalendarViews.dates);
              },
              title: Center(
                child: Text(
                  _monthNames[index],
                  style: TextStyle(
                      fontSize: 18,
                      color: (index == _currentDateTime.month - 1)
                          ? Colors.purple
                          : Colors.black),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  //years list views
  Widget _yearsView(int midYear) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            _toggleButton(false),
            const Spacer(),
            _toggleButton(true),
          ],
        ),
        Expanded(
          child: GridView.builder(
              shrinkWrap: true,
              itemCount: 9,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (context, index) {
                int thisYear;
                if (index < 4) {
                  thisYear = midYear - (4 - index);
                } else if (index > 4) {
                  thisYear = midYear + (index - 4);
                } else {
                  thisYear = midYear;
                }
                return ListTile(
                  onTap: () {
                    _currentDateTime =
                        DateTime(thisYear, _currentDateTime.month);
                    _getCalendarDates();
                    setState(() => _currentView = CalendarViews.months);
                  },
                  title: Text(
                    '$thisYear',
                    style: TextStyle(
                        fontSize: 18,
                        color: (thisYear == _currentDateTime.year)
                            ? Colors.purple
                            : Colors.black),
                  ),
                );
              }),
        ),
      ],
    );
  }
}
