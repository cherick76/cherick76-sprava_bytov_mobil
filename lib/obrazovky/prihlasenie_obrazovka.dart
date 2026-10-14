import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../sluzby/ulozisko_tokena.dart';
import 'prehlad_obrazovka.dart';

class PrihlasenieObrazovka extends StatefulWidget {
  const PrihlasenieObrazovka({
    super.key,
    required this.adresaApi,
    required this.uloziskoTokena,
  });

  final Uri adresaApi;
  final UloziskoTokena uloziskoTokena;

  @override
  State<PrihlasenieObrazovka> createState() => _StavPrihlaseniaObrazovky();
}

class _StavPrihlaseniaObrazovky extends State<PrihlasenieObrazovka> {
  final _klucFormulara = GlobalKey<FormState>();
  final _ovladacEmailu = TextEditingController();
  final _ovladacHesla = TextEditingController();
  bool _odosielaSa = false;
  bool _hesloJeSkryte = true;

  @override
  void dispose() {
    _ovladacEmailu.dispose();
    _ovladacHesla.dispose();
    super.dispose();
  }

  Future<void> _prihlasitSa() async {
    if (!_klucFormulara.currentState!.validate()) {
      return;
    }

    setState(() => _odosielaSa = true);
    try {
      final odpoved = await http.post(
        widget.adresaApi.resolve('/api/prihlasenie.php'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'email': _ovladacEmailu.text.trim(),
          'heslo': _ovladacHesla.text,
        }),
      );

      final dynamic telo = jsonDecode(odpoved.body);
      final token = telo is Map<String, dynamic> ? telo['token'] : null;
      if (odpoved.statusCode != 200 || token is! String || token.isEmpty) {
        final chyba = telo is Map<String, dynamic>
            ? telo['chyba'] ?? telo['sprava']
            : null;
        throw StateError(
          chyba is String ? chyba : 'Prihlásenie sa nepodarilo.',
        );
      }

      await widget.uloziskoTokena.ulozit(token);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => PrehladObrazovka(
            adresaApi: widget.adresaApi,
            token: token,
          ),
        ),
        (_) => false,
      );
    } on FormatException {
      _zobrazitSpravu('Server vrátil neplatnú odpoveď.');
    } on StateError catch (vynimka) {
      _zobrazitSpravu(vynimka.message.toString());
    } catch (_) {
      _zobrazitSpravu(
        'Prihlásenie sa nepodarilo. Skontrolujte pripojenie a skúste to znova.',
      );
    } finally {
      if (mounted) {
        setState(() => _odosielaSa = false);
      }
    }
  }

  void _zobrazitSpravu(String sprava) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(sprava),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prihlásenie vlastníka')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _klucFormulara,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Vitajte späť',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _ovladacEmailu,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (hodnota) {
                        final email = hodnota?.trim() ?? '';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                          return 'Zadajte platnú e-mailovú adresu.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ovladacHesla,
                      obscureText: _hesloJeSkryte,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Heslo',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip:
                              _hesloJeSkryte ? 'Zobraziť heslo' : 'Skryť heslo',
                          onPressed: () => setState(
                            () => _hesloJeSkryte = !_hesloJeSkryte,
                          ),
                          icon: Icon(
                            _hesloJeSkryte
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (hodnota) => hodnota == null || hodnota.isEmpty
                          ? 'Zadajte heslo.'
                          : null,
                      onFieldSubmitted: (_) {
                        if (!_odosielaSa) {
                          _prihlasitSa();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _odosielaSa ? null : _prihlasitSa,
                      child: _odosielaSa
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Prihlásiť sa'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
