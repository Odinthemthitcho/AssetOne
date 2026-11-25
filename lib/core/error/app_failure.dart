/// An expected application failure, safe to show after UI translation.
final class AppFailure {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => code == null ? message : '$code: $message';
}
