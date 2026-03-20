import '../../../../core/models/message_models.dart';

const observedHookSourceKey = '__recursor_source';

bool isObservedHookApproval(ToolCall toolCall) {
  return toolCall.params[observedHookSourceKey] == 'hooks';
}

Map<String, dynamic> visibleApprovalParams(ToolCall toolCall) {
  return toolCall.params.map((key, value) => MapEntry(key, value))
    ..removeWhere((key, _) => key.startsWith('__recursor_'));
}
