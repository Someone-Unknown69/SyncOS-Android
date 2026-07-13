// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_transfer_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FileTransferNotifier)
final fileTransferState = FileTransferNotifierProvider._();

final class FileTransferNotifierProvider
    extends $NotifierProvider<FileTransferNotifier, FileTransferState> {
  FileTransferNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileTransferState',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileTransferNotifierHash();

  @$internal
  @override
  FileTransferNotifier create() => FileTransferNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileTransferState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileTransferState>(value),
    );
  }
}

String _$fileTransferNotifierHash() =>
    r'6609e584ecd6855fcfa56a571a12b54ae6856ebe';

abstract class _$FileTransferNotifier extends $Notifier<FileTransferState> {
  FileTransferState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FileTransferState, FileTransferState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FileTransferState, FileTransferState>,
              FileTransferState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
