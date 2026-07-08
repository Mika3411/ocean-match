import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_error.dart';
import '../domain/models.dart';
import 'ocean_match_repository.dart';

class ApiOceanMatchRepository extends MockOceanMatchRepository {
  ApiOceanMatchRepository({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = _trimTrailingSlash(baseUrl),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;
  final Map<String, String> _verificationTokensByUserId = {};

  String? _accessToken;
  String? _refreshToken;

  static String defaultBaseUrl() {
    const configured = String.fromEnvironment('OCEAN_MATCH_API_URL');
    if (configured.isNotEmpty) return configured;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/v1';
    }
    return 'http://localhost:8080/v1';
  }

  @override
  Future<UserAccount> signUp({
    required String email,
    required String password,
  }) async {
    final result = await _request(
      'POST',
      'auth/signup',
      body: {'email': email, 'password': password},
    );
    return _applyAuthResult(result, password: password);
  }

  @override
  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    final result = await _request(
      'POST',
      'auth/login',
      body: {'email': email, 'password': password},
    );
    final user = _applyAuthResult(result, password: password);
    await _hydrateCurrentUser(user);
    return getAccount(user.id) ?? user;
  }

  @override
  Future<UserAccount> verifyEmail(String userId) async {
    final token = _verificationTokensByUserId[userId];
    if (token == null || token.isEmpty) {
      throw const OceanMatchException(
        'Aucun token de verification local disponible. Utilisez le lien recu par email ou renvoyez un email de verification.',
      );
    }

    final result = await _request(
      'POST',
      'auth/verify-email',
      body: {'token': token},
    );
    final userJson = _mapOrThrow(result['user']);
    final user = _parseUser(userJson);
    _verificationTokensByUserId.remove(userId);
    syncApiAccount(user);
    await _hydrateCurrentUser(user);
    return getAccount(user.id) ?? user;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _request(
      'POST',
      'auth/password-reset',
      body: {'email': email},
    );
  }

  @override
  Future<void> requestEmailVerification(String userId) async {
    final result = await _request(
      'POST',
      'auth/resend-verification',
      authenticated: true,
    );
    _storeVerificationToken(userId, result);
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
    await _request(
      'PUT',
      'profile',
      authenticated: true,
      body: {
        'firstName': profile.firstName,
        'birthDate': _dateOnly(profile.birthDate),
        'gender': _genderToApi(profile.gender),
        'searchGender': _searchGenderToApi(profile.searchGender),
        'languages': profile.languages,
        'bio': profile.bio,
      },
    );
    await _request(
      'PUT',
      'life-aboard',
      authenticated: true,
      body: {
        'status': _boardStatusToApi(lifeAboard.status),
        'boatOrProject': lifeAboard.boatOrProject,
        'sailingType': lifeAboard.sailingType,
        'experience': _sailingExperienceToApi(lifeAboard.experience),
        'lifestyleTags': lifeAboard.lifestyleTags,
      },
    );
    await _request(
      'PUT',
      'current-zone',
      authenticated: true,
      body: {
        'zone': currentZone.zone,
        if (currentZone.country != null) 'country': currentZone.country,
        if (currentZone.portId != null) 'portId': currentZone.portId,
      },
    );
    await _request(
      'PUT',
      'future-route',
      authenticated: true,
      body: {
        'destinationZone': futureRoute.destinationZone,
        if (futureRoute.destinationCountry != null)
          'destinationCountry': futureRoute.destinationCountry,
        if (futureRoute.destinationPortId != null)
          'destinationPortId': futureRoute.destinationPortId,
        'startPeriod': futureRoute.startPeriod,
        'endPeriod': futureRoute.endPeriod,
        'flexibility': _routeFlexibilityToApi(futureRoute.flexibility),
        'comment': futureRoute.comment,
      },
    );
    await _request(
      'PUT',
      'preferences',
      authenticated: true,
      body: {
        'ageMin': preferences.ageMin,
        'ageMax': preferences.ageMax,
        'genderTargets': _searchGenderToApi(preferences.genderTargets),
        'zones': preferences.zones,
        'intentions': preferences.intentions.map(_intentionToApi).toList(),
      },
    );

    await super.completeOnboarding(
      profile: profile,
      photos: photos,
      lifeAboard: lifeAboard,
      currentZone: currentZone,
      futureRoute: futureRoute,
      preferences: preferences,
    );
  }

