// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_battery_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BatteryNotifier)
final batteryProvider = BatteryNotifierProvider._();

final class BatteryNotifierProvider
    extends $NotifierProvider<BatteryNotifier, BatteryState> {
  BatteryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batteryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batteryNotifierHash();

  @$internal
  @override
  BatteryNotifier create() => BatteryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatteryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatteryState>(value),
    );
  }
}

String _$batteryNotifierHash() => r'06bc81ce38fc43b243e7dfe7f5440aeff1522779';

abstract class _$BatteryNotifier extends $Notifier<BatteryState> {
  BatteryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BatteryState, BatteryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BatteryState, BatteryState>,
              BatteryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
