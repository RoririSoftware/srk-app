import 'package:flutter/material.dart';

import '../match.dart';
import '../store.dart';
import '../ui.dart';
import 'add_farmer.dart';
import 'home.dart';

class FarmersPage extends StatefulWidget {
  const FarmersPage({super.key});

  @override
  State<FarmersPage> createState() => _FarmersPageState();
}

class _FarmersPageState extends State<FarmersPage> {
  final _search = TextEditingController();
  String _filter = 'All';

  static const _filters = ['All', 'Verified', 'Review', 'Pending'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = normalise(_search.text);
    final list = store.farmers.where((f) {
      final matchesFilter = switch (_filter) {
        'Verified' => f.verified == true,
        'Review' => f.verified == false,
        'Pending' => f.verified == null,
        _ => true,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      final haystack = normalise('${f.name} ${f.village} ${f.mobile} ${f.id} ${f.district}');
      return haystack.contains(q);
    }).toList();

    return PageScroll(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeading(
          eyebrow: 'FARMER DIRECTORY',
          title: 'Farmers',
          subtitle: '${store.farmers.length} records in this branch.',
          action: SizedBox(
            width: 150,
            child: PrimaryButton(
              label: 'Add farmer',
              icon: Icons.add_rounded,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddFarmerPage())),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SoftFieldWell(
          child: SoftField(
            controller: _search,
            label: 'Search by name, village, mobile or lead ID',
            icon: Icons.search_rounded,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in _filters)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SoftTap(
                  onTap: () => setState(() => _filter = f),
                  radius: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(f,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: _filter == f ? accent : muted)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          SoftPanel(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(children: [
              const Icon(Icons.person_search_outlined, color: muted, size: 34),
              const SizedBox(height: 12),
              const Text('No farmers match this search', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 5),
              const Text('Try a different name, village or clear the filter.',
                  textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12.5)),
            ]),
          )
        else
          for (final f in list) FarmerTile(farmer: f),
        const SizedBox(height: 20),
      ]),
    );
  }
}
