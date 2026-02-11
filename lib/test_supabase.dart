import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quick diagnostic tool to test Supabase connection and data fetching
class SupabaseDiagnostic {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> runDiagnostics() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 SUPABASE DIAGNOSTICS');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // 1. Check Authentication
    debugPrint('\n1️⃣ AUTHENTICATION CHECK:');
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('❌ NOT AUTHENTICATED');
      debugPrint('   You must log in first!');
      return;
    } else {
      debugPrint('✅ Authenticated');
      debugPrint('   User ID: ${user.id}');
      debugPrint('   Email: ${user.email}');
    }

    // 2. Test Connection to Supabase
    debugPrint('\n2️⃣ CONNECTION TEST:');
    try {
      final response = await _client
          .from('warranties')
          .select('count')
          .count(CountOption.exact);
      debugPrint('✅ Connection successful');
      debugPrint('   Response: $response');
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      if (e is PostgrestException) {
        debugPrint('   Code: ${e.code}');
        debugPrint('   Message: ${e.message}');
        debugPrint('   Details: ${e.details}');
        debugPrint('   Hint: ${e.hint}');
      }
      return;
    }

    // 3. Check if tables exist and have data
    debugPrint('\n3️⃣ TABLE STRUCTURE CHECK:');
    
    // Test warranties table
    try {
      final warrantyCheck = await _client
          .from('warranties')
          .select('id')
          .limit(1);
      debugPrint('✅ warranties table exists');
      debugPrint('   Sample query returned: ${warrantyCheck.length} rows');
    } catch (e) {
      debugPrint('❌ warranties table issue: $e');
    }

    // Test warranty_documents table
    try {
      await _client
          .from('warranty_documents')
          .select('id')
          .limit(1);
      debugPrint('✅ warranty_documents table exists');
    } catch (e) {
      debugPrint('⚠️  warranty_documents table issue: $e');
    }

    // Test activity_logs table
    try {
      await _client
          .from('activity_logs')
          .select('id')
          .limit(1);
      debugPrint('✅ activity_logs table exists');
    } catch (e) {
      debugPrint('⚠️  activity_logs table issue: $e');
    }

    // 4. Test user-specific data fetch
    debugPrint('\n4️⃣ USER DATA FETCH TEST:');
    try {
      final userWarranties = await _client
          .from('warranties')
          .select('*')
          .eq('user_id', user.id);
      
      debugPrint('✅ Successfully fetched user warranties');
      debugPrint('   Found ${(userWarranties as List).length} warranties for this user');
      
      if (userWarranties.isEmpty) {
        debugPrint('   ⚠️  No data found for this user!');
        debugPrint('   This might be why your app appears empty.');
        debugPrint('   Try adding a warranty through the app.');
      } else {
        debugPrint('   Sample data: ${userWarranties.first}');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch user warranties: $e');
      if (e is PostgrestException) {
        debugPrint('   🔴 PostgrestException Details:');
        debugPrint('      Code: ${e.code}');
        debugPrint('      Message: ${e.message}');
        debugPrint('      Hint: ${e.hint}');
        
        if (e.code == '42501') {
          debugPrint('\n   💡 DIAGNOSIS: Row Level Security (RLS) is blocking access!');
          debugPrint('   SOLUTION: Add this policy in Supabase Dashboard:');
          debugPrint('   ');
          debugPrint('   CREATE POLICY "Users can view own warranties"');
          debugPrint('   ON warranties FOR SELECT');
          debugPrint('   USING (auth.uid() = user_id);');
        }
      }
    }

    // 5. Test RLS policies
    debugPrint('\n5️⃣ ROW LEVEL SECURITY (RLS) CHECK:');
    try {
      // Try to fetch without user filter (should fail with RLS)
      final allData = await _client
          .from('warranties')
          .select('id')
          .limit(1);
      
      if ((allData as List).isNotEmpty) {
        debugPrint('⚠️  RLS might not be enabled or policies allow read-all');
      }
    } catch (e) {
      if (e is PostgrestException && e.code == '42501') {
        debugPrint('✅ RLS is active (blocking unauthorized access)');
      }
    }

    debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ DIAGNOSTICS COMPLETE');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
}
