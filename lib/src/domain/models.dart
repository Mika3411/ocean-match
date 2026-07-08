enum AccountStatus { pendingEmailVerification, active, suspended, deleted }

enum Gender { woman, man, nonBinary, other }

enum SearchGender { women, men, everyone }

enum BoardStatus {
  liveaboard,
  longDistanceSailor,
  owner,
  crew,
  futureLiveaboard,
}

enum SailingExperience { beginner, intermediate, confirmed, expert }

enum RouteFlexibility { fixed, flexible, veryFlexible }

enum Intention {
  seriousRelationship,
  casualDating,
  friendship,
  crew,
  sailingProject,
  liveaboardProject,
}

enum PhotoModerationStatus { pending, approved, rejected }

enum MatchStatus { active, blocked, deleted }

enum ReportReason {
  fakeProfile,
  harassment,
  inappropriateContent,
  suspiciousBehavior,
  other,
}

enum ReportStatus { newReport, inReview, resolved, rejected }

extension GenderLabel on Gender {
  String get label {
    switch (this) {
      case Gender.woman:
        return 'Femme';
      case Gender.man:
        return 'Homme';
      case Gender.nonBinary:
        return 'Non binaire';
      case Gender.other:
        return 'Autre';
    }
  }
}

extension SearchGenderLabel on SearchGender {
  String get label {
    switch (this) {
      case SearchGender.women:
        return 'Femmes';
      case SearchGender.men:
        return 'Hommes';
      case SearchGender.everyone:
        return 'Tout le monde';
    }
  }
}

extension BoardStatusLabel on BoardStatus {
  String get label {
    switch (this) {
      case BoardStatus.liveaboard:
        return 'Vit a bord';
      case BoardStatus.longDistanceSailor:
        return 'Navigue longtemps';
      case BoardStatus.owner:
        return 'Proprietaire';
      case BoardStatus.crew:
        return 'Equipier';
      case BoardStatus.futureLiveaboard:
        return 'Projet vie a bord';
    }
  }
}

extension SailingExperienceLabel on SailingExperience {
  String get label {
    switch (this) {
      case SailingExperience.beginner:
        return 'Debutant';
      case SailingExperience.intermediate:
        return 'Intermediaire';
      case SailingExperience.confirmed:
        return 'Confirme';
      case SailingExperience.expert:
        return 'Expert';
    }
  }
}

extension RouteFlexibilityLabel on RouteFlexibility {
  String get label {
    switch (this) {
      case RouteFlexibility.fixed:
        return 'Fixe';
      case RouteFlexibility.flexible:
        return 'Flexible';
      case RouteFlexibility.veryFlexible:
        return 'Tres flexible';
    }
  }
}

extension IntentionLabel on Intention {
  String get label {
    switch (this) {
      case Intention.seriousRelationship:
        return 'Relation serieuse';
      case Intention.casualDating:
        return 'Rencontre legere';
      case Intention.friendship:
        return 'Amitie';
      case Intention.crew:
        return 'Equipier';
      case Intention.sailingProject:
        return 'Projet de navigation';
      case Intention.liveaboardProject:
        return 'Projet vie a bord';
    }
  }
}

extension ReportReasonLabel on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.fakeProfile:
        return 'Faux profil';
      case ReportReason.harassment:
        return 'Harcelement';
      case ReportReason.inappropriateContent:
        return 'Contenu inapproprie';
      case ReportReason.suspiciousBehavior:
        return 'Comportement suspect';
      case ReportReason.other:
        return 'Autre';
    }
  }
}

