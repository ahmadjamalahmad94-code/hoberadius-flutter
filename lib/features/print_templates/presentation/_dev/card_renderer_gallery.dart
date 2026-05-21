/// Developer-only screen showing the SVG output of every web preset.
///
/// Mounted at `/_card-gallery` (only when [PlatformCapabilities.isDesktop]
/// or in debug builds). Useful for visual regression diffing against
/// the same gallery in the web admin's `/_gallery` page.
library;

import 'package:flutter/material.dart';

import '../../domain/card_render_model.dart';
import '../../domain/card_render_model_builder.dart';
import '../widgets/card_svg_view.dart';

/// The ten built-in presets — keys and copy match the Python
/// `_PRINT_PRESETS` dict.
const galleryPresets = <Map<String, dynamic>>[
  {
    'key': 'modern',
    'label': 'حديث',
    'gradient_start': '#0f172a',
    'gradient_end': '#22a7bd',
    'accent_color': '#f59e0b',
    'card_title': 'Internet Card',
  },
  {
    'key': 'dark',
    'label': 'داكن احترافي',
    'gradient_start': '#020617',
    'gradient_end': '#1e293b',
    'accent_color': '#38bdf8',
    'card_title': 'Hotspot Voucher',
  },
  {
    'key': 'gold',
    'label': 'ذهبي',
    'gradient_start': '#92400e',
    'gradient_end': '#fbbf24',
    'accent_color': '#facc15',
    'card_title': 'Premium Card',
  },
  {
    'key': 'minimal',
    'label': 'بسيط',
    'gradient_start': '#ffffff',
    'gradient_end': '#e5e7eb',
    'accent_color': '#0ea5e9',
    'card_title': 'Access Card',
    'text_color': '#0f172a',
  },
  {
    'key': 'telecom',
    'label': 'اتصالات',
    'gradient_start': '#155e75',
    'gradient_end': '#22d3ee',
    'accent_color': '#facc15',
    'card_title': 'WiFi Access',
  },
  {
    'key': 'neon',
    'label': 'نيون',
    'gradient_start': '#1e1b4b',
    'gradient_end': '#22d3ee',
    'accent_color': '#fde047',
    'card_title': 'Speed Card',
  },
  {
    'key': 'aurora',
    'label': 'Aurora',
    'gradient_start': '#172554',
    'gradient_end': '#14b8a6',
    'accent_color': '#f472b6',
    'card_title': 'Smart WiFi Pass',
  },
  {
    'key': 'fiber',
    'label': 'Fiber Pro',
    'gradient_start': '#0c1e3a',
    'gradient_end': '#1d4ed8',
    'accent_color': '#facc15',
    'card_title': 'Fiber Speed',
  },
  {
    'key': 'sunset',
    'label': 'Sunset',
    'gradient_start': '#7f1d1d',
    'gradient_end': '#ec4899',
    'accent_color': '#fde047',
    'card_title': 'Sunset Hotspot',
  },
  {
    'key': 'matrix',
    'label': 'Matrix',
    'gradient_start': '#022c22',
    'gradient_end': '#0f172a',
    'accent_color': '#22c55e',
    'card_title': 'Matrix Access',
  },
];

class CardRendererGalleryScreen extends StatelessWidget {
  const CardRendererGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Renderer Gallery'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisExtent: 260,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: galleryPresets.length,
        itemBuilder: (_, i) => _PresetTile(preset: galleryPresets[i]),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.preset});
  final Map<String, dynamic> preset;

  @override
  Widget build(BuildContext context) {
    final template = {
      'id': 1,
      'username_x': 0,
      'username_y': 0,
      'password_x': 0,
      'password_y': 0,
      'qr_x': 0,
      'qr_y': 0,
      'layout_json': <String, dynamic>{
        'card_orientation': 'horizontal',
        'card_width_mm': 85,
        'card_height_mm': 54,
        'design_preset': preset['key'],
        'brand_name': 'HobeRadius',
        'card_title': preset['card_title'],
        'footer_text': 'Keep login data until expiry',
        'hotspot_address': 'hotspot.local',
        'pattern_style': 'signal',
        'gradient_start': preset['gradient_start'],
        'gradient_end': preset['gradient_end'],
        'accent_color': preset['accent_color'],
        'text_color': preset['text_color'] ?? '#ffffff',
        'surface_color': '#e8f7fb',
        'show_brand': true,
        'show_username': true,
        'show_password': true,
        'show_qr': true,
        'show_hotspot': true,
        'show_serial': true,
      },
    };
    final model = buildCardRenderModel(
      template,
      card: const {'id': 1, 'username': 'CARD1234', 'password': 'pw1234'},
    );
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 5 / 3,
                child: CardSvgView(model: model),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${preset['label']}  ·  ${preset['key']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Build a [CardRenderModel] for a preset key — convenience for tests.
CardRenderModel modelForPresetTest(String key) {
  final preset = galleryPresets.firstWhere(
    (p) => p['key'] == key,
    orElse: () => galleryPresets.first,
  );
  return buildCardRenderModel(
    {
      'id': 1,
      'username_x': 0,
      'username_y': 0,
      'password_x': 0,
      'password_y': 0,
      'qr_x': 0,
      'qr_y': 0,
      'layout_json': {
        'card_orientation': 'horizontal',
        'card_width_mm': 85,
        'card_height_mm': 54,
        'gradient_start': preset['gradient_start'],
        'gradient_end': preset['gradient_end'],
        'accent_color': preset['accent_color'],
        'text_color': preset['text_color'] ?? '#ffffff',
        'surface_color': '#e8f7fb',
        'brand_name': 'HobeRadius',
        'card_title': preset['card_title'],
        'footer_text': 'Keep login data until expiry',
        'hotspot_address': 'hotspot.local',
        'pattern_style': 'signal',
        'show_brand': true,
        'show_username': true,
        'show_password': true,
        'show_qr': true,
        'show_hotspot': true,
        'show_serial': true,
      },
    },
    card: const {'id': 1, 'username': 'CARD1234', 'password': 'pw1234'},
  );
}
