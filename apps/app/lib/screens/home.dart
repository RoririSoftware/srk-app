import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'add_farmer.dart';
import 'farmer_detail.dart';
import 'farmers.dart';
import 'profile.dart';
import 'reports.dart';

const _tabs = [
  (label: 'Home', icon: Icons.dashboard_outlined),
  (label: 'Farmers', icon: Icons.groups_outlined),
  (label: 'Reports', icon: Icons.bar_chart_rounded),
  (label: 'Profile', icon: Icons.person_outline_rounded),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _go(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pages = [
          _Dashboard(onSeeFarmers: () => _go(1), onSeeReports: () => _go(2)),
          const FarmersPage(),
          const ReportsPage(),
          const ProfilePage(),
        ];
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 840;
                return Row(children: [
                  if (wide) _Sidebar(selected: _tab, onSelected: _go),
                  Expanded(child: pages[_tab]),
                ]);
              },
            ),
          ),
          bottomNavigationBar: MediaQuery.of(context).size.width >= 840 ? null : _BottomBar(selected: _tab, onSelected: _go),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: canvas,
        boxShadow: [BoxShadow(color: Color(0x3396A6B8), offset: Offset(0, -4), blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: Semantics(
                    selected: selected == i,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelected(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: canvas,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: selected == i ? pressed(2) : null,
                        ),
                        // Without min, this Column fills the loose height
                        // the Scaffold offers and eats the whole screen.
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_tabs[i].icon, size: 21, color: selected == i ? accent : muted),
                          const SizedBox(height: 4),
                          Text(_tabs[i].label,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: selected == i ? accent : muted)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      padding: const EdgeInsets.fromLTRB(16, 22, 10, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Padding(padding: EdgeInsets.only(left: 6), child: BrandMark()),
        const SizedBox(height: 28),
        for (var i = 0; i < _tabs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftTap(
              onTap: () => onSelected(i),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              radius: 15,
              child: Row(children: [
                Icon(_tabs[i].icon, size: 19, color: selected == i ? accent : muted),
                const SizedBox(width: 11),
                Text(_tabs[i].label,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: selected == i ? accent : ink)),
              ]),
            ),
          ),
        const Spacer(),
        SoftWell(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(store.staffName, style: const TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 13)),
            const SizedBox(height: 3),
            Text(store.branch, style: const TextStyle(color: muted, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onSeeFarmers, required this.onSeeReports});
  final VoidCallback onSeeFarmers;
  final VoidCallback onSeeReports;

  @override
  Widget build(BuildContext context) {
    final recent = store.farmers.take(4).toList();
    return PageScroll(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const BrandMark(),
          const Spacer(),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => toast(context, 'No new notifications.'),
            icon: const Icon(Icons.notifications_none_rounded, color: ink),
          ),
        ]),
        const SizedBox(height: 18),
        SoftPanel(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: canvas, shape: BoxShape.circle, boxShadow: raised(4)),
              child: const Icon(Icons.person_rounded, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hi, ${store.staffName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 3),
                Text('${store.staffRole} · ${store.branch}', style: const TextStyle(color: muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) => GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Fixed height rather than an aspect ratio: the tile content does
            // not shrink, so a narrow column must not squeeze it.
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: box.maxWidth >= 640 ? 4 : 2,
              mainAxisExtent: 108,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            children: [
              _Metric(label: 'Total farmers', value: '${store.farmers.length}', icon: Icons.groups_outlined, color: blue, onTap: onSeeFarmers),
              _Metric(label: 'Verified', value: '${store.verifiedCount}', icon: Icons.verified_outlined, color: accent, onTap: onSeeFarmers),
              _Metric(label: 'Pending docs', value: '${store.pendingDocs}', icon: Icons.pending_actions_outlined, color: warn, onTap: onSeeFarmers),
              _Metric(label: 'Needs review', value: '${store.mismatchCount}', icon: Icons.report_problem_outlined, color: danger, onTap: onSeeReports),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Add new farmer',
          icon: Icons.add_rounded,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddFarmerPage())),
        ),
        const SizedBox(height: 18),
        SoftPanel(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(child: Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 15))),
              TextButton(onPressed: onSeeFarmers, child: const Text('See all', style: TextStyle(color: blue, fontWeight: FontWeight.w700, fontSize: 13))),
            ]),
            const SizedBox(height: 6),
            for (final f in recent) FarmerTile(farmer: f),
          ]),
        ),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon, required this.color, this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SoftTap(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        radius: 20,
        semanticLabel: '$value $label',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 17),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ink, height: 1)),
          const SizedBox(height: 3),
          Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11.5)),
        ]),
      );
}

class FarmerTile extends StatelessWidget {
  const FarmerTile({super.key, required this.farmer});
  final Farmer farmer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SoftTap(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FarmerDetailPage(farmer: farmer))),
        padding: const EdgeInsets.all(13),
        radius: 16,
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFDCE9F7), shape: BoxShape.circle),
            child: Text(farmer.initial, style: const TextStyle(color: blue, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(farmer.name, style: const TextStyle(fontWeight: FontWeight.w700, color: ink, fontSize: 13.5)),
              const SizedBox(height: 3),
              Text('${farmer.village} · ${farmer.pattas.length} patta · ${stageLabels[farmer.stage]}',
                  overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11.5)),
            ]),
          ),
          const SizedBox(width: 8),
          VerificationChip(farmer: farmer),
        ]),
      ),
    );
  }
}
