// lib/presentation/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../../core/services/chatbot_service.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/preference_repository.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/chat_session_model.dart';
import '../../../data/models/preference_model.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String? sessionId;

  const ChatScreen({
    super.key,
    this.sessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  final ChatRepository _chatRepository = ChatRepository();
  final PreferenceRepository _preferenceRepository = PreferenceRepository();

  String? _currentSessionId;
  bool _isTyping = false;
  bool _isInitialized = false;
  PreferenceModel? _userPreferences;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    try {
      // Cargar preferencias del usuario
      _userPreferences = await _preferenceRepository.getPreferences(user.uid);

      // Si no hay sessionId, crear una nueva sesión
      if (_currentSessionId == null) {
        final userContext = {
          'userName': user.displayName ?? 'Usuario',
          'hasAnalysis': {
            'face': user.hasFaceAnalysis,
            'body': user.hasBodyAnalysis,
          },
          'preferences': _userPreferences?.toFirestore(),
        };

        _currentSessionId = await _chatRepository.createChatSession(
          user.uid,
          'Nueva conversación',
          userContext,
        );

        // Enviar mensaje de bienvenida
        await _sendWelcomeMessage(user);
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error inicializando chat: $e');
      _showErrorSnackBar('Error al inicializar el chat');
    }
  }

  Future<void> _sendWelcomeMessage(user) async {
    if (_currentSessionId == null) return;

    setState(() {
      _isTyping = true;
    });

    try {
      final welcomeResponse = await _chatbotService.startConversation(
        user,
        _userPreferences,
      );

      final assistantMessage = ChatMessageModel.assistant(
        userId: user.uid,
        content: welcomeResponse,
        metadata: {'isWelcome': true},
      );

      await _chatRepository.saveChatMessage(_currentSessionId!, assistantMessage);
    } catch (e) {
      print('Error enviando mensaje de bienvenida: $e');
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentSessionId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    // Limpiar el campo de texto
    _messageController.clear();

    try {
      // Guardar mensaje del usuario
      final userMessage = ChatMessageModel.user(
        userId: user.uid,
        content: message,
      );
      await _chatRepository.saveChatMessage(_currentSessionId!, userMessage);

      // Scroll automático
      _scrollToBottom();

      // Mostrar indicador de escritura
      setState(() {
        _isTyping = true;
      });

      // Obtener historial reciente para contexto
      final recentMessages = await _chatRepository.getRecentMessagesForContext(
        _currentSessionId!,
        10,
      );

      // Enviar a la IA
      final aiResponse = await _chatbotService.sendMessage(
        message,
        user,
        _userPreferences,
        recentMessages,
      );

      // Guardar respuesta de la IA
      final assistantMessage = ChatMessageModel.assistant(
        userId: user.uid,
        content: aiResponse,
      );
      await _chatRepository.saveChatMessage(_currentSessionId!, assistantMessage);

    } catch (e) {
      print('Error enviando mensaje: $e');
      _showErrorSnackBar('Error al enviar mensaje');
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('HuapoAI Assistant'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando tu asistente personal...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HuapoAI Assistant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Tu consejero de moda personal',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_chat':
                  _startNewChat();
                  break;
                case 'quick_tips':
                  _showQuickTips();
                  break;
                case 'clear_chat':
                  _clearCurrentChat();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: ListTile(
                  leading: Icon(Icons.add_comment_rounded),
                  title: Text('Nueva conversación'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'quick_tips',
                child: ListTile(
                  leading: Icon(Icons.lightbulb_outline_rounded),
                  title: Text('Ideas para preguntar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_chat',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Limpiar chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        elevation: 1,
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _currentSessionId != null
                  ? _chatRepository.getChatMessages(_currentSessionId!)
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isTyping) {
                      return const TypingIndicator();
                    }

                    final message = messages[index];
                    return ChatBubble(
                      message: message.content,
                      isUser: message.sender == 'user',
                      timestamp: message.timestamp,
                      imageUrl: message.imageUrl,
                    );
                  },
                );
              },
            ),
          ),

          // Input de mensaje
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Hola! Soy tu asistente de moda',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Puedo ayudarte con consejos personalizados de estilo, outfits para ocasiones específicas, y mucho más.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildQuickStartButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartButtons() {
    return Column(
      children: [
        const Text(
          'Ideas para empezar:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildQuickButton('¿Qué outfit me recomiendas para una cita?'),
            _buildQuickButton('Colores que me favorecen'),
            _buildQuickButton('Tendencias de esta temporada'),
            _buildQuickButton('Cómo combinar colores'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButton(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botón de opciones adicionales
            IconButton(
              onPressed: _showInputOptions,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: colorScheme.primary,
              ),
            ),

            // Campo de texto
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Pregúntame sobre moda y estilo...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Botón de enviar
            IconButton(
              onPressed: _sendMessage,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInputOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¿Cómo puedo ayudarte?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildOptionCard(
                  'Outfit para ocasión',
                  Icons.event_outlined,
                      () => _sendQuickMessage('Necesito un outfit para una ocasión específica'),
                ),
                _buildOptionCard(
                  'Análisis de look',
                  Icons.analytics_outlined,
                      () => _sendQuickMessage('¿Puedes analizar mi look actual?'),
                ),
                _buildOptionCard(
                  'Tendencias',
                  Icons.trending_up_rounded,
                      () => _sendQuickMessage('¿Cuáles son las tendencias actuales?'),
                ),
                _buildOptionCard(
                  'Combinaciones',
                  Icons.palette_outlined,
                      () => _sendQuickMessage('¿Qué colores combinan bien?'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(String title, IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  void _startNewChat() {
    // Navegar a una nueva instancia de chat
    context.push('/chat');
  }

  void _showQuickTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ideas para preguntar'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aquí tienes algunas ideas de qué puedes preguntarme:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ..._getQuickTipsList().map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(tip)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  List<String> _getQuickTipsList() {
    return [
      '¿Qué outfit me recomiendas para una cita romántica?',
      'Necesito un look profesional para una entrevista',
      '¿Qué colores me quedan mejor con mi tono de piel?',
      'Cómo puedo combinar esta prenda que tengo',
      '¿Cuáles son las tendencias de esta temporada?',
      'Consejos para vestirme según mi tipo de cuerpo',
      '¿Qué accesorios van bien con este outfit?',
      'Ideas para un look casual de fin de semana',
      'Cómo crear un guardarropa cápsula',
      '¿Qué zapatos combinan con este vestido?',
    ];
  }

  void _clearCurrentChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar conversación'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar todos los mensajes de esta conversación?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentSessionId != null) {
                await _chatRepository.deleteChatSession(_currentSessionId!);
                if (mounted) {
                  context.pop();
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}