import '../core/app_error.dart';
import '../core/id_generator.dart';
import '../domain/models.dart';
import 'ports_catalog.dart';

abstract class OceanMatchRepository {
  Future<UserAccount> signUp({
    required String email,
    required String password,
  });

  Future<UserAccount> login({
    required String email,
    required String password,
  });

  Future<UserAccount> verifyEmail(String userId);

  Future<void> requestPasswordReset(String email);

  Future<void> requestEmailVerification(String userId);

  Future<void> completeOnboarding({
    required Profile profile,
    required List<ProfilePhoto> photos,
    required LifeAboard lifeAboard,
    required CurrentZone currentZone,
    required FutureRoute futureRoute,
    required Preferences preferences,
  });

  Future<void> updateCurrentZone(String userId, CurrentZone zone);

  Future<void> updateFutureRoute(String userId, FutureRoute route);

  List<HarborPort> getPorts();

  Future<List<PortActivity>> getPortActivities(String userId);

  Future<void> updateCurrentPort(String userId, HarborPort port);

  Future<void> updateDestinationPort(String userId, HarborPort port);

  Future<List<DiscoveryProfile>> getDiscoveryProfiles(String userId);

  Future<MatchResult> likeProfile({
    required String userId,
    required String targetUserId,
  });

  Future<void> passProfile({
    required String userId,
    required String targetUserId,
  });

  Future<List<ConversationSummary>> getConversationSummaries(String userId);

  Future<List<Message>> getMessages({
    required String userId,
    required String conversationId,
  });

  Future<Message> sendMessage({
    required String userId,
    required String conversationId,
    required String content,
  });

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<List<Block>> getBlocks(String userId);

  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required ReportReason reason,
    String? conversationId,
    String? messageId,
    String? comment,
  });

  Future<void> deleteAccount(String userId);

  UserAccount? getAccount(String userId);

  Profile? getProfile(String userId);

  List<ProfilePhoto> getPhotos(String userId);

  LifeAboard? getLifeAboard(String userId);

  CurrentZone? getCurrentZone(String userId);

  FutureRoute? getFutureRoute(String userId);

  Preferences? getPreferences(String userId);
}

class MockOceanMatchRepository implements OceanMatchRepository {
  MockOceanMatchRepository() {
    _seedProfiles();
  }

  final IdGenerator _ids = IdGenerator();
  final Map<String, UserAccount> _accounts = {};
  final Map<String, String> _passwords = {};
  final Map<String, Profile> _profiles = {};
  final Map<String, List<ProfilePhoto>> _photos = {};
  final Map<String, LifeAboard> _lifeAboard = {};
  final Map<String, CurrentZone> _currentZones = {};
  final Map<String, FutureRoute> _futureRoutes = {};
  final Map<String, Preferences> _preferences = {};
  final List<Like> _likes = [];
  final List<Pass> _passes = [];
  final List<Match> _matches = [];
  final List<Conversation> _conversations = [];
  final List<Message> _messages = [];
  final List<Block> _blocks = [];
  final List<Report> _reports = [];

  void setAccountStatusForTesting(String userId, AccountStatus status) {
    final account = _requireAccount(userId);
    _accounts[userId] = account.copyWith(status: status);
  }

  @override
  Future<UserAccount> signUp({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    _validatePassword(password);
    final existing = _accounts.values.any(
      (account) =>
          account.email == normalizedEmail &&
          account.status != AccountStatus.deleted,
    );
    if (existing) {
      throw const OceanMatchException(
        'Un compte existe deja avec cet email. Connectez-vous ou utilisez le mot de passe oublie.',
      );
    }

    final account = UserAccount(
      id: _ids.next('user'),
      email: normalizedEmail,
      emailVerified: false,
      status: AccountStatus.pendingEmailVerification,
      createdAt: DateTime.now(),
    );
    _accounts[account.id] = account;
    _passwords[account.id] = password;

    // Demo seed: one profile has already liked the new user, so the MVP
    // can demonstrate instant match creation after the onboarding.
    _likes.add(
      Like(
        userId: 'seed-lea',
        targetUserId: account.id,
        createdAt: DateTime.now(),
      ),
    );
    return account;
  }

  @override
  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    _seedTestAccountIfNeeded(normalizedEmail);
    final account = _accounts.values.where((candidate) {
      return candidate.email == normalizedEmail &&
          candidate.status != AccountStatus.deleted;
    }).firstOrNull;
    if (account == null || !_passwordMatches(account, password)) {
      throw const OceanMatchException('Email ou mot de passe incorrect.');
    }
    if (account.status == AccountStatus.suspended) {
      throw const OceanMatchException(
        'Ce compte est suspendu. Contactez le support BlueWater Match.',
      );
    }
    final updated = account.copyWith(lastLoginAt: DateTime.now());
    _accounts[account.id] = updated;
    return updated;
  }

