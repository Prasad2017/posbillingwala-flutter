// Shared helpers for PHP API JSON envelopes (status / list payloads).

Map<String, dynamic> asJsonMap(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return const {};
}

List<T> mapJsonList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) map,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => map(Map<String, dynamic>.from(e)))
      .toList();
}

bool isApiSuccess(Map<String, dynamic> json) {
  return json['status']?.toString() == '1';
}

class StatusMessage {
  const StatusMessage({
    required this.status,
    this.message,
  });

  final String status;
  final String? message;

  bool get isSuccess => status == '1';

  factory StatusMessage.fromJson(Map<String, dynamic> json) {
    return StatusMessage(
      status: json['status']?.toString() ?? '0',
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
      };
}
