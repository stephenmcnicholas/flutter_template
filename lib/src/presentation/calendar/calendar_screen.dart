import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';

class ScheduledProgram {
  final String id;
  final String name;
  final DateTime date;
  ScheduledProgram({required this.id, required this.name, required this.date});
}

final _mockPrograms = <ScheduledProgram>[
  ScheduledProgram(id: '1', name: 'Push Day', date: DateTime.utc(2025, 5, 27)),
  ScheduledProgram(id: '2', name: 'Pull Day', date: DateTime.utc(2025, 5, 28)),
  ScheduledProgram(id: '3', name: 'Legs', date: DateTime.utc(2025, 5, 29)),
];

class CalendarScreen extends ConsumerStatefulWidget {
  final DateTime? initialFocusedDay;
  const CalendarScreen({super.key, this.initialFocusedDay});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  List<ScheduledProgram> _programsForDay(DateTime day) {
    return _mockPrograms.where((p) => isSameDay(p.date, day)).toList();
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedDay ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _selectedDay ?? _focusedDay;
    final programs = _programsForDay(selectedDay);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar<ScheduledProgram>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _programsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: programs.isEmpty
                ? const Center(child: Text('No programs scheduled for this day.'))
                : ListView.builder(
                    itemCount: programs.length,
                    itemBuilder: (context, index) {
                      final prog = programs[index];
                      return ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(prog.name),
                        subtitle: Text('${prog.date.year}-${prog.date.month}-${prog.date.day}'),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for scheduling a new program
          showInfoDialog(
            context,
            title: 'Schedule Program',
            message: 'Feature coming soon!',
          );
        },
        tooltip: 'Schedule Program',
        child: const Icon(Icons.add),
      ),
    );
  }
} 