import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as poziadavkyHttp;

class PrehladObrazovka extends StatefulWidget {
  const PrehladObrazovka({
    super.key,
    required this.adresaApi,
    required this.token,
  });

  final Uri adresaApi;
  final String token;

  @override
  State<PrehladObrazovka> createState() => _StavPrehladuObrazovky();
}

class _StavPrehladuObrazovky extends State<PrehladObrazovka> {
  bool _nacitaSa = true;
  String? _chyba;
  List<Map<String, dynamic>> _oznamy = [];
  Map<String, dynamic>? _odvoz;

  @override
  void initState() {
    super.initState();
    _nacitatPrehlad();
  }

  Future<void> _nacitatPrehlad() async {
    setState(() {
      _nacitaSa = true;
      _chyba = null;
    });

    try {
      final hlavicky = {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      };

      final odpovede = await Future.wait([
        poziadavkyHttp.get(
          widget.adresaApi.resolve('/api/oznamy.php'),
          headers: hlavicky,
        ),
        poziadavkyHttp.get(
          widget.adresaApi.resolve('/api/smeti_najblizsie.php'),
          headers: hlavicky,
        ),
      ]);

      final nacitaneOznamy = _spracovatOznamy(odpovede[0]);
      final nacitanyOdvoz = _spracovatOdvoz(odpovede[1]);

      if (!mounted) {
        return;
      }

      setState(() {
        _oznamy = nacitaneOznamy;
        _odvoz = nacitanyOdvoz;
        _nacitaSa = false;
      });
    } on ChybaApi catch (vynimka) {
      if (!mounted) {
        return;
      }
      setState(() {
        _chyba = vynimka.sprava;
        _nacitaSa = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _chyba = 'Prehľad sa nepodarilo načítať. Skontrolujte pripojenie a skúste to znova.';
        _nacitaSa = false;
      });
    }
  }