class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final String email;
  final bool emailVerified;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserAccount copyWith({
    String? email,
    bool? emailVerified,
    AccountStatus? status,
    DateTime? lastLoginAt,
  }) {
    return UserAccount(
      id: id,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      status: status ?? this.status,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class Profile {
  const Profile({
    required this.userId,
    required this.firstName,
    required this.birthDate,
    required this.gender,
    required this.searchGender,
    required this.languages,
    required this.bio,
    required this.isComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String firstName;
  final DateTime birthDate;
  final Gender gender;
  final SearchGender searchGender;
  final List<String> languages;
  final String bio;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get age {
    final now = DateTime.now();
    var value = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      value -= 1;
    }
    return value;
  }

  Profile copyWith({
    String? firstName,
    DateTime? birthDate,
    Gender? gender,
    SearchGender? searchGender,
    List<String>? languages,
    String? bio,
    bool? isComplete,
  }) {
    return Profile(
      userId: userId,
      firstName: firstName ?? this.firstName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      searchGender: searchGender ?? this.searchGender,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class ProfilePhoto {
  const ProfilePhoto({
    required this.id,
    required this.userId,
    required this.url,
    required this.isPrimary,
    required this.order,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String url;
  final bool isPrimary;
  final int order;
  final PhotoModerationStatus status;
  final DateTime createdAt;

  ProfilePhoto copyWith({
    String? url,
    bool? isPrimary,
    int? order,
    PhotoModerationStatus? status,
  }) {
    return ProfilePhoto(
      id: id,
      userId: userId,
      url: url ?? this.url,
      isPrimary: isPrimary ?? this.isPrimary,
      order: order ?? this.order,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class LifeAboard {
  const LifeAboard({
    required this.userId,
    required this.status,
    required this.boatOrProject,
    required this.sailingType,
    required this.experience,
    required this.lifestyleTags,
    required this.updatedAt,
  });

  final String userId;
  final BoardStatus status;
  final String boatOrProject;
  final String sailingType;
  final SailingExperience experience;
  final List<String> lifestyleTags;
  final DateTime updatedAt;
}

class CurrentZone {
  const CurrentZone({
    required this.userId,
    required this.zone,
    required this.updatedAt,
    this.country,
    this.portId,
  });

  final String userId;
  final String zone;
  final String? country;
  final String? portId;
  final DateTime updatedAt;
}

class FutureRoute {
  const FutureRoute({
    required this.id,
    required this.userId,
    required this.destinationZone,
    required this.startPeriod,
    required this.endPeriod,
    required this.flexibility,
    required this.comment,
    required this.isActive,
    required this.updatedAt,
    this.destinationCountry,
    this.destinationPortId,
  });

  final String id;
  final String userId;
  final String destinationZone;
  final String? destinationCountry;
  final String? destinationPortId;
  final String startPeriod;
  final String endPeriod;
  final RouteFlexibility flexibility;
  final String comment;
  final bool isActive;
  final DateTime updatedAt;

  FutureRoute copyWith({
    String? destinationZone,
    String? startPeriod,
    String? endPeriod,
    RouteFlexibility? flexibility,
    String? comment,
    bool? isActive,
    String? destinationCountry,
    String? destinationPortId,
  }) {
    return FutureRoute(
      id: id,
      userId: userId,
      destinationZone: destinationZone ?? this.destinationZone,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      destinationPortId: destinationPortId ?? this.destinationPortId,
      startPeriod: startPeriod ?? this.startPeriod,
      endPeriod: endPeriod ?? this.endPeriod,
      flexibility: flexibility ?? this.flexibility,
      comment: comment ?? this.comment,
      isActive: isActive ?? this.isActive,
      updatedAt: DateTime.now(),
    );
  }
}

class HarborPort {
  const HarborPort({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String country;
  final String region;
  final double latitude;
  final double longitude;

  String get displayName => '$name, $country';

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        country.toLowerCase().contains(normalized) ||
        region.toLowerCase().contains(normalized);
  }
}

class PortActivity {
  const PortActivity({
    required this.port,
    required this.currentCount,
    required this.destinationCount,
    required this.isCurrentUserHere,
    required this.isCurrentUserGoing,
  });

  final HarborPort port;
  final int currentCount;
  final int destinationCount;
  final bool isCurrentUserHere;
  final bool isCurrentUserGoing;

  int get totalCount => currentCount + destinationCount;
}

class Preferences {
  const Preferences({
    required this.userId,
    required this.ageMin,
    required this.ageMax,
    required this.genderTargets,
    required this.zones,
    required this.intentions,
  });

  final String userId;
  final int ageMin;
  final int ageMax;
  final SearchGender genderTargets;
  final List<String> zones;
  final List<Intention> intentions;
}

class Like {
  const Like({
    required this.userId,
    required this.targetUserId,
    required this.createdAt,
  });

  final String userId;
  final String targetUserId;
  final DateTime createdAt;
}

class Pass {
  const Pass({
    required this.userId,
    required this.targetUserId,
    required this.createdAt,
  });

  final String userId;
  final String targetUserId;
  final DateTime createdAt;
}

class Match {
  const Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String user1Id;
  final String user2Id;
  final MatchStatus status;
  final DateTime createdAt;

  bool contains(String userId) => user1Id == userId || user2Id == userId;

  String otherUserId(String userId) => user1Id == userId ? user2Id : user1Id;

  Match copyWith({MatchStatus? status}) {
    return Match(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.lastMessageAt,
  });

  final String id;
  final String matchId;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  bool contains(String userId) => user1Id == userId || user2Id == userId;

  String otherUserId(String userId) => user1Id == userId ? user2Id : user1Id;

  Conversation copyWith({DateTime? lastMessageAt}) {
    return Conversation(
      id: id,
      matchId: matchId,
      user1Id: user1Id,
      user2Id: user2Id,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
    this.deletedAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? deletedAt;
}

class Block {
  const Block({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  final String id;
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;
}

class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.conversationId,
    this.messageId,
    this.comment,
  });

  final String id;
  final String reporterId;
  final String reportedId;
  final String? conversationId;
  final String? messageId;
  final ReportReason reason;
  final String? comment;
  final ReportStatus status;
  final DateTime createdAt;
}

class DiscoveryProfile {
  const DiscoveryProfile({
    required this.profile,
    required this.photos,
    required this.lifeAboard,
    required this.currentZone,
    required this.futureRoute,
    required this.intentions,
    required this.score,
  });

  final Profile profile;
  final List<ProfilePhoto> photos;
  final LifeAboard lifeAboard;
  final CurrentZone currentZone;
  final FutureRoute futureRoute;
  final List<Intention> intentions;
  final int score;

  ProfilePhoto? get primaryPhoto {
    final approved = photos.where(
      (photo) => photo.status == PhotoModerationStatus.approved,
    );
    if (approved.isEmpty) return null;
    return approved.firstWhere(
      (photo) => photo.isPrimary,
      orElse: () => approved.first,
    );
  }
}

class ConversationSummary {
  const ConversationSummary({
    required this.conversation,
    required this.match,
    required this.otherProfile,
    required this.otherPhoto,
    required this.isBlocked,
    this.lastMessage,
  });

  final Conversation conversation;
  final Match match;
  final Profile otherProfile;
  final ProfilePhoto? otherPhoto;
  final Message? lastMessage;
  final bool isBlocked;
}

class MatchResult {
  const MatchResult({
    required this.createdMatch,
    this.match,
    this.conversation,
    this.matchedProfile,
  });

  final bool createdMatch;
  final Match? match;
  final Conversation? conversation;
  final DiscoveryProfile? matchedProfile;
}
