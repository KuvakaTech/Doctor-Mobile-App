import "dart:convert";

String getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first[0].toUpperCase();

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${d.day} ${months[d.month - 1]} ${d.year}, ';
}

/// Parses a timestamp coming from the backend and returns it in local time.
///
/// The backend sends UTC, but without a `Z`/offset suffix. `DateTime.parse`
/// treats such a string as local time, which makes `.toLocal()` a no-op, so we
/// tag it as UTC ourselves before converting.
DateTime parseServerDate(String? raw) {
  if (raw == null || raw.isEmpty) return DateTime.now();

  final value = raw.trim().replaceFirst(' ', 'T');
  final hasZone = value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);

  return DateTime.parse(hasZone ? value : '${value}Z').toLocal();
}

String getSpecialtyName(String specialty) {
  switch (specialty) {
    case "general_medicine":
      return "General Medicine";
    case "gynecology":
      return "Women's Health";
    case "psychotherapy":
      return "Mental Health";
    default:
      return specialty;
  }
}

String getDiagnosisStatus(String status) {
  const statuses = {
    "diagnosis": "Diagnosed",
    "questionnaire": "In Progress",
    "finalized": "Finalized",
    "prescription": "Prescribed",
  };

  return statuses[status] ?? status;
}

String formatKey(String key) {
  return key
      .replaceAll("_", " ")
      .split(" ")
      .map(
        (e) => e.isEmpty
        ? e
        : "${e[0].toUpperCase()}${e.substring(1).toLowerCase()}",
  )
      .join(" ");
}

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}
Map<String, dynamic> decodeJwt(String token) {
  // 1. Split the token into its 3 parts (Header.Payload.Signature)
  final parts = token.split('.');

  if (parts.length != 3) {
    throw Exception('Invalid JWT format');
  }

  // 2. Grab the Payload (the 2nd part)
  String payload = parts[1];

  // 3. Base64Url requires padding to be a multiple of 4.
  // Sometimes JWTs drop the padding ('=' characters), so we need to add it back.
  String normalizedPayload = base64Url.normalize(payload);

  // 4. Decode the Base64Url string into raw bytes, then into a UTF-8 String
  String decodedString = utf8.decode(base64Url.decode(normalizedPayload));

  // 5. Parse the JSON string into a Dart Map
  return jsonDecode(decodedString);
}