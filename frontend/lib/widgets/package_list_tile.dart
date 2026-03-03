import 'package:flutter/material.dart';

import '../models/package_info.dart';

class PackageListTile extends StatelessWidget {
  final PackageInfo package;

  const PackageListTile({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(package.name),
      subtitle: Text('${package.currentVersion} → ${package.targetVersion}'),
      trailing: package.currentVersion != package.targetVersion
          ? Icon(Icons.arrow_upward,
              color: Theme.of(context).colorScheme.primary)
          : Icon(Icons.check,
              color: Theme.of(context).colorScheme.tertiary),
    );
  }
}
