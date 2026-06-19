// ─────────────────────────────────────────────
// subscription_models.dart
// ─────────────────────────────────────────────

class SubscriptionModel {
  final int? id;
  final int? companyId; // ✅ NEW
  final int? projectId;
  final int? organizationId; // ✅ NEW
  final int? month;
  final int? year;

  // ── Plan Info ──────────────────────────────
  final String? plan; // "free" | "pro"
  final String? type; // ✅ NEW — "stripe" | "konnect" | "manual"
  final String? status; // active | past_due | canceled | trialing
  final int? seats; // ✅ NEW

  // ── Billing Cycle ──────────────────────────
  final String? billingInterval; // "month" | "year"
  final DateTime? currentPeriodStart; // ✅ NEW
  final DateTime? currentPeriodEnd; // ✅ NEW — used for countdown
  final bool? cancelAtPeriodEnd; // ✅ NEW
  final DateTime? trialEndsAt; // ✅ NEW

  // ── Payment Amounts ────────────────────────
  final int? price;
  final int? priceTotal;
  final double? amountPaid; // ✅ NEW — actual amount from Stripe
  final String? currency; // ✅ NEW — "EUR" | "TND"

  // ── Stripe References ──────────────────────
  final String? stripeSubscriptionId; // ✅ NEW
  final String? stripeSessionId; // ✅ NEW
  final String? stripeCustomerId; // ✅ NEW
  final String? stripeInvoiceId; // ✅ NEW
  final String? stripePriceId; // ✅ NEW
  final String? stripeProductId; // ✅ NEW
  final String? stripePaymentIntentId; // ✅ NEW

  // ── Legacy Konnect ─────────────────────────
  final String? konnectIdPaiment;
  final List<int> userIds;

  // ── Billing Location ───────────────────────
  final String? billingEmail; // ✅ NEW
  final String? billingCountry; // ✅ NEW

  // ── Payment Meta ───────────────────────────
  final DateTime? paymentDate; // ✅ NEW
  final String? paymentStatus; // "paid" | "unpaid" | "no_payment_required"

  // ── Timestamps ─────────────────────────────
  final DateTime? createdAt; // ✅ NEW
  final DateTime? updatedAt; // ✅ NEW

  // ── Relations ──────────────────────────────
  final Project? project;
  final Company? company;
  final List<SubscriptionUser> subscriptionUsers;
  final int? projectsCount;
  final int? usersCount;

