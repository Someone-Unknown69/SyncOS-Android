// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pairing_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PairingNotifier)
final pairingProvider = PairingNotifierProvider._();

final class PairingNotifierProvider
    extends $NotifierProvider<PairingNotifier, bool> {
  PairingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pairingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pairingNotifierHash();

  @$internal
  @override
  PairingNotifier create() => PairingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pairingNotifierHash() => r'e746a01e4a76a51fb947054d99ebd267608119bc';

abstract class _$PairingNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
