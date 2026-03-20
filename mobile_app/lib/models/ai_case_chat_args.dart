class AiCaseChatArgs {
  final String module;
  final String title;
  final Map<String, dynamic> context;
  final String? imagePath;

  const AiCaseChatArgs({
    required this.module,
    required this.title,
    required this.context,
    this.imagePath,
  });
}