  @override
  Future<UserAccount> verifyEmail(String userId) async {
    final account = _requireUsableAccount(userId);
    final updated = account.copyWith(
      emailVerified: true,
      status: AccountStatus.active,
    );
    _accounts[userId] = updated;
    return updated;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    return;
  }

  @override
  Future<void> requestEmailVerification(String userId) async {
    _requireUsableAccount(userId);
    return;
  }

  @override
  Future<void> completeOnboarding({
    required Profile profile,
    required List<ProfilePhoto> photos,
    required LifeAboard lifeAboard,
    required CurrentZone currentZone,
    required FutureRoute futureRoute,
    required Preferences preferences,
  }) async {
    _requireActiveUser(profile.userId);
    _validateOnboardingPayload(
      profile: profile,
      photos: photos,
      lifeAboard: lifeAboard,
      currentZone: currentZone,
      futureRoute: futureRoute,
      preferences: preferences,
    );
    if (photos.isNotEmpty && !photos.any((photo) => photo.isPrimary)) {
      throw const OceanMatchException('Choisissez une photo principale.');
    }

    _profiles[profile.userId] = profile.copyWith(isComplete: true);
    _photos[profile.userId] = photos;
    _lifeAboard[profile.userId] = lifeAboard;
    _currentZones[profile.userId] = currentZone;
    _futureRoutes[profile.userId] = futureRoute;
    _preferences[profile.userId] = preferences;
  }

  @override
  Future<void> updateCurrentZone(String userId, CurrentZone zone) async {
    _requireActiveUser(userId);
    _requireText(zone.zone, 'Zone actuelle obligatoire.');
    _rejectExactPosition(zone.zone);
    _currentZones[userId] = zone;
  }

  @override
  Future<void> updateFutureRoute(String userId, FutureRoute route) async {
    _requireActiveUser(userId);
    _requireText(route.destinationZone, 'Route future obligatoire.');
    _rejectExactPosition(route.destinationZone);
    _requireText(route.startPeriod, 'Periode de debut obligatoire.');
    _requireText(route.endPeriod, 'Periode de fin obligatoire.');
    _rejectExactPosition(route.comment);
    _futureRoutes[userId] = route.copyWith(isActive: true);
  }

  @override
  List<HarborPort> getPorts() => List.unmodifiable(harborPorts);

  @override
  Future<List<PortActivity>> getPortActivities(String userId) async {
    _requireActiveUser(userId);
    final current = _currentZones[userId];
    final route = _futureRoutes[userId];
    final activities = <PortActivity>[
      for (final port in harborPorts)
        PortActivity(
          port: port,
          currentCount: _currentCountForPort(port.id),
          destinationCount: _destinationCountForPort(port.id),
          isCurrentUserHere: current?.portId == port.id,
          isCurrentUserGoing: route?.destinationPortId == port.id,
        ),
    ];
    activities.sort((a, b) {
      final byTotal = b.totalCount.compareTo(a.totalCount);
      if (byTotal != 0) return byTotal;
      return a.port.name.compareTo(b.port.name);
    });
    return activities;
  }

