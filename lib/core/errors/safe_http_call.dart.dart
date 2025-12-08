// // lib/core/utils/safe_http_call.dart

// import 'package:circleslate/core/errors/exceptions.dart';
// import 'package:circleslate/core/errors/snackbar_service.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'http_error_handler.dart';


// Future<http.Response?> safeHttpCall(
//   Future<http.Response> Function() request, {
//   BuildContext? context,
//   String? url,
//   bool showError = true,
// }) async {
//   try {
//     final response = await request();
    
//     // Let handler check status codes
//     final exception = HttpErrorHandler.handle(response, url);
//     if (exception is! AppException || exception.message != null) {
//       // Only show if it's actually an error
//       if (showError && context != null && context.mounted) {
//         final msg = HttpErrorHandler.getMessage(exception);
//         SnackbarService.showError(context, msg);
//       }
//     }
    
//     return response;
//   } catch (error) {
//     final exception = HttpErrorHandler.handle(error, url);
//     final message = HttpErrorHandler.getMessage(exception);

//     if (showError && context != null && context.mounted) {
//       SnackbarService.showError(context, message);
//     }
//     return null;
//   }
// }