import 'package:careermatebd/core/errors/failure.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      FailureResult<T>(:final error) => failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.error);

  final Failure error;
}
