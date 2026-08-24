import 'package:flutter/material.dart';

import '../models/premium_entitlement.dart';
import '../models/restaurant_genre.dart';

/// Premium ジャンル選択の結果。
class PremiumGenreSelection {
  const PremiumGenreSelection.omakase() : genre = null;

  const PremiumGenreSelection.genre(this.genre);

  final RestaurantGenre? genre;

  bool get isOmakase => genre == null;
}

/// 大分類 → 詳細分類の2段階 Premium ジャンル選択画面。
class PremiumGenreSelectScreen extends StatefulWidget {
  const PremiumGenreSelectScreen({
    super.key,
    this.entitlement = const PremiumEntitlement.none(),
    this.onGenreSelected,
    this.onPremiumRequested,
  });

  final PremiumEntitlement entitlement;
  final ValueChanged<PremiumGenreSelection>? onGenreSelected;
  final VoidCallback? onPremiumRequested;

  @override
  State<PremiumGenreSelectScreen> createState() =>
      _PremiumGenreSelectScreenState();
}

class _PremiumGenreSelectScreenState extends State<PremiumGenreSelectScreen> {
  RestaurantGenreGroup? selectedGroup;

  bool get hasPremium => widget.entitlement.isPremiumAt();

  void selectGenre(RestaurantGenre genre) {
    if (!hasPremium) {
      showPremiumDialog();
      return;
    }

    final selection = PremiumGenreSelection.genre(genre);
    widget.onGenreSelected?.call(selection);
    if (widget.onGenreSelected == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${RestaurantGenreCatalog.definitionFor(genre).label}で探します',
          ),
        ),
      );
    }
  }

  void selectOmakase() {
    final selection = const PremiumGenreSelection.omakase();
    widget.onGenreSelected?.call(selection);
    if (widget.onGenreSelected == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('おまかせで探します')));
    }
  }

  Future<void> showPremiumDialog() async {
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Premium機能'),
          content: const Text(
            '7日間無料で試せます。\n'
            '無料体験後は、Google Playに表示される料金でPremiumを利用できます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('今はしない'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('無料で試す'),
            ),
          ],
        );
      },
    );

    if (shouldStart == true) {
      widget.onPremiumRequested?.call();
      if (widget.onPremiumRequested == null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ログイン後、無料体験を開始できます')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = selectedGroup == null
        ? const <RestaurantGenreDefinition>[]
        : RestaurantGenreCatalog.detailsFor(selectedGroup!);

    return Scaffold(
      appBar: AppBar(title: const Text('Premiumジャンル')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '何が食べたい？',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            hasPremium
                ? '希望を少し指定して、Swipeatに決めてもらいましょう。'
                : '詳細ジャンルはPremium機能です。おまかせは無料で使えます。',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: selectOmakase,
            icon: const Icon(Icons.shuffle),
            label: const Text('おまかせ'),
          ),
          const SizedBox(height: 20),
          const Text(
            '大分類',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...RestaurantGenreGroup.values.map((group) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: ValueKey<String>('genre-group-${group.name}'),
                style: selectedGroup == group
                    ? OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      )
                    : null,
                onPressed: () {
                  setState(() {
                    selectedGroup = group;
                  });
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(group.label),
                ),
              ),
            );
          }),
          if (selectedGroup != null) ...[
            const SizedBox(height: 20),
            Text(
              '${selectedGroup!.label}の詳細',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...details.map((definition) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => selectGenre(definition.genre),
                  child: Row(
                    children: [
                      Expanded(child: Text(definition.label)),
                      if (!hasPremium) const Icon(Icons.lock_outline, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

extension RestaurantGenreGroupLabels on RestaurantGenreGroup {
  String get label {
    switch (this) {
      case RestaurantGenreGroup.japanese:
        return '和食';
      case RestaurantGenreGroup.noodles:
        return '麺類';
      case RestaurantGenreGroup.meat:
        return '肉料理';
      case RestaurantGenreGroup.western:
        return '洋食';
      case RestaurantGenreGroup.curry:
        return 'カレー';
      case RestaurantGenreGroup.chineseAsian:
        return '中華・アジア';
      case RestaurantGenreGroup.cafeLightOther:
        return 'カフェ・軽食';
    }
  }
}
