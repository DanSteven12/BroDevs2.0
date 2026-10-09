class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server exception']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network exception']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache exception']);
}

