-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SUPABASE RLS POLICIES SETUP FOR VALIDATE APP
-- Run these commands in your Supabase SQL Editor
-- Your tables already exist, so we just need to add RLS policies
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ═══════════════════════════════════════════════════════════════
-- 1. ENABLE ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE public.warranties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warranty_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 2. DROP EXISTING POLICIES (if any)
-- ═══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Users can view own warranties" ON public.warranties;
DROP POLICY IF EXISTS "Users can insert own warranties" ON public.warranties;
DROP POLICY IF EXISTS "Users can update own warranties" ON public.warranties;
DROP POLICY IF EXISTS "Users can delete own warranties" ON public.warranties;

DROP POLICY IF EXISTS "Users can view own documents" ON public.warranty_documents;
DROP POLICY IF EXISTS "Users can insert own documents" ON public.warranty_documents;
DROP POLICY IF EXISTS "Users can delete own documents" ON public.warranty_documents;

DROP POLICY IF EXISTS "Users can view own logs" ON public.activity_logs;
DROP POLICY IF EXISTS "Users can insert own logs" ON public.activity_logs;

-- ═══════════════════════════════════════════════════════════════
-- 3. CREATE RLS POLICIES FOR WARRANTIES TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE POLICY "Users can view own warranties"
ON public.warranties FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own warranties"
ON public.warranties FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own warranties"
ON public.warranties FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own warranties"
ON public.warranties FOR DELETE
USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- 4. CREATE RLS POLICIES FOR WARRANTY_DOCUMENTS TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE POLICY "Users can view own documents"
ON public.warranty_documents FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.warranties
        WHERE warranties.id = warranty_documents.warranty_id
        AND warranties.user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own documents"
ON public.warranty_documents FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.warranties
        WHERE warranties.id = warranty_documents.warranty_id
        AND warranties.user_id = auth.uid()
    )
);

CREATE POLICY "Users can delete own documents"
ON public.warranty_documents FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.warranties
        WHERE warranties.id = warranty_documents.warranty_id
        AND warranties.user_id = auth.uid()
    )
);

-- ═══════════════════════════════════════════════════════════════
-- 5. CREATE RLS POLICIES FOR ACTIVITY_LOGS TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE POLICY "Users can view own logs"
ON public.activity_logs FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own logs"
ON public.activity_logs FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- 6. VERIFY SETUP
-- ═══════════════════════════════════════════════════════════════

-- Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('warranties', 'warranty_documents', 'activity_logs');

-- List all policies
SELECT 
    tablename,
    policyname,
    cmd AS operation
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('warranties', 'warranty_documents', 'activity_logs')
ORDER BY tablename, policyname;

-- ═══════════════════════════════════════════════════════════════
-- ✅ SETUP COMPLETE!
-- ═══════════════════════════════════════════════════════════════
-- 
-- You should see:
-- - RLS enabled = true for all 3 tables
-- - 9 policies total (4 for warranties, 3 for documents, 2 for logs)
--
-- Now test your Flutter app!