  List<Map<String, dynamic>> _spracovatOznamy(poziadavkyHttp.Response odpoved) {
    if (odpoved.statusCode != 200) {
      throw ChybaApi(_spravaChyby(odpoved));
    }

    final dynamic obsah = jsonDecode(odpoved.body);
    if (obsah is! List) {
      throw const FormatException('Odpoveď oznamov nemá správny formát.');
    }

    return obsah.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Map<String, dynamic>? _spracovatOdvoz(poziadavkyHttp.Response odpoved) {
    if (odpoved.statusCode != 200) {
      throw ChybaApi(_spravaChyby(odpoved));
    }

    final dynamic obsah = jsonDecode(odpoved.body);
    if (obsah == null) {
      return null;
    }
    if (obsah is! Map<String, dynamic>) {
      throw const FormatException('Odpoveď odvozu nemá správny formát.');
    }

    return obsah;
  }

  String _spravaChyby(poziadavkyHttp.Response odpoved) {
    try {
      final dynamic obsah = jsonDecode(odpoved.body);
      if (obsah is Map<String, dynamic> && obsah['sprava'] is String) {
        return obsah['sprava'] as String;
      }
    } on FormatException {
      return 'Server vrátil neplatnú odpoveď.';
    }

    return odpoved.statusCode == 401
        ? 'Prihlásenie vypršalo. Prihláste sa znova.'
        : 'Dáta sa nepodarilo načítať. Skúste to znova.';
  }

  Color _farbaOdpadu(String typOdpadu) {
    switch (typOdpadu) {
      case 'PLAST':
        return const Color(0xFFFDE68A);
      case 'PAPIER':
        return const Color(0xFFBFDBFE);
      case 'BIO':
        return const Color(0xFFBBF7D0);
      case 'KOMUNAL':
        return const Color(0xFF374151);
      case 'SKLO':
        return const Color(0xFFA7F3D0);
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color _farbaTextuOdpadu(String typOdpadu) {
    return typOdpadu == 'KOMUNAL' ? Colors.white : const Color(0xFF1F2937);
  }

  String _nazovOdpadu(String typOdpadu) {
    const nazvy = {
      'KOMUNAL': 'Komunálny odpad',
      'PLAST': 'Plast',
      'PAPIER': 'Papier',
      'SKLO': 'Sklo',
      'BIO': 'Bioodpad',
    };
    return nazvy[typOdpadu] ?? 'Odvoz odpadu';
  }

  String _slovenskyDatum(Object? hodnota) {
    if (hodnota is! String) {
      return 'Dátum nie je dostupný';
    }

    final datum = DateTime.tryParse(hodnota);
    if (datum == null) {
      return 'Dátum nie je dostupný';
    }

    final dnes = DateTime.now();
    final datumLen = DateTime(datum.year, datum.month, datum.day);
    final dnesLen = DateTime(dnes.year, dnes.month, dnes.day);
    final zajtraLen = dnesLen.add(const Duration(days: 1));

    if (datumLen == dnesLen) {
      return 'Dnes';
    }
    if (datumLen == zajtraLen) {
      return 'Zajtra';
    }

    final den = datum.day.toString().padLeft(2, '0');
    final mesiac = datum.month.toString().padLeft(2, '0');
    return '$den.$mesiac.${datum.year}';
  }

  String _slovenskyDatumOznamu(Object? hodnota) {
    if (hodnota is! String) {
      return '';
    }

    final datum = DateTime.tryParse(hodnota);
    if (datum == null) {
      return '';
    }

    final den = datum.day.toString().padLeft(2, '0');
    final mesiac = datum.month.toString().padLeft(2, '0');
    final hodina = datum.hour.toString().padLeft(2, '0');
    final minuta = datum.minute.toString().padLeft(2, '0');
    return '$den.$mesiac.${datum.year} o $hodina:$minuta';
  }

  Widget _kartaOdvozu() {
    if (_odvoz == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.event_available, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Najbližší odvoz smetí', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Momentálne nie je naplánovaný žiadny odvoz.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final typOdpadu = _odvoz!['typ_odpadu'] is String ? _odvoz!['typ_odpadu'] as String : '';
    final farbaTextu = _farbaTextuOdpadu(typOdpadu);
    final poznamka = _odvoz!['poznamka'] is String ? (_odvoz!['poznamka'] as String).trim() : '';

    return Card(
      color: _farbaOdpadu(typOdpadu),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.delete_outline, size: 34, color: farbaTextu),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Najbližší odvoz smetí', style: TextStyle(color: farbaTextu.withOpacity(0.75))),
                  const SizedBox(height: 6),
                  Text(
                    _nazovOdpadu(typOdpadu),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: farbaTextu,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _slovenskyDatum(_odvoz!['datum_vyvozu']),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: farbaTextu,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (poznamka.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(poznamka, style: TextStyle(color: farbaTextu)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartaOznamu(Map<String, dynamic> oznam) {
    final nadpis = oznam['nadpis'] is String ? oznam['nadpis'] as String : 'Oznam';
    final obsah = oznam['obsah'] is String ? oznam['obsah'] as String : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nadpis,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (_slovenskyDatumOznamu(oznam['datum_vytvorenia']).isNotEmpty)
              Text(
                _slovenskyDatumOznamu(oznam['datum_vytvorenia']),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            if (obsah.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                obsah,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farby = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prehľad domu'),
          actions: [
            IconButton(
              onPressed: _nacitaSa ? null : _nacitatPrehlad,
              tooltip: 'Obnoviť prehľad',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: _nacitaSa
              ? const Center(child: CircularProgressIndicator())
              : _chyba != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_outlined, size: 48, color: farby.error),
                            const SizedBox(height: 16),
                            Text(_chyba!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _nacitatPrehlad,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Skúsiť znova'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _nacitatPrehlad,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _kartaOdvozu(),
                          const SizedBox(height: 20),
                          Text(
                            'Dôležité oznamy',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_oznamy.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('Zatiaľ nie sú zverejnené žiadne oznamy.'),
                              ),
                            )
                          else
                            ListView.builder(
                              itemCount: _oznamy.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (kontext, poradie) => _kartaOznamu(_oznamy[poradie]),
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class ChybaApi implements Exception {
  const ChybaApi(this.sprava);

  final String sprava;
}
