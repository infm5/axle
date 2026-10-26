/// Models shared by several route modules.
library;

import 'dart:typed_data';

import 'package:axle_shelf/axle_shelf.dart';

/// Anything that can write itself as JSON.
abstract interface class Jsonable {
  /// The JSON form.
  Map<String, Object?> toJson();
}

/// RFC 9457 problem details, sent as `application/problem+json`.
@ApiSchema(description: 'Problem details as defined by RFC 9457.')
class Problem implements Jsonable {
  /// Creates a problem.
  const Problem({
    required this.status,
    required this.title,
    this.type = 'about:blank',
    this.detail,
    this.instance,
  });

  /// A URI that identifies the problem type.
  @ApiProperty(format: 'uri', example: 'about:blank')
  final String type;

  /// The HTTP status code.
  @ApiProperty(minimum: 100, maximum: 599)
  final int status;

  /// A short, human-readable summary.
  final String title;

  /// An explanation specific to this occurrence.
  final String? detail;

  /// A URI that identifies this occurrence.
  @ApiProperty(format: 'uri-reference')
  final String? instance;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'title': title,
    'status': status,
    if (detail != null) 'detail': detail,
    if (instance != null) 'instance': instance,
  };
}

/// A greeting that is sent in several languages and formats.
@ApiSchema(description: 'A greeting, rendered in the format you ask for.')
class Greeting implements Jsonable {
  /// Creates a greeting.
  const Greeting({required this.message, required this.language});

  /// The greeting.
  @ApiProperty(example: 'Hello, axle!')
  final String message;

  /// The language of [message].
  @ApiProperty(pattern: r'^[a-z]{2}$', example: 'en')
  final String language;

  @override
  Map<String, Object?> toJson() => {'message': message, 'language': language};
}

/// One row of a report.
@ApiSchema(description: 'One row of a report.')
class ReportRow implements Jsonable {
  /// Creates a row.
  const ReportRow({required this.id, required this.name, required this.score});

  /// The row number.
  @ApiProperty(minimum: 1)
  final int id;

  /// The row label.
  final String name;

  /// A score between 0 and 1.
  @ApiProperty(minimum: 0, maximum: 1)
  final double score;

  @override
  Map<String, Object?> toJson() => {'id': id, 'name': name, 'score': score};
}

/// A report, also available as CSV and TSV.
@ApiSchema(description: 'A report with a few rows.')
class Report implements Jsonable {
  /// Creates a report.
  const Report({
    required this.title,
    required this.generatedAt,
    required this.rows,
  });

  /// The report title.
  final String title;

  /// When the report was generated.
  final DateTime generatedAt;

  /// The report rows.
  final List<ReportRow> rows;

  @override
  Map<String, Object?> toJson() => {
    'title': title,
    'generatedAt': generatedAt.toIso8601String(),
    'rows': [for (final row in rows) row.toJson()],
  };
}

/// A catalog item.
@ApiSchema(description: 'A catalog item.')
class Item implements Jsonable {
  /// Creates an item.
  const Item({
    required this.id,
    required this.name,
    required this.price,
    this.tags = const [],
  });

  /// The item id.
  @ApiProperty(minimum: 1)
  final int id;

  /// The item name.
  @ApiProperty(minLength: 1, maxLength: 80)
  final String name;

  /// The price in cents.
  @ApiProperty(minimum: 0)
  final int price;

  /// Free-form labels. Optional when you send an item.
  @ApiProperty(required: false)
  final List<String> tags;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'tags': tags,
  };
}

/// One page of results.
///
/// Each instantiation is its own schema: `Page<Item>` is `Page_Item`.
@ApiSchema(description: 'One page of results.')
class Page<T extends Jsonable> implements Jsonable {
  /// Creates a page.
  const Page({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  /// The items on this page.
  final List<T> items;

  /// The page number, from 1.
  @ApiProperty(minimum: 1)
  final int page;

  /// The requested page size.
  @ApiProperty(minimum: 1, maximum: 100)
  final int size;

  /// The number of items across all pages.
  @ApiProperty(minimum: 0)
  final int total;

  @override
  Map<String, Object?> toJson() => {
    'items': [for (final item in items) item.toJson()],
    'page': page,
    'size': size,
    'total': total,
  };
}

/// The result of signing in.
@ApiSchema(description: 'An access token.')
class Token implements Jsonable {
  /// Creates a token.
  const Token({required this.accessToken, required this.expiresIn});

  /// The access token.
  @ApiProperty(example: 'demo-token')
  final String accessToken;

  /// The token type.
  final String tokenType = 'Bearer';

  /// Seconds until the token expires.
  @ApiProperty(minimum: 1)
  final int expiresIn;

  @override
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'tokenType': tokenType,
    'expiresIn': expiresIn,
  };
}

/// Credentials sent as a form or as JSON.
@ApiSchema(description: 'Credentials, as a form or as JSON.')
class LoginForm {
  /// Creates a login form.
  const LoginForm({required this.username, required this.password});

