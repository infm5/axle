/// Routes that show status codes, ranges, redirects, and async jobs.
library;

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http.dart';
import '../models/common.dart';
import '../models/jobs.dart';
import 'shared.dart';

const _tags = ['Responses'];

/// Registers the response routes.
void responseRoutes(Router router) {
  router
    ..get('/responses/status/<code>', statusPlayground)
    ..post('/responses/jobs', startJob)
    ..get('/responses/jobs/<id>', getJob)
    ..delete('/responses/jobs/<id>', cancelJob);
}

const _location = ApiResponseHeader(
  'Location',
  type: String,
  required: true,
  description: 'Where to go next.',
  example: '/responses/status/200',
);

const _retryAfter = ApiResponseHeader(
  'Retry-After',
  type: int,
  description: 'Seconds to wait before trying again.',
  example: 30,
);

/// Answers with the status code you ask for.
@ApiRoute(
  method: ApiMethod.get,
  path: '/responses/status/<code>',
  summary: 'Get any status code',
  description:
      'Try `200`, `201`, `204`, `301`, `302`, `304`, `404`, `418`, `429`, or '
      '`503`. Redirects carry a `Location`; `429` and `503` carry '
      '`Retry-After`. A code that is not listed here still works and falls '
      'under the `2XX`, `3XX`, `4XX`, `5XX`, or `default` response, so the '
      'spec describes it.',
  tags: _tags,
  pathParams: [
    ApiPathParam(
      'code',
      type: int,
      minimum: 200,
      maximum: 599,
      description: 'The status code to return.',
      example: 418,
    ),
  ],
  responses: [
    ApiResponse(status: 200, type: Greeting, description: 'OK.'),
    ApiResponse(
      status: 201,
      type: Greeting,
      description: 'Created.',
      headers: [_location],
    ),
    ApiResponse(status: 204, description: 'No content: no body at all.'),
    ApiResponse(
      status: 301,
      description: 'Moved permanently.',
      headers: [_location],
    ),
    ApiResponse(status: 302, description: 'Found.', headers: [_location]),
    ApiResponse(status: 304, description: 'Not modified: no body.'),
    ApiResponse(
      status: 307,
      description: 'Temporary redirect that keeps the method.',
      headers: [_location],
    ),
    ApiResponse(
      status: 308,
      description: 'Permanent redirect that keeps the method.',
      headers: [_location],
    ),
    ApiResponse(
      status: 404,
      type: Problem,
      description: 'Not found.',
      contentTypes: [problemJson],
    ),
    ApiResponse(
      status: 418,
      type: Problem,
      description: "I'm a teapot.",
      contentTypes: [problemJson],
    ),
    ApiResponse(
      status: 429,
      type: Problem,
      description: 'Too many requests.',
      contentTypes: [problemJson],
      headers: [_retryAfter],
    ),
    ApiResponse(
      status: 503,
      type: Problem,
      description: 'Unavailable.',
      contentTypes: [problemJson],
      headers: [_retryAfter],
    ),
    ApiResponse.range(2, type: Greeting, description: 'Any other success.'),
    ApiResponse.range(
      3,
      description: 'Any other redirect.',
      headers: [_location],
    ),
    ...catchAllErrors,
  ],
)
Future<Response> statusPlayground(Request request, String code) async {
  final status = int.tryParse(code);
  if (status == null || status < 200 || status > 599) {
    return problem(400, 'Bad Request', detail: '`code` is 200 to 599.');
  }
  switch (status) {
    case 204:
    case 304:
      return Response(status);
    case 201:
      return json(
        const Greeting(message: 'Created', language: 'en').toJson(),
        status: 201,
        headers: {'location': '/responses/status/200'},
      );
  }
  if (status >= 300 && status < 400) {
    return Response(status, headers: {'location': '/responses/status/200'});
  }
  if (status < 300) {
    return json(
      Greeting(message: 'Status $status', language: 'en').toJson(),
      status: status,
    );
  }
  const titles = {
    404: 'Not Found',
    418: "I'm a teapot",
    429: 'Too Many Requests',
    503: 'Service Unavailable',
  };
  return problem(
    status,
    titles[status] ?? 'Status $status',
    headers: {if (status == 429 || status == 503) 'retry-after': '30'},
  );
}

// ---------------------------------------------------------------------------
// An asynchronous job: 202, polling, and cancellation.

final _jobs = <int, int>{};

JobStatus _status(int id, int polls) {
  final progress = (polls / 3).clamp(0.0, 1.0);
  return JobStatus(
    id: id,
    state: progress >= 1
        ? JobState.done
        : polls == 0
        ? JobState.queued
        : JobState.running,
    progress: progress,
  );
}

/// Starts a job and returns before it finishes.
@ApiRoute(
  method: ApiMethod.post,
  path: '/responses/jobs',
  summary: 'Start a job (202 Accepted)',
  description: 'The work happens later. Poll the `Location` to follow it.',
  tags: _tags,
  responses: [
    ApiResponse(
      status: 202,
      type: JobStatus,
      description: 'The job was accepted.',
      headers: [
        ApiResponseHeader(
          'Location',
          type: String,
          required: true,
          example: '/responses/jobs/1',
        ),
        _retryAfter,
      ],
    ),
    ...catchAllErrors,
  ],
)
Future<Response> startJob(Request request) async {
  final id = _jobs.length + 1;
  _jobs[id] = 0;
  return json(
    _status(id, 0).toJson(),
    status: 202,
    headers: {'location': '/responses/jobs/$id', 'retry-after': '1'},
  );
}

/// Polls a job.
@ApiRoute(
  method: ApiMethod.get,
  path: '/responses/jobs/<id>',
  summary: 'Poll a job',
  description: 'Each poll moves the job along; the third one finds it done.',
  tags: _tags,
  pathParams: [ApiPathParam('id', type: int, minimum: 1)],
  responses: [
    ApiResponse(status: 200, type: JobStatus),
    ApiResponse(
      status: 404,
      type: Problem,
      description: 'No such job.',
      contentTypes: [problemJson],
    ),
  ],
)
Future<Response> getJob(Request request, String id) async {
  final key = int.tryParse(id);
  final polls = _jobs[key];
  if (key == null || polls == null) return problem(404, 'Not Found');
  _jobs[key] = polls + 1;
  return json(_status(key, polls + 1).toJson());
}

/// Cancels a job.
@ApiRoute(
  method: ApiMethod.delete,
  path: '/responses/jobs/<id>',
  summary: 'Cancel a job (204 No Content)',
  tags: _tags,
  pathParams: [ApiPathParam('id', type: int, minimum: 1)],
  responses: [
    ApiResponse(status: 204, description: 'The job was cancelled.'),
    ApiResponse(
      status: 404,
      type: Problem,
      description: 'No such job.',
      contentTypes: [problemJson],
    ),
    ApiResponse(
      status: 409,
      type: Problem,
      description: 'The job already finished.',
      contentTypes: [problemJson],
    ),
  ],
)
Future<Response> cancelJob(Request request, String id) async {
  final key = int.tryParse(id);
  final polls = _jobs[key];
  if (key == null || polls == null) return problem(404, 'Not Found');
  if (polls >= 3) {
    return problem(409, 'Conflict', detail: 'The job already finished.');
  }
  _jobs.remove(key);
  return Response(204);
}
