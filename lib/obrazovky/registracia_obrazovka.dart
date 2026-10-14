import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class RegistraciaObrazovka extends StatefulWidget {
  const RegistraciaObrazovka({
    super.key,
    required this.adresaApi,
    required this.vytvoritPrihlasovaciuObrazovku,
  });

  final Uri adresaApi;
  final WidgetBuilder vytvoritPrihlasovaciuObrazovku;

  @override
  State<RegistraciaObrazovka> createState() => _StavRegistracnejObrazovky();
}

class _StavRegistracnejObrazovky extends State<RegistraciaObrazovka> {
  final _klucFormulara = GlobalKey<FormState>();
  final _ovladacMena = TextEditingController();
  final _ovladacPriezviska = TextEditingController();
  final _ovladacEmailu = TextEditingController();
  final _ovladacHesla = TextEditingController();
  final _ovladacKodu = TextEditingController();

  bool _odosielaSa = false;
  bool _hesloJeSkryte = true;

  @override
  void dispose() {
    _ovladacMena.dispose();
    _ovladacPriezviska.dispose();
    _ovladacEmailu.dispose();
    _ovladacHesla.dispose();
    _ovladacKodu.dispose();
    super.dispose();
  }

  String? _overitPovinnePole(String? hodnota, String nazovPola) {
    if (hodnota == null || hodnota.trim().isEmpty) {
      return 'Vyplňte pole: $nazovPola.';
    }

    return null;
  }

  String? _overitEmail(String? hodnota) {
    final chyba = _overitPovinnePole(hodnota, 'e-mail');
    if (chyba != null) {
      return chyba;
    }

    final email = hodnota!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Zadajte platnú e-mailovú adresu.';
    }

    return null;
  }

  String? _overitHeslo(String? hodnota) {
    final chyba = _overitPovinnePole(hodnota, 'heslo');
    if (chyba != null) {
      return chyba;
    }

    if (hodnota!.length < 8 || utf8.encode(hodnota).length > 72) {
      return 'Heslo musí mať aspoň 8 znakov a najviac 72 bajtov.';
    }

    return null;
  }

  String? _overitKod(String? hodnota) {
    final chyba = _overitPovinnePole(hodnota, 'pozývací kód');
    if (chyba != null) {
      return chyba;
    }

    if (!RegExp(r'^[A-HJ-NP-Z2-9]{6}$').hasMatch(hodnota!.trim().toUpperCase())) {
      return 'Kód musí obsahovať 6 platných znakov.';
    }

    return null;
  }

  Future<void> _odoslatRegistraciu() async {
    if (!_klucFormulara.currentState!.validate()) {
      return;
    }

    setState(() => _odosielaSa = true);

    try {
      final odpoved = await http.post(
        widget.adresaApi.resolve('/api/registracia.php'),
        headers: const {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'meno': _ovladacMena.text.trim(),
          'priezvisko': _ovladacPriezviska.text.trim(),
          'email': _ovladacEmailu.text.trim(),
          'heslo': _ovladacHesla.text,
          'registracny_kod': _ovladacKodu.text.trim().toUpperCase(),
        }),
      );

      final dynamic telo = jsonDecode(odpoved.body);
      final sprava = telo is Map<String, dynamic> && telo['sprava'] is String
          ? telo['sprava'] as String
          : 'Server vrátil neočakávanú odpoveď.';

      if (!mounted) {
        return;
      }

      if (odpoved.statusCode == 201) {
        final spravcaHlaseni = ScaffoldMessenger.of(context);
        spravcaHlaseni
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(sprava),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade700,
            ),
          );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: widget.vytvoritPrihlasovaciuObrazovku,
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(sprava),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      }
    } on FormatException {
      if (mounted) {
        _zobrazitChybu('Server vrátil neplatnú odpoveď.');
      }
    } catch (_) {
      if (mounted) {
        _zobrazitChybu('Registráciu sa nepodarilo odoslať. Skontrolujte pripojenie a skúste to znova.');
      }
    } finally {
      if (mounted) {
        setState(() => _odosielaSa = false);
      }
    }
  }

  void _zobrazitChybu(String sprava) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(sprava),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  InputDecoration _vzhledPola(String nazov, IconData ikona) {
    return InputDecoration(
      labelText: nazov,
      prefixIcon: Icon(ikona),
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farby = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrácia vlastníka')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 0,
                  color: farby.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: farby.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _klucFormulara,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.apartment_rounded, size: 42, color: farby.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Vytvorte si účet',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Na registráciu použite pozývací kód od správcu vášho domu.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: farby.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _ovladacMena,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: _vzhledPola('Meno', Icons.person_outline),
                            validator: (hodnota) => _overitPovinnePole(hodnota, 'meno'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ovladacPriezviska,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.familyName],
                            decoration: _vzhledPola('Priezvisko', Icons.person_outline),
                            validator: (hodnota) => _overitPovinnePole(hodnota, 'priezvisko'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ovladacEmailu,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            decoration: _vzhledPola('E-mail', Icons.email_outlined),
                            validator: _overitEmail,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ovladacHesla,
                            obscureText: _hesloJeSkryte,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: _vzhledPola('Heslo', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                tooltip: _hesloJeSkryte ? 'Zobraziť heslo' : 'Skryť heslo',
                                onPressed: () => setState(() => _hesloJeSkryte = !_hesloJeSkryte),
                                icon: Icon(_hesloJeSkryte ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: _overitHeslo,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ovladacKodu,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[A-HJ-NP-Z2-9a-hj-np-z]')),
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: _vzhledPola('6-miestny pozývací kód', Icons.confirmation_number_outlined),
                            validator: _overitKod,
                            onFieldSubmitted: (_) {
                              if (!_odosielaSa) {
                                _odoslatRegistraciu();
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _odosielaSa ? null : _odoslatRegistraciu,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _odosielaSa
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Vytvoriť účet'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