  @override
  Future<void> updateCurrentZone(String userId, CurrentZone zone) async {
    await _request(
      'PUT',
      'current-zone',
      authenticated: true,
      body: {
        'zone': zone.zone,
        if (zone.country != null) 'country': zone.country,
        if (zone.portId != null) 'portId': zone.portId,
      },
    );
    await super.updateCurrentZone(userId, zone);
  }

  @override
  Future<void> updateFutureRoute(String userId, FutureRoute route) async {
    await _request(
      'PUT',
      'future-route',
      authenticated: true,
      body: {
        'destinationZone': route.destinationZone,
        if (route.destinationCountry != null)
          'destinationCountry': route.destinationCountry,
        if (route.destinationPortId != null)
          'destinationPortId': route.destinationPortId,
        'startPeriod': route.startPeriod,
        'endPeriod': route.endPeriod,
        'flexibility': _routeFlexibilityToApi(route.flexibility),
        'comment': route.comment,
      },
    );
    await super.updateFutureRoute(userId, route);
  }

  @override
  Future<void> updateCurrentPort(String userId, HarborPort port) async {
    await _request(
      'PUT',
      'current-zone',
      authenticated: true,
      body: {
        'zone': port.region,
        'country': port.country,
        'portId': port.id,
      },
    );
    await super.updateCurrentPort(userId, port);
  }

  @override
  Future<void> updateDestinationPort(String userId, HarborPort port) async {
    await _request(
      'PUT',
      'future-route',
      authenticated: true,
      body: {
        'destinationZone': port.region,
        'destinationCountry': port.country,
        'destinationPortId': port.id,
        'startPeriod': getFutureRoute(userId)?.startPeriod ?? 'A preciser',
        'endPeriod': getFutureRoute(userId)?.endPeriod ?? 'A preciser',
        'flexibility': _routeFlexibilityToApi(
          getFutureRoute(userId)?.flexibility ?? RouteFlexibility.flexible,
        ),
        'comment': getFutureRoute(userId)?.comment ?? '',
      },
    );
    await super.updateDestinationPort(userId, port);
  }

  @override
  Future<void> deleteAccount(String userId) async {
    await _request('DELETE', 'account', authenticated: true);
    await super.deleteAccount(userId);
  }

  Future<void> _hydrateCurrentUser(UserAccount user) async {
    if (!user.emailVerified || user.status != AccountStatus.active) return;

    final result = await _request('GET', 'me', authenticated: true);
    final userData = _maybeMap(result['user']);
    if (userData != null) {
      syncApiAccount(_parseUser(userData));
    }

    final profile = _maybeMap(result['profile']);
    final lifeAboard = _maybeMap(result['lifeAboard']);
    final currentZone = _maybeMap(result['currentZone']);
    final futureRoute = _maybeMap(result['futureRoute']);
    final preferences = _maybeMap(result['preferences']);
    final photos = _listOfMaps(result['photos']).map(_parsePhoto).toList();

    final parsedProfile = profile == null ? null : _parseProfile(profile);
    final parsedLifeAboard =
        lifeAboard == null ? null : _parseLifeAboard(lifeAboard);
    final parsedCurrentZone =
        currentZone == null ? null : _parseCurrentZone(currentZone);
    final parsedFutureRoute =
        futureRoute == null ? null : _parseFutureRoute(futureRoute);
    final parsedPreferences =
        preferences == null ? null : _parsePreferences(preferences);
    final hasPublishedOnboarding = parsedProfile != null &&
        parsedLifeAboard != null &&
        parsedCurrentZone != null &&
        parsedFutureRoute != null &&
        parsedPreferences != null;

    syncApiProfileSnapshot(
      profile: hasPublishedOnboarding
          ? parsedProfile.copyWith(isComplete: true)
          : parsedProfile,
      photos: photos,
      lifeAboard: parsedLifeAboard,
      currentZone: parsedCurrentZone,
      futureRoute: parsedFutureRoute,
      preferences: parsedPreferences,
    );
  }

