import 'package:flutter/foundation.dart';

import '../core/app_error.dart';
import '../data/ocean_match_repository.dart';
import '../domain/models.dart';

class OceanMatchController extends ChangeNotifier {
  OceanMatchController({required OceanMatchRepository repository})
      : _repository = repository;

  final OceanMatchRepository _repository;

  UserAccount? _currentUser;
  List<DiscoveryProfile> _discoveryProfiles = const [];
  List<ConversationSummary> _conversationSummaries = const [];
  List<PortActivity> _portActivities = const [];
  final Map<String, List<Message>> _messagesByConversation = {};

  UserAccount? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get isEmailVerified => _currentUser?.emailVerified == true;

  bool get hasActiveAccount {
    final user = _currentUser;
    return user != null &&
        user.emailVerified &&
        user.status == AccountStatus.active;
  }

  bool get isProfileComplete {
    final userId = _currentUser?.id;
    if (userId == null) return false;
    return _repository.getProfile(userId)?.isComplete == true;
  }

  bool get canAccessDiscovery => hasActiveAccount && isProfileComplete;

  Profile? get currentProfile {
    if (!hasActiveAccount) return null;
    final userId = _currentUser?.id;
    if (userId == null) return null;
    return _repository.getProfile(userId);
  }

  List<ProfilePhoto> get currentPhotos {
    if (!hasActiveAccount) return const [];
    final userId = _currentUser?.id;
    if (userId == null) return const [];
    return _repository.getPhotos(userId);
  }

  LifeAboard? get currentLifeAboard {
    if (!hasActiveAccount) return null;
    final userId = _currentUser?.id;
    if (userId == null) return null;
    return _repository.getLifeAboard(userId);
  }

  CurrentZone? get currentZone {
    if (!hasActiveAccount) return null;
    final userId = _currentUser?.id;
    if (userId == null) return null;
    return _repository.getCurrentZone(userId);
  }

  FutureRoute? get currentFutureRoute {
    if (!hasActiveAccount) return null;
    final userId = _currentUser?.id;
    if (userId == null) return null;
    return _repository.getFutureRoute(userId);
  }

  Preferences? get currentPreferences {
    if (!hasActiveAccount) return null;
    final userId = _currentUser?.id;
    if (userId == null) return null;
    return _repository.getPreferences(userId);
  }

  List<DiscoveryProfile> get discoveryProfiles => _discoveryProfiles;

  List<ConversationSummary> get conversationSummaries => _conversationSummaries;

  List<HarborPort> get ports => _repository.getPorts();

