# 🔧 Supabase Data Fetching Troubleshooting Guide

## ✅ Your API Key Status

**Status:** VALID ✓  
**Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`  
**Expires:** January 18, 2036  
**Current Date:** February 9, 2026  
**Remaining:** ~10 years

Your API key is **NOT expired** - the issue is something else.

---

## 🔍 Common Issues & Solutions

### Issue 1: No Data Showing Up

**Problem:** App loads but shows empty list  
**Likely Cause:** Row Level Security (RLS) blocking data access

**Solution:**
1. Open your Supabase Dashboard
2. Go to SQL Editor
3. Run all the commands in `supabase_setup.sql` file
4. This will create tables and set up proper RLS policies

---

### Issue 2: "403 Forbidden" or Permission Errors

**Problem:** App crashes or shows permission errors  
**Cause:** RLS policies not configured

**Solution:**
Run these policies in your Supabase SQL Editor:

```sql
-- Enable RLS
ALTER TABLE public.warranties ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own data
CREATE POLICY "Users can view own warranties"
ON public.warranties FOR SELECT
USING (auth.uid() = user_id);

-- Allow users to insert their own data
CREATE POLICY "Users can insert own warranties"
ON public.warranties FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

---

### Issue 3: Tables Don't Exist

**Problem:** Error like "relation 'warranties' does not exist"  
**Cause:** Database tables haven't been created yet

**Solution:**
1. Copy the entire `supabase_setup.sql` file
2. Paste it into Supabase SQL Editor
3. Click "Run" to execute all commands

---

## 🧪 Testing Your Setup

I've added a diagnostic tool to your app. Here's how to use it:

1. **Run your app:**
   ```bash
   flutter run
   ```

2. **Log in** with your account

3. **Check the debug console** - you'll see detailed diagnostics like:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🔍 SUPABASE DIAGNOSTICS
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   1️⃣ AUTHENTICATION CHECK:
   ✅ Authenticated
      User ID: abc-123-def
      Email: your@email.com
   
   2️⃣ CONNECTION TEST:
   ✅ Connection successful
   
   3️⃣ TABLE STRUCTURE CHECK:
   ✅ warranties table exists
   ✅ warranty_documents table exists
   ✅ activity_logs table exists
   
   4️⃣ USER DATA FETCH TEST:
   ✅ Successfully fetched user warranties
      Found 5 warranties for this user
   ```

4. **Look for error messages** marked with ❌ or 🔴
   - These will tell you exactly what's wrong
   - Share these errors if you need more help

---

## 📋 Setup Checklist

Before running your app, make sure:

- [ ] Supabase project is created
- [ ] Database tables are created (run `supabase_setup.sql`)
- [ ] RLS policies are configured
- [ ] Storage bucket `warranty-images` is created and public
- [ ] Email authentication is enabled
- [ ] You have a registered user account
- [ ] API keys in `main.dart` match your Supabase project

---

## 🚀 Quick Fix Commands

If you just want to get it working fast, run these in Supabase SQL Editor:

```sql
-- 1. Drop everything (if exists)
DROP TABLE IF EXISTS public.warranty_documents CASCADE;
DROP TABLE IF EXISTS public.activity_logs CASCADE;
DROP TABLE IF EXISTS public.warranties CASCADE;

-- 2. Run the entire supabase_setup.sql file
-- (copy/paste from the file)
```

---

## 📞 Still Having Issues?

If the diagnostics show errors, share:
1. The exact error messages from the console (look for ❌)
2. Your Supabase project URL
3. Screenshots of the errors

Common error codes:
- **42501** = RLS is blocking access (add policies)
- **42P01** = Table doesn't exist (run setup SQL)
- **PGRST116** = Table not found (run setup SQL)
- **Auth error** = Not logged in or session expired
