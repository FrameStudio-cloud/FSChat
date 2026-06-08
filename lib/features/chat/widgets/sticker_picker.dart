import 'package:flutter/material.dart';
import '../models/sticker_model.dart';
import '../services/sticker_service.dart';
import '../screens/sticker_creator_screen.dart';

class StickerPicker extends StatefulWidget {
  final void Function(Sticker sticker) onStickerSelected;

  const StickerPicker({super.key, required this.onStickerSelected});

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  final _service = StickerService.instance;
  int _selectedPackIndex = 0;

  @override
  void initState() {
    super.initState();
    _service.init();
  }

  List<StickerPack> get _allPacks => _service.packs;

  @override
  Widget build(BuildContext context) {
    final packs = _allPacks;
    if (packs.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No sticker packs installed',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create your first sticker'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _openStickerCreator(context);
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedPackIndex >= packs.length) {
      _selectedPackIndex = 0;
    }
    final activePack = packs[_selectedPackIndex];

    return SizedBox(
      height: 320,
      child: Column(
        children: [
          _buildPackBar(packs),
          const Divider(height: 1),
          Expanded(child: _buildStickerGrid(activePack)),
        ],
      ),
    );
  }

  Widget _buildPackBar(List<StickerPack> packs) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: packs.length + 1,
        itemBuilder: (context, index) {
          if (index == packs.length) {
            return IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                Navigator.of(context).pop();
                _openStickerCreator(context);
              },
              tooltip: 'Create sticker',
            );
          }
          final pack = packs[index];
          final isActive = index == _selectedPackIndex;
          final isBuiltIn = pack.isBuiltIn;
          return GestureDetector(
            onTap: () => setState(() => _selectedPackIndex = index),
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                pack.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  fontSize: isBuiltIn ? null : 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickerGrid(StickerPack pack) {
    if (pack.stickers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No stickers in this pack',
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openStickerCreator(context);
              },
              child: const Text('Add stickers'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pack.stickers.length,
      itemBuilder: (context, index) {
        final sticker = pack.stickers[index];
        return GestureDetector(
          onTap: () => widget.onStickerSelected(sticker),
          child: StickerService.stickerPreview(
            sticker.packId,
            sticker.id,
            localPath: sticker.localPath,
          ),
        );
      },
    );
  }

  void _openStickerCreator(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const StickerCreatorScreen()),
    );
    if (result == true && mounted) {
      await _service.refresh();
      setState(() {
        final packs = _allPacks;
        _selectedPackIndex = packs.length - 1;
        for (int i = 0; i < packs.length; i++) {
          if (!packs[i].isBuiltIn) {
            _selectedPackIndex = i;
            break;
          }
        }
      });
    }
  }
}
