// ============================================================
// 1. POST /api/v1/auth/login
// ============================================================

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: (json['email'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };

  @override
  String toString() => 'LoginRequest(email: $email)';
}

// NOTE: Response body for /api/v1/auth/login was not captured in the
// timeline (only "user receives a JWT" is documented). No model created
// until the actual response shape is confirmed.


// ============================================================
// 2. GET /api/v2/admin/hospital?hospital_id={id}
// ============================================================

class HospitalDetails {
  final String hospitalId;
  final String? slug;
  final String? name;
  final String? defaultLanguage;
  final bool? collectCaste;
  final String? createdAt;
  final bool? hasKioskPin;

  HospitalDetails({
    required this.hospitalId,
    this.slug,
    this.name,
    this.defaultLanguage,
    this.collectCaste,
    this.createdAt,
    this.hasKioskPin,
  });

  factory HospitalDetails.fromJson(Map<String, dynamic> json) {
    return HospitalDetails(
      hospitalId: (json['hospital_id'] ?? '').toString(),
      slug: json['slug'],
      name: json['name'],
      defaultLanguage: json['default_language'],
      collectCaste: json['collect_caste'],
      createdAt: json['created_at'],
      hasKioskPin: json['has_kiosk_pin'],
    );
  }

  Map<String, dynamic> toJson() => {
    'hospital_id': hospitalId,
    'slug': slug,
    'name': name,
    'default_language': defaultLanguage,
    'collect_caste': collectCaste,
    'created_at': createdAt,
    'has_kiosk_pin': hasKioskPin,
  };

  @override
  String toString() =>
      'HospitalDetails(hospitalId: $hospitalId, slug: $slug, name: $name)';
}


// ============================================================
// 3. GET /api/v2/t/{slug}/config
// (Also re-used verbatim for the "Kiosk Reset" call.)
// ============================================================

class KioskConfig {
  final String? slug;
  final String? name;
  final bool? collectCaste;
  final bool? hasKioskPin;

  KioskConfig({
    this.slug,
    this.name,
    this.collectCaste,
    this.hasKioskPin,
  });

  factory KioskConfig.fromJson(Map<String, dynamic> json) {
    return KioskConfig(
      slug: json['slug'],
      name: json['name'],
      collectCaste: json['collect_caste'],
      hasKioskPin: json['has_kiosk_pin'],
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'collect_caste': collectCaste,
    'has_kiosk_pin': hasKioskPin,
  };

  @override
  String toString() =>
      'KioskConfig(slug: $slug, name: $name, hasKioskPin: $hasKioskPin)';
}


// ============================================================
// 4. POST /api/v2/t/{slug}/unlock
// ============================================================

class KioskUnlockRequest {
  final String pin;

  KioskUnlockRequest({
    required this.pin,
  });

