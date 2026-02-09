import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorUtils {
  static String getFriendlyErrorMessage(dynamic error) {
    // Log the raw error for debugging
    debugPrint('Raw Error encountered: $error');
    
    final String msg = error.toString();
    final String msgLower = msg.toLowerCase(); // Case-insensitive check

    // 1. Network / Connection Errors
    if (msg.contains('SocketException') || 
        msg.contains('ClientException') || 
        msg.contains('Failed host lookup') || 
        msg.contains('Connection refused') ||
        msg.contains('Network request failed') ||
        msg.contains('AuthRetryableFetchException') || // Supabase network wrapper
        msgLower.contains('network error') ||
        msgLower.contains('offline')) {
      return 'No internet connection. Please check your network settings.';
    }

    // 2. Auth Specific (if captured as AuthException)
    if (error is AuthException) {
      if (error.message.toLowerCase().contains('invalid login credentials')) {
        return 'Incorrect email or password.';
      }
      return error.message; // Return the Clean Supabase message if it's not network related
    }

    // 3. Fallback for generic messages
    return 'An unexpected error occurred. Please try again.';
  }
}
