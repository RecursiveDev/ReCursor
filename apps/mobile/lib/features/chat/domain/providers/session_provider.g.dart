// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSessionsHash() => r'2a09c0c9f456bc31004a871e0d41ab9398323eae';

/// See also [ActiveSessions].
@ProviderFor(ActiveSessions)
final activeSessionsProvider = AutoDisposeAsyncNotifierProvider<ActiveSessions,
    List<ChatSession>>.internal(
  ActiveSessions.new,
  name: r'activeSessionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveSessions = AutoDisposeAsyncNotifier<List<ChatSession>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