  List<PortActivity> get portActivities => _portActivities;

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _currentUser = await _repository.signUp(email: email, password: password);
    _clearPrivateData();
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _currentUser = await _repository.login(email: email, password: password);
    await refreshAppData();
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _clearPrivateData();
    notifyListeners();
  }

  Future<void> verifyEmail() async {
    final userId = _requireCurrentUserId();
    _currentUser = await _repository.verifyEmail(userId);
    notifyListeners();
  }

  Future<void> requestEmailVerification() async {
    final userId = _requireCurrentUserId();
    await _repository.requestEmailVerification(userId);
  }

  Future<void> requestPasswordReset(String email) {
    return _repository.requestPasswordReset(email);
  }

  Future<void> completeOnboarding({
    required Profile profile,
    required List<ProfilePhoto> photos,
    required LifeAboard lifeAboard,
    required CurrentZone currentZone,
    required FutureRoute futureRoute,
    required Preferences preferences,
  }) async {
    _requireActiveAccount();
    await _repository.completeOnboarding(
      profile: profile,
      photos: photos,
      lifeAboard: lifeAboard,
      currentZone: currentZone,
      futureRoute: futureRoute,
      preferences: preferences,
    );
    await refreshAppData();
    notifyListeners();
  }

  Future<void> updateCurrentZone(String zone) async {
    _requireCompleteProfile();
    final userId = _requireCurrentUserId();
    await _repository.updateCurrentZone(
      userId,
      CurrentZone(userId: userId, zone: zone, updatedAt: DateTime.now()),
    );
    await refreshDiscovery();
    await refreshPorts();
    notifyListeners();
  }

  Future<void> updateFutureRoute({
    required String destinationZone,
    required String startPeriod,
    required String endPeriod,
    required RouteFlexibility flexibility,
    required String comment,
  }) async {
    _requireCompleteProfile();
    final userId = _requireCurrentUserId();
    final existing = _repository.getFutureRoute(userId);
    final route = FutureRoute(
      id: existing?.id ?? 'route-${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      destinationZone: destinationZone,
      startPeriod: startPeriod,
      endPeriod: endPeriod,
      flexibility: flexibility,
      comment: comment,
      isActive: true,
      updatedAt: DateTime.now(),
    );
    await _repository.updateFutureRoute(userId, route);
    await refreshDiscovery();
    await refreshPorts();
    notifyListeners();
  }

  Future<void> updateCurrentPort(HarborPort port) async {
    _requireCompleteProfile();
    final userId = _requireCurrentUserId();
    await _repository.updateCurrentPort(userId, port);
    await refreshDiscovery();
    await refreshPorts();
    notifyListeners();
  }

  Future<void> updateDestinationPort(HarborPort port) async {
    _requireCompleteProfile();
    final userId = _requireCurrentUserId();
    await _repository.updateDestinationPort(userId, port);
    await refreshDiscovery();
    await refreshPorts();
    notifyListeners();
  }

  Future<void> refreshAppData() async {
    if (!canAccessDiscovery) {
      _clearPrivateData();
      notifyListeners();
      return;
    }
    await refreshDiscovery();
    await refreshConversations();
    await refreshPorts();
  }

  Future<void> refreshDiscovery() async {
    final userId = _currentUser?.id;
    if (userId == null || !canAccessDiscovery) {
      _clearDiscovery();
      notifyListeners();
      return;
    }
    _discoveryProfiles = await _repository.getDiscoveryProfiles(userId);
    notifyListeners();
  }

  Future<void> refreshPorts() async {
    final userId = _currentUser?.id;
    if (userId == null || !canAccessDiscovery) {
      _portActivities = const [];
      notifyListeners();
      return;
    }
    _portActivities = await _repository.getPortActivities(userId);
    notifyListeners();
  }

  Future<MatchResult> likeProfile(String targetUserId) async {
    _requireCompleteProfile();
    final userId = _requireCurrentUserId();
    final result = await _repository.likeProfile(
      userId: userId,
      targetUserId: targetUserId,
    );
    await refreshDiscovery();
    await refreshConversations();
    notifyListeners();
    return result;
  }

  Future<void> passProfile(String targetUserId) async {
    _requireCompleteProfile();
    final userId = _requireCurrentUserId();
    await _repository.passProfile(userId: userId, targetUserId: targetUserId);
    await refreshDiscovery();
    notifyListeners();
  }

  Future<void> refreshConversations() async {
    final userId = _currentUser?.id;
    if (userId == null || !hasActiveAccount) {
      _conversationSummaries = const [];
      _messagesByConversation.clear();
      notifyListeners();
      return;
    }
    _conversationSummaries = await _repository.getConversationSummaries(userId);
    notifyListeners();
  }

  List<Message> messagesFor(String conversationId) {
    if (!hasActiveAccount) return const [];
    return _messagesByConversation[conversationId] ?? const [];
  }

  Future<void> loadMessages(String conversationId) async {
    _requireActiveAccount();
    final userId = _requireCurrentUserId();
    _messagesByConversation[conversationId] = await _repository.getMessages(
      userId: userId,
      conversationId: conversationId,
    );
    notifyListeners();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    _requireActiveAccount();
    final userId = _requireCurrentUserId();
    await _repository.sendMessage(
      userId: userId,
      conversationId: conversationId,
      content: content,
    );
    await loadMessages(conversationId);
    await refreshConversations();
  }

  Future<void> blockUser(String blockedId) async {
    _requireActiveAccount();
    final userId = _requireCurrentUserId();
    await _repository.blockUser(blockerId: userId, blockedId: blockedId);
    await refreshAppData();
    notifyListeners();
  }

  Future<void> unblockUser(String blockedId) async {
    _requireActiveAccount();
    final userId = _requireCurrentUserId();
    await _repository.unblockUser(blockerId: userId, blockedId: blockedId);
    await refreshAppData();
    notifyListeners();
  }

  Future<List<Block>> getBlocks() async {
    _requireActiveAccount();
    final userId = _requireCurrentUserId();
    return _repository.getBlocks(userId);
  }

  Future<void> reportUser({
    required String reportedId,
    required ReportReason reason,
    String? conversationId,
    String? messageId,
    String? comment,
  }) async {
    _requireActiveAccount();
    final userId = _requireCurrentUserId();
    await _repository.reportUser(
      reporterId: userId,
      reportedId: reportedId,
      reason: reason,
      conversationId: conversationId,
      messageId: messageId,
      comment: comment,
    );
  }

  Future<void> deleteAccount() async {
    final userId = _requireCurrentUserId();
    await _repository.deleteAccount(userId);
    _currentUser = null;
    _clearPrivateData();
    notifyListeners();
  }

  Profile? profileFor(String userId) {
    if (!hasActiveAccount) return null;
    return _repository.getProfile(userId);
  }

  List<ProfilePhoto> photosFor(String userId) {
    if (!hasActiveAccount) return const [];
    return _repository.getPhotos(userId);
  }

  LifeAboard? lifeAboardFor(String userId) {
    if (!hasActiveAccount) return null;
    return _repository.getLifeAboard(userId);
  }

  CurrentZone? currentZoneFor(String userId) {
    if (!hasActiveAccount) return null;
    return _repository.getCurrentZone(userId);
  }

  FutureRoute? futureRouteFor(String userId) {
    if (!hasActiveAccount) return null;
    return _repository.getFutureRoute(userId);
  }

  Preferences? preferencesFor(String userId) {
    if (!hasActiveAccount) return null;
    return _repository.getPreferences(userId);
  }

  void _clearDiscovery() {
    _discoveryProfiles = const [];
  }

  void _clearPrivateData() {
    _clearDiscovery();
    _portActivities = const [];
    _conversationSummaries = const [];
    _messagesByConversation.clear();
  }

  void _requireActiveAccount() {
    final user = _currentUser;
    if (user == null) {
      throw const OceanMatchException('Connectez-vous pour continuer.');
    }
    if (user.status == AccountStatus.suspended) {
      throw const OceanMatchException(
        'Ce compte est suspendu. Contactez le support BlueWater Match.',
      );
    }
    if (user.status == AccountStatus.deleted) {
      throw const OceanMatchException('Ce compte n est plus disponible.');
    }
    if (!user.emailVerified || user.status != AccountStatus.active) {
      throw const OceanMatchException(
        'Verifiez votre email pour activer votre compte.',
      );
    }
  }

  void _requireCompleteProfile() {
    _requireActiveAccount();
    if (!isProfileComplete) {
      throw const OceanMatchException(
        'Completez votre profil avant d acceder a Decouvrir.',
      );
    }
  }

  String _requireCurrentUserId() {
    final userId = _currentUser?.id;
    if (userId == null) {
      throw const OceanMatchException('Connectez-vous pour continuer.');
    }
    return userId;
  }
}
