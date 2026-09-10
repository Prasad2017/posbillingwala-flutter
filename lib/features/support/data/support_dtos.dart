import 'package:pos_billingwala_v2/core/network/api_response.dart';
import 'package:pos_billingwala_v2/core/utils/json_parsers.dart';

class SupportTicketDto {
  const SupportTicketDto({
    this.id,
    this.ticketNo,
    this.appName,
    this.category = '',
    this.subject = '',
    this.description = '',
    this.status = '',
    this.createdAt,
    this.shopName,
  });

  final String? id;
  final String? ticketNo;
  final String? appName;
  final String category;
  final String subject;
  final String description;
  final String status;
  final String? createdAt;
  final String? shopName;

  factory SupportTicketDto.fromJson(Map<String, dynamic> json) {
    return SupportTicketDto(
      id: parseString(json['id']),
      ticketNo: parseString(json['ticketNo']),
      appName: parseString(json['appName']),
      category: parseString(json['category']) ?? '',
      subject: parseString(json['subject']) ?? '',
      description: parseString(json['description']) ?? '',
      status: parseString(json['status'] ?? json['ticketStatus']) ?? '',
      createdAt: parseString(json['createdAt']),
      shopName: parseString(json['shopName']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketNo': ticketNo,
        'appName': appName,
        'category': category,
        'subject': subject,
        'description': description,
        'status': status,
        'createdAt': createdAt,
        'shopName': shopName,
      };
}

class SupportMessageDto {
  const SupportMessageDto({
    this.id,
    this.sender = '',
    this.message = '',
    this.createdAt,
  });

  final String? id;
  final String sender;
  final String message;
  final String? createdAt;

  factory SupportMessageDto.fromJson(Map<String, dynamic> json) {
    return SupportMessageDto(
      id: parseString(json['id']),
      sender: parseString(json['sender']) ?? '',
      message: parseString(json['message']) ?? '',
      createdAt: parseString(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'message': message,
        'createdAt': createdAt,
      };

  bool get isFromUser => sender.toLowerCase() == 'you';
}

class SupportTicketDetailsDto {
  const SupportTicketDetailsDto({
    this.ticketNo,
    this.subject = '',
    this.description = '',
    this.status = '',
    this.createdAt,
    this.messages = const [],
  });

  final String? ticketNo;
  final String subject;
  final String description;
  final String status;
  final String? createdAt;
  final List<SupportMessageDto> messages;

  bool get isClosed {
    final s = status.toLowerCase();
    return s == 'closed' || s == 'resolved';
  }

  factory SupportTicketDetailsDto.fromJson(Map<String, dynamic> json) {
    return SupportTicketDetailsDto(
      ticketNo: parseString(json['ticketNo']),
      subject: parseString(json['subject']) ?? '',
      description: parseString(json['description']) ?? '',
      status: parseString(json['ticketStatus'] ?? json['status']) ?? '',
      createdAt: parseString(json['createdAt']),
      messages: mapJsonList(
        json['ticketMessages'] ?? json['messages'],
        SupportMessageDto.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'ticketNo': ticketNo,
        'subject': subject,
        'description': description,
        'ticketStatus': status,
        'createdAt': createdAt,
        'ticketMessages': messages.map((e) => e.toJson()).toList(),
      };
}
