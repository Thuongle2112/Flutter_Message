class ServerException implements Exception {
  final String message;
  final dynamic code;

  ServerException(this.message, {this.code});

  @override
  String toString() {
    return 'ServerException: $message${code != null ? ' (code: $code)' : ''}';
  }
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() {
    return 'CacheException: $message';
  }
}