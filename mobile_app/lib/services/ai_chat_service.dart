import '../core/constants/api_constants.dart';
import '../models/response_model.dart';
import 'api_service.dart';

class AiChatSvc {
  static final AiChatSvc _i = AiChatSvc._();
  factory AiChatSvc() => _i;
  AiChatSvc._();

  Future<Res<Map<String, dynamic>>> askCase({
    required String module,
    required String question,
    required Map<String, dynamic> context,
    required String language,
  }) {
    return ApiSvc().post(ApiK.chatCase, {
      'module': module,
      'question': question,
      'context': context,
      'language': language,
    });
  }
}
