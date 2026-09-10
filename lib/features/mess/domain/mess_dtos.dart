import 'package:pos_billingwala_v2/core/utils/json_parsers.dart';

class MessMemberDto {
  const MessMemberDto({
    required this.memberId,
    required this.memberName,
    this.memberMobileNumber,
    this.memberAltenetMobileNumber,
    this.memberAddress,
    this.registrationNo,
    this.memberType = 'student',
    this.rollNo,
    this.college,
    this.studentYear,
    this.company,
    this.memberStatus = '1',
    this.memberNetworkStatus,
  });

  final int memberId;
  final String memberName;
  final String? memberMobileNumber;
  final String? memberAltenetMobileNumber;
  final String? memberAddress;
  final String? registrationNo;
  final String memberType;
  final String? rollNo;
  final String? college;
  final String? studentYear;
  final String? company;
  final String memberStatus;
  final String? memberNetworkStatus;

  factory MessMemberDto.fromJson(Map<String, dynamic> json) {
    return MessMemberDto(
      memberId: parseInt(json['memberId']) ?? 0,
      memberName: parseString(json['memberName'])?.trim() ?? '',
      memberMobileNumber: parseString(json['memberMobileNumber']),
      memberAltenetMobileNumber:
          parseString(json['memberAltenetMobileNumber']),
      memberAddress: parseString(json['memberAddress']),
      registrationNo: parseString(json['registrationNo']),
      memberType: parseString(json['memberType'])?.trim().isNotEmpty == true
          ? parseString(json['memberType'])!.trim()
          : 'student',
      rollNo: parseString(json['rollNo']),
      college: parseString(json['college']),
      studentYear: parseString(json['studentYear']),
      company: parseString(json['company']),
      memberStatus: parseString(json['memberStatus']) ?? '1',
      memberNetworkStatus: parseString(json['memberNetworkStatus']),
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'memberName': memberName,
        'memberMobileNumber': memberMobileNumber,
        'memberAltenetMobileNumber': memberAltenetMobileNumber,
        'memberAddress': memberAddress,
        'registrationNo': registrationNo,
        'memberType': memberType,
        'rollNo': rollNo,
        'college': college,
        'studentYear': studentYear,
        'company': company,
        'memberStatus': memberStatus,
        'memberNetworkStatus': memberNetworkStatus,
      };
}

class MessCommonQrDto {
  const MessCommonQrDto({
    required this.publicToken,
    required this.qrUrl,
    this.messLabel,
    this.branchLabel,
    this.status = 'ACTIVE',
  });

  final String publicToken;
  final String qrUrl;
  final String? messLabel;
  final String? branchLabel;
  final String status;

  factory MessCommonQrDto.fromJson(Map<String, dynamic> json) {
    return MessCommonQrDto(
      publicToken: parseString(json['publicToken']) ?? '',
      qrUrl: parseString(json['qrUrl']) ?? '',
      messLabel: parseString(json['messLabel']),
      branchLabel: parseString(json['branchLabel']),
      status: parseString(json['status']) ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
        'publicToken': publicToken,
        'qrUrl': qrUrl,
        'messLabel': messLabel,
        'branchLabel': branchLabel,
        'status': status,
      };
}

class MessMealSessionDto {
  const MessMealSessionDto({
    required this.sessionId,
    required this.sessionName,
    this.startTime = '08:00',
    this.endTime = '10:00',
    this.tokenPrefix = '',
    this.isActive = '1',
    this.menuNotes = '',
    this.sortOrder = '0',
  });

  final String sessionId;
  final String sessionName;
  final String startTime;
  final String endTime;
  final String tokenPrefix;
  final String isActive;
  final String menuNotes;
  final String sortOrder;

  bool get active => isActive == '1' || isActive.toLowerCase() == 'true';

  factory MessMealSessionDto.fromJson(Map<String, dynamic> json) {
    return MessMealSessionDto(
      sessionId: parseString(json['sessionId']) ?? '',
      sessionName: parseString(json['sessionName']) ?? '',
      startTime: parseString(json['startTime']) ?? '08:00',
      endTime: parseString(json['endTime']) ?? '10:00',
      tokenPrefix: parseString(json['tokenPrefix']) ?? '',
      isActive: parseString(json['isActive']) ?? '1',
      menuNotes: parseString(json['menuNotes']) ?? '',
      sortOrder: parseString(json['sortOrder']) ?? '0',
    );
  }
}

class MessMealTokenDto {
  const MessMealTokenDto({
    this.tokenId = '',
    this.tokenNumber = '',
    this.registrationNo = '',
    this.mealSession = '',
    this.date = '',
    this.printStatus = '',
    this.createdAt = '',
    this.printedAt = '',
    this.memberName = '',
    this.memberMobile = '',
  });

