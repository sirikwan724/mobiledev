/// Result Pattern: ห่อผลลัพธ์จาก Data Layer ไม่ให้ UI ต้องจับ try/catch เอง
/// (ตามแนวทาง MVVM ของ docs.flutter.dev/app-architecture/design-patterns/result)
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok._;
  factory Result.error(Exception error) = Failure._;
}

class Ok<T> extends Result<T> {
  const Ok._(this.value);
  final T value;
}

class Failure<T> extends Result<T> {
  const Failure._(this.error);
  final Exception error;
}