  factory KioskUnlockRequest.fromJson(Map<String, dynamic> json) {
    return KioskUnlockRequest(
      pin: (json['pin'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pin': pin,
  };

  @override
  String toString() => 'KioskUnlockRequest(pin: ***)';
}


class KioskUnlockResult {
  final String accessToken;
  final String? tokenType;
  final int? expiresIn;
  final String? hospitalName;
  final bool? collectCaste;

  KioskUnlockResult({
    required this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.hospitalName,
    this.collectCaste,
  });

  factory KioskUnlockResult.fromJson(Map<String, dynamic> json) {
    return KioskUnlockResult(
      accessToken: (json['access_token'] ?? '').toString(),
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
      hospitalName: json['hospital_name'],
      collectCaste: json['collect_caste'],
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
    'expires_in': expiresIn,
    'hospital_name': hospitalName,
    'collect_caste': collectCaste,
  };

  @override
  String toString() =>
      'KioskUnlockResult(tokenType: $tokenType, expiresIn: $expiresIn, hospitalName: $hospitalName)';
}


// ============================================================
// 5. POST /api/v2/t/{slug}/session
// ============================================================

class PatientSessionRequest {
  final String phone;
  final String? language;
  final String? visitType;
  final String? gender;

  PatientSessionRequest({
    required this.phone,
    this.language,
    this.visitType,
    this.gender,
  });

  factory PatientSessionRequest.fromJson(Map<String, dynamic> json) {
    return PatientSessionRequest(
      phone: (json['phone'] ?? '').toString(),
      language: json['language'],
      visitType: json['visit_type'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'language': language,
    'visit_type': visitType,
    'gender': gender,
  };

  @override
  String toString() =>
      'PatientSessionRequest(language: $language, visitType: $visitType, gender: $gender)';
}


class PatientSessionInit {
  final String sessionId;
  final String? ticketNumber;
  final int? opdNumber;
  final String? patientId;
  final String? language;
  final String? phase;
  final String? status;

  PatientSessionInit({
    required this.sessionId,
    this.ticketNumber,
    this.opdNumber,
    this.patientId,
    this.language,
    this.phase,
    this.status,
  });

  factory PatientSessionInit.fromJson(Map<String, dynamic> json) {
    return PatientSessionInit(
      sessionId: (json['session_id'] ?? '').toString(),
      ticketNumber: json['ticket_number'],
      opdNumber: json['opd_number'],
      patientId: json['patient_id'],
      language: json['language'],
      phase: json['phase'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'ticket_number': ticketNumber,
    'opd_number': opdNumber,
    'patient_id': patientId,
    'language': language,
    'phase': phase,
    'status': status,
  };

  @override
  String toString() =>
      'PatientSessionInit(sessionId: $sessionId, ticketNumber: $ticketNumber, phase: $phase, status: $status)';
}


// ============================================================
// 6. GET /api/v2/t/{slug}/session/{session_id}/result
// ============================================================

class TicketingResult {
  final String sessionId;
  final String? ticketNumber;
  final int? opdNumber;
  final String? opdDateIst;
  final String? visitType;
  final bool? collectCaste;
  final String? phase;
  final String? status;
  final ResultCategory? category;
  final List<ResultFlag> flags;
  final String? summary;
  final String? startedAt;
  final String? endedAt;
  final ResultPatient? patient;
  final String? hospitalName;

  TicketingResult({
    required this.sessionId,
    this.ticketNumber,
    this.opdNumber,
    this.opdDateIst,
    this.visitType,
    this.collectCaste,
    this.phase,
    this.status,
    this.category,
    required this.flags,
    this.summary,
    this.startedAt,
    this.endedAt,
    this.patient,
    this.hospitalName,
  });

  factory TicketingResult.fromJson(Map<String, dynamic> json) {
    return TicketingResult(
      sessionId: (json['session_id'] ?? '').toString(),
      ticketNumber: json['ticket_number'],
      opdNumber: json['opd_number'],
      opdDateIst: json['opd_date_ist'],
      visitType: json['visit_type'],
      collectCaste: json['collect_caste'],
      phase: json['phase'],
      status: json['status'],
      category: json['category'] != null
          ? ResultCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      flags: (json['flags'] as List<dynamic>? ?? [])
          .map((e) => ResultFlag.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'],
      startedAt: json['started_at'],
      endedAt: json['ended_at'],
      patient: json['patient'] != null
          ? ResultPatient.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      hospitalName: json['hospital_name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'ticket_number': ticketNumber,
    'opd_number': opdNumber,
    'opd_date_ist': opdDateIst,
    'visit_type': visitType,
    'collect_caste': collectCaste,
    'phase': phase,
    'status': status,
    'category': category?.toJson(),
    'flags': flags.map((e) => e.toJson()).toList(),
    'summary': summary,
    'started_at': startedAt,
    'ended_at': endedAt,
    'patient': patient?.toJson(),
    'hospital_name': hospitalName,
  };

  @override
  String toString() =>
      'TicketingResult(sessionId: $sessionId, ticketNumber: $ticketNumber, phase: $phase, status: $status)';
}


class ResultCategory {
  final String? key;
  final String? label;
  final String? source;

  ResultCategory({
    this.key,
    this.label,
    this.source,
  });

  factory ResultCategory.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return ResultCategory(
      key: json['key'],
      label: json['label'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'source': source,
  };

  @override
  String toString() => 'ResultCategory(key: $key, label: $label, source: $source)';
}


class ResultFlag {
  final String? flagType;
  final String? description;
  final String? raisedAt;

  ResultFlag({
    this.flagType,
    this.description,
    this.raisedAt,
  });

  factory ResultFlag.fromJson(Map<String, dynamic> json) {
    return ResultFlag(
      flagType: json['flag_type'],
      description: json['description'],
      raisedAt: json['raised_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'flag_type': flagType,
    'description': description,
    'raised_at': raisedAt,
  };

  @override
  String toString() => 'ResultFlag(flagType: $flagType, description: $description)';
}


class ResultPatient {
  final String? patientId;
  final String? name;
  final int? age;
  final String? gender;
  final String? caste;
  final String? address;
  final String? guardianName;
  final String? phone;

  ResultPatient({
    this.patientId,
    this.name,
    this.age,
    this.gender,
    this.caste,
    this.address,
    this.guardianName,
    this.phone,
  });

  factory ResultPatient.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return ResultPatient(
      patientId: json['patient_id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      caste: json['caste'],
      address: json['address'],
      guardianName: json['guardian_name'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'name': name,
    'age': age,
    'gender': gender,
    'caste': caste,
    'address': address,
    'guardian_name': guardianName,
    'phone': phone,
  };

  @override
  String toString() => 'ResultPatient(patientId: $patientId, name: $name, age: $age)';
}