  @override
  Future<void> updateCurrentPort(String userId, HarborPort port) async {
    _requireActiveUser(userId);
    _currentZones[userId] = CurrentZone(
      userId: userId,
      zone: port.region,
      country: port.country,
      portId: port.id,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateDestinationPort(String userId, HarborPort port) async {
    _requireActiveUser(userId);
    final existing = _futureRoutes[userId];
    _futureRoutes[userId] = FutureRoute(
      id: existing?.id ?? _ids.next('route'),
      userId: userId,
      destinationZone: port.region,
      destinationCountry: port.country,
      destinationPortId: port.id,
      startPeriod: existing?.startPeriod ?? 'A preciser',
      endPeriod: existing?.endPeriod ?? 'A preciser',
      flexibility: existing?.flexibility ?? RouteFlexibility.flexible,
      comment: existing?.comment ?? '',
      isActive: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<DiscoveryProfile>> getDiscoveryProfiles(String userId) async {
    _requireDiscoverableUser(userId);
    final result = <DiscoveryProfile>[];
    for (final targetId in _profiles.keys) {
      if (targetId == userId) continue;
      final discovery = _buildDiscoveryProfile(
        currentUserId: userId,
        targetUserId: targetId,
      );
      if (discovery != null) {
        result.add(discovery);
      }
    }
    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }

  @override
  Future<MatchResult> likeProfile({
    required String userId,
    required String targetUserId,
  }) async {
    _requireDiscoverableUser(userId);
    _requireDiscoverableTarget(targetUserId);
    _throwIfSameUser(userId, targetUserId);
    _throwIfBlocked(userId, targetUserId);

    final exists = _likes.any(
      (like) => like.userId == userId && like.targetUserId == targetUserId,
    );
    if (!exists) {
      _likes.add(
        Like(
          userId: userId,
          targetUserId: targetUserId,
          createdAt: DateTime.now(),
        ),
      );
    }

    final reciprocal = _likes.any(
      (like) => like.userId == targetUserId && like.targetUserId == userId,
    );
    if (!reciprocal) {
      return const MatchResult(createdMatch: false);
    }

    final existingMatch = _matchBetween(userId, targetUserId);
    if (existingMatch != null) {
      return MatchResult(
        createdMatch: false,
        match: existingMatch,
        conversation: _conversationForMatch(existingMatch.id),
        matchedProfile: _buildDiscoveryProfile(
          currentUserId: userId,
          targetUserId: targetUserId,
        ),
      );
    }

    final match = Match(
      id: _ids.next('match'),
      user1Id: userId,
      user2Id: targetUserId,
      status: MatchStatus.active,
      createdAt: DateTime.now(),
    );
    final conversation = Conversation(
      id: _ids.next('conversation'),
      matchId: match.id,
      user1Id: userId,
      user2Id: targetUserId,
      createdAt: DateTime.now(),
    );
    _matches.add(match);
    _conversations.add(conversation);

    return MatchResult(
      createdMatch: true,
      match: match,
      conversation: conversation,
      matchedProfile: _buildDiscoveryProfile(
        currentUserId: userId,
        targetUserId: targetUserId,
      ),
    );
  }

  @override
  Future<void> passProfile({
    required String userId,
    required String targetUserId,
  }) async {
    _requireDiscoverableUser(userId);
    _requireDiscoverableTarget(targetUserId);
    _throwIfSameUser(userId, targetUserId);
    _throwIfBlocked(userId, targetUserId);

    final exists = _passes.any(
      (pass) => pass.userId == userId && pass.targetUserId == targetUserId,
    );
    if (!exists) {
      _passes.add(
        Pass(
          userId: userId,
          targetUserId: targetUserId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<List<ConversationSummary>> getConversationSummaries(
      String userId) async {
    _requireActiveUser(userId);
    final summaries = <ConversationSummary>[];
    for (final conversation
        in _conversations.where((item) => item.contains(userId))) {
      final match =
          _matches.where((item) => item.id == conversation.matchId).firstOrNull;
      if (match == null || match.status == MatchStatus.deleted) continue;
      final otherUserId = conversation.otherUserId(userId);
      final otherProfile = _profiles[otherUserId];
      if (otherProfile == null) continue;
      final messages = _messages
          .where((message) =>
              message.conversationId == conversation.id &&
              message.deletedAt == null)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      summaries.add(
        ConversationSummary(
          conversation: conversation,
          match: match,
          otherProfile: otherProfile,
          otherPhoto: _primaryPhoto(otherUserId),
          lastMessage: messages.firstOrNull,
          isBlocked: _isBlockedEitherWay(userId, otherUserId) ||
              match.status == MatchStatus.blocked,
        ),
      );
    }
    summaries.sort((a, b) {
      final aDate = a.lastMessage?.createdAt ?? a.conversation.createdAt;
      final bDate = b.lastMessage?.createdAt ?? b.conversation.createdAt;
      return bDate.compareTo(aDate);
    });
    return summaries;
  }

  @override
  Future<List<Message>> getMessages({
    required String userId,
    required String conversationId,
  }) async {
    _requireActiveUser(userId);
    final conversation = _requireConversation(conversationId);
    if (!conversation.contains(userId)) {
      throw const OceanMatchException('Acces conversation refuse.');
    }
    final result = _messages
        .where((message) =>
            message.conversationId == conversationId &&
            message.deletedAt == null)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  @override
  Future<Message> sendMessage({
    required String userId,
    required String conversationId,
    required String content,
  }) async {
    _requireActiveUser(userId);
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const OceanMatchException('Message vide.');
    }
    if (trimmed.length > 1000) {
      throw const OceanMatchException('Message trop long.');
    }
    final conversation = _requireConversation(conversationId);
    if (!conversation.contains(userId)) {
      throw const OceanMatchException('Acces conversation refuse.');
    }
    final match =
        _matches.where((item) => item.id == conversation.matchId).firstOrNull;
    if (match == null || match.status != MatchStatus.active) {
      throw const OceanMatchException('Conversation inactive.');
    }
    final otherUserId = conversation.otherUserId(userId);
    _throwIfBlocked(userId, otherUserId);

    final message = Message(
      id: _ids.next('message'),
      conversationId: conversationId,
      senderId: userId,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    _messages.add(message);

    final index =
        _conversations.indexWhere((item) => item.id == conversationId);
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessageAt: message.createdAt,
      );
    }
    return message;
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _requireActiveUser(blockerId);
    _requireUsableAccount(blockedId);
    if (blockerId == blockedId) {
      throw const OceanMatchException('Action impossible.');
    }
    final exists = _blocks.any(
      (block) => block.blockerId == blockerId && block.blockedId == blockedId,
    );
    if (!exists) {
      _blocks.add(
        Block(
          id: _ids.next('block'),
          blockerId: blockerId,
          blockedId: blockedId,
          createdAt: DateTime.now(),
        ),
      );
    }
    for (var i = 0; i < _matches.length; i += 1) {
      final match = _matches[i];
      if (match.contains(blockerId) && match.contains(blockedId)) {
        _matches[i] = match.copyWith(status: MatchStatus.blocked);
      }
    }
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _requireActiveUser(blockerId);
    _requireUsableAccount(blockedId);
    _blocks.removeWhere(
      (block) => block.blockerId == blockerId && block.blockedId == blockedId,
    );
    if (_isBlockedEitherWay(blockerId, blockedId)) return;
    for (var i = 0; i < _matches.length; i += 1) {
      final match = _matches[i];
      if (match.status == MatchStatus.blocked &&
          match.contains(blockerId) &&
          match.contains(blockedId)) {
        _matches[i] = match.copyWith(status: MatchStatus.active);
      }
    }
  }

  @override
  Future<List<Block>> getBlocks(String userId) async {
    _requireActiveUser(userId);
    return _blocks.where((block) => block.blockerId == userId).toList();
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required ReportReason reason,
    String? conversationId,
    String? messageId,
    String? comment,
  }) async {
    _requireActiveUser(reporterId);
    _requireUsableAccount(reportedId);
    if (reporterId == reportedId) {
      throw const OceanMatchException('Action impossible.');
    }
    _validateReportContext(
      reporterId: reporterId,
      reportedId: reportedId,
      conversationId: conversationId,
      messageId: messageId,
    );
    _reports.add(
      Report(
        id: _ids.next('report'),
        reporterId: reporterId,
        reportedId: reportedId,
        conversationId: conversationId,
        messageId: messageId,
        reason: reason,
        comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
        status: ReportStatus.newReport,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteAccount(String userId) async {
    final account = _requireAccount(userId);
    _accounts[userId] = account.copyWith(status: AccountStatus.deleted);
    for (var i = 0; i < _matches.length; i += 1) {
      if (_matches[i].contains(userId)) {
        _matches[i] = _matches[i].copyWith(status: MatchStatus.deleted);
      }
    }
    _photos.remove(userId);
  }

  @override
  UserAccount? getAccount(String userId) => _accounts[userId];

  @override
  Profile? getProfile(String userId) => _profiles[userId];

  @override
  List<ProfilePhoto> getPhotos(String userId) {
    final photos = List<ProfilePhoto>.from(_photos[userId] ?? const []);
    photos.sort((a, b) => a.order.compareTo(b.order));
    return photos;
  }

  @override
  LifeAboard? getLifeAboard(String userId) => _lifeAboard[userId];

  @override
  CurrentZone? getCurrentZone(String userId) => _currentZones[userId];

  @override
  FutureRoute? getFutureRoute(String userId) => _futureRoutes[userId];

  @override
  Preferences? getPreferences(String userId) => _preferences[userId];

  int _currentCountForPort(String portId) {
    return _currentZones.entries.where((entry) {
      return entry.value.portId == portId &&
          _hasPublicCompleteProfile(entry.key);
    }).length;
  }

  int _destinationCountForPort(String portId) {
    return _futureRoutes.entries.where((entry) {
      return entry.value.destinationPortId == portId &&
          entry.value.isActive &&
          _hasPublicCompleteProfile(entry.key);
    }).length;
  }

  bool _hasPublicCompleteProfile(String userId) {
    final account = _accounts[userId];
    final profile = _profiles[userId];
    if (account == null || profile == null) return false;
    return account.status == AccountStatus.active &&
        account.emailVerified &&
        profile.isComplete;
  }

  void _validateOnboardingPayload({
    required Profile profile,
    required List<ProfilePhoto> photos,
    required LifeAboard lifeAboard,
    required CurrentZone currentZone,
    required FutureRoute futureRoute,
    required Preferences preferences,
  }) {
    final userId = profile.userId;
    final mismatchedUserId = lifeAboard.userId != userId ||
        currentZone.userId != userId ||
        futureRoute.userId != userId ||
        preferences.userId != userId ||
        photos.any((photo) => photo.userId != userId);
    if (mismatchedUserId) {
      throw const OceanMatchException('Profil incoherent.');
    }

    _requireText(profile.firstName, 'Prenom obligatoire.');
    final age = profile.age;
    if (age < 18 || age > 99) {
      throw const OceanMatchException(
        'Age valide obligatoire, entre 18 et 99 ans.',
      );
    }
    final languages = profile.languages
        .map((language) => language.trim())
        .where((language) => language.isNotEmpty)
        .toList();
    if (languages.isEmpty) {
      throw const OceanMatchException('Ajoutez au moins une langue.');
    }
    _requireText(profile.bio, 'Bio obligatoire.');
    _rejectExactPosition(profile.bio);

    _requireText(lifeAboard.boatOrProject, 'Ajoutez un bateau ou un projet.');
    _rejectExactPosition(lifeAboard.boatOrProject);
    _requireText(lifeAboard.sailingType, 'Statut de vie a bord obligatoire.');

    _requireText(currentZone.zone, 'Zone actuelle obligatoire.');
    _rejectExactPosition(currentZone.zone);
    _requireText(futureRoute.destinationZone, 'Route future obligatoire.');
    _rejectExactPosition(futureRoute.destinationZone);
    _requireText(futureRoute.startPeriod, 'Periode de debut obligatoire.');
    _requireText(futureRoute.endPeriod, 'Periode de fin obligatoire.');
    _rejectExactPosition(futureRoute.comment);

    if (preferences.intentions.isEmpty) {
      throw const OceanMatchException(
        'Selectionnez au moins une intention.',
      );
    }
    if (preferences.ageMin < 18 || preferences.ageMin > preferences.ageMax) {
      throw const OceanMatchException('Preferences d age invalides.');
    }
    if (preferences.zones.isEmpty ||
        preferences.zones.any((zone) => zone.trim().isEmpty)) {
      throw const OceanMatchException('Ajoutez au moins une zone large.');
    }
    for (final zone in preferences.zones) {
      _rejectExactPosition(zone);
    }
  }

  void _requireText(String value, String message) {
    if (value.trim().isEmpty) {
      throw OceanMatchException(message);
    }
  }

  void _rejectExactPosition(String value) {
    if (!_containsExactPositionHint(value)) return;
    throw const OceanMatchException(
      'Gardez uniquement des zones larges, sans GPS, marina, quai ou ponton.',
    );
  }

  bool _containsExactPositionHint(String value) {
    final normalized = value.toLowerCase();
    final coordinatePattern = RegExp(
      r'\b\d{1,2}([.,]\d+)?\s*[ns]\b|\b\d{1,3}([.,]\d+)?\s*[eoew]\b',
    );
    final coordinatePairPattern = RegExp(
      r'[-+]?\d{1,2}([.,]\d+)?\s*[,;/]\s*[-+]?\d{1,3}([.,]\d+)?',
    );
    final exactWords = RegExp(
      r"\b(gps|latitude|longitude|lat\.?|lon\.?|coordonnees|coordinates|marina|quai|ponton|anneau|mouillage|port\s+(de|du|des|d'))\b",
    );
    return coordinatePattern.hasMatch(normalized) ||
        coordinatePairPattern.hasMatch(normalized) ||
        exactWords.hasMatch(normalized);
  }

  UserAccount _requireAccount(String userId) {
    final account = _accounts[userId];
    if (account == null) {
      throw const OceanMatchException('Compte introuvable.');
    }
    return account;
  }

  UserAccount _requireUsableAccount(String userId) {
    final account = _requireAccount(userId);
    if (account.status == AccountStatus.deleted) {
      throw const OceanMatchException('Ce compte n est plus disponible.');
    }
    if (account.status == AccountStatus.suspended) {
      throw const OceanMatchException(
        'Ce compte est suspendu. Contactez le support BlueWater Match.',
      );
    }
    return account;
  }

  UserAccount _requireActiveUser(String userId) {
    final account = _requireUsableAccount(userId);
    if (!account.emailVerified || account.status != AccountStatus.active) {
      throw const OceanMatchException(
        'Verifiez votre email pour activer votre compte.',
      );
    }
    return account;
  }

  void _requireDiscoverableUser(String userId) {
    _requireActiveUser(userId);
    final profile = _profiles[userId];
    if (profile == null || !profile.isComplete) {
      throw const OceanMatchException(
        'Completez votre profil avant d acceder a Decouvrir.',
      );
    }
  }

  void _requireDiscoverableTarget(String userId) {
    _requireDiscoverableUser(userId);
    final photos = getPhotos(userId).where(
      (photo) => photo.status == PhotoModerationStatus.approved,
    );
    final lifeAboard = _lifeAboard[userId];
    final currentZone = _currentZones[userId];
    final futureRoute = _futureRoutes[userId];
    final preferences = _preferences[userId];
    if (photos.length < 2 ||
        lifeAboard == null ||
        currentZone == null ||
        futureRoute == null ||
        !futureRoute.isActive ||
        preferences == null ||
        preferences.intentions.isEmpty) {
      throw const OceanMatchException('Ce profil n est pas disponible.');
    }
  }

  Conversation _requireConversation(String conversationId) {
    final conversation =
        _conversations.where((item) => item.id == conversationId).firstOrNull;
    if (conversation == null) {
      throw const OceanMatchException('Conversation introuvable.');
    }
    return conversation;
  }

  void _validateReportContext({
    required String reporterId,
    required String reportedId,
    required String? conversationId,
    required String? messageId,
  }) {
    if (conversationId == null) {
      if (messageId != null) {
        throw const OceanMatchException('Signalement incoherent.');
      }
      return;
    }
    final conversation = _requireConversation(conversationId);
    final validParticipants = conversation.contains(reporterId) &&
        conversation.contains(reportedId) &&
        conversation.otherUserId(reporterId) == reportedId;
    if (!validParticipants) {
      throw const OceanMatchException('Signalement conversation refuse.');
    }
    if (messageId == null) return;
    final message = _messages.where((item) {
      return item.id == messageId && item.conversationId == conversationId;
    }).firstOrNull;
    if (message == null) {
      throw const OceanMatchException('Message introuvable.');
    }
  }

  void _throwIfBlocked(String userId, String otherUserId) {
    if (_isBlockedEitherWay(userId, otherUserId)) {
      throw const OceanMatchException('Interaction bloquee.');
    }
  }

  void _throwIfSameUser(String userId, String otherUserId) {
    if (userId == otherUserId) {
      throw const OceanMatchException('Action impossible.');
    }
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool _passwordMatches(UserAccount account, String password) {
    if (_passwords[account.id] == password) return true;
    if (account.email != 'test@oceanmatch.app') return false;
    return password == 'password123' || password == 'passworddemo';
  }

  void _validateEmail(String email) {
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) {
      throw const OceanMatchException('Entrez une adresse email valide.');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const OceanMatchException(
        'Le mot de passe doit contenir au moins 8 caracteres.',
      );
    }
  }

  bool _isBlockedEitherWay(String userId, String otherUserId) {
    return _blocks.any(
      (block) =>
          (block.blockerId == userId && block.blockedId == otherUserId) ||
          (block.blockerId == otherUserId && block.blockedId == userId),
    );
  }

  Match? _matchBetween(String userA, String userB) {
    return _matches.where((match) {
      return match.contains(userA) && match.contains(userB);
    }).firstOrNull;
  }

  Conversation? _conversationForMatch(String matchId) {
    return _conversations.where((item) => item.matchId == matchId).firstOrNull;
  }

  ProfilePhoto? _primaryPhoto(String userId) {
    final approved = getPhotos(userId).where(
      (photo) => photo.status == PhotoModerationStatus.approved,
    );
    if (approved.isEmpty) return null;
    return approved.firstWhere(
      (photo) => photo.isPrimary,
      orElse: () => approved.first,
    );
  }

  DiscoveryProfile? _buildDiscoveryProfile({
    required String currentUserId,
    required String targetUserId,
  }) {
    if (targetUserId == 'seed-test' && currentUserId != 'seed-test') {
      return null;
    }
    final currentAccount = _accounts[currentUserId];
    final targetAccount = _accounts[targetUserId];
    if (currentAccount == null || targetAccount == null) return null;
    if (targetAccount.status != AccountStatus.active ||
        !targetAccount.emailVerified) {
      return null;
    }
    if (_isBlockedEitherWay(currentUserId, targetUserId)) return null;
    if (_likes.any((like) =>
        like.userId == currentUserId && like.targetUserId == targetUserId)) {
      return null;
    }
    if (_passes.any((pass) =>
        pass.userId == currentUserId && pass.targetUserId == targetUserId)) {
      return null;
    }
    final existingMatch = _matchBetween(currentUserId, targetUserId);
    if (existingMatch != null && existingMatch.status == MatchStatus.active) {
      return null;
    }

    final currentProfile = _profiles[currentUserId];
    final targetProfile = _profiles[targetUserId];
    final currentZone = _currentZones[currentUserId];
    final targetZone = _currentZones[targetUserId];
    final currentRoute = _futureRoutes[currentUserId];
    final targetRoute = _futureRoutes[targetUserId];
    final currentPreferences = _preferences[currentUserId];
    final targetPreferences = _preferences[targetUserId];
    final targetLife = _lifeAboard[targetUserId];
    final currentLife = _lifeAboard[currentUserId];
    final targetPhotos = getPhotos(targetUserId)
        .where(
          (photo) => photo.status == PhotoModerationStatus.approved,
        )
        .toList();

    if (currentProfile == null ||
        targetProfile == null ||
        !targetProfile.isComplete ||
        currentZone == null ||
        targetZone == null ||
        currentRoute == null ||
        targetRoute == null ||
        currentPreferences == null ||
        targetPreferences == null ||
        targetLife == null ||
        currentLife == null ||
        targetPhotos.length < 2) {
      return null;
    }

    if (targetProfile.age < currentPreferences.ageMin ||
        targetProfile.age > currentPreferences.ageMax) {
      return null;
    }
    if (!_searchMatches(currentProfile.searchGender, targetProfile.gender)) {
      return null;
    }
    if (!_searchMatches(targetProfile.searchGender, currentProfile.gender)) {
      return null;
    }

    final hasNauticalFit = currentZone.zone == targetZone.zone ||
        currentRoute.destinationZone == targetZone.zone ||
        targetRoute.destinationZone == currentZone.zone ||
        currentRoute.destinationZone == targetRoute.destinationZone;
    if (!hasNauticalFit) return null;

    final sharedIntentions = currentPreferences.intentions
        .where((intention) => targetPreferences.intentions.contains(intention))
        .toList();
    if (sharedIntentions.isEmpty) return null;

    var score = 0;
    if (currentZone.zone == targetZone.zone) score += 25;
    if (currentRoute.destinationZone == targetZone.zone ||
        targetRoute.destinationZone == currentZone.zone ||
        currentRoute.destinationZone == targetRoute.destinationZone) {
      score += 25;
    }
    score += sharedIntentions.isNotEmpty ? 20 : 0;
    score += 10;
    score += 10;
    final sharedLifestyle = currentLife.lifestyleTags
        .where((tag) => targetLife.lifestyleTags.contains(tag))
        .length;
    if (sharedLifestyle > 0) score += sharedLifestyle >= 2 ? 10 : 5;

    return DiscoveryProfile(
      profile: targetProfile,
      photos: targetPhotos,
      lifeAboard: targetLife,
      currentZone: targetZone,
      futureRoute: targetRoute,
      intentions: targetPreferences.intentions,
      score: score,
    );
  }

  bool _searchMatches(SearchGender search, Gender gender) {
    switch (search) {
      case SearchGender.everyone:
        return true;
      case SearchGender.women:
        return gender == Gender.woman;
      case SearchGender.men:
        return gender == Gender.man;
    }
  }

  void _seedProfiles() {
    _seedTestUser();
    _seedUser(
      id: 'seed-lea',
      email: 'lea.demo@oceanmatch.app',
      firstName: 'Lea',
      age: 34,
      gender: Gender.woman,
      searchGender: SearchGender.everyone,
      bio: 'Vie a bord entre Canaries et Cap-Vert, plutot navigation lente.',
      status: BoardStatus.liveaboard,
      boatOrProject: 'Voilier 36 pieds',
      sailingType: 'Hauturier tranquille',
      experience: SailingExperience.confirmed,
      lifestyle: ['minimaliste', 'escales calmes', 'navigation lente'],
      zone: 'Canaries',
      route: 'Caraibes',
      currentPortId: 'las-palmas',
      destinationPortId: 'le-marin',
      intentions: [Intention.seriousRelationship, Intention.sailingProject],
      photos: const [
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
      ],
    );
    _seedUser(
      id: 'seed-marc',
      email: 'marc.demo@oceanmatch.app',
      firstName: 'Marc',
      age: 42,
      gender: Gender.man,
      searchGender: SearchGender.women,
      bio:
          'Tour Atlantique en preparation, envie de rencontres simples en escale.',
      status: BoardStatus.longDistanceSailor,
      boatOrProject: 'Monocoque aluminium',
      sailingType: 'Transat et longues escales',
      experience: SailingExperience.expert,
      lifestyle: ['aventure', 'longue traversee', 'vie sociale'],
      zone: 'Atlantique Europe',
      route: 'Canaries',
      currentPortId: 'lisbonne',
      destinationPortId: 'las-palmas',
      intentions: [Intention.casualDating, Intention.friendship],
      photos: const [
        'https://images.unsplash.com/photo-1469796466635-455ede028aca?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1515238152791-8216bfdf89a7?auto=format&fit=crop&w=900&q=80',
      ],
    );
    _seedUser(
      id: 'seed-sofia',
      email: 'sofia.demo@oceanmatch.app',
      firstName: 'Sofia',
      age: 29,
      gender: Gender.woman,
      searchGender: SearchGender.everyone,
      bio: 'Equipiere dispo pour une route vers les Caraibes cet hiver.',
      status: BoardStatus.crew,
      boatOrProject: 'Recherche embarquement',
      sailingType: 'Equipage partage',
      experience: SailingExperience.intermediate,
      lifestyle: ['equipage partage', 'aventure', 'escales calmes'],
      zone: 'Cap-Vert',
      route: 'Caraibes',
      currentPortId: 'mindelo',
      destinationPortId: 'pointe-a-pitre',
      intentions: [
        Intention.crew,
        Intention.sailingProject,
        Intention.friendship
      ],
      photos: const [
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=900&q=80',
      ],
    );
    _seedUser(
      id: 'seed-nina',
      email: 'nina.demo@oceanmatch.app',
      firstName: 'Nina',
      age: 37,
      gender: Gender.woman,
      searchGender: SearchGender.everyone,
      bio: 'Projet de vie a bord, encore a terre mais tres motivee.',
      status: BoardStatus.futureLiveaboard,
      boatOrProject: 'Projet catamaran',
      sailingType: 'Vie a bord progressive',
      experience: SailingExperience.beginner,
      lifestyle: ['confort', 'projet familial', 'navigation lente'],
      zone: 'Mediterranee',
      route: 'Canaries',
      currentPortId: 'palma',
      destinationPortId: 'santa-cruz-tenerife',
      intentions: [Intention.liveaboardProject, Intention.seriousRelationship],
      photos: const [
        'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=900&q=80',
      ],
    );
  }

  void _seedTestAccountIfNeeded(String email) {
    if (email != 'test@oceanmatch.app') return;
    final exists = _accounts.values.any(
      (account) =>
          account.email == 'test@oceanmatch.app' &&
          account.status != AccountStatus.deleted,
    );
    if (!exists) _seedTestUser();
  }

  void _seedTestUser() {
    _seedUser(
      id: 'seed-test',
      email: 'test@oceanmatch.app',
      firstName: 'Test',
      age: 35,
      gender: Gender.woman,
      searchGender: SearchGender.everyone,
      bio: 'Compte de test complet pour valider rapidement le parcours MVP.',
      status: BoardStatus.liveaboard,
      boatOrProject: 'Voilier test 34 pieds',
      sailingType: 'Navigation tranquille',
      experience: SailingExperience.intermediate,
      lifestyle: ['navigation lente', 'escales calmes', 'vie a bord'],
      zone: 'Canaries',
      route: 'Caraibes',
      currentPortId: 'las-palmas',
      destinationPortId: 'le-marin',
      intentions: [Intention.seriousRelationship, Intention.sailingProject],
      photos: const [
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=900&q=80',
      ],
    );
  }

  void _seedUser({
    required String id,
    required String email,
    required String firstName,
    required int age,
    required Gender gender,
    required SearchGender searchGender,
    required String bio,
    required BoardStatus status,
    required String boatOrProject,
    required String sailingType,
    required SailingExperience experience,
    required List<String> lifestyle,
    required String zone,
    required String route,
    String? currentPortId,
    String? destinationPortId,
    required List<Intention> intentions,
    required List<String> photos,
  }) {
    final now = DateTime.now();
    _accounts[id] = UserAccount(
      id: id,
      email: email,
      emailVerified: true,
      status: AccountStatus.active,
      createdAt: now,
    );
    _passwords[id] = 'password-demo';
    _profiles[id] = Profile(
      userId: id,
      firstName: firstName,
      birthDate: DateTime(now.year - age, now.month, now.day),
      gender: gender,
      searchGender: searchGender,
      languages: const ['Francais', 'Anglais'],
      bio: bio,
      isComplete: true,
      createdAt: now,
      updatedAt: now,
    );
    _photos[id] = [
      for (var i = 0; i < photos.length; i += 1)
        ProfilePhoto(
          id: '$id-photo-$i',
          userId: id,
          url: photos[i],
          isPrimary: i == 0,
          order: i,
          status: PhotoModerationStatus.approved,
          createdAt: now,
        ),
    ];
    _lifeAboard[id] = LifeAboard(
      userId: id,
      status: status,
      boatOrProject: boatOrProject,
      sailingType: sailingType,
      experience: experience,
      lifestyleTags: lifestyle,
      updatedAt: now,
    );
    final currentPort =
        harborPortById(currentPortId) ?? _firstPortForRegion(zone);
    final destinationPort =
        harborPortById(destinationPortId) ?? _firstPortForRegion(route);
    _currentZones[id] = CurrentZone(
      userId: id,
      zone: zone,
      country: currentPort?.country,
      portId: currentPort?.id,
      updatedAt: now,
    );
    _futureRoutes[id] = FutureRoute(
      id: '$id-route',
      userId: id,
      destinationZone: route,
      destinationCountry: destinationPort?.country,
      destinationPortId: destinationPort?.id,
      startPeriod: 'Hiver',
      endPeriod: 'Printemps',
      flexibility: RouteFlexibility.flexible,
      comment: '',
      isActive: true,
      updatedAt: now,
    );
    _preferences[id] = Preferences(
      userId: id,
      ageMin: 18,
      ageMax: 70,
      genderTargets: searchGender,
      zones: [zone, route],
      intentions: intentions,
    );
  }

  HarborPort? _firstPortForRegion(String region) {
    for (final port in harborPorts) {
      if (port.region == region) return port;
    }
    return null;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