  UserAccount _applyAuthResult(
    Map<String, dynamic> result, {
    String? password,
  }) {
    final user = _parseUser(_mapOrThrow(result['user']));
    _storeTokens(result);
    _storeVerificationToken(user.id, result);
    syncApiAccount(user, password: password);
    return user;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool authenticated = false,
    bool retryOnUnauthorized = true,
  }) async {
    try {
      var response = await _send(
        method,
        path,
        body: body,
        authenticated: authenticated,
      );
      if (authenticated &&
          response.statusCode == 401 &&
          retryOnUnauthorized &&
          await _refreshSession()) {
        response = await _send(
          method,
          path,
          body: body,
          authenticated: authenticated,
        );
      }
      return _decodeResponse(response);
    } on OceanMatchException {
      rethrow;
    } on TimeoutException {
      throw const OceanMatchException(
        'L API BlueWater Match ne repond pas. Verifiez que le backend est lance.',
      );
    } catch (_) {
      throw const OceanMatchException(
        'Impossible de joindre l API BlueWater Match. Verifiez que le backend est lance et que OCEAN_MATCH_API_URL pointe vers /v1.',
      );
    }
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool authenticated = false,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = _accessToken;
      if (token == null || token.isEmpty) {
        throw const OceanMatchException(
          'Session API absente. Reconnectez-vous pour continuer.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }
    final uri = Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}');
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        return _httpClient
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 12));
      case 'POST':
        return _httpClient
            .post(uri, headers: headers, body: encodedBody)
            .timeout(const Duration(seconds: 12));
      case 'PUT':
        return _httpClient
            .put(uri, headers: headers, body: encodedBody)
            .timeout(const Duration(seconds: 12));
      case 'DELETE':
        return _httpClient
            .delete(uri, headers: headers, body: encodedBody)
            .timeout(const Duration(seconds: 12));
      default:
        throw OceanMatchException('Methode API non supportee: $method.');
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = response.bodyBytes.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes));
    final body = decoded is Map ? _mapOrThrow(decoded) : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = _maybeMap(body['error']);
    final message = error?['message'] ?? body['message'];
    if (message is String && message.trim().isNotEmpty) {
      throw OceanMatchException(message.trim());
    }
    throw OceanMatchException('Erreur API (${response.statusCode}).');
  }

  Future<bool> _refreshSession() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _send(
        'POST',
        'auth/refresh',
        body: {'refreshToken': refreshToken},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      _applyAuthResult(_decodeResponse(response));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _storeTokens(Map<String, dynamic> result) {
    final tokens = _maybeMap(result['tokens']);
    if (tokens == null) return;
    final accessToken = tokens['accessToken'];
    final refreshToken = tokens['refreshToken'];
    if (accessToken is String && accessToken.isNotEmpty) {
      _accessToken = accessToken;
    }
    if (refreshToken is String && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }
  }

  void _storeVerificationToken(String userId, Map<String, dynamic> result) {
    final token = result['debugEmailVerificationToken'];
    if (token is String && token.isNotEmpty) {
      _verificationTokensByUserId[userId] = token;
    }
  }

  UserAccount _parseUser(Map<String, dynamic> json) {
    return UserAccount(
      id: _requiredString(json, 'id'),
      email: _requiredString(json, 'email'),
      emailVerified: json['emailVerified'] == true,
      status: _accountStatusFromApi(_requiredString(json, 'status')),
      createdAt: _dateTime(json['createdAt']),
      lastLoginAt: _nullableDateTime(json['lastLoginAt']),
    );
  }

  Profile _parseProfile(Map<String, dynamic> json) {
    return Profile(
      userId: _requiredString(json, 'userId'),
      firstName: _requiredString(json, 'firstName'),
      birthDate: _dateTime(json['birthDate']),
      gender: _genderFromApi(_requiredString(json, 'gender')),
      searchGender: _searchGenderFromApi(_requiredString(json, 'searchGender')),
      languages: _stringList(json['languages']),
      bio: _requiredString(json, 'bio'),
      isComplete: json['isComplete'] == true,
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }

  ProfilePhoto _parsePhoto(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: _requiredString(json, 'id'),
      userId: _requiredString(json, 'userId'),
      url: _requiredString(json, 'url'),
      isPrimary: json['isPrimary'] == true,
      order: _intValue(json['order']),
      status: _photoStatusFromApi(_requiredString(json, 'status')),
      createdAt: _dateTime(json['createdAt']),
    );
  }

  LifeAboard _parseLifeAboard(Map<String, dynamic> json) {
    return LifeAboard(
      userId: _requiredString(json, 'userId'),
      status: _boardStatusFromApi(_requiredString(json, 'status')),
      boatOrProject: _requiredString(json, 'boatOrProject'),
      sailingType: _requiredString(json, 'sailingType'),
      experience:
          _sailingExperienceFromApi(_requiredString(json, 'experience')),
      lifestyleTags: _stringList(json['lifestyleTags']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }

  CurrentZone _parseCurrentZone(Map<String, dynamic> json) {
    return CurrentZone(
      userId: _requiredString(json, 'userId'),
      zone: _requiredString(json, 'zone'),
      country: _optionalString(json['country']),
      portId: _optionalString(json['portId']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }

  FutureRoute _parseFutureRoute(Map<String, dynamic> json) {
    return FutureRoute(
      id: _requiredString(json, 'id'),
      userId: _requiredString(json, 'userId'),
      destinationZone: _requiredString(json, 'destinationZone'),
      destinationCountry: _optionalString(json['destinationCountry']),
      destinationPortId: _optionalString(json['destinationPortId']),
      startPeriod: _requiredString(json, 'startPeriod'),
      endPeriod: _requiredString(json, 'endPeriod'),
      flexibility:
          _routeFlexibilityFromApi(_requiredString(json, 'flexibility')),
      comment: _requiredString(json, 'comment'),
      isActive: json['isActive'] == true,
      updatedAt: _dateTime(json['updatedAt']),
    );
  }

  Preferences _parsePreferences(Map<String, dynamic> json) {
    return Preferences(
      userId: _requiredString(json, 'userId'),
      ageMin: _intValue(json['ageMin']),
      ageMax: _intValue(json['ageMax']),
      genderTargets:
          _searchGenderFromApi(_requiredString(json, 'genderTargets')),
      zones: _stringList(json['zones']),
      intentions:
          _stringList(json['intentions']).map(_intentionFromApi).toList(),
    );
  }

  static String _trimTrailingSlash(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static Map<String, dynamic> _mapOrThrow(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const OceanMatchException('Reponse API invalide.');
  }

  static Map<String, dynamic>? _maybeMap(Object? value) {
    if (value == null) return null;
    return _mapOrThrow(value);
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return const [];
    return value.map(_mapOrThrow).toList();
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    if (value != null) return value.toString();
    throw OceanMatchException('Champ API manquant: $key.');
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _dateTime(Object? value) {
    return _nullableDateTime(value) ?? DateTime.now();
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static AccountStatus _accountStatusFromApi(String value) {
    switch (value) {
      case 'pending_email_verification':
        return AccountStatus.pendingEmailVerification;
      case 'active':
        return AccountStatus.active;
      case 'suspended':
        return AccountStatus.suspended;
      case 'deleted':
        return AccountStatus.deleted;
      default:
        throw OceanMatchException('Statut de compte inconnu: $value.');
    }
  }

  static String _genderToApi(Gender value) {
    switch (value) {
      case Gender.woman:
        return 'woman';
      case Gender.man:
        return 'man';
      case Gender.nonBinary:
        return 'non_binary';
      case Gender.other:
        return 'other';
    }
  }

  static Gender _genderFromApi(String value) {
    switch (value) {
      case 'woman':
        return Gender.woman;
      case 'man':
        return Gender.man;
      case 'non_binary':
        return Gender.nonBinary;
      case 'other':
        return Gender.other;
      default:
        throw OceanMatchException('Genre inconnu: $value.');
    }
  }

  static String _searchGenderToApi(SearchGender value) {
    switch (value) {
      case SearchGender.women:
        return 'women';
      case SearchGender.men:
        return 'men';
      case SearchGender.everyone:
        return 'everyone';
    }
  }

  static SearchGender _searchGenderFromApi(String value) {
    switch (value) {
      case 'women':
        return SearchGender.women;
      case 'men':
        return SearchGender.men;
      case 'everyone':
        return SearchGender.everyone;
      default:
        throw OceanMatchException('Recherche inconnue: $value.');
    }
  }

  static String _boardStatusToApi(BoardStatus value) {
    switch (value) {
      case BoardStatus.liveaboard:
        return 'liveaboard';
      case BoardStatus.longDistanceSailor:
        return 'long_distance_sailor';
      case BoardStatus.owner:
        return 'owner';
      case BoardStatus.crew:
        return 'crew';
      case BoardStatus.futureLiveaboard:
        return 'future_liveaboard';
    }
  }

  static BoardStatus _boardStatusFromApi(String value) {
    switch (value) {
      case 'liveaboard':
        return BoardStatus.liveaboard;
      case 'long_distance_sailor':
        return BoardStatus.longDistanceSailor;
      case 'owner':
        return BoardStatus.owner;
      case 'crew':
        return BoardStatus.crew;
      case 'future_liveaboard':
        return BoardStatus.futureLiveaboard;
      default:
        throw OceanMatchException('Statut de vie a bord inconnu: $value.');
    }
  }

  static String _sailingExperienceToApi(SailingExperience value) {
    switch (value) {
      case SailingExperience.beginner:
        return 'beginner';
      case SailingExperience.intermediate:
        return 'intermediate';
      case SailingExperience.confirmed:
        return 'confirmed';
      case SailingExperience.expert:
        return 'expert';
    }
  }

  static SailingExperience _sailingExperienceFromApi(String value) {
    switch (value) {
      case 'beginner':
        return SailingExperience.beginner;
      case 'intermediate':
        return SailingExperience.intermediate;
      case 'confirmed':
        return SailingExperience.confirmed;
      case 'expert':
        return SailingExperience.expert;
      default:
        throw OceanMatchException('Experience inconnue: $value.');
    }
  }

  static String _routeFlexibilityToApi(RouteFlexibility value) {
    switch (value) {
      case RouteFlexibility.fixed:
        return 'fixed';
      case RouteFlexibility.flexible:
        return 'flexible';
      case RouteFlexibility.veryFlexible:
        return 'very_flexible';
    }
  }

  static RouteFlexibility _routeFlexibilityFromApi(String value) {
    switch (value) {
      case 'fixed':
        return RouteFlexibility.fixed;
      case 'flexible':
        return RouteFlexibility.flexible;
      case 'very_flexible':
        return RouteFlexibility.veryFlexible;
      default:
        throw OceanMatchException('Flexibilite inconnue: $value.');
    }
  }

  static String _intentionToApi(Intention value) {
    switch (value) {
      case Intention.seriousRelationship:
        return 'serious_relationship';
      case Intention.casualDating:
        return 'casual_dating';
      case Intention.friendship:
        return 'friendship';
      case Intention.crew:
        return 'crew';
      case Intention.sailingProject:
        return 'sailing_project';
      case Intention.liveaboardProject:
        return 'liveaboard_project';
    }
  }

  static Intention _intentionFromApi(String value) {
    switch (value) {
      case 'serious_relationship':
        return Intention.seriousRelationship;
      case 'casual_dating':
        return Intention.casualDating;
      case 'friendship':
        return Intention.friendship;
      case 'crew':
        return Intention.crew;
      case 'sailing_project':
        return Intention.sailingProject;
      case 'liveaboard_project':
        return Intention.liveaboardProject;
      default:
        throw OceanMatchException('Intention inconnue: $value.');
    }
  }

  static PhotoModerationStatus _photoStatusFromApi(String value) {
    switch (value) {
      case 'pending':
        return PhotoModerationStatus.pending;
      case 'approved':
        return PhotoModerationStatus.approved;
      case 'rejected':
        return PhotoModerationStatus.rejected;
      default:
        throw OceanMatchException('Statut photo inconnu: $value.');
    }
  }
}

OceanMatchRepository createDefaultOceanMatchRepository() {
  const useMock = bool.fromEnvironment('OCEAN_MATCH_USE_MOCK_REPOSITORY');
  if (useMock) return MockOceanMatchRepository();
  return ApiOceanMatchRepository(
    baseUrl: ApiOceanMatchRepository.defaultBaseUrl(),
  );
}