  final String tokenId;
  final String tokenNumber;
  final String registrationNo;
  final String mealSession;
  final String date;
  final String printStatus;
  final String createdAt;
  final String printedAt;
  final String memberName;
  final String memberMobile;

  factory MessMealTokenDto.fromJson(Map<String, dynamic> json) {
    return MessMealTokenDto(
      tokenId: parseString(json['tokenId']) ?? '',
      tokenNumber: parseString(json['tokenNumber']) ?? '',
      registrationNo: parseString(json['registrationNo']) ?? '',
      mealSession: parseString(json['mealSession']) ?? '',
      date: parseString(json['date']) ?? '',
      printStatus: parseString(json['printStatus']) ?? '',
      createdAt: parseString(json['createdAt']) ?? '',
      printedAt: parseString(json['printedAt']) ?? '',
      memberName: parseString(json['memberName']) ?? '',
      memberMobile: parseString(json['memberMobile']) ?? '',
    );
  }
}

class MessSessionCountDto {
  const MessSessionCountDto({
    this.sessionName = '',
    this.generated = '0',
    this.printed = '0',
    this.pending = '0',
    this.failed = '0',
  });

  final String sessionName;
  final String generated;
  final String printed;
  final String pending;
  final String failed;

  factory MessSessionCountDto.fromJson(Map<String, dynamic> json) {
    return MessSessionCountDto(
      sessionName: parseString(json['sessionName']) ?? '',
      generated: parseString(json['generated']) ?? '0',
      printed: parseString(json['printed']) ?? '0',
      pending: parseString(json['pending']) ?? '0',
      failed: parseString(json['failed']) ?? '0',
    );
  }
}

class MessMealTokenTodayResult {
  const MessMealTokenTodayResult({
    this.tokens = const [],
    this.sessionCounts = const [],
  });

  final List<MessMealTokenDto> tokens;
  final List<MessSessionCountDto> sessionCounts;
}

class MessInvoiceDto {
  const MessInvoiceDto({
    this.invoiceId = 0,
    this.memberId = '',
    this.memberName = '',
    this.messType = 'Lunch',
    this.messInvoiceDate = '',
    this.messInvoiceNetworkStatus,
    this.messInvoiceStatus = '1',
  });

  final int invoiceId;
  final String memberId;
  final String memberName;
  final String messType;
  final String messInvoiceDate;
  final String? messInvoiceNetworkStatus;
  final String messInvoiceStatus;

  factory MessInvoiceDto.fromJson(Map<String, dynamic> json) {
    return MessInvoiceDto(
      invoiceId: parseInt(json['invoiceId']) ?? 0,
      memberId: parseString(json['memberId']) ?? '',
      memberName: parseString(json['memberName']) ?? '',
      messType: parseString(json['messType']) ?? 'Lunch',
      messInvoiceDate: parseString(json['messInvoiceDate']) ?? '',
      messInvoiceNetworkStatus: parseString(json['messInvoiceNetworkStatus']),
      messInvoiceStatus: parseString(json['messInvoiceStatus']) ?? '1',
    );
  }
}

class MessMemberPaymentDto {
  const MessMemberPaymentDto({
    this.paymentId = 0,
    required this.memberId,
    required this.memberName,
    this.paymentMessAmount = 0,
    this.paymentPaidAmount = 0,
    this.messTotalDays = '30',
    required this.paymentDate,
    this.paymentNetworkStatus,
    this.paymentStatus = '0',
  });

  final int paymentId;
  final String memberId;
  final String memberName;
  final double paymentMessAmount;
  final double paymentPaidAmount;
  final String messTotalDays;
  final String paymentDate;
  final String? paymentNetworkStatus;
  final String paymentStatus;

  factory MessMemberPaymentDto.fromJson(Map<String, dynamic> json) {
    return MessMemberPaymentDto(
      paymentId: parseInt(json['paymentId']) ?? 0,
      memberId: parseString(json['memberId']) ?? '',
      memberName: parseString(json['memberName']) ?? '',
      paymentMessAmount: parseMoney(json['paymentMessAmount']),
      paymentPaidAmount: parseMoney(json['paymentPaidAmount']),
      messTotalDays: parseString(json['messTotalDays']) ?? '30',
      paymentDate: parseString(json['paymentDate']) ?? '',
      paymentNetworkStatus: parseString(json['paymentNetworkStatus']),
      paymentStatus: parseString(json['paymentStatus']) ?? '0',
    );
  }
}
