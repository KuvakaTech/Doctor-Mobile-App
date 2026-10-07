import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Models/kiosk_api_models.dart';
import '../../Models/kiosk_voice_socket.dart';
import '../Authentication/auth_service.dart';

String baseUrl = "https://med-history-agent.decrackle.io";

class KioskService {
  /// GET /api/v2/admin/hospital?hospital_id={hospitalId}
  static Future<HospitalDetails> getHospitalDetails({
    required String hospitalId,
  }) async {
    final response = await TokenManager.handle401((token) => http.get(
      Uri.parse("$baseUrl/api/v2/admin/hospital?hospital_id=$hospitalId"),
      headers: {"Authorization": "Bearer $token"},
    ));

    return HospitalDetails.fromJson(jsonDecode(response.body));
  }

  /// GET /api/v2/t/{slug}/config
  static Future<KioskConfig> getKioskConfig({
    required String slug,
  }) async {
    final response = await TokenManager.handle401((token) => http.get(
      Uri.parse("$baseUrl/api/v2/t/$slug/config"),
      headers: {"Authorization": "Bearer $token"},
    ));

    return KioskConfig.fromJson(jsonDecode(response.body));
  }

  /// Verify if a stored kioskToken is valid/authorized
  static Future<bool> verifyKioskToken({
    required String slug,
    required String kioskToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/v2/t/$slug/config"),
        headers: {"Authorization": "Bearer $kioskToken"},
      );
      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/v2/t/{slug}/unlock
  static Future<KioskUnlockResult> unlockKiosk({
    required String slug,
    required String pin,
  }) async {
    final response = await TokenManager.handle401((token) => http.post(
      Uri.parse("$baseUrl/api/v2/t/$slug/unlock"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"pin": pin}),
    ));

    return KioskUnlockResult.fromJson(jsonDecode(response.body));
  }

  /// POST /api/v2/t/{slug}/session
  static Future<PatientSessionInit> startPatientSession({
    required String slug,
    required String phone,
    String? language,
    String? visitType,
    String? gender,
    required String kioskToken,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/v2/t/$slug/session"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $kioskToken",
      },
      body: jsonEncode({
        "phone": phone,
        "language": language,
        "visit_type": visitType,
        "gender": gender,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception("Failed to start patient session: ${response.statusCode} - ${response.body}");
    }

    return PatientSessionInit.fromJson(jsonDecode(response.body));
  }

  /// GET /api/v2/t/{slug}/session/{session_id}/result
  static Future<TicketingResult> getTicketingResult({
    required String slug,
    required String sessionId,
    required String kioskToken,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/v2/t/$slug/session/$sessionId/result"),
      headers: {
        "Authorization": "Bearer $kioskToken",
      },
    );

    if (response.statusCode >= 400) {
      throw Exception("Failed to fetch ticketing result: ${response.statusCode} - ${response.body}");
    }

    return TicketingResult.fromJson(jsonDecode(response.body));
  }

  /// Connect to the kiosk voice WebSocket using KioskVoiceConnection
  static KioskVoiceConnection connectVoice({
    required String slug,
    required String sessionId,
    required String kioskToken,
    bool secure = true,
  }) {
    final uri = Uri.parse(baseUrl);
    return KioskVoiceConnection.connect(
      host: uri.host,
      slug: slug,
      sessionId: sessionId,
      kioskToken: kioskToken,
      secure: secure,
    );
  }
}
