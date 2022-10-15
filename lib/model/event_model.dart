class Events {
  final String eventTitle;
  final String eventDescp;
  final String eventTime;

  Events({
    required this.eventTitle,
    required this.eventDescp,
    required this.eventTime,
  });

  @override
  String toString() {
    return '$eventTitle/$eventDescp/$eventTime';
  }
}
