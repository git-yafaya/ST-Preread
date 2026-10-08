import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/mock_provider_bindings.dart';
import 'app/st_preread_app.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: buildMockProviderBindings(),
      child: const StPrereadApp(),
    ),
  );
}
