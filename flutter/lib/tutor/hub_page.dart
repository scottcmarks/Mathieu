// The way in to everything the toy cannot do.

import 'package:flutter/material.dart';

import 'actions.dart';
import 'lesson_page.dart';
import 'library_page.dart';
import 'widgets.dart';
import 'workshop_page.dart';

class TutorHubPage extends StatefulWidget {
  final TutorActions actions;
  const TutorHubPage({super.key, required this.actions});

  @override
  State<TutorHubPage> createState() => _TutorHubPageState();
}

class _TutorHubPageState extends State<TutorHubPage> {
  TutorActions get a => widget.actions;

  @override
  void initState() {
    super.initState();
    a.brain.addListener(_onBrain);
    a.brain.ensureTable();
  }

  @override
  void dispose() {
    a.brain.removeListener(_onBrain);
    super.dispose();
  }

  void _onBrain() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final brain = a.brain;
    final t = brain.table;
    final here = t?.distanceOf(a.arrangement);

    return BackPage(
      title: 'Learn',
      body: BackList(children: [
        _tile(
          icon: Icons.menu_book_outlined,
          title: 'Lessons',
          subtitle: 'Ten short ones, each about something the toy cannot do.',
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LessonListPage(actions: a))),
        ),
        _tile(
          icon: Icons.bookmarks_outlined,
          title: 'Macro library',
          subtitle:
              '${brain.library.entries.length} saved · five keys to bind them to',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => LibraryPage(actions: a))),
        ),
        _tile(
          icon: Icons.build_outlined,
          title: 'Workshop',
          subtitle: 'Inverse, composition, commutator, aiming, and the search.',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => WorkshopPage(actions: a))),
        ),
        Section(
          title: 'Where you are',
          child: t == null
              ? const Working('Mapping all 95,040 positions…')
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    here == 0
                        ? 'The board is at home.'
                        : 'The board is $here move${here == 1 ? '' : 's'} from '
                            'home — exactly, not approximately.',
                    style: kLabelStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Swap #${brain.swapNumber} · furthest possible '
                    '${t.diameter} moves · map built in '
                    '${t.buildTime.inMilliseconds} ms',
                    style: kSubtleStyle,
                  ),
                  const SizedBox(height: 10),
                  Center(child: SeatRing.forPerm(a.arrangement, size: 180)),
                ]),
        ),
      ]),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.black54),
        title: Text(title, style: kLabelStyle),
        subtitle: Text(subtitle, style: kSubtleStyle),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: onTap,
      );
}
