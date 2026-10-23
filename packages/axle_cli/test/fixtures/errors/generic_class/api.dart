import 'package:axle_core/axle_core.dart';

@ApiSchema()
class GenericDto<T> {
  late final T value;
}
