import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.domain,
    this.size = 128,
  });

  static const _token = 'pk_DUDiRH5gQnO35ZH7tQ6a-g';

  final String domain;
  final double size;

  String get _normalizedDomain {
    var value = domain.trim().toLowerCase();
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    value = value.split('/').first.split('?').first;
    if (value.startsWith('www.')) value = value.substring(4);
    return value;
  }

  Uri get _logoUri {
    final imageSize = size.clamp(1, 800).round();
    return Uri.https('img.logo.dev', '/$_normalizedDomain', {
      'token': _token,
      'format': 'png',
      'size': '$imageSize',
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageSize = size.clamp(1, 800).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: imageSize,
          height: imageSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(imageSize * 0.12),
            child: _normalizedDomain.isEmpty
                ? _fallback(colorScheme)
                : CachedNetworkImage(
                    imageUrl: _logoUri.toString(),
                    fit: BoxFit.contain,
                    placeholder: (_, __) => _loading(colorScheme),
                    errorWidget: (_, __, ___) => _fallback(colorScheme),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => launchUrl(
            Uri.parse('https://logo.dev'),
            mode: LaunchMode.externalApplication,
          ),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              'Logo by Logo.dev',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loading(ColorScheme colorScheme) => Center(
        child: SizedBox(
          width: size * 0.2,
          height: size * 0.2,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      );

  Widget _fallback(ColorScheme colorScheme) => Container(
        alignment: Alignment.center,
        color: colorScheme.surfaceContainerHighest,
        child: Text(
          _normalizedDomain.isEmpty ? '?' : _normalizedDomain[0].toUpperCase(),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}
