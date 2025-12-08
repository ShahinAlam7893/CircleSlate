// // lib/core/utils/http_error_handler.dart

// import 'dart:io';
// import 'package:circleslate/core/errors/exceptions.dart';
// import 'package:http/http.dart' as http;


// class HttpErrorHandler {
//   static AppException handle(Object error, [String? url]) {
//     // Timeout from http package
//     if (error is http.ClientException) {
//       if (error.message.contains('Connection timed out') ||
//           error.message.contains('Timeout')) {
//         return TimeoutException('Server is taking too long', url);
//       }
//       return FetchDataException(error.message, url);
//     }

//     // SocketException = no internet
//     if (error is SocketException) {
//       return FetchDataException('No internet connection', url);
//     }

//     // TimeoutException from .timeout()
//     if (error is TimeoutException) {
//       return TimeoutException('Request timeout', url);
//     }

//     // http.Response with bad status
//     if (error is http.Response) {
//       switch (error.statusCode) {
//         case 400:
//           return BadRequestException('Bad request', url);
//         case 401:
//           return UnauthorizedException('Session expired', url);
//         case 403:
//           return UnauthorizedException('Access denied', url);
//         case 404:
//           return NotFoundException('Data not found', url);
//         case 500:
//         case 502:
//         case 503:
//           return ServerException('Server error', url);
//         default:
//           return FetchDataException('Error ${error.statusCode}', url);
//       }
//     }

//     return AppException('Unknown error: $error', 'Error', url);
//   }

//   static String getMessage(AppException e) {
//     if (e is FetchDataException) {
//       return e.message?.contains('internet') == true
//           ? 'No internet connection'
//           : 'Failed to connect';
//     }
//     if (e is TimeoutException) return 'Server is slow';
//     if (e is UnauthorizedException) return 'Please log in again';
//     if (e is ServerException) return 'Server is down';
//     return e.message ?? 'Something went wrong';
//   }
// }