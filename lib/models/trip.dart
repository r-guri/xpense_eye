import 'member.dart';

class Trip {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  List<Member> members;

  Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.members = const [],
  });
}
