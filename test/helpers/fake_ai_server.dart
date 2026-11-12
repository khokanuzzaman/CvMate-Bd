import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One canned answer of [FakeAiServer]: a status and a JSON body, or a
/// connection error when [status] is null.
class FakeAiReply {
  const FakeAiReply(this.status, [this.body = const {}]);

  const FakeAiReply.offline() : status = null, body = const {};

  final int? status;
  final Map<String, dynamic> body;
}

/// A Dio [HttpClientAdapter] standing in for the AI server: records every
/// request and answers from [replies] in order (the last one repeats), or
/// from [handler] when given (e.g. to answer by path).
class FakeAiServer implements HttpClientAdapter {
  FakeAiServer(this.replies) : handler = null;

  FakeAiServer.handler(FakeAiReply Function(RequestOptions request) this.handler)
    : replies = const [];

  final List<FakeAiReply> replies;
  final FakeAiReply Function(RequestOptions request)? handler;
  final List<RequestOptions> requests = [];

  /// The JSON bodies the app sent, in order.
  List<Map<String, dynamic>> get sentBodies => [
    for (final request in requests)
      if (request.data is Map) Map<String, dynamic>.from(request.data as Map),
  ];

  Dio dio() => Dio(BaseOptions(baseUrl: 'https://ai.test'))
    ..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply =
        handler?.call(options) ??
        replies[(requests.length - 1).clamp(0, replies.length - 1)];
    final status = reply.status;
    if (status == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> aiSuccessBody(
  String action,
  Map<String, dynamic> content, {
  int remainingActions = 2,
}) => {
  'success': true,
  'action': action,
  'content': content,
  'message': null,
  'usage': {
    'model': 'claude-haiku-5-5',
    'inputTokens': 10,
    'outputTokens': 20,
    'totalTokens': 30,
  },
  'remainingActions': remainingActions,
};

Map<String, dynamic> aiErrorBody(String code) => {
  'error': {'code': code, 'message': 'Server says $code.'},
};