  SubscriptionModel({
    this.id,
    this.companyId,
    this.projectId,
    this.organizationId,
    this.month,
    this.year,
    this.plan,
    this.type,
    this.status,
    this.seats,
    this.billingInterval,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd,
    this.trialEndsAt,
    this.price,
    this.priceTotal,
    this.amountPaid,
    this.currency,
    this.stripeSubscriptionId,
    this.stripeSessionId,
    this.stripeCustomerId,
    this.stripeInvoiceId,
    this.stripePriceId,
    this.stripeProductId,
    this.stripePaymentIntentId,
    this.konnectIdPaiment,
    this.userIds = const [],
    this.billingEmail,
    this.billingCountry,
    this.paymentDate,
    this.paymentStatus,
    this.createdAt,
    this.updatedAt,
    this.project,
    this.company,
    this.subscriptionUsers = const [],
    this.projectsCount,
    this.usersCount,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      companyId: json['companyId'],
      projectId: json['projectId'],
      organizationId: json['organizationId'],
      month: json['month'],
      year: json['year'],

      // Plan
      plan: json['plan'],
      type: json['type'],
      status: json['status'],
      seats: json['seats'],

      // Billing cycle
      billingInterval: json['billingInterval'],
      currentPeriodStart: _parseDate(json['currentPeriodStart']),
      currentPeriodEnd: _parseDate(json['currentPeriodEnd']),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'],
      trialEndsAt: _parseDate(json['trialEndsAt']),

      // Amounts
      price: json['price'],
      priceTotal: json['priceTotal'],
      amountPaid: num.tryParse(
        json['amountPaid']?.toString() ?? '',
      )?.toDouble(),
      currency: json['currency'],

      // Stripe
      stripeSubscriptionId: json['stripeSubscriptionId'],
      stripeSessionId: json['stripeSessionId'],
      stripeCustomerId: json['stripeCustomerId'],
      stripeInvoiceId: json['stripeInvoiceId'],
      stripePriceId: json['stripePriceId'],
      stripeProductId: json['stripeProductId'],
      stripePaymentIntentId: json['stripePaymentIntentId'],

      // Legacy
      konnectIdPaiment: json['konnectIdPaiment'],
      userIds: json['userIds'] == null
          ? []
          : (json['userIds'] as List).cast<int>(),

      // Billing location
      billingEmail: json['billingEmail'],
      billingCountry: json['billingCountry'],

      // Payment meta
      paymentDate: _parseDate(json['paymentDate']),
      paymentStatus: json['paymentStatus'],

      // Timestamps
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),

      // Relations
      project: json['project'] == null
          ? null
          : Project.fromJson(json['project']),
      company: json['company'] == null
          ? null
          : Company.fromJson(json['company']),
      subscriptionUsers: json['subscriptionUsers'] == null
          ? []
          : List<SubscriptionUser>.from(
              json['subscriptionUsers'].map(
                (x) => SubscriptionUser.fromJson(x),
              ),
            ),
      projectsCount: int.tryParse(json['projectsCount']?.toString() ?? ''),
      usersCount: int.tryParse(json['usersCount']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyId': companyId,
    'projectId': projectId,
    'organizationId': organizationId,
    'month': month,
    'year': year,
    'plan': plan,
    'type': type,
    'status': status,
    'seats': seats,
    'billingInterval': billingInterval,
    'currentPeriodStart': currentPeriodStart?.toIso8601String(),
    'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
    'cancelAtPeriodEnd': cancelAtPeriodEnd,
    'trialEndsAt': trialEndsAt?.toIso8601String(),
    'price': price,
    'priceTotal': priceTotal,
    'amountPaid': amountPaid,
    'currency': currency,
    'stripeSubscriptionId': stripeSubscriptionId,
    'stripeSessionId': stripeSessionId,
    'stripeCustomerId': stripeCustomerId,
    'stripeInvoiceId': stripeInvoiceId,
    'stripePriceId': stripePriceId,
    'stripeProductId': stripeProductId,
    'stripePaymentIntentId': stripePaymentIntentId,
    'konnectIdPaiment': konnectIdPaiment,
    'userIds': userIds,
    'billingEmail': billingEmail,
    'billingCountry': billingCountry,
    'paymentDate': paymentDate?.toIso8601String(),
    'paymentStatus': paymentStatus,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'project': project?.toJson(),
    'company': company?.toJson(),
    'subscriptionUsers': subscriptionUsers.map((x) => x.toJson()).toList(),
    'projectsCount': projectsCount,
    'usersCount': usersCount,
  };

  // ── Private helper ──────────────────────────────────────
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

// ─────────────────────────────────────────────
// Company
// ─────────────────────────────────────────────

class Company {
  final int? id;
  final String? name;
  final String? plan; // ✅ "free" | "pro"
  final int? seats; // ✅ NEW
  final String? billingEmail; // ✅ NEW
  final String? billingCountry; // ✅ NEW
  final String? stripeCustomerId; // ✅ NEW
  final String? stripeSessionId; // ✅ NEW
  final String? subscriptionStatus; // ✅ "pending" | "active" | ...
  final DateTime? createdAt; // ✅ NEW
  final DateTime? updatedAt; // ✅ NEW
  final List<UserCompany> userCompanies;

  Company({
    this.id,
    this.name,
    this.plan,
    this.seats,
    this.billingEmail,
    this.billingCountry,
    this.stripeCustomerId,
    this.stripeSessionId,
    this.subscriptionStatus,
    this.createdAt,
    this.updatedAt,
    this.userCompanies = const [],
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      plan: json['plan'],
      seats: json['seats'],
      billingEmail: json['billingEmail'],
      billingCountry: json['billingCountry'],
      stripeCustomerId: json['stripeCustomerId'],
      stripeSessionId: json['stripeSessionId'],
      subscriptionStatus: json['subscriptionStatus'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      userCompanies: json['userCompanies'] == null
          ? []
          : List<UserCompany>.from(
              json['userCompanies'].map((x) => UserCompany.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'plan': plan,
    'seats': seats,
    'billingEmail': billingEmail,
    'billingCountry': billingCountry,
    'stripeCustomerId': stripeCustomerId,
    'stripeSessionId': stripeSessionId,
    'subscriptionStatus': subscriptionStatus,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'userCompanies': userCompanies.map((x) => x.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────
// UserCompany
// ─────────────────────────────────────────────

class UserCompany {
  final int? id; // ✅ NEW
  final int? userId;
  final int? companyId;
  final String? role; // "owner" | "admin" | "member"
  final String? status; // "active" | "invited" | "suspended"
  final DateTime? joinedAt; // ✅ NEW

  UserCompany({
    this.id,
    this.userId,
    this.companyId,
    this.role,
    this.status,
    this.joinedAt,
  });

  factory UserCompany.fromJson(Map<String, dynamic> json) {
    return UserCompany(
      id: json['id'],
      userId: json['userId'],
      companyId: json['companyId'],
      role: json['role'],
      status: json['status'],
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'companyId': companyId,
    'role': role,
    'status': status,
    'joinedAt': joinedAt?.toIso8601String(),
  };
}

// ─────────────────────────────────────────────
// Project  (unchanged — already complete)
// ─────────────────────────────────────────────

class Project {
  final int? id;
  final String? name;
  final String? color;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? budget;
  final String? localisation;
  final String? latitude;
  final String? longitude;
  final int? delai;
  final String? delaiUnity;
  final dynamic imageId;
  final dynamic parentId;
  final bool? isActive;
  final DateTime? createdAt;
  final List<UserProject> userProjects;
  final Company? company;

  Project({
    this.id,
    this.name,
    this.color,
    this.description,
    this.startDate,
    this.endDate,
    this.budget,
    this.localisation,
    this.latitude,
    this.longitude,
    this.delai,
    this.delaiUnity,
    this.imageId,
    this.parentId,
    this.isActive,
    this.createdAt,
    this.userProjects = const [],
    this.company,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      description: json['description'],
      startDate: DateTime.tryParse(json['startDate'] ?? ''),
      endDate: DateTime.tryParse(json['endDate'] ?? ''),
      budget: json['budget'],
      localisation: json['localisation'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      delai: json['delai'],
      delaiUnity: json['delai_unity'],
      imageId: json['imageId'],
      parentId: json['parentId'],
      isActive: json['isActive'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      userProjects: json['userProjects'] == null
          ? []
          : List<UserProject>.from(
              json['userProjects'].map((x) => UserProject.fromJson(x)),
            ),
      company: json['company'] == null
          ? null
          : Company.fromJson(json['company']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'description': description,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'budget': budget,
    'localisation': localisation,
    'latitude': latitude,
    'longitude': longitude,
    'delai': delai,
    'delai_unity': delaiUnity,
    'imageId': imageId,
    'parentId': parentId,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
    'userProjects': userProjects.map((x) => x.toJson()).toList(),
    'company': company?.toJson(),
  };
}

// ─────────────────────────────────────────────
// UserProject  (unchanged)
// ─────────────────────────────────────────────

class UserProject {
  final int? id;
  final int? userId;
  final int? projectId;
  final String? role;
  final String? status;

  UserProject({this.id, this.userId, this.projectId, this.role, this.status});

  factory UserProject.fromJson(Map<String, dynamic> json) {
    return UserProject(
      id: json['id'],
      userId: json['userId'],
      projectId: json['projectId'],
      role: json['role'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'projectId': projectId,
    'role': role,
    'status': status,
  };
}

// ─────────────────────────────────────────────
// SubscriptionUser
// ─────────────────────────────────────────────

class SubscriptionUser {
  final int? id;
  final int? userId;
  final int? subscriptionId;
  final bool? isPaid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SubscriptionUserDetail? user;

  SubscriptionUser({
    this.id,
    this.userId,
    this.subscriptionId,
    this.isPaid,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory SubscriptionUser.fromJson(Map<String, dynamic> json) {
    return SubscriptionUser(
      id: json['id'],
      userId: json['userId'],
      subscriptionId: json['subscriptionId'],
      isPaid: json['isPaid'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      user: json['user'] == null
          ? null
          : SubscriptionUserDetail.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'subscriptionId': subscriptionId,
    'isPaid': isPaid,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'user': user?.toJson(),
  };
}

// ─────────────────────────────────────────────
// SubscriptionUserDetail
// ─────────────────────────────────────────────

class SubscriptionUserDetail {
  final int? id;
  final dynamic firstname;
  final dynamic lastname;
  final String? email;
  final dynamic phone;
  final dynamic function;
  final bool? isActive;
  final int? imageId;
  final dynamic organizationId;

  SubscriptionUserDetail({
    this.id,
    this.firstname,
    this.lastname,
    this.email,
    this.phone,
    this.function,
    this.isActive,
    this.imageId,
    this.organizationId,
  });

  factory SubscriptionUserDetail.fromJson(Map<String, dynamic> json) {
    return SubscriptionUserDetail(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      function: json['function'],
      isActive: json['isActive'],
      imageId: json['imageId'],
      organizationId: json['organizationId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstname': firstname,
    'lastname': lastname,
    'email': email,
    'phone': phone,
    'function': function,
    'isActive': isActive,
    'imageId': imageId,
    'organizationId': organizationId,
  };
}
