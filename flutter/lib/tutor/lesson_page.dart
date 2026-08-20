// The lesson list and one lesson.
//
// A lesson that needs the group map says so and builds it on entry rather than
// showing an empty page; on web that build runs inline, so the "working" state
// is real rather than decorative.

import 'package:flutter/material.dart';

import 'actions.dart';
import 'lessons.dart';
import 'widgets.dart';

/// Lessons available in this build. L0 exists only when a device skin is on,
/// so it ships and hides with its pack.
List<Lesson> lessonsFor(TutorActions a) =>
    kLessons.where((l) => !l.skinGated || a.skin.sensitive).toList()
      ..sort((x, y) => x.number.compareTo(y.number));

class LessonListPage extends StatelessWidget {
  final TutorActions actions;
  const LessonListPage({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final lessons = lessonsFor(actions);
    return BackPage(
      title: 'Lessons',
      body: BackList(children: [
        Text(
          'Ten short lessons, each about something the app can do that a '
          'mechanical toy cannot.',
          style: kSubtleStyle,
        ),
        const SizedBox(height: 8),
        for (final l in lessons)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFE8EEF7),
              child: Text('${l.number}',
                  style: const TextStyle(color: Colors.black87, fontSize: 14)),
            ),
            title: Text(l.title, style: kLabelStyle),
            subtitle: Text(l.tagline, style: kSubtleStyle),
            trailing: const Icon(Icons.chevron_right, color: Colors.black26),
            onTap: () => openLesson(context, actions, l.number),
          ),
      ]),
    );
  }
}

Future<void> openLesson(BuildContext context, TutorActions actions, int number) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => LessonPage(actions: actions, number: number),
  ));
}

class LessonPage extends StatefulWidget {
  final TutorActions actions;
  final int number;
  const LessonPage({super.key, required this.actions, required this.number});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  TutorActions get a => widget.actions;
  late int _n = widget.number;

  Lesson get _lesson {
    final all = lessonsFor(a);
    // A deep link may name a lesson that does not exist in this build; clamp.
    if (all.isEmpty) return kLessons.first;
    final found = all.where((l) => l.number == _n);
    if (found.isNotEmpty) return found.first;
    final clamped = _n < all.first.number ? all.first.number : all.last.number;
    _n = clamped;
    return all.firstWhere((l) => l.number == clamped);
  }

  @override
  void initState() {
    super.initState();
    a.brain.addListener(_onBrain);
    _prepare();
  }

  @override
  void dispose() {
    a.brain.removeListener(_onBrain);
    super.dispose();
  }

  void _onBrain() {
    if (mounted) setState(() {});
  }

  void _prepare() {
    final l = _lesson;
    if (l.needsDiscovery) {
      a.brain.ensureDiscovery();
    } else if (l.needsTable) {
      a.brain.ensureTable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _lesson;
    final brain = a.brain;
    final all = lessonsFor(a);
    final i = all.indexWhere((x) => x.number == l.number);

    Widget content;
    if (l.needsDiscovery && brain.discovery == null) {
      content = Working(brain.isBuildingTable
          ? 'Mapping all 95,040 positions…'
          : 'Searching the group…');
    } else if (l.needsTable && brain.table == null) {
      content = const Working('Mapping all 95,040 positions…');
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: l.body(LessonContext(
          actions: a,
          table: brain.table,
          discovery: brain.discovery,
          context: context,
        )),
      );
    }

    return BackPage(
      title: 'Lesson ${l.number}',
      body: BackList(children: [
        Text(l.title,
            style: const TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(l.tagline, style: kSubtleStyle),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.smartphone, size: 14, color: Colors.black38),
          const SizedBox(width: 6),
          Expanded(
              child: Text(l.toyCant,
                  style: kSubtleStyle.copyWith(fontStyle: FontStyle.italic))),
        ]),
        const SizedBox(height: 18),
        content,
      ]),
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
              onPressed: i > 0
                  ? () => setState(() {
                        _n = all[i - 1].number;
                        _prepare();
                      })
                  : null,
              child: const Text('Previous'),
            ),
            Text('${i + 1} of ${all.length}', style: kSubtleStyle),
            TextButton(
              onPressed: i >= 0 && i < all.length - 1
                  ? () => setState(() {
                        _n = all[i + 1].number;
                        _prepare();
                      })
                  : null,
              child: const Text('Next'),
            ),
          ]),
        ),
      ),
    );
  }
}
