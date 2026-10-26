/// Models for the asynchronous job routes.
library;

import 'package:axle_shelf/axle_shelf.dart';

import 'common.dart';

/// Where a job is.
enum JobState { queued, running, done }

/// A background job.
@ApiSchema(description: 'A background job.')
class JobStatus implements Jsonable {
  /// Creates a status.
  const JobStatus({
    required this.id,
    required this.state,
    required this.progress,
  });

  /// The job id.
  @ApiProperty(minimum: 1)
  final int id;

  /// Where the job is.
  final JobState state;

  /// How far along it is, from 0 to 1.
  @ApiProperty(minimum: 0, maximum: 1)
  final double progress;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'state': state.name,
    'progress': progress,
  };
}
