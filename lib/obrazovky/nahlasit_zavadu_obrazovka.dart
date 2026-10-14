import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class NahlasitZavaduObrazovka extends StatefulWidget {
  const NahlasitZavaduObrazovka({
    super.key,
    required this.adresaApi,
    required this.token,
  });

  final Uri adresaApi;
  final String token;

  @override
  State<NahlasitZavaduObrazovka> createState() => _StavNahlaseniaZavadyObrazovky();
}

class _StavNahlaseniaZavadyObrazovky extends State<NahlasitZavaduObrazovka> {
  final _klucFormulara = GlobalKey<FormState>();
  final _ovladacNadpisu = TextEditingController();
  final _ovladacPopisu = TextEditingController();
  final _vyberacObrazkov = ImagePicker();

  String _naliehavost = 'STREDNA';
  XFile? _fotografia;
  bool _odosielaSa = false;

  @override
  void dispose() {
    _ovladacNadpisu.dispose();
    _ovladacPopisu.dispose();
    super.dispose();
  }

  String? _overitNadpis(String? hodnota) {
    if (hodnota == null || hodnota.trim().isEmpty) {
      return 'Zadajte nadpis závady.';
    }
    if (hodnota.trim().length > 255) {
      return 'Nadpis môže mať najviac 255 znakov.';
    }
    return null;
  }

  String? _overitPopis(String? hodnota) {
    if (hodnota == null || hodnota.trim().isEmpty) {
      return 'Opíšte nahlasovanú poruchu.';
    }
    return null;
  }

  Future<void> _vybratFotografiu() async {
    final zdroj = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (kontext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Odfotiť'),
              onTap: () => Navigator.pop(kontext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Vybrať z galérie'),
              onTap: () => Navigator.pop(kontext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (zdroj == null) {
      return;
    }

    try {
      final fotografia = await _vyberacObrazkov.pickImage(
        source: zdroj,
        imageQuality: 88,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (fotografia == null || !mounted) {
        return;
      }

      final velkost = await fotografia.length();
      if (velkost > 5 * 1024 * 1024) {
        _zobrazitSpravu('Fotografia musí mať veľkosť najviac 5 MB.', chyba: true);
        return;
      }

      setState(() => _fotografia = fotografia);
    } catch (_) {
      if (mounted) {
        _zobrazitSpravu('Fotografiu sa nepodarilo načítať. Skúste to znova.', chyba: true);
      }
    }
  }

  Future<void> _odoslatNahlasenie() async {
    if (!_klucFormulara.currentState!.validate()) {
      return;
    }

    setState(() => _odosielaSa = true);

    try {
      final poziadavka = http.MultipartRequest(
        'POST',
        widget.adresaApi.resolve('/api/zavady_nahlasit.php'),
      )
        ..headers['Authorization'] = 'Bearer ${widget.token}'
        ..headers['Accept'] = 'application/json'
        ..fields['nadpis'] = _ovladacNadpisu.text.trim()
        ..fields['popis'] = _ovladacPopisu.text.trim()
        ..fields['naliehavost'] = _naliehavost;

      if (_fotografia != null) {
        poziadavka.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            _fotografia!.path,
          ),
        );
      }

      final odoslana = await poziadavka.send().timeout(const Duration(seconds: 60));
      final odpoved = await http.Response.fromStream(odoslana)
          .timeout(const Duration(seconds: 15));
      dynamic obsah;
      try {
        obsah = jsonDecode(utf8.decode(odpoved.bodyBytes));
      } on FormatException {
        throw const ChybaNahlasenia('Server vrátil neplatnú odpoveď.');
      }

      final sprava = obsah is Map<String, dynamic> && obsah['sprava'] is String
          ? obsah['sprava'] as String
          : 'Hlásenie sa nepodarilo spracovať.';

      if (!mounted) {
        return;
      }

      if (odpoved.statusCode == 201) {
        _klucFormulara.currentState!.reset();
        _ovladacNadpisu.clear();
        _ovladacPopisu.clear();
        setState(() {
          _fotografia = null;
          _naliehavost = 'STREDNA';
        });

        final spravcaHlaseni = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        spravcaHlaseni
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(sprava),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade700,
            ),
          );
      } else {
        _zobrazitSpravu(sprava, chyba: true);
      }
    } on ChybaNahlasenia catch (vynimka) {
      if (mounted) {
        _zobrazitSpravu(vynimka.sprava, chyba: true);
      }
    } on SocketException {
      if (mounted) {
        _zobrazitSpravu('Nepodarilo sa pripojiť k serveru. Skontrolujte internetové pripojenie.', chyba: true);
      }
    } catch (_) {
      if (mounted) {
        _zobrazitSpravu('Nahlásenie sa nepodarilo odoslať. Skúste to znova.', chyba: true);
      }
    } finally {
      if (mounted) {
        setState(() => _odosielaSa = false);
      }
    }
  }

  void _zobrazitSpravu(String sprava, {required bool chyba}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(sprava),
          behavior: SnackBarBehavior.floating,
          backgroundColor: chyba ? Theme.of(context).colorScheme.error : Colors.green.shade700,
        ),
      );
  }

  InputDecoration _vzhledPola(String nazov, IconData ikona) {
    return InputDecoration(
      labelText: nazov,
      prefixIcon: Icon(ikona),
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farby = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Nahlásiť závadu')),
        body: SafeArea(
          child: Form(
            key: _klucFormulara,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Čo sa v dome pokazilo?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Opíšte problém. Správca dostane vaše hlásenie a bude ho môcť začať riešiť.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: farby.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _ovladacNadpisu,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 255,
                  decoration: _vzhledPola('Nadpis', Icons.title),
                  validator: _overitNadpis,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ovladacPopisu,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 7,
                  decoration: _vzhledPola('Popis poruchy', Icons.description_outlined),
                  validator: _overitPopis,
                ),
                const SizedBox(height: 20),
                DropdownMenu<String>(
                  initialSelection: _naliehavost,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Naliehavosť'),
                  leadingIcon: const Icon(Icons.priority_high),
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'NIZKA', label: 'Nízka'),
                    DropdownMenuEntry(value: 'STREDNA', label: 'Stredná'),
                    DropdownMenuEntry(value: 'VYSOKA', label: 'Vysoká'),
                  ],
                  onSelected: (hodnota) {
                    if (hodnota != null) {
                      setState(() => _naliehavost = hodnota);
                    }
                  },
                ),
                const SizedBox(height: 24),
                Text('Fotografia', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _odosielaSa ? null : _vybratFotografiu,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Odfotiť / Vybrať fotku'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                if (_fotografia != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_fotografia!.path),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (kontext, chyba, zasobnik) => Container(
                        height: 140,
                        color: farby.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Text('Náhľad fotografie sa nepodarilo zobraziť.'),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _odosielaSa ? null : () => setState(() => _fotografia = null),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Odstrániť fotografiu'),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _odosielaSa ? null : _odoslatNahlasenie,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _odosielaSa
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Odoslať nahlásenie'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChybaNahlasenia implements Exception {
  const ChybaNahlasenia(this.sprava);

  final String sprava;
}
