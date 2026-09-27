import '../../../shared/widgets/status_pill.dart';

/// Ticket status colour: open/pending = amber (waiting on us), in progress =
/// blue, resolved = green, closed = neutral.
PillTone ticketStatusTone(String status) => switch (status) {
      'open' || 'pending' => PillTone.amber,
      'in_progress' => PillTone.blue,
      'resolved' => PillTone.green,
      _ => PillTone.neutral,
    };

/// Ticket priority colour: urgent = red, high = amber, normal = blue,
/// low = neutral.
PillTone ticketPriorityTone(String priority) => switch (priority) {
      'urgent' => PillTone.red,
      'high' => PillTone.amber,
      'normal' => PillTone.blue,
      _ => PillTone.neutral,
    };