  /// The user name.
  @ApiProperty(minLength: 1, example: 'demo')
  final String username;

  /// The password.
  @ApiProperty(format: 'password', example: 'demo')
  final String password;
}

/// A multipart upload with one cover, several attachments, and fields.
@ApiSchema(description: 'A multipart upload: fields plus files.')
class UploadForm {
  /// Creates an upload form.
  const UploadForm({
    required this.title,
    required this.cover,
    required this.attachments,
    this.tags = const [],
  });

  /// A title for the upload.
  @ApiProperty(minLength: 1, maxLength: 80)
  final String title;

  /// A single cover image.
  @ApiProperty(format: 'binary')
  final Uint8List cover;

  /// Any number of attachments. `format: binary` applies to each file.
  @ApiProperty(format: 'binary')
  final List<Uint8List> attachments;

  /// Labels, repeated as `tags=a&tags=b`.
  final List<String> tags;
}

/// A file the server received.
@ApiSchema(description: 'A file the server received.')
class StoredFile implements Jsonable {
  /// Creates a stored file.
  const StoredFile({
    required this.field,
    required this.filename,
    required this.contentType,
    required this.size,
    required this.checksum,
  });

  /// The form field it arrived in.
  final String field;

  /// The file name the client sent.
  final String? filename;

  /// The media type the client sent.
  final String? contentType;

  /// The size in bytes.
  @ApiProperty(minimum: 0)
  final int size;

  /// An additive checksum of the bytes.
  final int checksum;

  @override
  Map<String, Object?> toJson() => {
    'field': field,
    'filename': filename,
    'contentType': contentType,
    'size': size,
    'checksum': checksum,
  };
}

/// What the server made of an upload.
@ApiSchema(description: 'What the server made of an upload.')
class UploadResult implements Jsonable {
  /// Creates a result.
  const UploadResult({
    required this.title,
    required this.files,
    required this.tags,
  });

  /// The title field.
  final String title;

  /// Every file that arrived.
  final List<StoredFile> files;

  /// The tags that arrived.
  final List<String> tags;

  @override
  Map<String, Object?> toJson() => {
    'title': title,
    'files': [for (final file in files) file.toJson()],
    'tags': tags,
  };
}

/// A stored document.
@ApiSchema(description: 'A document that supports PATCH.')
class DocumentRecord implements Jsonable {
  /// Creates a document.
  const DocumentRecord({
    required this.id,
    required this.title,
    required this.completed,
    required this.revision,
  });

  /// The document id.
  @ApiProperty(minimum: 1)
  final int id;

  /// The title.
  final String title;

  /// Whether the document is done.
  final bool completed;

  /// Increments with every change.
  @ApiProperty(minimum: 1)
  final int revision;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'revision': revision,
  };
}

/// A JSON Merge Patch (RFC 7396) for a document.
@ApiSchema(description: 'A JSON Merge Patch: only the fields to change.')
class MergePatch {
  /// Creates a patch.
  const MergePatch({this.title, this.completed});

  /// The new title.
  @ApiProperty(minLength: 1)
  final String? title;

  /// The new completion state.
  final bool? completed;
}

/// The operation of a JSON Patch step.
enum PatchOp { add, remove, replace, move, copy, test }

/// One step of a JSON Patch (RFC 6902).
@ApiSchema(description: 'One step of a JSON Patch.')
class PatchOperation {
  /// Creates a step.
  const PatchOperation({required this.op, required this.path, this.value});

  /// The operation.
  final PatchOp op;

  /// A JSON Pointer to the target.
  @ApiProperty(pattern: r'^(/[^/]*)*$', example: '/title')
  final String path;

  /// The value, for `add`, `replace`, and `test`.
  final Object? value;
}
