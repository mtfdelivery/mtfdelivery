-- ============================================================================
-- MTF SUPER APP — Complete Production Schema v4.1 (Patched)
-- ============================================================================
-- Architecture: PostgreSQL schemas for app isolation (Supabase)
--   public.*    → shared infrastructure
--   food.*      → food delivery
--   market.*    → groceries / marketplace
--   taxi.*      → ride-hailing
--   pharmacy.*  → pharmacy delivery
--   clothes.*   → fashion / clothing store
--
-- Changelog v4.0 → v4.1:
--   [FIX] is_admin/is_support/has_role defined BEFORE all tables/RLS policies.
--   [FIX] profiles.email column added; handle_new_user trigger updated.
--   [FIX] clothes.orders.delivery_fee column added.
--   [FIX] create-audit-partition cron job dollar-quote nesting fixed.
--   [FIX] audit_log partitions get UNIQUE index on id.
--   [FIX] payout_batch_items junction table replaces commission_ids UUID[].
--   [FIX] market.orders.delivery_location GEOGRAPHY column added.
--   [FIX] apply_promo_code uses FOR UPDATE to prevent race conditions.
--   [FIX] clothes.dispatch_attempts table added.
--   [FIX] market/pharmacy/clothes order_status_log tables + triggers added.
--   [FIX] featured_until added to market.sellers + pharmacy.pharmacies.
--   [FIX] compute_daily_stats cancelled_orders fully synced for all 5 apps.
--   [ADD] Pharmacy scheduled orders + cron activation.
--   [ADD] Wishlist validate_target trigger.
--   [ADD] get_user_email() SECURITY DEFINER helper.
--   [ADD] Composite (user_id, status) indexes on all order tables.
--   [ADD] order-evidence storage bucket.
-- ============================================================================


-- ============================================================================
-- EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_cron";


-- ============================================================================
-- SCHEMAS
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS food;
CREATE SCHEMA IF NOT EXISTS market;
CREATE SCHEMA IF NOT EXISTS taxi;
CREATE SCHEMA IF NOT EXISTS pharmacy;
CREATE SCHEMA IF NOT EXISTS clothes;


-- ============================================================================
-- SEQUENCES — atomic order numbers, collision-proof
-- ============================================================================
CREATE SEQUENCE IF NOT EXISTS food_order_seq    START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS market_order_seq  START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS taxi_ride_seq     START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS pharma_order_seq  START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS clothes_order_seq START 1 INCREMENT 1 NO CYCLE;


-- ============================================================================
-- HELPER FUNCTIONS — defined FIRST so RLS policies can reference them
-- ============================================================================
-- [FIX v4.1] These were originally at line ~2179 in v4.0, after hundreds of
-- CREATE POLICY statements that call them. On a fresh deploy that caused:
-- "ERROR: function public.is_admin() does not exist"
-- Moving them here resolves that completely.

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id     = auth.uid()
          AND role        = 'admin'
          AND app_context = 'global'
          AND is_active   = TRUE
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_support()
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id   = auth.uid()
          AND role      IN ('admin', 'support')
          AND is_active = TRUE
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.has_role(p_app_context VARCHAR, p_role VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id     = auth.uid()
          AND app_context = p_app_context
          AND role        = p_role
          AND is_active   = TRUE
    );
END;
$$;


-- ============================================================================
-- PUBLIC SCHEMA — SHARED INFRASTRUCTURE
-- ============================================================================


-- ── profiles ─────────────────────────────────────────────────────────────────
-- [FIX v4.1] Added email column (was missing; views and triggers needed it)
CREATE TABLE public.profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name       VARCHAR(255),
    avatar_url      TEXT,
    phone           VARCHAR(50) UNIQUE,
    email           TEXT,                          -- [v4.1] synced from auth.users
    date_of_birth   DATE,
    gender          VARCHAR(20),
    referral_code   VARCHAR(20) UNIQUE DEFAULT UPPER(SUBSTR(MD5(gen_random_uuid()::TEXT), 1, 8)),
    referred_by     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    preferred_lang  VARCHAR(10) DEFAULT 'ar',
    is_active       BOOLEAN DEFAULT TRUE,
    last_seen_at    TIMESTAMP WITH TIME ZONE,
    risk_score      SMALLINT DEFAULT 0,
    is_banned       BOOLEAN DEFAULT FALSE,
    ban_reason      TEXT,
    banned_at       TIMESTAMP WITH TIME ZONE,
    banned_by       UUID REFERENCES public.profiles(id),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select_own"    ON public.profiles FOR SELECT  USING (id = auth.uid());
CREATE POLICY "profiles_update_own"    ON public.profiles FOR UPDATE  USING (id = auth.uid());
CREATE POLICY "profiles_admin_all"     ON public.profiles FOR ALL     USING (public.is_admin());
CREATE POLICY "profiles_support_read"  ON public.profiles FOR SELECT  USING (public.is_support());

CREATE INDEX idx_profiles_phone   ON public.profiles(phone);
CREATE INDEX idx_profiles_risk    ON public.profiles(risk_score) WHERE risk_score > 0;
CREATE INDEX idx_profiles_banned  ON public.profiles(is_banned)  WHERE is_banned = TRUE;


-- ── user_roles ────────────────────────────────────────────────────────────────
CREATE TABLE public.user_roles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    app_context VARCHAR(20) NOT NULL DEFAULT 'global',
    role        VARCHAR(30) NOT NULL DEFAULT 'customer',
    is_active   BOOLEAN DEFAULT TRUE,
    granted_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by  UUID REFERENCES public.profiles(id),
    UNIQUE (user_id, app_context, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "roles_select_own"   ON public.user_roles FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "roles_admin_all"    ON public.user_roles FOR ALL   USING (public.is_admin());
CREATE POLICY "roles_support_read" ON public.user_roles FOR SELECT USING (public.is_support());

CREATE INDEX idx_user_roles_user_id  ON public.user_roles(user_id);
CREATE INDEX idx_user_roles_app_role ON public.user_roles(app_context, role);
CREATE INDEX idx_user_roles_active   ON public.user_roles(user_id, app_context) WHERE is_active = TRUE;


-- ── addresses ────────────────────────────────────────────────────────────────
CREATE TABLE public.addresses (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    label        VARCHAR(50) NOT NULL DEFAULT 'Home',
    full_address TEXT NOT NULL,
    apt_floor    VARCHAR(100),
    city         VARCHAR(100),
    country      VARCHAR(100) DEFAULT 'TN',
    postal_code  VARCHAR(20),
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION,
    location     GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                     CASE
                         WHEN latitude IS NOT NULL AND longitude IS NOT NULL
                         THEN ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                         ELSE NULL
                     END
                 ) STORED,
    plus_code    VARCHAR(50),
    is_default   BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "addresses_all_own"      ON public.addresses FOR ALL    USING (user_id = auth.uid());
CREATE POLICY "addresses_admin_all"    ON public.addresses FOR ALL    USING (public.is_admin());
CREATE POLICY "addresses_support_read" ON public.addresses FOR SELECT USING (public.is_support());

CREATE INDEX idx_addresses_user_id  ON public.addresses(user_id);
CREATE INDEX idx_addresses_default  ON public.addresses(user_id, is_default) WHERE is_default = TRUE;
CREATE INDEX idx_addresses_location ON public.addresses USING GIST (location);


-- ── payment_methods ───────────────────────────────────────────────────────────
CREATE TABLE public.payment_methods (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    provider        VARCHAR(50),
    type            VARCHAR(30),
    display_name    VARCHAR(100),
    provider_token  TEXT,
    last4           VARCHAR(4),
    expiry_month    SMALLINT,
    expiry_year     SMALLINT,
    is_default      BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payment_methods_all_own"   ON public.payment_methods FOR ALL USING (user_id = auth.uid());
CREATE POLICY "payment_methods_admin_all" ON public.payment_methods FOR ALL USING (public.is_admin());

CREATE INDEX idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX idx_payment_methods_default ON public.payment_methods(user_id, is_default) WHERE is_default = TRUE;


-- ── payment_transactions ──────────────────────────────────────────────────────
-- Real gateway call tracking (separate from internal wallet_transactions ledger)
CREATE TABLE public.payment_transactions (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID REFERENCES public.profiles(id),
    app_context      VARCHAR(20) NOT NULL,
    reference_id     UUID,
    reference_type   VARCHAR(30),             -- food_order | taxi_ride | etc
    provider         VARCHAR(30) NOT NULL,    -- d17 | flouci | stripe | orange_money | cash
    provider_tx_id   VARCHAR(255) UNIQUE,
    idempotency_key  VARCHAR(255) UNIQUE NOT NULL DEFAULT gen_random_uuid()::TEXT,
    amount           DECIMAL(12,3) NOT NULL,
    currency         VARCHAR(3) DEFAULT 'TND',
    status           VARCHAR(20) DEFAULT 'initiated',
    -- initiated | pending | success | failed | refunded | partially_refunded | disputed | chargeback
    provider_status   VARCHAR(50),
    provider_response JSONB,
    failure_code      VARCHAR(50),
    failure_message   TEXT,
    refund_amount     DECIMAL(12,3) DEFAULT 0,
    refund_reason     TEXT,
    refunded_at       TIMESTAMP WITH TIME ZONE,
    refunded_by       UUID REFERENCES public.profiles(id),
    webhook_received_at TIMESTAMP WITH TIME ZONE,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pay_tx_select_own"   ON public.payment_transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "pay_tx_admin_all"    ON public.payment_transactions FOR ALL    USING (public.is_admin());
CREATE POLICY "pay_tx_support_read" ON public.payment_transactions FOR SELECT USING (public.is_support());

CREATE INDEX idx_pay_tx_user_id   ON public.payment_transactions(user_id);
CREATE INDEX idx_pay_tx_reference ON public.payment_transactions(reference_type, reference_id);
CREATE INDEX idx_pay_tx_status    ON public.payment_transactions(status);
CREATE INDEX idx_pay_tx_provider  ON public.payment_transactions(provider, provider_tx_id);
CREATE INDEX idx_pay_tx_created   ON public.payment_transactions(created_at DESC);
CREATE INDEX idx_pay_tx_webhook   ON public.payment_transactions(webhook_received_at)
    WHERE webhook_received_at IS NOT NULL;


-- ── wallets ───────────────────────────────────────────────────────────────────
CREATE TABLE public.wallets (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance     DECIMAL(12,3) DEFAULT 0 CHECK (balance >= 0),
    currency    VARCHAR(3) DEFAULT 'TND',
    is_frozen   BOOLEAN DEFAULT FALSE,
    frozen_reason TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wallets_select_own" ON public.wallets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "wallets_admin_all"  ON public.wallets FOR ALL   USING (public.is_admin());

CREATE INDEX idx_wallets_user_id ON public.wallets(user_id);


-- ── wallet_transactions ───────────────────────────────────────────────────────
CREATE TABLE public.wallet_transactions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type            VARCHAR(30) NOT NULL,
    -- credit | debit | refund | bonus | cashback | withdrawal | topup | commission
    amount          DECIMAL(12,3) NOT NULL,
    balance_after   DECIMAL(12,3) NOT NULL,
    reference_type  VARCHAR(30),
    reference_id    UUID,
    description     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wallet_tx_select_own" ON public.wallet_transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "wallet_tx_admin_all"  ON public.wallet_transactions FOR ALL   USING (public.is_admin());

CREATE INDEX idx_wallet_tx_user_id    ON public.wallet_transactions(user_id);
CREATE INDEX idx_wallet_tx_reference  ON public.wallet_transactions(reference_type, reference_id);
CREATE INDEX idx_wallet_tx_created_at ON public.wallet_transactions(created_at DESC);


-- ── commissions ───────────────────────────────────────────────────────────────
-- Platform revenue ledger: one row per delivered order
CREATE TABLE public.commissions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    app_context     VARCHAR(20) NOT NULL,
    reference_id    UUID NOT NULL,
    reference_type  VARCHAR(30) NOT NULL,
    vendor_id       UUID NOT NULL REFERENCES public.profiles(id),
    order_total     DECIMAL(12,3) NOT NULL,
    delivery_fee    DECIMAL(12,3) DEFAULT 0,
    commission_rate DECIMAL(5,2) NOT NULL,
    commission_amt  DECIMAL(12,3) NOT NULL,
    vendor_payout   DECIMAL(12,3) NOT NULL,
    status          VARCHAR(20) DEFAULT 'pending',
    -- pending | settled | disputed | reversed
    payout_batch_id UUID,
    settled_at      TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.commissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "commissions_admin_all"   ON public.commissions FOR ALL    USING (public.is_admin());
CREATE POLICY "commissions_vendor_read" ON public.commissions FOR SELECT USING (vendor_id = auth.uid());

CREATE INDEX idx_commissions_vendor_id ON public.commissions(vendor_id);
CREATE INDEX idx_commissions_app       ON public.commissions(app_context);
CREATE INDEX idx_commissions_status    ON public.commissions(status);
CREATE INDEX idx_commissions_reference ON public.commissions(reference_type, reference_id);
CREATE INDEX idx_commissions_created   ON public.commissions(created_at DESC);
CREATE INDEX idx_commissions_pending   ON public.commissions(vendor_id, status) WHERE status = 'pending';


-- ── payout_batches ────────────────────────────────────────────────────────────
-- Weekly/bi-weekly payouts to vendors and drivers
CREATE TABLE public.payout_batches (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_id    UUID NOT NULL REFERENCES public.profiles(id),
    recipient_type  VARCHAR(20) NOT NULL,     -- vendor | driver
    app_context     VARCHAR(20) NOT NULL,
    total_amount    DECIMAL(12,3) NOT NULL,
    -- [v4.1] commission_ids array kept for backward compat; use payout_batch_items instead
    commission_ids  UUID[],
    period_start    TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end      TIMESTAMP WITH TIME ZONE NOT NULL,
    status          VARCHAR(20) DEFAULT 'pending',
    -- pending | processing | paid | failed | cancelled
    payment_method  VARCHAR(50),
    payment_ref     VARCHAR(255),
    failure_reason  TEXT,
    paid_at         TIMESTAMP WITH TIME ZONE,
    processed_by    UUID REFERENCES public.profiles(id),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.payout_batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payout_admin_all"      ON public.payout_batches FOR ALL    USING (public.is_admin());
CREATE POLICY "payout_recipient_read" ON public.payout_batches FOR SELECT USING (recipient_id = auth.uid());

CREATE INDEX idx_payout_recipient ON public.payout_batches(recipient_id);
CREATE INDEX idx_payout_status    ON public.payout_batches(status);
CREATE INDEX idx_payout_period    ON public.payout_batches(period_start, period_end);


-- ── payout_batch_items ────────────────────────────────────────────────────────
-- [FIX v4.1] Replaces commission_ids UUID[] with a proper FK junction table
CREATE TABLE public.payout_batch_items (
    payout_batch_id UUID NOT NULL REFERENCES public.payout_batches(id) ON DELETE CASCADE,
    commission_id   UUID NOT NULL REFERENCES public.commissions(id)    ON DELETE RESTRICT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (payout_batch_id, commission_id)
);

ALTER TABLE public.payout_batch_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pbi_admin_all"      ON public.payout_batch_items FOR ALL    USING (public.is_admin());
CREATE POLICY "pbi_recipient_read" ON public.payout_batch_items FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.payout_batches pb
        WHERE pb.id = payout_batch_id AND pb.recipient_id = auth.uid()
    ));

CREATE INDEX idx_pbi_batch      ON public.payout_batch_items(payout_batch_id);
CREATE INDEX idx_pbi_commission ON public.payout_batch_items(commission_id);


-- ── driver_earnings ───────────────────────────────────────────────────────────
CREATE TABLE public.driver_earnings (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_user_id  UUID NOT NULL REFERENCES public.profiles(id),
    app_context     VARCHAR(20) NOT NULL,
    reference_id    UUID NOT NULL,
    reference_type  VARCHAR(30) NOT NULL,
    base_earning    DECIMAL(10,3) NOT NULL,
    tip             DECIMAL(10,3) DEFAULT 0,
    bonus           DECIMAL(10,3) DEFAULT 0,
    deduction       DECIMAL(10,3) DEFAULT 0,
    net_earning     DECIMAL(10,3) GENERATED ALWAYS AS (base_earning + tip + bonus - deduction) STORED,
    payout_batch_id UUID REFERENCES public.payout_batches(id),
    status          VARCHAR(20) DEFAULT 'pending',
    -- pending | included_in_batch | paid
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.driver_earnings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "earnings_driver_read" ON public.driver_earnings FOR SELECT USING (driver_user_id = auth.uid());
CREATE POLICY "earnings_admin_all"   ON public.driver_earnings FOR ALL    USING (public.is_admin());

CREATE INDEX idx_driver_earnings_driver  ON public.driver_earnings(driver_user_id);
CREATE INDEX idx_driver_earnings_status  ON public.driver_earnings(status);
CREATE INDEX idx_driver_earnings_created ON public.driver_earnings(created_at DESC);
CREATE INDEX idx_driver_earnings_unpaid  ON public.driver_earnings(driver_user_id, status) WHERE status = 'pending';


-- ── notifications ─────────────────────────────────────────────────────────────
CREATE TABLE public.notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    app_context VARCHAR(20) DEFAULT 'global',
    type        VARCHAR(50) NOT NULL,
    title       VARCHAR(255) NOT NULL,
    title_ar    VARCHAR(255),
    body        TEXT,
    body_ar     TEXT,
    data        JSONB DEFAULT '{}',
    image_url   TEXT,
    action_url  TEXT,
    is_read     BOOLEAN DEFAULT FALSE,
    read_at     TIMESTAMP WITH TIME ZONE,
    sent_via    VARCHAR(20) DEFAULT 'in_app',
    push_status VARCHAR(20),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notif_select_own" ON public.notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notif_update_own" ON public.notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "notif_admin_all"  ON public.notifications FOR ALL   USING (public.is_admin());

CREATE INDEX idx_notif_user_id     ON public.notifications(user_id);
CREATE INDEX idx_notif_unread      ON public.notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notif_app_context ON public.notifications(app_context);
CREATE INDEX idx_notif_created_at  ON public.notifications(created_at DESC);


-- ── device_tokens ─────────────────────────────────────────────────────────────
CREATE TABLE public.device_tokens (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token        TEXT NOT NULL UNIQUE,
    platform     VARCHAR(10) NOT NULL,   -- ios | android | web
    app_version  VARCHAR(20),
    device_model VARCHAR(100),
    is_active    BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tokens_all_own"   ON public.device_tokens FOR ALL USING (user_id = auth.uid());
CREATE POLICY "tokens_admin_all" ON public.device_tokens FOR ALL USING (public.is_admin());

CREATE INDEX idx_device_tokens_user_id ON public.device_tokens(user_id);
CREATE INDEX idx_device_tokens_active  ON public.device_tokens(is_active) WHERE is_active = TRUE;


-- ── promo_codes ───────────────────────────────────────────────────────────────
CREATE TABLE public.promo_codes (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code             VARCHAR(50) NOT NULL UNIQUE,
    description      TEXT,
    app_context      VARCHAR(20) DEFAULT 'global',
    discount_type    VARCHAR(20) NOT NULL,  -- percentage | fixed | free_delivery
    discount_value   DECIMAL(10,3) NOT NULL,
    max_discount     DECIMAL(10,3),
    min_order_amount DECIMAL(10,3),
    max_total_uses   INTEGER,
    current_uses     INTEGER DEFAULT 0,
    max_uses_per_user INTEGER DEFAULT 1,
    valid_from       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until      TIMESTAMP WITH TIME ZONE,
    is_active        BOOLEAN DEFAULT TRUE,
    created_by       UUID REFERENCES public.profiles(id),
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "promo_select_all" ON public.promo_codes FOR SELECT USING (is_active = TRUE);
CREATE POLICY "promo_admin_all"  ON public.promo_codes FOR ALL   USING (public.is_admin());

CREATE INDEX idx_promo_codes_code        ON public.promo_codes(code);
CREATE INDEX idx_promo_codes_app_context ON public.promo_codes(app_context);
CREATE INDEX idx_promo_codes_active      ON public.promo_codes(is_active, valid_until);
CREATE INDEX idx_promo_codes_valid       ON public.promo_codes(code, is_active, valid_until) WHERE is_active = TRUE;
CREATE INDEX idx_promo_codes_expiry      ON public.promo_codes(valid_until) WHERE is_active = TRUE AND valid_until IS NOT NULL;


-- ── promo_code_uses ───────────────────────────────────────────────────────────
CREATE TABLE public.promo_code_uses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promo_code_id   UUID NOT NULL REFERENCES public.promo_codes(id),
    user_id         UUID NOT NULL REFERENCES public.profiles(id),
    reference_type  VARCHAR(30),
    reference_id    UUID,
    discount_amount DECIMAL(10,3) DEFAULT 0,
    used_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.promo_code_uses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "promo_uses_select_own" ON public.promo_code_uses FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "promo_uses_admin_all"  ON public.promo_code_uses FOR ALL   USING (public.is_admin());

CREATE INDEX idx_promo_uses_user_id ON public.promo_code_uses(user_id);
CREATE INDEX idx_promo_uses_code_id ON public.promo_code_uses(promo_code_id);


-- ── disputes ──────────────────────────────────────────────────────────────────
CREATE TABLE public.disputes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    raised_by       UUID NOT NULL REFERENCES public.profiles(id),
    app_context     VARCHAR(20) NOT NULL,
    reference_type  VARCHAR(30),
    reference_id    UUID,
    category        VARCHAR(50),
    -- wrong_item | missing_item | not_delivered | late_delivery | overcharged
    -- driver_behavior | damaged_item | payment_issue | other
    description     TEXT NOT NULL,
    evidence_urls   TEXT[],
    status          VARCHAR(20) DEFAULT 'open',
    -- open | under_review | resolved_customer | resolved_vendor | rejected | escalated
    resolution_note TEXT,
    refund_amount   DECIMAL(12,3) DEFAULT 0,
    refund_issued   BOOLEAN DEFAULT FALSE,
    assigned_to     UUID REFERENCES public.profiles(id),
    resolved_by     UUID REFERENCES public.profiles(id),
    resolved_at     TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "disputes_all_own"     ON public.disputes FOR ALL USING (raised_by = auth.uid());
CREATE POLICY "disputes_admin_all"   ON public.disputes FOR ALL USING (public.is_admin());
CREATE POLICY "disputes_support_all" ON public.disputes FOR ALL USING (public.is_support());

CREATE INDEX idx_disputes_raised_by ON public.disputes(raised_by);
CREATE INDEX idx_disputes_status    ON public.disputes(status);
CREATE INDEX idx_disputes_reference ON public.disputes(reference_type, reference_id);
CREATE INDEX idx_disputes_created   ON public.disputes(created_at DESC);


-- ── support_tickets ───────────────────────────────────────────────────────────
CREATE TABLE public.support_tickets (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    app_context    VARCHAR(20) DEFAULT 'global',
    subject        VARCHAR(255) NOT NULL,
    status         VARCHAR(20) DEFAULT 'open',
    priority       VARCHAR(10) DEFAULT 'medium',
    category       VARCHAR(50),
    reference_type VARCHAR(30),
    reference_id   UUID,
    assigned_to    UUID REFERENCES public.profiles(id),
    closed_at      TIMESTAMP WITH TIME ZONE,
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tickets_all_own"     ON public.support_tickets FOR ALL USING (user_id = auth.uid());
CREATE POLICY "tickets_admin_all"   ON public.support_tickets FOR ALL USING (public.is_admin());
CREATE POLICY "tickets_support_all" ON public.support_tickets FOR ALL USING (public.is_support());

CREATE INDEX idx_tickets_user_id     ON public.support_tickets(user_id);
CREATE INDEX idx_tickets_status      ON public.support_tickets(status);
CREATE INDEX idx_tickets_app_context ON public.support_tickets(app_context);
CREATE INDEX idx_tickets_created_at  ON public.support_tickets(created_at DESC);


-- ── support_messages ──────────────────────────────────────────────────────────
CREATE TABLE public.support_messages (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id   UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_id   UUID NOT NULL REFERENCES public.profiles(id),
    body        TEXT NOT NULL,
    attachments TEXT[],
    is_internal BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "support_msg_own"     ON public.support_messages FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.support_tickets st WHERE st.id = ticket_id AND st.user_id = auth.uid()));
CREATE POLICY "support_msg_send"    ON public.support_messages FOR INSERT WITH CHECK (sender_id = auth.uid());
CREATE POLICY "support_msg_admin"   ON public.support_messages FOR ALL USING (public.is_admin());
CREATE POLICY "support_msg_support" ON public.support_messages FOR ALL USING (public.is_support());

CREATE INDEX idx_support_msg_ticket_id ON public.support_messages(ticket_id);
CREATE INDEX idx_support_msg_created   ON public.support_messages(created_at DESC);


-- ── reviews ───────────────────────────────────────────────────────────────────
CREATE TABLE public.reviews (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    app_context    VARCHAR(20) NOT NULL,
    target_type    VARCHAR(30) NOT NULL,
    target_id      UUID NOT NULL,
    reference_type VARCHAR(30),
    reference_id   UUID,
    rating         SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment        TEXT,
    images         TEXT[],
    is_verified    BOOLEAN DEFAULT FALSE,
    is_visible     BOOLEAN DEFAULT TRUE,
    helpful_count  INTEGER DEFAULT 0,
    reply          TEXT,
    replied_at     TIMESTAMP WITH TIME ZONE,
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reviews_select_all" ON public.reviews FOR SELECT USING (is_visible = TRUE);
CREATE POLICY "reviews_insert_own" ON public.reviews FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "reviews_update_own" ON public.reviews FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "reviews_admin_all"  ON public.reviews FOR ALL   USING (public.is_admin());

CREATE INDEX idx_reviews_target      ON public.reviews(target_type, target_id);
CREATE INDEX idx_reviews_user_id     ON public.reviews(user_id);
CREATE INDEX idx_reviews_app_context ON public.reviews(app_context);
CREATE INDEX idx_reviews_rating      ON public.reviews(rating);
CREATE INDEX idx_reviews_created_at  ON public.reviews(created_at DESC);


-- ── loyalty_points ────────────────────────────────────────────────────────────
CREATE TABLE public.loyalty_points (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    total_points    INTEGER DEFAULT 0 CHECK (total_points >= 0),
    lifetime_points INTEGER DEFAULT 0,
    tier            VARCHAR(20) DEFAULT 'bronze',
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.loyalty_points ENABLE ROW LEVEL SECURITY;
CREATE POLICY "loyalty_select_own" ON public.loyalty_points FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "loyalty_admin_all"  ON public.loyalty_points FOR ALL   USING (public.is_admin());

CREATE INDEX idx_loyalty_user_id ON public.loyalty_points(user_id);


-- ── referrals ─────────────────────────────────────────────────────────────────
CREATE TABLE public.referrals (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id   UUID NOT NULL REFERENCES public.profiles(id),
    referee_id    UUID NOT NULL UNIQUE REFERENCES public.profiles(id),
    referral_code VARCHAR(20) NOT NULL,
    status        VARCHAR(20) DEFAULT 'pending',
    bonus_amount  DECIMAL(10,3) DEFAULT 0,
    rewarded_at   TIMESTAMP WITH TIME ZONE,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "referrals_select_own" ON public.referrals FOR SELECT
    USING (referrer_id = auth.uid() OR referee_id = auth.uid());
CREATE POLICY "referrals_admin_all"  ON public.referrals FOR ALL USING (public.is_admin());

CREATE INDEX idx_referrals_referrer_id ON public.referrals(referrer_id);


-- ── fraud_flags ───────────────────────────────────────────────────────────────
CREATE TABLE public.fraud_flags (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id),
    flag_type       VARCHAR(50) NOT NULL,
    severity        VARCHAR(10) DEFAULT 'low',
    metadata        JSONB DEFAULT '{}',
    auto_action     VARCHAR(30),
    action_taken    VARCHAR(30),
    is_resolved     BOOLEAN DEFAULT FALSE,
    reviewed_by     UUID REFERENCES public.profiles(id),
    reviewed_at     TIMESTAMP WITH TIME ZONE,
    resolution_note TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.fraud_flags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "fraud_admin_all"   ON public.fraud_flags FOR ALL USING (public.is_admin());
CREATE POLICY "fraud_support_all" ON public.fraud_flags FOR ALL USING (public.is_support());

CREATE INDEX idx_fraud_user_id  ON public.fraud_flags(user_id);
CREATE INDEX idx_fraud_type     ON public.fraud_flags(flag_type);
CREATE INDEX idx_fraud_severity ON public.fraud_flags(severity);
CREATE INDEX idx_fraud_resolved ON public.fraud_flags(is_resolved) WHERE is_resolved = FALSE;


-- ── audit_log (partitioned by month) ─────────────────────────────────────────
-- [FIX v4.1] No PRIMARY KEY on partitioned table (PG requires partition key in PK).
-- We use UNIQUE INDEX per partition instead (created below + by cron job).
CREATE TABLE public.audit_log (
    id          BIGSERIAL,
    user_id     UUID,
    action      VARCHAR(20) NOT NULL,
    schema_name VARCHAR(30) NOT NULL,
    table_name  VARCHAR(100) NOT NULL,
    record_id   UUID,
    old_data    JSONB,
    new_data    JSONB,
    ip_address  INET,
    user_agent  TEXT,
    app_context VARCHAR(20),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
) PARTITION BY RANGE (created_at);

CREATE TABLE public.audit_log_2026_01 PARTITION OF public.audit_log FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE public.audit_log_2026_02 PARTITION OF public.audit_log FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE public.audit_log_2026_03 PARTITION OF public.audit_log FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE public.audit_log_2026_04 PARTITION OF public.audit_log FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE public.audit_log_2026_05 PARTITION OF public.audit_log FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE public.audit_log_2026_06 PARTITION OF public.audit_log FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE public.audit_log_2026_07 PARTITION OF public.audit_log FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE public.audit_log_2026_08 PARTITION OF public.audit_log FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE public.audit_log_2026_09 PARTITION OF public.audit_log FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE public.audit_log_2026_10 PARTITION OF public.audit_log FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE public.audit_log_2026_11 PARTITION OF public.audit_log FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE public.audit_log_2026_12 PARTITION OF public.audit_log FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- [FIX v4.1] Per-partition unique index on id (replaces impossible cross-partition PK)
CREATE UNIQUE INDEX uidx_audit_log_2026_01_id ON public.audit_log_2026_01(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_02_id ON public.audit_log_2026_02(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_03_id ON public.audit_log_2026_03(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_04_id ON public.audit_log_2026_04(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_05_id ON public.audit_log_2026_05(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_06_id ON public.audit_log_2026_06(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_07_id ON public.audit_log_2026_07(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_08_id ON public.audit_log_2026_08(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_09_id ON public.audit_log_2026_09(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_10_id ON public.audit_log_2026_10(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_11_id ON public.audit_log_2026_11(id);
CREATE UNIQUE INDEX uidx_audit_log_2026_12_id ON public.audit_log_2026_12(id);

CREATE INDEX idx_audit_log_user_id    ON public.audit_log(user_id);
CREATE INDEX idx_audit_log_table      ON public.audit_log(schema_name, table_name);
CREATE INDEX idx_audit_log_created_at ON public.audit_log(created_at DESC);


-- ── daily_stats ───────────────────────────────────────────────────────────────
CREATE TABLE public.daily_stats (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stat_date        DATE NOT NULL,
    app_context      VARCHAR(20) NOT NULL,
    orders_count     INTEGER DEFAULT 0,
    completed_orders INTEGER DEFAULT 0,
    cancelled_orders INTEGER DEFAULT 0,
    new_users        INTEGER DEFAULT 0,
    active_drivers   INTEGER DEFAULT 0,
    gmv              DECIMAL(16,3) DEFAULT 0,
    commission_rev   DECIMAL(16,3) DEFAULT 0,
    delivery_fees    DECIMAL(16,3) DEFAULT 0,
    avg_order_value  DECIMAL(12,3) DEFAULT 0,
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(stat_date, app_context)
);

CREATE INDEX idx_daily_stats_date ON public.daily_stats(stat_date DESC);
CREATE INDEX idx_daily_stats_app  ON public.daily_stats(app_context);


-- ── banners ───────────────────────────────────────────────────────────────────
CREATE TABLE public.banners (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    app_context VARCHAR(20) DEFAULT 'global',
    title       VARCHAR(255),
    title_ar    VARCHAR(255),
    subtitle    TEXT,
    subtitle_ar TEXT,
    image_url   TEXT,
    deep_link   TEXT,
    action_type VARCHAR(30) DEFAULT 'none',
    action_value TEXT,
    position    INTEGER DEFAULT 0,
    valid_from  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active   BOOLEAN DEFAULT TRUE,
    created_by  UUID REFERENCES public.profiles(id),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
CREATE POLICY "banners_select_active" ON public.banners FOR SELECT
    USING (is_active = TRUE AND (valid_until IS NULL OR valid_until > NOW()));
CREATE POLICY "banners_admin_all" ON public.banners FOR ALL USING (public.is_admin());

CREATE INDEX idx_banners_app    ON public.banners(app_context);
CREATE INDEX idx_banners_active ON public.banners(is_active, valid_until);
CREATE INDEX idx_banners_pos    ON public.banners(position);


-- ── app_settings ──────────────────────────────────────────────────────────────
CREATE TABLE public.app_settings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key         VARCHAR(100) NOT NULL UNIQUE,
    value       JSONB NOT NULL DEFAULT '{}',
    app_context VARCHAR(20) DEFAULT 'global',
    description TEXT,
    is_public   BOOLEAN DEFAULT FALSE,
    updated_by  UUID REFERENCES public.profiles(id),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "settings_select_public" ON public.app_settings FOR SELECT USING (is_public = TRUE);
CREATE POLICY "settings_admin_all"     ON public.app_settings FOR ALL   USING (public.is_admin());

CREATE INDEX idx_app_settings_key ON public.app_settings(key);


-- ── tax_rates ─────────────────────────────────────────────────────────────────
CREATE TABLE public.tax_rates (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name         VARCHAR(100) NOT NULL,
    rate_percent DECIMAL(5,2) NOT NULL,
    app_context  VARCHAR(20) DEFAULT 'global',
    applies_to   TEXT[],
    country_code VARCHAR(3) DEFAULT 'TN',
    is_default   BOOLEAN DEFAULT FALSE,
    is_active    BOOLEAN DEFAULT TRUE,
    valid_from   DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_until  DATE,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.tax_rates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tax_rates_select" ON public.tax_rates FOR SELECT USING (is_active = TRUE);
CREATE POLICY "tax_rates_admin"  ON public.tax_rates FOR ALL   USING (public.is_admin());

CREATE INDEX idx_tax_rates_app    ON public.tax_rates(app_context);
CREATE INDEX idx_tax_rates_active ON public.tax_rates(is_active, valid_from);


-- ── webhook_events ────────────────────────────────────────────────────────────
CREATE TABLE public.webhook_events (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider          VARCHAR(30) NOT NULL,
    event_type        VARCHAR(50),
    provider_event_id VARCHAR(255),
    payload           JSONB NOT NULL DEFAULT '{}',
    headers           JSONB DEFAULT '{}',
    signature_valid   BOOLEAN,
    processed         BOOLEAN DEFAULT FALSE,
    processing_attempts INTEGER DEFAULT 0,
    linked_tx_id      UUID REFERENCES public.payment_transactions(id),
    error             TEXT,
    received_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at      TIMESTAMP WITH TIME ZONE,
    UNIQUE(provider, provider_event_id)
);

ALTER TABLE public.webhook_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "webhooks_admin_all" ON public.webhook_events FOR ALL USING (public.is_admin());

CREATE INDEX idx_webhooks_provider    ON public.webhook_events(provider);
CREATE INDEX idx_webhooks_unprocessed ON public.webhook_events(processed, received_at) WHERE processed = FALSE;
CREATE INDEX idx_webhooks_received    ON public.webhook_events(received_at DESC);
CREATE INDEX idx_webhooks_linked_tx   ON public.webhook_events(linked_tx_id);


-- ── vendor_applications ───────────────────────────────────────────────────────
CREATE TABLE public.vendor_applications (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID NOT NULL REFERENCES public.profiles(id),
    app_context      VARCHAR(20) NOT NULL,
    role_requested   VARCHAR(20) NOT NULL DEFAULT 'vendor',
    business_name    VARCHAR(255),
    business_name_ar VARCHAR(255),
    business_type    VARCHAR(50),
    business_address TEXT,
    city             VARCHAR(100),
    phone            VARCHAR(50),
    email            VARCHAR(255),
    documents        JSONB DEFAULT '{}',
    status           VARCHAR(20) DEFAULT 'pending',
    -- pending | under_review | approved | rejected | more_info_needed
    rejection_reason  TEXT,
    review_notes      TEXT,
    reviewed_by       UUID REFERENCES public.profiles(id),
    reviewed_at       TIMESTAMP WITH TIME ZONE,
    created_vendor_id UUID,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.vendor_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "vendor_app_own"     ON public.vendor_applications FOR ALL    USING (user_id = auth.uid());
CREATE POLICY "vendor_app_admin"   ON public.vendor_applications FOR ALL    USING (public.is_admin());
CREATE POLICY "vendor_app_support" ON public.vendor_applications FOR SELECT USING (public.is_support());

CREATE INDEX idx_vendor_app_user_id ON public.vendor_applications(user_id);
CREATE INDEX idx_vendor_app_status  ON public.vendor_applications(status);
CREATE INDEX idx_vendor_app_context ON public.vendor_applications(app_context);
CREATE INDEX idx_vendor_app_created ON public.vendor_applications(created_at DESC);


-- ── return_requests ───────────────────────────────────────────────────────────
CREATE TABLE public.return_requests (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id              UUID NOT NULL REFERENCES public.profiles(id),
    app_context          VARCHAR(20) NOT NULL,
    order_id             UUID NOT NULL,
    return_type          VARCHAR(20) DEFAULT 'return',
    reason               VARCHAR(50) NOT NULL,
    description          TEXT,
    evidence_urls        TEXT[],
    items                JSONB NOT NULL,
    status               VARCHAR(20) DEFAULT 'pending',
    -- pending | approved | rejected | collection_scheduled | collected | refund_issued | exchange_sent
    pickup_address_id    UUID REFERENCES public.addresses(id),
    pickup_scheduled_at  TIMESTAMP WITH TIME ZONE,
    collection_driver_id UUID REFERENCES public.profiles(id),
    refund_method        VARCHAR(30),
    refund_amount        DECIMAL(12,3) DEFAULT 0,
    refund_issued_at     TIMESTAMP WITH TIME ZONE,
    rejection_reason     TEXT,
    reviewed_by          UUID REFERENCES public.profiles(id),
    reviewed_at          TIMESTAMP WITH TIME ZONE,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.return_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "returns_own"     ON public.return_requests FOR ALL    USING (user_id = auth.uid());
CREATE POLICY "returns_admin"   ON public.return_requests FOR ALL    USING (public.is_admin());
CREATE POLICY "returns_support" ON public.return_requests FOR SELECT USING (public.is_support());

CREATE INDEX idx_returns_user_id  ON public.return_requests(user_id);
CREATE INDEX idx_returns_order_id ON public.return_requests(order_id);
CREATE INDEX idx_returns_status   ON public.return_requests(status);
CREATE INDEX idx_returns_app      ON public.return_requests(app_context);
CREATE INDEX idx_returns_created  ON public.return_requests(created_at DESC);


-- ── conversations ─────────────────────────────────────────────────────────────
CREATE TABLE public.conversations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference_type  VARCHAR(30) NOT NULL,
    reference_id    UUID NOT NULL,
    participant_ids UUID[] NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    closed_at       TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reference_type, reference_id)
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "conv_participant_all" ON public.conversations FOR ALL
    USING (auth.uid() = ANY(participant_ids));
CREATE POLICY "conv_admin_all" ON public.conversations FOR ALL USING (public.is_admin());

CREATE INDEX idx_conversations_ref    ON public.conversations(reference_type, reference_id);
CREATE INDEX idx_conversations_active ON public.conversations(is_active) WHERE is_active = TRUE;


-- ── chat_messages ─────────────────────────────────────────────────────────────
CREATE TABLE public.chat_messages (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES public.profiles(id),
    body            TEXT,
    type            VARCHAR(20) DEFAULT 'text',
    media_url       TEXT,
    location_lat    DOUBLE PRECISION,
    location_lng    DOUBLE PRECISION,
    is_read         BOOLEAN DEFAULT FALSE,
    read_at         TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_msg_participant_select" ON public.chat_messages FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id AND auth.uid() = ANY(c.participant_ids)
    ));
CREATE POLICY "chat_msg_participant_insert" ON public.chat_messages FOR INSERT
    WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = conversation_id
              AND auth.uid() = ANY(c.participant_ids)
              AND c.is_active = TRUE
        )
    );
CREATE POLICY "chat_msg_admin_all" ON public.chat_messages FOR ALL USING (public.is_admin());

CREATE INDEX idx_chat_msg_conversation ON public.chat_messages(conversation_id);
CREATE INDEX idx_chat_msg_unread       ON public.chat_messages(conversation_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_chat_msg_created      ON public.chat_messages(created_at DESC);


-- ── delivery_zones ────────────────────────────────────────────────────────────
CREATE TABLE public.delivery_zones (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name              VARCHAR(100) NOT NULL,
    name_ar           VARCHAR(100),
    city              VARCHAR(100) NOT NULL DEFAULT 'Tunis',
    boundary          GEOGRAPHY(Polygon, 4326) NOT NULL,
    app_context       VARCHAR(20) DEFAULT 'global',
    base_delivery_fee DECIMAL(10,3) DEFAULT 0,
    is_active         BOOLEAN DEFAULT TRUE,
    sort_order        INTEGER DEFAULT 0,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "zones_select_active" ON public.delivery_zones FOR SELECT USING (is_active = TRUE);
CREATE POLICY "zones_admin_all"     ON public.delivery_zones FOR ALL   USING (public.is_admin());

CREATE INDEX idx_delivery_zones_boundary ON public.delivery_zones USING GIST (boundary);
CREATE INDEX idx_delivery_zones_city     ON public.delivery_zones(city);
CREATE INDEX idx_delivery_zones_app      ON public.delivery_zones(app_context);


-- ── driver_zone_assignments ───────────────────────────────────────────────────
CREATE TABLE public.driver_zone_assignments (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    zone_id     UUID NOT NULL REFERENCES public.delivery_zones(id) ON DELETE CASCADE,
    app_context VARCHAR(20) NOT NULL,
    is_active   BOOLEAN DEFAULT TRUE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES public.profiles(id),
    UNIQUE(driver_id, zone_id, app_context)
);

ALTER TABLE public.driver_zone_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "zone_assign_own"   ON public.driver_zone_assignments FOR SELECT USING (driver_id = auth.uid());
CREATE POLICY "zone_assign_admin" ON public.driver_zone_assignments FOR ALL   USING (public.is_admin());

CREATE INDEX idx_zone_assign_driver ON public.driver_zone_assignments(driver_id);
CREATE INDEX idx_zone_assign_zone   ON public.driver_zone_assignments(zone_id);


-- ── driver_shifts ─────────────────────────────────────────────────────────────
CREATE TABLE public.driver_shifts (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    app_context      VARCHAR(20) NOT NULL,
    zone_id          UUID REFERENCES public.delivery_zones(id),
    scheduled_start  TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end    TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_start     TIMESTAMP WITH TIME ZONE,
    actual_end       TIMESTAMP WITH TIME ZONE,
    status           VARCHAR(20) DEFAULT 'scheduled',
    orders_completed INTEGER DEFAULT 0,
    total_earned     DECIMAL(10,3) DEFAULT 0,
    notes            TEXT,
    created_by       UUID REFERENCES public.profiles(id),
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.driver_shifts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "shifts_own"   ON public.driver_shifts FOR SELECT USING (driver_id = auth.uid());
CREATE POLICY "shifts_admin" ON public.driver_shifts FOR ALL   USING (public.is_admin());

CREATE INDEX idx_shifts_driver    ON public.driver_shifts(driver_id);
CREATE INDEX idx_shifts_scheduled ON public.driver_shifts(scheduled_start, scheduled_end);
CREATE INDEX idx_shifts_status    ON public.driver_shifts(status);
CREATE INDEX idx_shifts_zone      ON public.driver_shifts(zone_id);


-- ── notification_templates ────────────────────────────────────────────────────
CREATE TABLE public.notification_templates (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type  VARCHAR(100) NOT NULL,
    app_context VARCHAR(20) DEFAULT 'global',
    channel     VARCHAR(20) DEFAULT 'push',
    title_en    VARCHAR(255),
    title_ar    VARCHAR(255),
    title_fr    VARCHAR(255),
    body_en     TEXT,
    body_ar     TEXT,
    body_fr     TEXT,
    variables   TEXT[] DEFAULT '{}',
    deep_link   TEXT,
    icon        VARCHAR(50),
    is_active   BOOLEAN DEFAULT TRUE,
    updated_by  UUID REFERENCES public.profiles(id),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_type, app_context, channel)
);

ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notif_tmpl_select"    ON public.notification_templates FOR SELECT USING (is_active = TRUE);
CREATE POLICY "notif_tmpl_admin_all" ON public.notification_templates FOR ALL   USING (public.is_admin());

CREATE INDEX idx_notif_tmpl_event   ON public.notification_templates(event_type);
CREATE INDEX idx_notif_tmpl_app     ON public.notification_templates(app_context);
CREATE INDEX idx_notif_tmpl_channel ON public.notification_templates(channel);


-- ── feature_flags ─────────────────────────────────────────────────────────────
CREATE TABLE public.feature_flags (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key             VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    is_enabled      BOOLEAN DEFAULT FALSE,
    rollout_percent INTEGER DEFAULT 100 CHECK (rollout_percent BETWEEN 0 AND 100),
    conditions      JSONB DEFAULT '{}',
    variant_config  JSONB DEFAULT '{}',
    created_by      UUID REFERENCES public.profiles(id),
    updated_by      UUID REFERENCES public.profiles(id),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "flags_select_enabled" ON public.feature_flags FOR SELECT USING (is_enabled = TRUE);
CREATE POLICY "flags_admin_all"      ON public.feature_flags FOR ALL   USING (public.is_admin());

CREATE INDEX idx_feature_flags_key     ON public.feature_flags(key);
CREATE INDEX idx_feature_flags_enabled ON public.feature_flags(is_enabled) WHERE is_enabled = TRUE;


-- ── wishlists ─────────────────────────────────────────────────────────────────
CREATE TABLE public.wishlists (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    app_context VARCHAR(20) NOT NULL,
    target_type VARCHAR(30) NOT NULL,
    target_id   UUID NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, app_context, target_type, target_id)
);

ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wishlists_own"   ON public.wishlists FOR ALL USING (user_id = auth.uid());
CREATE POLICY "wishlists_admin" ON public.wishlists FOR ALL USING (public.is_admin());

CREATE INDEX idx_wishlists_user   ON public.wishlists(user_id);
CREATE INDEX idx_wishlists_target ON public.wishlists(target_type, target_id);


-- ── platform_announcements ────────────────────────────────────────────────────
CREATE TABLE public.platform_announcements (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type               VARCHAR(30) NOT NULL,
    title              VARCHAR(255) NOT NULL,
    title_ar           VARCHAR(255),
    title_fr           VARCHAR(255),
    message            TEXT,
    message_ar         TEXT,
    message_fr         TEXT,
    min_version        VARCHAR(20),
    store_url_ios      TEXT,
    store_url_android  TEXT,
    maintenance_start  TIMESTAMP WITH TIME ZONE,
    maintenance_end    TIMESTAMP WITH TIME ZONE,
    app_context        VARCHAR(20) DEFAULT 'global',
    platforms          TEXT[] DEFAULT ARRAY['ios','android','web'],
    audience           VARCHAR(20) DEFAULT 'all',
    is_dismissible     BOOLEAN DEFAULT TRUE,
    is_active          BOOLEAN DEFAULT TRUE,
    valid_from         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until        TIMESTAMP WITH TIME ZONE,
    created_by         UUID REFERENCES public.profiles(id),
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.platform_announcements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "announcements_select" ON public.platform_announcements FOR SELECT
    USING (is_active = TRUE AND valid_from <= NOW() AND (valid_until IS NULL OR valid_until > NOW()));
CREATE POLICY "announcements_admin"  ON public.platform_announcements FOR ALL USING (public.is_admin());

CREATE INDEX idx_announcements_active ON public.platform_announcements(is_active, valid_from);
CREATE INDEX idx_announcements_type   ON public.platform_announcements(type);
CREATE INDEX idx_announcements_app    ON public.platform_announcements(app_context);


-- ============================================================================
-- FOOD SCHEMA
-- ============================================================================

CREATE TABLE food.categories (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name       VARCHAR(100) NOT NULL UNIQUE,
    name_ar    VARCHAR(100),
    name_fr    VARCHAR(100),
    icon_url   TEXT,
    color      VARCHAR(7) DEFAULT '#FF6B35',
    sort_order INTEGER DEFAULT 0,
    is_active  BOOLEAN DEFAULT TRUE
);

ALTER TABLE food.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_cat_select" ON food.categories FOR SELECT USING (is_active = TRUE);
CREATE POLICY "food_cat_admin"  ON food.categories FOR ALL   USING (public.is_admin());

CREATE INDEX idx_food_categories_sort ON food.categories(sort_order);


CREATE TABLE food.cuisines (
    id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name      VARCHAR(100) NOT NULL UNIQUE,
    name_ar   VARCHAR(100),
    name_fr   VARCHAR(100),
    icon_url  TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE food.cuisines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_cuisine_select" ON food.cuisines FOR SELECT USING (is_active = TRUE);
CREATE POLICY "food_cuisine_admin"  ON food.cuisines FOR ALL   USING (public.is_admin());


CREATE TABLE food.restaurants (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id                UUID NOT NULL REFERENCES public.profiles(id),
    name                    VARCHAR(255) NOT NULL,
    name_ar                 VARCHAR(255),
    description             TEXT,
    description_ar          TEXT,
    phone                   VARCHAR(50),
    email                   VARCHAR(255),
    logo_url                TEXT,
    cover_url               TEXT,
    images                  TEXT[],
    category_ids            UUID[],
    cuisine_ids             UUID[],
    address                 TEXT,
    city                    VARCHAR(100),
    latitude                DOUBLE PRECISION,
    longitude               DOUBLE PRECISION,
    location                GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                                CASE
                                    WHEN latitude IS NOT NULL AND longitude IS NOT NULL
                                    THEN ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                                    ELSE NULL
                                END
                            ) STORED,
    delivery_radius_km      DECIMAL(5,2) DEFAULT 5,
    delivery_fee            DECIMAL(10,3) DEFAULT 0,
    delivery_fee_type       VARCHAR(20) DEFAULT 'fixed',
    free_delivery_threshold DECIMAL(10,3),
    min_order_amount        DECIMAL(10,3) DEFAULT 0,
    estimated_delivery_min  INTEGER DEFAULT 30,
    preparation_time_min    INTEGER DEFAULT 15,
    commission_rate         DECIMAL(5,2) DEFAULT 15,
    rating                  DECIMAL(3,2) DEFAULT 0,
    rating_count            INTEGER DEFAULT 0,
    is_open                 BOOLEAN DEFAULT FALSE,
    is_active               BOOLEAN DEFAULT TRUE,
    is_verified             BOOLEAN DEFAULT FALSE,
    is_featured             BOOLEAN DEFAULT FALSE,
    featured_until          TIMESTAMP WITH TIME ZONE,
    accepts_cash            BOOLEAN DEFAULT TRUE,
    accepts_card            BOOLEAN DEFAULT TRUE,
    accepts_wallet          BOOLEAN DEFAULT TRUE,
    tags                    TEXT[],
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food.restaurants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_rest_select_active" ON food.restaurants FOR SELECT USING (is_active = TRUE);
CREATE POLICY "food_rest_owner_all"     ON food.restaurants FOR ALL   USING (owner_id = auth.uid());
CREATE POLICY "food_rest_admin_all"     ON food.restaurants FOR ALL   USING (public.is_admin());

CREATE INDEX idx_food_restaurants_owner_id  ON food.restaurants(owner_id);
CREATE INDEX idx_food_restaurants_location  ON food.restaurants USING GIST (location);
CREATE INDEX idx_food_restaurants_rating    ON food.restaurants(rating DESC);
CREATE INDEX idx_food_restaurants_featured  ON food.restaurants(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_food_restaurants_open      ON food.restaurants(is_open) WHERE is_open = TRUE;
CREATE INDEX idx_food_restaurants_name_trgm ON food.restaurants USING GIN (name gin_trgm_ops);
CREATE INDEX idx_food_restaurants_active    ON food.restaurants(is_active, is_verified);


CREATE TABLE food.operating_hours (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES food.restaurants(id) ON DELETE CASCADE,
    day_of_week   SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    opens_at      TIME NOT NULL,
    closes_at     TIME NOT NULL,
    is_closed     BOOLEAN DEFAULT FALSE,
    UNIQUE(restaurant_id, day_of_week)
);

ALTER TABLE food.operating_hours ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_hours_select"    ON food.operating_hours FOR SELECT USING (TRUE);
CREATE POLICY "food_hours_owner_all" ON food.operating_hours FOR ALL
    USING (EXISTS (SELECT 1 FROM food.restaurants r WHERE r.id = restaurant_id AND r.owner_id = auth.uid()));
CREATE POLICY "food_hours_admin_all" ON food.operating_hours FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_hours_restaurant ON food.operating_hours(restaurant_id);


CREATE TABLE food.menu_sections (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id   UUID NOT NULL REFERENCES food.restaurants(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    name_ar         VARCHAR(100),
    name_fr         VARCHAR(100),
    description     TEXT,
    sort_order      INTEGER DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    available_from  TIME,
    available_until TIME
);

ALTER TABLE food.menu_sections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_sections_select"    ON food.menu_sections FOR SELECT USING (is_active = TRUE);
CREATE POLICY "food_sections_owner_all" ON food.menu_sections FOR ALL
    USING (EXISTS (SELECT 1 FROM food.restaurants r WHERE r.id = restaurant_id AND r.owner_id = auth.uid()));
CREATE POLICY "food_sections_admin_all" ON food.menu_sections FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_menu_sections_restaurant ON food.menu_sections(restaurant_id);


CREATE TABLE food.menu_items (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id  UUID NOT NULL REFERENCES food.restaurants(id) ON DELETE CASCADE,
    section_id     UUID REFERENCES food.menu_sections(id) ON DELETE SET NULL,
    name           VARCHAR(255) NOT NULL,
    name_ar        VARCHAR(255),
    name_fr        VARCHAR(255),
    description    TEXT,
    description_ar TEXT,
    description_fr TEXT,
    price          DECIMAL(10,3) NOT NULL CHECK (price >= 0),
    compare_price  DECIMAL(10,3),
    images         TEXT[],
    calories       INTEGER,
    prep_time_min  INTEGER DEFAULT 10,
    is_available   BOOLEAN DEFAULT TRUE,
    is_featured    BOOLEAN DEFAULT FALSE,
    is_popular     BOOLEAN DEFAULT FALSE,
    is_spicy       BOOLEAN DEFAULT FALSE,
    is_vegetarian  BOOLEAN DEFAULT FALSE,
    is_vegan       BOOLEAN DEFAULT FALSE,
    allergens      TEXT[],
    sort_order     INTEGER DEFAULT 0,
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food.menu_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_items_select"    ON food.menu_items FOR SELECT USING (is_available = TRUE);
CREATE POLICY "food_items_owner_all" ON food.menu_items FOR ALL
    USING (EXISTS (SELECT 1 FROM food.restaurants r WHERE r.id = restaurant_id AND r.owner_id = auth.uid()));
CREATE POLICY "food_items_admin_all" ON food.menu_items FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_menu_items_restaurant ON food.menu_items(restaurant_id);
CREATE INDEX idx_food_menu_items_section    ON food.menu_items(section_id);
CREATE INDEX idx_food_menu_items_popular    ON food.menu_items(is_popular) WHERE is_popular = TRUE;
CREATE INDEX idx_food_menu_items_name_trgm  ON food.menu_items USING GIN (name gin_trgm_ops);


CREATE TABLE food.addon_groups (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID NOT NULL REFERENCES food.menu_items(id) ON DELETE CASCADE,
    name         VARCHAR(100) NOT NULL,
    name_ar      VARCHAR(100),
    required     BOOLEAN DEFAULT FALSE,
    min_select   INTEGER DEFAULT 0,
    max_select   INTEGER DEFAULT 1,
    sort_order   INTEGER DEFAULT 0
);

ALTER TABLE food.addon_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_addon_groups_select" ON food.addon_groups FOR SELECT USING (TRUE);
CREATE POLICY "food_addon_groups_admin"  ON food.addon_groups FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_addon_groups_item ON food.addon_groups(menu_item_id);


CREATE TABLE food.addons (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id     UUID NOT NULL REFERENCES food.addon_groups(id) ON DELETE CASCADE,
    name         VARCHAR(100) NOT NULL,
    name_ar      VARCHAR(100),
    price        DECIMAL(10,3) DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    sort_order   INTEGER DEFAULT 0
);

ALTER TABLE food.addons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_addons_select" ON food.addons FOR SELECT USING (is_available = TRUE);
CREATE POLICY "food_addons_admin"  ON food.addons FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_addons_group ON food.addons(group_id);


CREATE TABLE food.drivers (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL UNIQUE REFERENCES public.profiles(id),
    vehicle_type      VARCHAR(30),
    vehicle_make      VARCHAR(100),
    vehicle_model     VARCHAR(100),
    vehicle_plate     VARCHAR(30) UNIQUE,
    vehicle_color     VARCHAR(50),
    vehicle_photo_url TEXT,
    license_url       TEXT,
    id_card_url       TEXT,
    bank_account      TEXT,
    rating            DECIMAL(3,2) DEFAULT 5,
    rating_count      INTEGER DEFAULT 0,
    total_deliveries  INTEGER DEFAULT 0,
    acceptance_rate   DECIMAL(5,2) DEFAULT 100,
    cancellation_rate DECIMAL(5,2) DEFAULT 0,
    is_available      BOOLEAN DEFAULT FALSE,
    is_online         BOOLEAN DEFAULT FALSE,
    is_verified       BOOLEAN DEFAULT FALSE,
    is_active         BOOLEAN DEFAULT TRUE,
    current_lat       DOUBLE PRECISION,
    current_lng       DOUBLE PRECISION,
    current_location  GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                          CASE
                              WHEN current_lat IS NOT NULL AND current_lng IS NOT NULL
                              THEN ST_SetSRID(ST_MakePoint(current_lng, current_lat), 4326)::geography
                              ELSE NULL
                          END
                      ) STORED,
    heading           DOUBLE PRECISION,
    last_location_at  TIMESTAMP WITH TIME ZONE,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food.drivers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_drivers_select_verified" ON food.drivers FOR SELECT USING (is_active = TRUE);
CREATE POLICY "food_drivers_own"             ON food.drivers FOR ALL   USING (user_id = auth.uid());
CREATE POLICY "food_drivers_admin_all"       ON food.drivers FOR ALL   USING (public.is_admin());

CREATE INDEX idx_food_drivers_user_id   ON food.drivers(user_id);
CREATE INDEX idx_food_drivers_location  ON food.drivers USING GIST (current_location);
CREATE INDEX idx_food_drivers_available ON food.drivers(is_available, is_verified) WHERE is_active = TRUE;


CREATE TABLE food.carts (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES food.restaurants(id),
    promo_code_id UUID REFERENCES public.promo_codes(id),
    notes         TEXT,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food.carts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_cart_all_own" ON food.carts FOR ALL USING (user_id = auth.uid());

CREATE INDEX idx_food_carts_user_id ON food.carts(user_id);


CREATE TABLE food.cart_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id         UUID NOT NULL REFERENCES food.carts(id) ON DELETE CASCADE,
    menu_item_id    UUID NOT NULL REFERENCES food.menu_items(id),
    quantity        INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    selected_addons JSONB DEFAULT '[]',
    unit_price      DECIMAL(10,3) NOT NULL,
    notes           TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food.cart_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_cart_items_own" ON food.cart_items FOR ALL
    USING (EXISTS (SELECT 1 FROM food.carts c WHERE c.id = cart_id AND c.user_id = auth.uid()));

CREATE INDEX idx_food_cart_items_cart ON food.cart_items(cart_id);


CREATE TABLE food.orders (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number           VARCHAR(30) UNIQUE,
    user_id                UUID NOT NULL REFERENCES public.profiles(id),
    restaurant_id          UUID NOT NULL REFERENCES food.restaurants(id),
    driver_id              UUID REFERENCES food.drivers(id),
    delivery_address_id    UUID REFERENCES public.addresses(id),
    delivery_address_text  TEXT,
    delivery_lat           DOUBLE PRECISION,
    delivery_lng           DOUBLE PRECISION,
    delivery_location      GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                               CASE
                                   WHEN delivery_lat IS NOT NULL AND delivery_lng IS NOT NULL
                                   THEN ST_SetSRID(ST_MakePoint(delivery_lng, delivery_lat), 4326)::geography
                                   ELSE NULL
                               END
                           ) STORED,
    status                 VARCHAR(30) DEFAULT 'pending',
    -- pending | pending_dispatch | confirmed | preparing | ready | picked_up | delivered | cancelled | refunded
    subtotal               DECIMAL(12,3) NOT NULL DEFAULT 0,
    delivery_fee           DECIMAL(10,3) DEFAULT 0,
    service_fee            DECIMAL(10,3) DEFAULT 0,
    discount               DECIMAL(10,3) DEFAULT 0,
    tip                    DECIMAL(10,3) DEFAULT 0,
    tax_rate_id            UUID REFERENCES public.tax_rates(id),
    tax_amount             DECIMAL(12,3) DEFAULT 0,
    tax_rate_pct           DECIMAL(5,2) DEFAULT 0,
    total                  DECIMAL(12,3) NOT NULL DEFAULT 0,
    payment_method         VARCHAR(30) NOT NULL,
    payment_status         VARCHAR(20) DEFAULT 'pending',
    payment_reference      VARCHAR(255),
    payment_transaction_id UUID REFERENCES public.payment_transactions(id),
    promo_code_id          UUID REFERENCES public.promo_codes(id),
    promo_discount         DECIMAL(10,3) DEFAULT 0,
    notes                  TEXT,
    cutlery_requested      BOOLEAN DEFAULT FALSE,
    is_scheduled           BOOLEAN DEFAULT FALSE,
    scheduled_for          TIMESTAMP WITH TIME ZONE,
    estimated_delivery_at  TIMESTAMP WITH TIME ZONE,
    actual_delivery_at     TIMESTAMP WITH TIME ZONE,
    preparation_started_at TIMESTAMP WITH TIME ZONE,
    driver_assigned_at     TIMESTAMP WITH TIME ZONE,
    driver_picked_up_at    TIMESTAMP WITH TIME ZONE,
    cancelled_at           TIMESTAMP WITH TIME ZONE,
    cancelled_by           VARCHAR(20),
    cancellation_reason    TEXT,
    dispatch_attempts      INTEGER DEFAULT 0,
    dispatch_radius_m      INTEGER DEFAULT 3000,
    last_dispatch_at       TIMESTAMP WITH TIME ZONE,
    delivery_route         JSONB,
    current_eta_minutes    INTEGER,
    eta_updated_at         TIMESTAMP WITH TIME ZONE,
    created_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_orders_select_own"   ON food.orders FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "food_orders_insert_own"   ON food.orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "food_orders_update_own"   ON food.orders FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "food_orders_restaurant"   ON food.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM food.restaurants r WHERE r.id = restaurant_id AND r.owner_id = auth.uid()));
CREATE POLICY "food_orders_driver"       ON food.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM food.drivers d WHERE d.id = driver_id AND d.user_id = auth.uid()));
CREATE POLICY "food_orders_admin_all"    ON food.orders FOR ALL USING (public.is_admin());
CREATE POLICY "food_orders_support_read" ON food.orders FOR SELECT USING (public.is_support());

CREATE INDEX idx_food_orders_user_id       ON food.orders(user_id);
CREATE INDEX idx_food_orders_restaurant_id ON food.orders(restaurant_id);
CREATE INDEX idx_food_orders_driver_id     ON food.orders(driver_id);
CREATE INDEX idx_food_orders_status        ON food.orders(status);
CREATE INDEX idx_food_orders_created_at    ON food.orders(created_at DESC);
CREATE INDEX idx_food_orders_scheduled     ON food.orders(scheduled_for) WHERE is_scheduled = TRUE;
CREATE INDEX idx_food_orders_payment       ON food.orders(payment_status);
CREATE INDEX idx_food_orders_dispatch      ON food.orders(status) WHERE status = 'pending_dispatch';
CREATE INDEX idx_food_orders_user_status   ON food.orders(user_id, status);


CREATE TABLE food.order_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES food.orders(id) ON DELETE CASCADE,
    menu_item_id    UUID NOT NULL REFERENCES food.menu_items(id),
    menu_item_name  VARCHAR(255) NOT NULL,
    quantity        INTEGER NOT NULL DEFAULT 1,
    unit_price      DECIMAL(10,3) NOT NULL,
    addons_price    DECIMAL(10,3) DEFAULT 0,
    total_price     DECIMAL(10,3) NOT NULL,
    selected_addons JSONB DEFAULT '[]',
    notes           TEXT
);

ALTER TABLE food.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_order_items_own"   ON food.order_items FOR SELECT
    USING (EXISTS (SELECT 1 FROM food.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "food_order_items_admin" ON food.order_items FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_order_items_order_id ON food.order_items(order_id);


CREATE TABLE food.order_status_log (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id   UUID NOT NULL REFERENCES food.orders(id) ON DELETE CASCADE,
    status     VARCHAR(30) NOT NULL,
    note       TEXT,
    changed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food.order_status_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_status_log_own"   ON food.order_status_log FOR SELECT
    USING (EXISTS (SELECT 1 FROM food.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "food_status_log_admin" ON food.order_status_log FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_order_log_order_id   ON food.order_status_log(order_id);
CREATE INDEX idx_food_order_log_created_at ON food.order_status_log(created_at DESC);


CREATE TABLE food.dispatch_attempts (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id         UUID NOT NULL REFERENCES food.orders(id) ON DELETE CASCADE,
    driver_id        UUID REFERENCES food.drivers(id),
    attempted_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    offer_expires_at TIMESTAMP WITH TIME ZONE,
    response         VARCHAR(20),
    response_at      TIMESTAMP WITH TIME ZONE,
    distance_m       DOUBLE PRECISION,
    attempt_number   INTEGER DEFAULT 1
);

ALTER TABLE food.dispatch_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_dispatch_admin" ON food.dispatch_attempts FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_dispatch_order  ON food.dispatch_attempts(order_id);
CREATE INDEX idx_food_dispatch_driver ON food.dispatch_attempts(driver_id);


CREATE TABLE food.driver_locations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id   UUID NOT NULL REFERENCES food.drivers(id) ON DELETE CASCADE,
    order_id    UUID REFERENCES food.orders(id),
    latitude    DOUBLE PRECISION NOT NULL,
    longitude   DOUBLE PRECISION NOT NULL,
    location    GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                ) STORED,
    heading     DOUBLE PRECISION,
    speed_kmh   DOUBLE PRECISION,
    accuracy_m  DOUBLE PRECISION,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food.driver_locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "food_driver_locs_own"   ON food.driver_locations FOR INSERT
    WITH CHECK (EXISTS (SELECT 1 FROM food.drivers d WHERE d.id = driver_id AND d.user_id = auth.uid()));
CREATE POLICY "food_driver_locs_order" ON food.driver_locations FOR SELECT
    USING (EXISTS (SELECT 1 FROM food.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "food_driver_locs_admin" ON food.driver_locations FOR ALL USING (public.is_admin());

CREATE INDEX idx_food_driver_locs_driver   ON food.driver_locations(driver_id);
CREATE INDEX idx_food_driver_locs_location ON food.driver_locations USING GIST (location);
CREATE INDEX idx_food_driver_locs_time     ON food.driver_locations(recorded_at DESC);


-- ============================================================================
-- MARKET SCHEMA
-- ============================================================================

CREATE TABLE market.categories (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name       VARCHAR(100) NOT NULL UNIQUE,
    name_ar    VARCHAR(100),
    name_fr    VARCHAR(100),
    icon_url   TEXT,
    parent_id  UUID REFERENCES market.categories(id),
    sort_order INTEGER DEFAULT 0,
    is_active  BOOLEAN DEFAULT TRUE
);

ALTER TABLE market.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_cat_select" ON market.categories FOR SELECT USING (is_active = TRUE);
CREATE POLICY "market_cat_admin"  ON market.categories FOR ALL   USING (public.is_admin());


CREATE TABLE market.sellers (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id           UUID NOT NULL REFERENCES public.profiles(id),
    name               VARCHAR(255) NOT NULL,
    name_ar            VARCHAR(255),
    description        TEXT,
    description_ar     TEXT,
    phone              VARCHAR(50),
    logo_url           TEXT,
    cover_url          TEXT,
    address            TEXT,
    city               VARCHAR(100),
    latitude           DOUBLE PRECISION,
    longitude          DOUBLE PRECISION,
    location           GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                           CASE
                               WHEN latitude IS NOT NULL AND longitude IS NOT NULL
                               THEN ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                               ELSE NULL
                           END
                       ) STORED,
    delivery_radius_km DECIMAL(5,2) DEFAULT 10,
    delivery_fee       DECIMAL(10,3) DEFAULT 0,
    min_order_amount   DECIMAL(10,3) DEFAULT 0,
    commission_rate    DECIMAL(5,2) DEFAULT 12,
    rating             DECIMAL(3,2) DEFAULT 0,
    rating_count       INTEGER DEFAULT 0,
    is_open            BOOLEAN DEFAULT FALSE,
    is_active          BOOLEAN DEFAULT TRUE,
    is_verified        BOOLEAN DEFAULT FALSE,
    is_featured        BOOLEAN DEFAULT FALSE,
    featured_until     TIMESTAMP WITH TIME ZONE,                 -- [v4.1]
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE market.sellers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_sellers_select" ON market.sellers FOR SELECT USING (is_active = TRUE);
CREATE POLICY "market_sellers_own"    ON market.sellers FOR ALL   USING (owner_id = auth.uid());
CREATE POLICY "market_sellers_admin"  ON market.sellers FOR ALL   USING (public.is_admin());

CREATE INDEX idx_market_sellers_owner    ON market.sellers(owner_id);
CREATE INDEX idx_market_sellers_location ON market.sellers USING GIST (location);
CREATE INDEX idx_market_sellers_rating   ON market.sellers(rating DESC);
CREATE INDEX idx_market_sellers_featured ON market.sellers(is_featured) WHERE is_featured = TRUE;


CREATE TABLE market.products (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    seller_id           UUID NOT NULL REFERENCES market.sellers(id) ON DELETE CASCADE,
    category_id         UUID REFERENCES market.categories(id),
    name                VARCHAR(255) NOT NULL,
    name_ar             VARCHAR(255),
    name_fr             VARCHAR(255),
    description         TEXT,
    description_ar      TEXT,
    barcode             VARCHAR(100),
    sku                 VARCHAR(100),
    price               DECIMAL(10,3) NOT NULL CHECK (price >= 0),
    compare_price       DECIMAL(10,3),
    unit                VARCHAR(30) DEFAULT 'piece',
    images              TEXT[],
    stock_qty           INTEGER DEFAULT 0,
    reserved_qty        INTEGER DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 5,
    is_available        BOOLEAN DEFAULT TRUE,
    is_featured         BOOLEAN DEFAULT FALSE,
    weight_kg           DECIMAL(6,3),
    tags                TEXT[],
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE market.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_products_select" ON market.products FOR SELECT USING (is_available = TRUE);
CREATE POLICY "market_products_own"    ON market.products FOR ALL
    USING (EXISTS (SELECT 1 FROM market.sellers s WHERE s.id = seller_id AND s.owner_id = auth.uid()));
CREATE POLICY "market_products_admin"  ON market.products FOR ALL USING (public.is_admin());

CREATE INDEX idx_market_products_seller   ON market.products(seller_id);
CREATE INDEX idx_market_products_category ON market.products(category_id);
CREATE INDEX idx_market_products_name     ON market.products USING GIN (name gin_trgm_ops);
CREATE INDEX idx_market_products_stock    ON market.products(stock_qty) WHERE stock_qty <= 5;


CREATE TABLE market.stock_reservations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id  UUID NOT NULL REFERENCES market.products(id) ON DELETE CASCADE,
    order_id    UUID,
    session_id  VARCHAR(100),
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW() + INTERVAL '15 minutes',
    is_released BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE market.stock_reservations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "stock_res_admin" ON market.stock_reservations FOR ALL USING (public.is_admin());

CREATE INDEX idx_stock_res_product ON market.stock_reservations(product_id);
CREATE INDEX idx_stock_res_order   ON market.stock_reservations(order_id);
CREATE INDEX idx_stock_res_expires ON market.stock_reservations(expires_at) WHERE is_released = FALSE;


CREATE TABLE market.stock_movement_log (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id  UUID NOT NULL REFERENCES market.products(id),
    movement    INTEGER NOT NULL,
    reason      VARCHAR(50) NOT NULL,
    reference_id UUID,
    note        TEXT,
    changed_by  UUID REFERENCES public.profiles(id),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE market.stock_movement_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "stock_log_seller" ON market.stock_movement_log FOR SELECT
    USING (EXISTS (SELECT 1 FROM market.products p JOIN market.sellers s ON s.id = p.seller_id
                   WHERE p.id = product_id AND s.owner_id = auth.uid()));
CREATE POLICY "stock_log_admin"  ON market.stock_movement_log FOR ALL USING (public.is_admin());

CREATE INDEX idx_stock_log_product ON market.stock_movement_log(product_id);
CREATE INDEX idx_stock_log_created ON market.stock_movement_log(created_at DESC);


CREATE TABLE market.carts (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    seller_id     UUID REFERENCES market.sellers(id),
    promo_code_id UUID REFERENCES public.promo_codes(id),
    notes         TEXT,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE market.carts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_cart_own" ON market.carts FOR ALL USING (user_id = auth.uid());

CREATE INDEX idx_market_carts_user_id ON market.carts(user_id);


CREATE TABLE market.cart_items (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id    UUID NOT NULL REFERENCES market.carts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES market.products(id),
    quantity   INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10,3) NOT NULL,
    notes      TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE market.cart_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_cart_items_own" ON market.cart_items FOR ALL
    USING (EXISTS (SELECT 1 FROM market.carts c WHERE c.id = cart_id AND c.user_id = auth.uid()));

CREATE INDEX idx_market_cart_items_cart ON market.cart_items(cart_id);


CREATE TABLE market.orders (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number           VARCHAR(30) UNIQUE,
    user_id                UUID NOT NULL REFERENCES public.profiles(id),
    seller_id              UUID NOT NULL REFERENCES market.sellers(id),
    driver_id              UUID REFERENCES food.drivers(id),
    delivery_address_id    UUID REFERENCES public.addresses(id),
    delivery_address_text  TEXT,
    delivery_lat           DOUBLE PRECISION,
    delivery_lng           DOUBLE PRECISION,
    delivery_location      GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (  -- [v4.1]
                               CASE
                                   WHEN delivery_lat IS NOT NULL AND delivery_lng IS NOT NULL
                                   THEN ST_SetSRID(ST_MakePoint(delivery_lng, delivery_lat), 4326)::geography
                                   ELSE NULL
                               END
                           ) STORED,
    status                 VARCHAR(30) DEFAULT 'pending',
    subtotal               DECIMAL(12,3) NOT NULL DEFAULT 0,
    delivery_fee           DECIMAL(10,3) DEFAULT 0,
    service_fee            DECIMAL(10,3) DEFAULT 0,
    discount               DECIMAL(10,3) DEFAULT 0,
    tax_rate_id            UUID REFERENCES public.tax_rates(id),
    tax_amount             DECIMAL(12,3) DEFAULT 0,
    tax_rate_pct           DECIMAL(5,2) DEFAULT 0,
    total                  DECIMAL(12,3) NOT NULL DEFAULT 0,
    payment_method         VARCHAR(30) NOT NULL,
    payment_status         VARCHAR(20) DEFAULT 'pending',
    payment_reference      VARCHAR(255),
    payment_transaction_id UUID REFERENCES public.payment_transactions(id),
    promo_code_id          UUID REFERENCES public.promo_codes(id),
    notes                  TEXT,
    cancelled_at           TIMESTAMP WITH TIME ZONE,
    cancellation_reason    TEXT,
    dispatch_attempts      INTEGER DEFAULT 0,
    dispatch_radius_m      INTEGER DEFAULT 3000,
    current_eta_minutes    INTEGER,
    created_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE market.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_orders_own"    ON market.orders FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "market_orders_insert" ON market.orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "market_orders_seller" ON market.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM market.sellers s WHERE s.id = seller_id AND s.owner_id = auth.uid()));
CREATE POLICY "market_orders_admin"  ON market.orders FOR ALL USING (public.is_admin());

CREATE INDEX idx_market_orders_user_id    ON market.orders(user_id);
CREATE INDEX idx_market_orders_seller_id  ON market.orders(seller_id);
CREATE INDEX idx_market_orders_status     ON market.orders(status);
CREATE INDEX idx_market_orders_created_at ON market.orders(created_at DESC);
CREATE INDEX idx_market_orders_location   ON market.orders USING GIST (delivery_location);
CREATE INDEX idx_market_orders_user_status ON market.orders(user_id, status);


CREATE TABLE market.order_items (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id     UUID NOT NULL REFERENCES market.orders(id) ON DELETE CASCADE,
    product_id   UUID NOT NULL REFERENCES market.products(id),
    product_name VARCHAR(255) NOT NULL,
    quantity     INTEGER NOT NULL DEFAULT 1,
    unit_price   DECIMAL(10,3) NOT NULL,
    total_price  DECIMAL(10,3) NOT NULL,
    notes        TEXT
);

ALTER TABLE market.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_order_items_own"   ON market.order_items FOR SELECT
    USING (EXISTS (SELECT 1 FROM market.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "market_order_items_admin" ON market.order_items FOR ALL USING (public.is_admin());

CREATE INDEX idx_market_order_items_order ON market.order_items(order_id);


-- [v4.1] Order status log for market
CREATE TABLE market.order_status_log (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id   UUID NOT NULL REFERENCES market.orders(id) ON DELETE CASCADE,
    status     VARCHAR(30) NOT NULL,
    note       TEXT,
    changed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE market.order_status_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_status_log_own"   ON market.order_status_log FOR SELECT
    USING (EXISTS (SELECT 1 FROM market.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "market_status_log_admin" ON market.order_status_log FOR ALL USING (public.is_admin());

CREATE INDEX idx_market_order_log_order   ON market.order_status_log(order_id);
CREATE INDEX idx_market_order_log_created ON market.order_status_log(created_at DESC);


CREATE TABLE market.dispatch_attempts (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id         UUID NOT NULL REFERENCES market.orders(id) ON DELETE CASCADE,
    driver_id        UUID REFERENCES food.drivers(id),
    attempted_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    offer_expires_at TIMESTAMP WITH TIME ZONE,
    response         VARCHAR(20),
    response_at      TIMESTAMP WITH TIME ZONE,
    distance_m       DOUBLE PRECISION,
    attempt_number   INTEGER DEFAULT 1
);

ALTER TABLE market.dispatch_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_dispatch_admin" ON market.dispatch_attempts FOR ALL USING (public.is_admin());

CREATE INDEX idx_market_dispatch_order  ON market.dispatch_attempts(order_id);
CREATE INDEX idx_market_dispatch_driver ON market.dispatch_attempts(driver_id);


-- ============================================================================
-- TAXI SCHEMA
-- ============================================================================

CREATE TABLE taxi.vehicle_types (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name             VARCHAR(50) NOT NULL UNIQUE,
    name_ar          VARCHAR(50),
    description      TEXT,
    icon_url         TEXT,
    base_fare        DECIMAL(10,3) NOT NULL,
    per_km_rate      DECIMAL(10,3) NOT NULL,
    per_min_rate     DECIMAL(10,3) DEFAULT 0,
    min_fare         DECIMAL(10,3) NOT NULL,
    cancellation_fee DECIMAL(10,3) DEFAULT 2,
    capacity         INTEGER DEFAULT 4,
    sort_order       INTEGER DEFAULT 0,
    is_active        BOOLEAN DEFAULT TRUE
);

ALTER TABLE taxi.vehicle_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "taxi_vehicle_types_select" ON taxi.vehicle_types FOR SELECT USING (is_active = TRUE);
CREATE POLICY "taxi_vehicle_types_admin"  ON taxi.vehicle_types FOR ALL   USING (public.is_admin());

CREATE INDEX idx_taxi_vehicle_types_sort ON taxi.vehicle_types(sort_order);


CREATE TABLE taxi.drivers (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL UNIQUE REFERENCES public.profiles(id),
    vehicle_type_id   UUID REFERENCES taxi.vehicle_types(id),
    vehicle_make      VARCHAR(100),
    vehicle_model     VARCHAR(100),
    vehicle_year      SMALLINT,
    vehicle_plate     VARCHAR(30) UNIQUE,
    vehicle_color     VARCHAR(50),
    vehicle_photo_url TEXT,
    license_url       TEXT,
    id_card_url       TEXT,
    insurance_url     TEXT,
    insurance_expiry  DATE,
    bank_account      TEXT,
    rating            DECIMAL(3,2) DEFAULT 5,
    rating_count      INTEGER DEFAULT 0,
    total_rides       INTEGER DEFAULT 0,
    acceptance_rate   DECIMAL(5,2) DEFAULT 100,
    cancellation_rate DECIMAL(5,2) DEFAULT 0,
    is_available      BOOLEAN DEFAULT FALSE,
    is_online         BOOLEAN DEFAULT FALSE,
    is_on_ride        BOOLEAN DEFAULT FALSE,
    is_verified       BOOLEAN DEFAULT FALSE,
    is_active         BOOLEAN DEFAULT TRUE,
    current_lat       DOUBLE PRECISION,
    current_lng       DOUBLE PRECISION,
    current_location  GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                          CASE
                              WHEN current_lat IS NOT NULL AND current_lng IS NOT NULL
                              THEN ST_SetSRID(ST_MakePoint(current_lng, current_lat), 4326)::geography
                              ELSE NULL
                          END
                      ) STORED,
    heading           DOUBLE PRECISION,
    last_location_at  TIMESTAMP WITH TIME ZONE,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE taxi.drivers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "taxi_drivers_select" ON taxi.drivers FOR SELECT USING (is_active = TRUE);
CREATE POLICY "taxi_drivers_own"    ON taxi.drivers FOR ALL   USING (user_id = auth.uid());
CREATE POLICY "taxi_drivers_admin"  ON taxi.drivers FOR ALL   USING (public.is_admin());

CREATE INDEX idx_taxi_drivers_user_id   ON taxi.drivers(user_id);
CREATE INDEX idx_taxi_drivers_location  ON taxi.drivers USING GIST (current_location);
CREATE INDEX idx_taxi_drivers_available ON taxi.drivers(is_available, is_verified) WHERE is_active = TRUE;


CREATE TABLE taxi.driver_locations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id   UUID NOT NULL REFERENCES taxi.drivers(id) ON DELETE CASCADE,
    ride_id     UUID,
    latitude    DOUBLE PRECISION NOT NULL,
    longitude   DOUBLE PRECISION NOT NULL,
    location    GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                ) STORED,
    heading     DOUBLE PRECISION,
    speed_kmh   DOUBLE PRECISION,
    accuracy_m  DOUBLE PRECISION,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE taxi.driver_locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "taxi_driver_locs_own"   ON taxi.driver_locations FOR INSERT
    WITH CHECK (EXISTS (SELECT 1 FROM taxi.drivers d WHERE d.id = driver_id AND d.user_id = auth.uid()));
CREATE POLICY "taxi_driver_locs_admin" ON taxi.driver_locations FOR ALL USING (public.is_admin());

CREATE INDEX idx_taxi_driver_locs_driver ON taxi.driver_locations(driver_id);
CREATE INDEX idx_taxi_driver_locs_time   ON taxi.driver_locations(recorded_at DESC);


CREATE TABLE taxi.rides (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_number             VARCHAR(30) UNIQUE,
    passenger_id            UUID NOT NULL REFERENCES public.profiles(id),
    driver_id               UUID REFERENCES taxi.drivers(id),
    vehicle_type_id         UUID NOT NULL REFERENCES taxi.vehicle_types(id),
    pickup_address          TEXT,
    pickup_lat              DOUBLE PRECISION NOT NULL,
    pickup_lng              DOUBLE PRECISION NOT NULL,
    pickup_location         GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                                ST_SetSRID(ST_MakePoint(pickup_lng, pickup_lat), 4326)::geography
                            ) STORED,
    dropoff_address         TEXT,
    dropoff_lat             DOUBLE PRECISION NOT NULL,
    dropoff_lng             DOUBLE PRECISION NOT NULL,
    dropoff_location        GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                                ST_SetSRID(ST_MakePoint(dropoff_lng, dropoff_lat), 4326)::geography
                            ) STORED,
    status                  VARCHAR(20) DEFAULT 'searching',
    estimated_distance_km   DECIMAL(8,3),
    estimated_duration_min  INTEGER,
    actual_distance_km      DECIMAL(8,3),
    actual_duration_min     INTEGER,
    route                   JSONB,
    base_fare               DECIMAL(10,3),
    distance_fare           DECIMAL(10,3),
    time_fare               DECIMAL(10,3),
    surge_multiplier        DECIMAL(4,2) DEFAULT 1.0,
    surge_amount            DECIMAL(10,3) DEFAULT 0,
    tip                     DECIMAL(10,3) DEFAULT 0,
    promo_discount          DECIMAL(10,3) DEFAULT 0,
    tax_rate_id             UUID REFERENCES public.tax_rates(id),
    tax_amount              DECIMAL(12,3) DEFAULT 0,
    tax_rate_pct            DECIMAL(5,2) DEFAULT 0,
    total_fare              DECIMAL(12,3),
    payment_method          VARCHAR(30) DEFAULT 'cash',
    payment_status          VARCHAR(20) DEFAULT 'pending',
    payment_reference       VARCHAR(255),
    payment_transaction_id  UUID REFERENCES public.payment_transactions(id),
    promo_code_id           UUID REFERENCES public.promo_codes(id),
    cancellation_fee_charged DECIMAL(10,3) DEFAULT 0,
    current_eta_minutes     INTEGER,
    eta_updated_at          TIMESTAMP WITH TIME ZONE,
    driver_assigned_at      TIMESTAMP WITH TIME ZONE,
    driver_arrived_at       TIMESTAMP WITH TIME ZONE,
    ride_started_at         TIMESTAMP WITH TIME ZONE,
    ride_completed_at       TIMESTAMP WITH TIME ZONE,
    cancelled_at            TIMESTAMP WITH TIME ZONE,
    cancelled_by            VARCHAR(20),
    cancellation_reason     TEXT,
    dispatch_attempts       INTEGER DEFAULT 0,
    passenger_rating        SMALLINT CHECK (passenger_rating BETWEEN 1 AND 5),
    driver_rating           SMALLINT CHECK (driver_rating BETWEEN 1 AND 5),
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE taxi.rides ENABLE ROW LEVEL SECURITY;
CREATE POLICY "taxi_rides_passenger_own" ON taxi.rides FOR SELECT USING (passenger_id = auth.uid());
CREATE POLICY "taxi_rides_insert_own"    ON taxi.rides FOR INSERT WITH CHECK (passenger_id = auth.uid());
CREATE POLICY "taxi_rides_driver"        ON taxi.rides FOR SELECT
    USING (EXISTS (SELECT 1 FROM taxi.drivers d WHERE d.id = driver_id AND d.user_id = auth.uid()));
CREATE POLICY "taxi_rides_admin_all"     ON taxi.rides FOR ALL USING (public.is_admin());

CREATE INDEX idx_taxi_rides_passenger    ON taxi.rides(passenger_id);
CREATE INDEX idx_taxi_rides_driver       ON taxi.rides(driver_id);
CREATE INDEX idx_taxi_rides_status       ON taxi.rides(status);
CREATE INDEX idx_taxi_rides_created_at   ON taxi.rides(created_at DESC);
CREATE INDEX idx_taxi_rides_pickup_loc   ON taxi.rides USING GIST (pickup_location);
CREATE INDEX idx_taxi_rides_searching    ON taxi.rides(status) WHERE status = 'searching';
CREATE INDEX idx_taxi_rides_passenger_status ON taxi.rides(passenger_id, status);


CREATE TABLE taxi.dispatch_attempts (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id          UUID NOT NULL REFERENCES taxi.rides(id) ON DELETE CASCADE,
    driver_id        UUID REFERENCES taxi.drivers(id),
    attempted_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    offer_expires_at TIMESTAMP WITH TIME ZONE,
    response         VARCHAR(20),
    response_at      TIMESTAMP WITH TIME ZONE,
    distance_m       DOUBLE PRECISION,
    attempt_number   INTEGER DEFAULT 1
);

ALTER TABLE taxi.dispatch_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "taxi_dispatch_admin" ON taxi.dispatch_attempts FOR ALL USING (public.is_admin());

CREATE INDEX idx_taxi_dispatch_ride   ON taxi.dispatch_attempts(ride_id);
CREATE INDEX idx_taxi_dispatch_driver ON taxi.dispatch_attempts(driver_id);


CREATE TABLE taxi.surge_zones (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name       VARCHAR(100) NOT NULL,
    zone       GEOGRAPHY(Polygon, 4326) NOT NULL,
    multiplier DECIMAL(4,2) DEFAULT 1.5,
    reason     VARCHAR(100),
    is_active  BOOLEAN DEFAULT TRUE,
    starts_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ends_at    TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES public.profiles(id)
);

ALTER TABLE taxi.surge_zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "taxi_surge_admin"  ON taxi.surge_zones FOR ALL    USING (public.is_admin());
CREATE POLICY "taxi_surge_select" ON taxi.surge_zones FOR SELECT USING (is_active = TRUE);

CREATE INDEX idx_taxi_surge_zone ON taxi.surge_zones USING GIST (zone);


CREATE TABLE taxi.vehicle_inspections (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id       UUID NOT NULL REFERENCES taxi.drivers(id) ON DELETE CASCADE,
    inspection_type VARCHAR(30) DEFAULT 'periodic',
    inspected_by    UUID REFERENCES public.profiles(id),
    inspection_date DATE NOT NULL DEFAULT CURRENT_DATE,
    result          VARCHAR(20) DEFAULT 'pending',
    score           SMALLINT CHECK (score BETWEEN 0 AND 100),
    issues          JSONB DEFAULT '[]',
    photos          TEXT[],
    notes           TEXT,
    next_due_date   DATE,
    expires_at      DATE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE taxi.vehicle_inspections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "inspections_driver_read" ON taxi.vehicle_inspections FOR SELECT
    USING (EXISTS (SELECT 1 FROM taxi.drivers d WHERE d.id = driver_id AND d.user_id = auth.uid()));
CREATE POLICY "inspections_admin_all"   ON taxi.vehicle_inspections FOR ALL USING (public.is_admin());

CREATE INDEX idx_inspections_driver  ON taxi.vehicle_inspections(driver_id);
CREATE INDEX idx_inspections_result  ON taxi.vehicle_inspections(result);
CREATE INDEX idx_inspections_expires ON taxi.vehicle_inspections(expires_at);


-- ============================================================================
-- PHARMACY SCHEMA
-- ============================================================================

CREATE TABLE pharmacy.categories (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name       VARCHAR(100) NOT NULL UNIQUE,
    name_ar    VARCHAR(100),
    name_fr    VARCHAR(100),
    icon_url   TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active  BOOLEAN DEFAULT TRUE
);

ALTER TABLE pharmacy.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pharma_cat_select" ON pharmacy.categories FOR SELECT USING (is_active = TRUE);
CREATE POLICY "pharma_cat_admin"  ON pharmacy.categories FOR ALL   USING (public.is_admin());


CREATE TABLE pharmacy.pharmacies (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id            UUID NOT NULL REFERENCES public.profiles(id),
    name                VARCHAR(255) NOT NULL,
    name_ar             VARCHAR(255),
    description         TEXT,
    phone               VARCHAR(50),
    email               VARCHAR(100),
    logo_url            TEXT,
    cover_url           TEXT,
    address             TEXT,
    city                VARCHAR(100),
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    location            GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                            CASE
                                WHEN latitude IS NOT NULL AND longitude IS NOT NULL
                                THEN ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                                ELSE NULL
                            END
                        ) STORED,
    delivery_radius_km  DECIMAL(5,2) DEFAULT 5,
    delivery_fee        DECIMAL(10,3) DEFAULT 0,
    min_order_amount    DECIMAL(10,3) DEFAULT 0,
    commission_rate     DECIMAL(5,2) DEFAULT 10,
    rating              DECIMAL(3,2) DEFAULT 0,
    rating_count        INTEGER DEFAULT 0,
    is_open             BOOLEAN DEFAULT FALSE,
    is_active           BOOLEAN DEFAULT TRUE,
    is_verified         BOOLEAN DEFAULT FALSE,
    is_24h              BOOLEAN DEFAULT FALSE,
    is_featured         BOOLEAN DEFAULT FALSE,                    -- [v4.1]
    featured_until      TIMESTAMP WITH TIME ZONE,                -- [v4.1]
    accepts_prescription BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE pharmacy.pharmacies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pharma_select"    ON pharmacy.pharmacies FOR SELECT USING (is_active = TRUE);
CREATE POLICY "pharma_owner_all" ON pharmacy.pharmacies FOR ALL   USING (owner_id = auth.uid());
CREATE POLICY "pharma_admin_all" ON pharmacy.pharmacies FOR ALL   USING (public.is_admin());

CREATE INDEX idx_pharma_owner    ON pharmacy.pharmacies(owner_id);
CREATE INDEX idx_pharma_location ON pharmacy.pharmacies USING GIST (location);
CREATE INDEX idx_pharma_open     ON pharmacy.pharmacies(is_open) WHERE is_open = TRUE;
CREATE INDEX idx_pharma_featured ON pharmacy.pharmacies(is_featured) WHERE is_featured = TRUE;


CREATE TABLE pharmacy.operating_hours (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pharmacy_id UUID NOT NULL REFERENCES pharmacy.pharmacies(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    opens_at    TIME NOT NULL,
    closes_at   TIME NOT NULL,
    is_closed   BOOLEAN DEFAULT FALSE,
    UNIQUE(pharmacy_id, day_of_week)
);

ALTER TABLE pharmacy.operating_hours ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pharma_hours_select"    ON pharmacy.operating_hours FOR SELECT USING (TRUE);
CREATE POLICY "pharma_hours_owner_all" ON pharmacy.operating_hours FOR ALL
    USING (EXISTS (SELECT 1 FROM pharmacy.pharmacies p WHERE p.id = pharmacy_id AND p.owner_id = auth.uid()));
CREATE POLICY "pharma_hours_admin_all" ON pharmacy.operating_hours FOR ALL USING (public.is_admin());

CREATE INDEX idx_pharma_hours ON pharmacy.operating_hours(pharmacy_id);


CREATE TABLE pharmacy.medicines (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pharmacy_id          UUID NOT NULL REFERENCES pharmacy.pharmacies(id) ON DELETE CASCADE,
    category_id          UUID REFERENCES pharmacy.categories(id),
    name                 VARCHAR(255) NOT NULL,
    name_ar              VARCHAR(255),
    generic_name         VARCHAR(255),
    description          TEXT,
    dosage               VARCHAR(100),
    form                 VARCHAR(50),
    images               TEXT[],
    price                DECIMAL(10,3) NOT NULL CHECK (price >= 0),
    stock_qty            INTEGER DEFAULT 0,
    low_stock_threshold  INTEGER DEFAULT 10,
    requires_prescription BOOLEAN DEFAULT FALSE,
    is_available         BOOLEAN DEFAULT TRUE,
    is_otc               BOOLEAN DEFAULT TRUE,
    manufacturer         VARCHAR(255),
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE pharmacy.medicines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pharma_med_select" ON pharmacy.medicines FOR SELECT USING (is_available = TRUE);
CREATE POLICY "pharma_med_owner"  ON pharmacy.medicines FOR ALL
    USING (EXISTS (SELECT 1 FROM pharmacy.pharmacies p WHERE p.id = pharmacy_id AND p.owner_id = auth.uid()));
CREATE POLICY "pharma_med_admin"  ON pharmacy.medicines FOR ALL USING (public.is_admin());

CREATE INDEX idx_pharma_med_pharmacy ON pharmacy.medicines(pharmacy_id);
CREATE INDEX idx_pharma_med_category ON pharmacy.medicines(category_id);
CREATE INDEX idx_pharma_med_name     ON pharmacy.medicines USING GIN (name gin_trgm_ops);
CREATE INDEX idx_pharma_med_rx       ON pharmacy.medicines(requires_prescription);


CREATE TABLE pharmacy.prescriptions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES public.profiles(id),
    image_urls  TEXT[] NOT NULL,
    status      VARCHAR(20) DEFAULT 'pending',
    verified_by UUID REFERENCES public.profiles(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    expires_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '90 days',
    notes       TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE pharmacy.prescriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rx_own"    ON pharmacy.prescriptions FOR ALL    USING (user_id = auth.uid());
CREATE POLICY "rx_admin"  ON pharmacy.prescriptions FOR ALL    USING (public.is_admin());
CREATE POLICY "rx_pharma" ON pharmacy.prescriptions FOR SELECT USING (public.is_support());

CREATE INDEX idx_rx_user_id ON pharmacy.prescriptions(user_id);
CREATE INDEX idx_rx_status  ON pharmacy.prescriptions(status);


CREATE TABLE pharmacy.orders (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number           VARCHAR(30) UNIQUE,
    user_id                UUID NOT NULL REFERENCES public.profiles(id),
    pharmacy_id            UUID NOT NULL REFERENCES pharmacy.pharmacies(id),
    driver_id              UUID REFERENCES food.drivers(id),
    prescription_id        UUID REFERENCES pharmacy.prescriptions(id),
    delivery_address_id    UUID REFERENCES public.addresses(id),
    delivery_address_text  TEXT,
    delivery_lat           DOUBLE PRECISION,
    delivery_lng           DOUBLE PRECISION,
    status                 VARCHAR(30) DEFAULT 'pending',
    subtotal               DECIMAL(12,3) NOT NULL DEFAULT 0,
    delivery_fee           DECIMAL(10,3) DEFAULT 0,
    discount               DECIMAL(10,3) DEFAULT 0,
    tax_rate_id            UUID REFERENCES public.tax_rates(id),
    tax_amount             DECIMAL(12,3) DEFAULT 0,
    tax_rate_pct           DECIMAL(5,2) DEFAULT 0,
    total                  DECIMAL(12,3) NOT NULL DEFAULT 0,
    payment_method         VARCHAR(30) NOT NULL,
    payment_status         VARCHAR(20) DEFAULT 'pending',
    payment_reference      VARCHAR(255),
    payment_transaction_id UUID REFERENCES public.payment_transactions(id),
    promo_code_id          UUID REFERENCES public.promo_codes(id),
    notes                  TEXT,
    requires_prescription  BOOLEAN DEFAULT FALSE,
    prescription_verified  BOOLEAN DEFAULT FALSE,
    is_scheduled           BOOLEAN DEFAULT FALSE,                -- [v4.1]
    scheduled_for          TIMESTAMP WITH TIME ZONE,            -- [v4.1]
    cancelled_at           TIMESTAMP WITH TIME ZONE,
    cancellation_reason    TEXT,
    dispatch_attempts      INTEGER DEFAULT 0,
    current_eta_minutes    INTEGER,
    created_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE pharmacy.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pharma_orders_own"    ON pharmacy.orders FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "pharma_orders_insert" ON pharmacy.orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "pharma_orders_pharma" ON pharmacy.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM pharmacy.pharmacies p WHERE p.id = pharmacy_id AND p.owner_id = auth.uid()));
CREATE POLICY "pharma_orders_admin"  ON pharmacy.orders FOR ALL USING (public.is_admin());

CREATE INDEX idx_pharma_orders_user_id    ON pharmacy.orders(user_id);
CREATE INDEX idx_pharma_orders_pharmacy   ON pharmacy.orders(pharmacy_id);
CREATE INDEX idx_pharma_orders_status     ON pharmacy.orders(status);
CREATE INDEX idx_pharma_orders_created_at ON pharmacy.orders(created_at DESC);
CREATE INDEX idx_pharma_orders_scheduled  ON pharmacy.orders(scheduled_for) WHERE is_scheduled = TRUE;
CREATE INDEX idx_pharma_orders_user_status ON pharmacy.orders(user_id, status);


CREATE TABLE pharmacy.order_items (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id      UUID NOT NULL REFERENCES pharmacy.orders(id) ON DELETE CASCADE,
    medicine_id   UUID NOT NULL REFERENCES pharmacy.medicines(id),
    medicine_name VARCHAR(255) NOT NULL,
    quantity      INTEGER NOT NULL DEFAULT 1,
    unit_price    DECIMAL(10,3) NOT NULL,
    total_price   DECIMAL(10,3) NOT NULL,
    notes         TEXT
);

ALTER TABLE pharmacy.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pharma_order_items_own"   ON pharmacy.order_items FOR SELECT
    USING (EXISTS (SELECT 1 FROM pharmacy.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "pharma_order_items_admin" ON pharmacy.order_items FOR ALL USING (public.is_admin());

CREATE INDEX idx_pharma_order_items_order ON pharmacy.order_items(order_id);


-- [v4.1] Order status log for pharmacy
CREATE TABLE pharmacy.order_status_log (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id   UUID NOT NULL REFERENCES pharmacy.orders(id) ON DELETE CASCADE,
    status     VARCHAR(30) NOT NULL,
    note       TEXT,
    changed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE pharmacy.order_status_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pharma_status_log_own"   ON pharmacy.order_status_log FOR SELECT
    USING (EXISTS (SELECT 1 FROM pharmacy.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "pharma_status_log_admin" ON pharmacy.order_status_log FOR ALL USING (public.is_admin());

CREATE INDEX idx_pharma_order_log_order   ON pharmacy.order_status_log(order_id);
CREATE INDEX idx_pharma_order_log_created ON pharmacy.order_status_log(created_at DESC);


CREATE TABLE pharmacy.dispatch_attempts (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id         UUID NOT NULL REFERENCES pharmacy.orders(id) ON DELETE CASCADE,
    driver_id        UUID REFERENCES food.drivers(id),
    attempted_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    offer_expires_at TIMESTAMP WITH TIME ZONE,
    response         VARCHAR(20),
    response_at      TIMESTAMP WITH TIME ZONE,
    distance_m       DOUBLE PRECISION,
    attempt_number   INTEGER DEFAULT 1
);

ALTER TABLE pharmacy.dispatch_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pharma_dispatch_admin" ON pharmacy.dispatch_attempts FOR ALL USING (public.is_admin());

CREATE INDEX idx_pharma_dispatch_order ON pharmacy.dispatch_attempts(order_id);


-- ============================================================================
-- CLOTHES SCHEMA
-- ============================================================================

CREATE TABLE clothes.categories (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name       VARCHAR(100) NOT NULL UNIQUE,
    name_ar    VARCHAR(100),
    name_fr    VARCHAR(100),
    icon_url   TEXT,
    parent_id  UUID REFERENCES clothes.categories(id),
    sort_order INTEGER DEFAULT 0,
    is_active  BOOLEAN DEFAULT TRUE
);

ALTER TABLE clothes.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_cat_select" ON clothes.categories FOR SELECT USING (is_active = TRUE);
CREATE POLICY "clothes_cat_admin"  ON clothes.categories FOR ALL   USING (public.is_admin());


CREATE TABLE clothes.stores (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id           UUID NOT NULL REFERENCES public.profiles(id),
    name               VARCHAR(255) NOT NULL,
    name_ar            VARCHAR(255),
    description        TEXT,
    description_ar     TEXT,
    phone              VARCHAR(50),
    logo_url           TEXT,
    cover_url          TEXT,
    address            TEXT,
    city               VARCHAR(100),
    latitude           DOUBLE PRECISION,
    longitude          DOUBLE PRECISION,
    location           GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                           CASE
                               WHEN latitude IS NOT NULL AND longitude IS NOT NULL
                               THEN ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                               ELSE NULL
                           END
                       ) STORED,
    delivery_radius_km   DECIMAL(5,2) DEFAULT 15,
    delivery_fee         DECIMAL(10,3) DEFAULT 0,
    min_order_amount     DECIMAL(10,3) DEFAULT 0,
    commission_rate      DECIMAL(5,2) DEFAULT 15,
    rating               DECIMAL(3,2) DEFAULT 0,
    rating_count         INTEGER DEFAULT 0,
    is_open              BOOLEAN DEFAULT TRUE,
    is_active            BOOLEAN DEFAULT TRUE,
    is_verified          BOOLEAN DEFAULT FALSE,
    is_featured          BOOLEAN DEFAULT FALSE,
    return_policy_days   INTEGER DEFAULT 7,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE clothes.stores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_stores_select" ON clothes.stores FOR SELECT USING (is_active = TRUE);
CREATE POLICY "clothes_stores_own"    ON clothes.stores FOR ALL   USING (owner_id = auth.uid());
CREATE POLICY "clothes_stores_admin"  ON clothes.stores FOR ALL   USING (public.is_admin());

CREATE INDEX idx_clothes_stores_owner    ON clothes.stores(owner_id);
CREATE INDEX idx_clothes_stores_location ON clothes.stores USING GIST (location);
CREATE INDEX idx_clothes_stores_rating   ON clothes.stores(rating DESC);
CREATE INDEX idx_clothes_stores_featured ON clothes.stores(is_featured) WHERE is_featured = TRUE;


CREATE TABLE clothes.products (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id          UUID NOT NULL REFERENCES clothes.stores(id) ON DELETE CASCADE,
    category_id       UUID REFERENCES clothes.categories(id),
    name              VARCHAR(255) NOT NULL,
    name_ar           VARCHAR(255),
    name_fr           VARCHAR(255),
    description       TEXT,
    description_ar    TEXT,
    brand             VARCHAR(100),
    gender            VARCHAR(20) DEFAULT 'unisex',
    base_price        DECIMAL(10,3) NOT NULL CHECK (base_price >= 0),
    compare_price     DECIMAL(10,3),
    images            TEXT[],
    tags              TEXT[],
    material          VARCHAR(100),
    care_instructions TEXT,
    is_active         BOOLEAN DEFAULT TRUE,
    is_featured       BOOLEAN DEFAULT FALSE,
    sort_order        INTEGER DEFAULT 0,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE clothes.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_products_select" ON clothes.products FOR SELECT USING (is_active = TRUE);
CREATE POLICY "clothes_products_own"    ON clothes.products FOR ALL
    USING (EXISTS (SELECT 1 FROM clothes.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()));
CREATE POLICY "clothes_products_admin"  ON clothes.products FOR ALL USING (public.is_admin());

CREATE INDEX idx_clothes_products_store    ON clothes.products(store_id);
CREATE INDEX idx_clothes_products_category ON clothes.products(category_id);
CREATE INDEX idx_clothes_products_gender   ON clothes.products(gender);
CREATE INDEX idx_clothes_products_name     ON clothes.products USING GIN (name gin_trgm_ops);


CREATE TABLE clothes.product_variants (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id   UUID NOT NULL REFERENCES clothes.products(id) ON DELETE CASCADE,
    size         VARCHAR(20),
    color        VARCHAR(50),
    color_hex    CHAR(7),
    sku          VARCHAR(100) UNIQUE,
    stock_qty    INTEGER DEFAULT 0,
    reserved_qty INTEGER DEFAULT 0,
    price        DECIMAL(10,3),
    images       TEXT[],
    is_active    BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE clothes.product_variants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_variants_select" ON clothes.product_variants FOR SELECT USING (is_active = TRUE);
CREATE POLICY "clothes_variants_own"    ON clothes.product_variants FOR ALL
    USING (EXISTS (SELECT 1 FROM clothes.products p JOIN clothes.stores s ON s.id = p.store_id
                   WHERE p.id = product_id AND s.owner_id = auth.uid()));
CREATE POLICY "clothes_variants_admin"  ON clothes.product_variants FOR ALL USING (public.is_admin());

CREATE INDEX idx_clothes_variants_product ON clothes.product_variants(product_id);
CREATE INDEX idx_clothes_variants_sku     ON clothes.product_variants(sku);
CREATE INDEX idx_clothes_variants_stock   ON clothes.product_variants(stock_qty) WHERE stock_qty <= 5;


CREATE TABLE clothes.carts (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    store_id      UUID REFERENCES clothes.stores(id),
    promo_code_id UUID REFERENCES public.promo_codes(id),
    notes         TEXT,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE clothes.carts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_cart_own" ON clothes.carts FOR ALL USING (user_id = auth.uid());

CREATE INDEX idx_clothes_carts_user ON clothes.carts(user_id);


CREATE TABLE clothes.cart_items (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id    UUID NOT NULL REFERENCES clothes.carts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES clothes.products(id),
    variant_id UUID REFERENCES clothes.product_variants(id),
    quantity   INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10,3) NOT NULL,
    notes      TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE clothes.cart_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_cart_items_own" ON clothes.cart_items FOR ALL
    USING (EXISTS (SELECT 1 FROM clothes.carts c WHERE c.id = cart_id AND c.user_id = auth.uid()));

CREATE INDEX idx_clothes_cart_items_cart ON clothes.cart_items(cart_id);


CREATE TABLE clothes.orders (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number           VARCHAR(30) UNIQUE,
    user_id                UUID NOT NULL REFERENCES public.profiles(id),
    store_id               UUID NOT NULL REFERENCES clothes.stores(id),
    driver_id              UUID REFERENCES food.drivers(id),
    delivery_address_id    UUID REFERENCES public.addresses(id),
    delivery_address_text  TEXT,
    status                 VARCHAR(30) DEFAULT 'pending',
    -- pending | confirmed | processing | shipped | delivered | cancelled | return_requested | returned | refunded
    subtotal               DECIMAL(12,3) NOT NULL DEFAULT 0,
    delivery_fee           DECIMAL(10,3) DEFAULT 0,             -- [v4.1] was missing
    discount               DECIMAL(10,3) DEFAULT 0,
    tax_rate_id            UUID REFERENCES public.tax_rates(id),
    tax_amount             DECIMAL(12,3) DEFAULT 0,
    tax_rate_pct           DECIMAL(5,2) DEFAULT 0,
    total                  DECIMAL(12,3) NOT NULL DEFAULT 0,
    payment_method         VARCHAR(30) NOT NULL,
    payment_status         VARCHAR(20) DEFAULT 'pending',
    payment_reference      VARCHAR(255),
    payment_transaction_id UUID REFERENCES public.payment_transactions(id),
    promo_code_id          UUID REFERENCES public.promo_codes(id),
    notes                  TEXT,
    is_gift                BOOLEAN DEFAULT FALSE,
    gift_message           TEXT,
    return_requested_at    TIMESTAMP WITH TIME ZONE,
    return_reason          TEXT,
    cancelled_at           TIMESTAMP WITH TIME ZONE,
    cancellation_reason    TEXT,
    created_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE clothes.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_orders_own"    ON clothes.orders FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "clothes_orders_insert" ON clothes.orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "clothes_orders_store"  ON clothes.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM clothes.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()));
CREATE POLICY "clothes_orders_admin"  ON clothes.orders FOR ALL USING (public.is_admin());

CREATE INDEX idx_clothes_orders_user    ON clothes.orders(user_id);
CREATE INDEX idx_clothes_orders_store   ON clothes.orders(store_id);
CREATE INDEX idx_clothes_orders_status  ON clothes.orders(status);
CREATE INDEX idx_clothes_orders_created ON clothes.orders(created_at DESC);
CREATE INDEX idx_clothes_orders_user_status ON clothes.orders(user_id, status);


CREATE TABLE clothes.order_items (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id     UUID NOT NULL REFERENCES clothes.orders(id) ON DELETE CASCADE,
    product_id   UUID NOT NULL REFERENCES clothes.products(id),
    variant_id   UUID REFERENCES clothes.product_variants(id),
    product_name VARCHAR(255) NOT NULL,
    size         VARCHAR(20),
    color        VARCHAR(50),
    quantity     INTEGER NOT NULL DEFAULT 1,
    unit_price   DECIMAL(10,3) NOT NULL,
    total_price  DECIMAL(10,3) NOT NULL
);

ALTER TABLE clothes.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_order_items_own"   ON clothes.order_items FOR SELECT
    USING (EXISTS (SELECT 1 FROM clothes.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "clothes_order_items_admin" ON clothes.order_items FOR ALL USING (public.is_admin());

CREATE INDEX idx_clothes_order_items_order ON clothes.order_items(order_id);


-- [v4.1] Order status log for clothes
CREATE TABLE clothes.order_status_log (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id   UUID NOT NULL REFERENCES clothes.orders(id) ON DELETE CASCADE,
    status     VARCHAR(30) NOT NULL,
    note       TEXT,
    changed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE clothes.order_status_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_status_log_own"   ON clothes.order_status_log FOR SELECT
    USING (EXISTS (SELECT 1 FROM clothes.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "clothes_status_log_admin" ON clothes.order_status_log FOR ALL USING (public.is_admin());

CREATE INDEX idx_clothes_order_log_order   ON clothes.order_status_log(order_id);
CREATE INDEX idx_clothes_order_log_created ON clothes.order_status_log(created_at DESC);


CREATE TABLE clothes.stock_reservations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    variant_id  UUID NOT NULL REFERENCES clothes.product_variants(id) ON DELETE CASCADE,
    order_id    UUID,
    session_id  VARCHAR(100),
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW() + INTERVAL '15 minutes',
    is_released BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE clothes.stock_reservations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_stock_res_admin" ON clothes.stock_reservations FOR ALL USING (public.is_admin());

CREATE INDEX idx_clothes_stock_res_variant ON clothes.stock_reservations(variant_id);
CREATE INDEX idx_clothes_stock_res_expires ON clothes.stock_reservations(expires_at) WHERE is_released = FALSE;


-- [v4.1] Dispatch attempts for clothes (was missing)
CREATE TABLE clothes.dispatch_attempts (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id         UUID NOT NULL REFERENCES clothes.orders(id) ON DELETE CASCADE,
    driver_id        UUID REFERENCES food.drivers(id),
    attempted_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    offer_expires_at TIMESTAMP WITH TIME ZONE,
    response         VARCHAR(20),
    response_at      TIMESTAMP WITH TIME ZONE,
    distance_m       DOUBLE PRECISION,
    attempt_number   INTEGER DEFAULT 1
);

ALTER TABLE clothes.dispatch_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clothes_dispatch_admin" ON clothes.dispatch_attempts FOR ALL USING (public.is_admin());

CREATE INDEX idx_clothes_dispatch_order  ON clothes.dispatch_attempts(order_id);
CREATE INDEX idx_clothes_dispatch_driver ON clothes.dispatch_attempts(driver_id);


-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================


-- ── Auto-create profile + wallet + roles on signup ────────────────────────────
-- [FIX v4.1] Updated to populate profiles.email from auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_referral_code TEXT;
    v_referrer_id   UUID;
BEGIN
    LOOP
        v_referral_code := UPPER(SUBSTR(MD5(gen_random_uuid()::TEXT), 1, 8));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE referral_code = v_referral_code);
    END LOOP;

    IF NEW.raw_user_meta_data->>'referral_code' IS NOT NULL THEN
        SELECT id INTO v_referrer_id
        FROM public.profiles
        WHERE referral_code = NEW.raw_user_meta_data->>'referral_code'
          AND is_active = TRUE;
    END IF;

    INSERT INTO public.profiles (
        id, full_name, avatar_url, phone, email,
        referral_code, referred_by, preferred_lang
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'phone',
        NEW.email,
        v_referral_code,
        v_referrer_id,
        COALESCE(NEW.raw_user_meta_data->>'lang', 'ar')
    )
    ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO public.user_roles (user_id, app_context, role) VALUES
        (NEW.id, 'global',   'customer'),
        (NEW.id, 'food',     'customer'),
        (NEW.id, 'market',   'customer'),
        (NEW.id, 'taxi',     'customer'),
        (NEW.id, 'pharmacy', 'customer'),
        (NEW.id, 'clothes',  'customer')
    ON CONFLICT (user_id, app_context, role) DO NOTHING;

    INSERT INTO public.wallets (user_id) VALUES (NEW.id) ON CONFLICT (user_id) DO NOTHING;
    INSERT INTO public.loyalty_points (user_id) VALUES (NEW.id) ON CONFLICT (user_id) DO NOTHING;

    IF v_referrer_id IS NOT NULL THEN
        INSERT INTO public.referrals (referrer_id, referee_id, referral_code)
        VALUES (v_referrer_id, NEW.id, NEW.raw_user_meta_data->>'referral_code')
        ON CONFLICT (referee_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ── updated_at auto-maintenance ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DO $body$
DECLARE t RECORD;
BEGIN
    FOR t IN
        SELECT schemaname, tablename
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND schemaname IN ('public', 'food', 'market', 'taxi', 'pharmacy', 'clothes')
        GROUP BY schemaname, tablename
    LOOP
        EXECUTE FORMAT(
            'DROP TRIGGER IF EXISTS set_updated_at ON %I.%I;
             CREATE TRIGGER set_updated_at
                 BEFORE UPDATE ON %I.%I
                 FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();',
            t.schemaname, t.tablename,
            t.schemaname, t.tablename
        );
    END LOOP;
END $body$;


-- ── Order number generators ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION food.generate_order_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.order_number := 'FD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-'
                        || LPAD(nextval('food_order_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER food_order_number_trigger
    BEFORE INSERT ON food.orders
    FOR EACH ROW WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
    EXECUTE FUNCTION food.generate_order_number();

CREATE OR REPLACE FUNCTION market.generate_order_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.order_number := 'MK-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-'
                        || LPAD(nextval('market_order_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER market_order_number_trigger
    BEFORE INSERT ON market.orders
    FOR EACH ROW WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
    EXECUTE FUNCTION market.generate_order_number();

CREATE OR REPLACE FUNCTION taxi.generate_ride_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.ride_number := 'TX-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-'
                       || LPAD(nextval('taxi_ride_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER taxi_ride_number_trigger
    BEFORE INSERT ON taxi.rides
    FOR EACH ROW WHEN (NEW.ride_number IS NULL OR NEW.ride_number = '')
    EXECUTE FUNCTION taxi.generate_ride_number();

CREATE OR REPLACE FUNCTION pharmacy.generate_order_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.order_number := 'PH-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-'
                        || LPAD(nextval('pharma_order_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER pharmacy_order_number_trigger
    BEFORE INSERT ON pharmacy.orders
    FOR EACH ROW WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
    EXECUTE FUNCTION pharmacy.generate_order_number();

CREATE OR REPLACE FUNCTION clothes.generate_order_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.order_number := 'CL-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-'
                        || LPAD(nextval('clothes_order_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER clothes_order_number_trigger
    BEFORE INSERT ON clothes.orders
    FOR EACH ROW WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
    EXECUTE FUNCTION clothes.generate_order_number();


-- ── Order status log triggers (all 4 schemas) ─────────────────────────────────
CREATE OR REPLACE FUNCTION food.log_order_status_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO food.order_status_log (order_id, status, note, changed_by)
        VALUES (NEW.id, NEW.status, 'Status changed: ' || OLD.status || ' → ' || NEW.status, auth.uid());
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER food_order_status_log_trigger
    AFTER UPDATE OF status ON food.orders
    FOR EACH ROW EXECUTE FUNCTION food.log_order_status_change();

CREATE OR REPLACE FUNCTION market.log_order_status_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO market.order_status_log (order_id, status, note, changed_by)
        VALUES (NEW.id, NEW.status, 'Status changed: ' || OLD.status || ' → ' || NEW.status, auth.uid());
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER market_order_status_log_trigger
    AFTER UPDATE OF status ON market.orders
    FOR EACH ROW EXECUTE FUNCTION market.log_order_status_change();

CREATE OR REPLACE FUNCTION pharmacy.log_order_status_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO pharmacy.order_status_log (order_id, status, note, changed_by)
        VALUES (NEW.id, NEW.status, 'Status changed: ' || OLD.status || ' → ' || NEW.status, auth.uid());
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER pharmacy_order_status_log_trigger
    AFTER UPDATE OF status ON pharmacy.orders
    FOR EACH ROW EXECUTE FUNCTION pharmacy.log_order_status_change();

CREATE OR REPLACE FUNCTION clothes.log_order_status_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO clothes.order_status_log (order_id, status, note, changed_by)
        VALUES (NEW.id, NEW.status, 'Status changed: ' || OLD.status || ' → ' || NEW.status, auth.uid());
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER clothes_order_status_log_trigger
    AFTER UPDATE OF status ON clothes.orders
    FOR EACH ROW EXECUTE FUNCTION clothes.log_order_status_change();


-- ── Atomic wallet transaction ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.wallet_transact(
    p_user_id     UUID,
    p_amount      DECIMAL,
    p_type        VARCHAR,
    p_ref_type    VARCHAR DEFAULT NULL,
    p_ref_id      UUID    DEFAULT NULL,
    p_description TEXT    DEFAULT NULL
)
RETURNS DECIMAL
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_balance     DECIMAL;
    v_new_balance DECIMAL;
BEGIN
    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE user_id = p_user_id AND is_frozen = FALSE
    FOR UPDATE;

    IF NOT FOUND THEN
        IF EXISTS (SELECT 1 FROM public.wallets WHERE user_id = p_user_id AND is_frozen = TRUE) THEN
            RAISE EXCEPTION 'Wallet is frozen for user %', p_user_id;
        END IF;
        RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
    END IF;

    v_new_balance := v_balance + p_amount;

    IF v_new_balance < 0 THEN
        RAISE EXCEPTION 'Insufficient balance. Has: %, needs: %', v_balance, ABS(p_amount);
    END IF;

    UPDATE public.wallets SET balance = v_new_balance, updated_at = NOW()
    WHERE user_id = p_user_id;

    INSERT INTO public.wallet_transactions (
        user_id, type, amount, balance_after, reference_type, reference_id, description
    ) VALUES (
        p_user_id, p_type, p_amount, v_new_balance, p_ref_type, p_ref_id, p_description
    );

    RETURN v_new_balance;
END;
$$;


-- ── Validate and apply promo code (race-condition safe) ───────────────────────
-- [FIX v4.1] Added FOR UPDATE to prevent concurrent usage exceeding max_total_uses
CREATE OR REPLACE FUNCTION public.apply_promo_code(
    p_user_id      UUID,
    p_code         VARCHAR,
    p_app_context  VARCHAR,
    p_order_amount DECIMAL,
    p_ref_type     VARCHAR DEFAULT NULL,
    p_ref_id       UUID    DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_promo      public.promo_codes%ROWTYPE;
    v_uses_count INTEGER;
    v_discount   DECIMAL;
BEGIN
    SELECT * INTO v_promo
    FROM public.promo_codes
    WHERE code = UPPER(p_code)
      AND is_active = TRUE
      AND (valid_from IS NULL OR valid_from <= NOW())
      AND (valid_until IS NULL OR valid_until >= NOW())
      AND (app_context = 'global' OR app_context = p_app_context)
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Invalid or expired promo code');
    END IF;

    IF v_promo.max_total_uses IS NOT NULL AND v_promo.current_uses >= v_promo.max_total_uses THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Promo code usage limit reached');
    END IF;

    SELECT COUNT(*) INTO v_uses_count
    FROM public.promo_code_uses
    WHERE promo_code_id = v_promo.id AND user_id = p_user_id;

    IF v_promo.max_uses_per_user IS NOT NULL AND v_uses_count >= v_promo.max_uses_per_user THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'You have already used this promo code');
    END IF;

    IF v_promo.min_order_amount IS NOT NULL AND p_order_amount < v_promo.min_order_amount THEN
        RETURN jsonb_build_object('success', FALSE,
            'error', FORMAT('Minimum order amount is %s TND', v_promo.min_order_amount));
    END IF;

    IF v_promo.discount_type = 'percentage' THEN
        v_discount := p_order_amount * v_promo.discount_value / 100;
        IF v_promo.max_discount IS NOT NULL THEN
            v_discount := LEAST(v_discount, v_promo.max_discount);
        END IF;
    ELSIF v_promo.discount_type = 'fixed' THEN
        v_discount := LEAST(v_promo.discount_value, p_order_amount);
    ELSIF v_promo.discount_type = 'free_delivery' THEN
        v_discount := 0;
    END IF;

    INSERT INTO public.promo_code_uses (
        promo_code_id, user_id, reference_type, reference_id, discount_amount
    ) VALUES (v_promo.id, p_user_id, p_ref_type, p_ref_id, v_discount);

    UPDATE public.promo_codes SET current_uses = current_uses + 1 WHERE id = v_promo.id;

    RETURN jsonb_build_object(
        'success',       TRUE,
        'discount',      v_discount,
        'discount_type', v_promo.discount_type,
        'promo_id',      v_promo.id
    );
END;
$$;


-- ── Award loyalty points ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.award_loyalty_points(
    p_user_id     UUID,
    p_order_total DECIMAL,
    p_ref_type    VARCHAR,
    p_ref_id      UUID
)
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_points       INTEGER;
    v_new_lifetime INTEGER;
BEGIN
    v_points := GREATEST(1, FLOOR(p_order_total)::INTEGER);

    INSERT INTO public.loyalty_points (user_id, total_points, lifetime_points)
    VALUES (p_user_id, v_points, v_points)
    ON CONFLICT (user_id) DO UPDATE
    SET total_points    = public.loyalty_points.total_points + v_points,
        lifetime_points = public.loyalty_points.lifetime_points + v_points,
        updated_at      = NOW()
    RETURNING lifetime_points INTO v_new_lifetime;

    UPDATE public.loyalty_points
    SET tier = CASE
        WHEN v_new_lifetime >= 10000 THEN 'platinum'
        WHEN v_new_lifetime >= 5000  THEN 'gold'
        WHEN v_new_lifetime >= 1000  THEN 'silver'
        ELSE 'bronze'
    END
    WHERE user_id = p_user_id;

    RETURN v_points;
END;
$$;


-- ── Record commission on order delivery ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.record_commission(
    p_app_context    VARCHAR,
    p_reference_id   UUID,
    p_reference_type VARCHAR,
    p_vendor_id      UUID,
    p_order_total    DECIMAL,
    p_delivery_fee   DECIMAL,
    p_commission_rate DECIMAL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_commission_amt DECIMAL;
    v_vendor_payout  DECIMAL;
    v_id             UUID;
BEGIN
    v_commission_amt := ROUND(p_order_total * p_commission_rate / 100, 3);
    v_vendor_payout  := ROUND(p_order_total - v_commission_amt + p_delivery_fee, 3);

    INSERT INTO public.commissions (
        app_context, reference_id, reference_type,
        vendor_id, order_total, delivery_fee,
        commission_rate, commission_amt, vendor_payout
    ) VALUES (
        p_app_context, p_reference_id, p_reference_type,
        p_vendor_id, p_order_total, p_delivery_fee,
        p_commission_rate, v_commission_amt, v_vendor_payout
    ) RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;


-- ── Loyalty + Commission triggers on order delivery ───────────────────────────
CREATE OR REPLACE FUNCTION food.on_order_delivered()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_restaurant food.restaurants%ROWTYPE;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status IS DISTINCT FROM 'delivered' THEN
        PERFORM public.award_loyalty_points(NEW.user_id, NEW.total, 'food_order', NEW.id);
        SELECT * INTO v_restaurant FROM food.restaurants WHERE id = NEW.restaurant_id;
        PERFORM public.record_commission('food', NEW.id, 'food_order',
            v_restaurant.owner_id, NEW.subtotal, NEW.delivery_fee, v_restaurant.commission_rate);
        IF NEW.actual_delivery_at IS NOT NULL AND NEW.created_at IS NOT NULL THEN
            UPDATE food.restaurants
            SET estimated_delivery_min = (
                SELECT ROUND(AVG(EXTRACT(EPOCH FROM (actual_delivery_at - created_at))/60))
                FROM food.orders
                WHERE restaurant_id = NEW.restaurant_id
                  AND status = 'delivered'
                  AND actual_delivery_at > NOW() - INTERVAL '30 days'
            )
            WHERE id = NEW.restaurant_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER food_award_loyalty_trigger
    AFTER UPDATE OF status ON food.orders
    FOR EACH ROW EXECUTE FUNCTION food.on_order_delivered();

CREATE OR REPLACE FUNCTION market.on_order_delivered()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_seller market.sellers%ROWTYPE;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status IS DISTINCT FROM 'delivered' THEN
        PERFORM public.award_loyalty_points(NEW.user_id, NEW.total, 'market_order', NEW.id);
        SELECT * INTO v_seller FROM market.sellers WHERE id = NEW.seller_id;
        PERFORM public.record_commission('market', NEW.id, 'market_order',
            v_seller.owner_id, NEW.subtotal, NEW.delivery_fee, v_seller.commission_rate);
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER market_award_loyalty_trigger
    AFTER UPDATE OF status ON market.orders
    FOR EACH ROW EXECUTE FUNCTION market.on_order_delivered();

CREATE OR REPLACE FUNCTION pharmacy.on_order_delivered()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_pharmacy pharmacy.pharmacies%ROWTYPE;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status IS DISTINCT FROM 'delivered' THEN
        PERFORM public.award_loyalty_points(NEW.user_id, NEW.total, 'pharma_order', NEW.id);
        SELECT * INTO v_pharmacy FROM pharmacy.pharmacies WHERE id = NEW.pharmacy_id;
        PERFORM public.record_commission('pharmacy', NEW.id, 'pharmacy_order',
            v_pharmacy.owner_id, NEW.subtotal, NEW.delivery_fee, v_pharmacy.commission_rate);
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER pharmacy_award_loyalty_trigger
    AFTER UPDATE OF status ON pharmacy.orders
    FOR EACH ROW EXECUTE FUNCTION pharmacy.on_order_delivered();

CREATE OR REPLACE FUNCTION clothes.on_order_delivered()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_store clothes.stores%ROWTYPE;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status IS DISTINCT FROM 'delivered' THEN
        PERFORM public.award_loyalty_points(NEW.user_id, NEW.total, 'clothes_order', NEW.id);
        SELECT * INTO v_store FROM clothes.stores WHERE id = NEW.store_id;
        PERFORM public.record_commission('clothes', NEW.id, 'clothes_order',
            v_store.owner_id, NEW.subtotal, NEW.delivery_fee, v_store.commission_rate);
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER clothes_award_loyalty_trigger
    AFTER UPDATE OF status ON clothes.orders
    FOR EACH ROW EXECUTE FUNCTION clothes.on_order_delivered();


-- ── Audit trigger ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.audit_record_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    INSERT INTO public.audit_log (
        user_id, action, schema_name, table_name,
        record_id, old_data, new_data
    ) VALUES (
        auth.uid(), TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME,
        CASE WHEN TG_OP = 'DELETE' THEN (OLD.id)::UUID ELSE (NEW.id)::UUID END,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
    );
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE TRIGGER audit_wallets
    AFTER INSERT OR UPDATE OR DELETE ON public.wallets
    FOR EACH ROW EXECUTE FUNCTION public.audit_record_change();
CREATE OR REPLACE TRIGGER audit_wallet_transactions
    AFTER INSERT OR UPDATE OR DELETE ON public.wallet_transactions
    FOR EACH ROW EXECUTE FUNCTION public.audit_record_change();
CREATE OR REPLACE TRIGGER audit_payment_transactions
    AFTER INSERT OR UPDATE OR DELETE ON public.payment_transactions
    FOR EACH ROW EXECUTE FUNCTION public.audit_record_change();
CREATE OR REPLACE TRIGGER audit_user_roles
    AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
    FOR EACH ROW EXECUTE FUNCTION public.audit_record_change();
CREATE OR REPLACE TRIGGER audit_profiles_ban
    AFTER UPDATE OF is_banned, risk_score ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.audit_record_change();


-- ── Risk score updater ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_risk_score()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_score INTEGER;
BEGIN
    SELECT COUNT(*) * 10 INTO v_score
    FROM public.fraud_flags
    WHERE user_id = NEW.user_id AND is_resolved = FALSE AND severity IN ('high', 'critical');

    UPDATE public.profiles SET risk_score = LEAST(100, v_score) WHERE id = NEW.user_id;

    IF v_score >= 100 THEN
        UPDATE public.profiles
        SET is_banned = TRUE, ban_reason = 'Automatic ban: critical fraud score', banned_at = NOW()
        WHERE id = NEW.user_id AND is_banned = FALSE;
    END IF;

    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER fraud_flag_risk_update
    AFTER INSERT OR UPDATE ON public.fraud_flags
    FOR EACH ROW EXECUTE FUNCTION public.update_risk_score();


-- ── Rating aggregation trigger ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.refresh_target_rating()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_avg   DECIMAL(3,2);
    v_count INTEGER;
BEGIN
    SELECT ROUND(AVG(rating)::DECIMAL, 2), COUNT(*)
    INTO v_avg, v_count
    FROM public.reviews
    WHERE target_type = NEW.target_type AND target_id = NEW.target_id
      AND is_visible = TRUE AND is_verified = TRUE;

    CASE NEW.target_type
        WHEN 'restaurant'   THEN UPDATE food.restaurants  SET rating = COALESCE(v_avg,0), rating_count = v_count WHERE id = NEW.target_id;
        WHEN 'food_driver'  THEN UPDATE food.drivers      SET rating = COALESCE(v_avg,5), rating_count = v_count WHERE id = NEW.target_id;
        WHEN 'seller'       THEN UPDATE market.sellers    SET rating = COALESCE(v_avg,0), rating_count = v_count WHERE id = NEW.target_id;
        WHEN 'taxi_driver'  THEN UPDATE taxi.drivers      SET rating = COALESCE(v_avg,5), rating_count = v_count WHERE id = NEW.target_id;
        WHEN 'pharmacy'     THEN UPDATE pharmacy.pharmacies SET rating = COALESCE(v_avg,0), rating_count = v_count WHERE id = NEW.target_id;
        WHEN 'clothes_store' THEN UPDATE clothes.stores   SET rating = COALESCE(v_avg,0), rating_count = v_count WHERE id = NEW.target_id;
        ELSE NULL;
    END CASE;

    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER reviews_refresh_rating
    AFTER INSERT OR UPDATE OF rating, is_visible, is_verified ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION public.refresh_target_rating();


-- ── Auto-verify review from completed order ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.auto_verify_review()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_verified BOOLEAN := FALSE;
BEGIN
    IF NEW.reference_id IS NOT NULL THEN
        CASE NEW.app_context
            WHEN 'food'     THEN SELECT TRUE INTO v_verified FROM food.orders     WHERE id = NEW.reference_id AND user_id = NEW.user_id AND status = 'delivered';
            WHEN 'market'   THEN SELECT TRUE INTO v_verified FROM market.orders   WHERE id = NEW.reference_id AND user_id = NEW.user_id AND status = 'delivered';
            WHEN 'taxi'     THEN SELECT TRUE INTO v_verified FROM taxi.rides      WHERE id = NEW.reference_id AND passenger_id = NEW.user_id AND status = 'completed';
            WHEN 'pharmacy' THEN SELECT TRUE INTO v_verified FROM pharmacy.orders WHERE id = NEW.reference_id AND user_id = NEW.user_id AND status = 'delivered';
            WHEN 'clothes'  THEN SELECT TRUE INTO v_verified FROM clothes.orders  WHERE id = NEW.reference_id AND user_id = NEW.user_id AND status = 'delivered';
            ELSE NULL;
        END CASE;
    END IF;
    NEW.is_verified := COALESCE(v_verified, FALSE);
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER reviews_auto_verify
    BEFORE INSERT ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION public.auto_verify_review();


-- ── Wishlist target validation trigger ───────────────────────────────────────
-- [ADD v4.1] Prevents orphaned wishlist entries
CREATE OR REPLACE FUNCTION public.validate_wishlist_target()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_exists BOOLEAN := FALSE;
BEGIN
    CASE NEW.target_type
        WHEN 'menu_item'       THEN SELECT EXISTS(SELECT 1 FROM food.menu_items    WHERE id = NEW.target_id) INTO v_exists;
        WHEN 'restaurant'      THEN SELECT EXISTS(SELECT 1 FROM food.restaurants   WHERE id = NEW.target_id) INTO v_exists;
        WHEN 'product'         THEN SELECT EXISTS(SELECT 1 FROM market.products    WHERE id = NEW.target_id) INTO v_exists;
        WHEN 'medicine'        THEN SELECT EXISTS(SELECT 1 FROM pharmacy.medicines WHERE id = NEW.target_id) INTO v_exists;
        WHEN 'clothes_product' THEN SELECT EXISTS(SELECT 1 FROM clothes.products   WHERE id = NEW.target_id) INTO v_exists;
        WHEN 'store'           THEN SELECT EXISTS(SELECT 1 FROM clothes.stores     WHERE id = NEW.target_id) INTO v_exists;
        ELSE v_exists := TRUE;
    END CASE;
    IF NOT v_exists THEN
        RAISE EXCEPTION 'Wishlist target_type=% target_id=% does not exist', NEW.target_type, NEW.target_id;
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER wishlists_validate_target
    BEFORE INSERT ON public.wishlists
    FOR EACH ROW EXECUTE FUNCTION public.validate_wishlist_target();


-- ── Nearby restaurants ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION food.nearby_restaurants(
    p_lat      DOUBLE PRECISION,
    p_lng      DOUBLE PRECISION,
    p_radius_m INTEGER DEFAULT 5000,
    p_limit    INTEGER DEFAULT 20
)
RETURNS TABLE (
    id                UUID, name VARCHAR, image_url TEXT, rating DECIMAL,
    delivery_time_min INTEGER, delivery_fee DECIMAL,
    min_order_amount  DECIMAL, is_open BOOLEAN, distance_m DOUBLE PRECISION
)
LANGUAGE sql STABLE AS $$
    SELECT r.id, r.name, r.logo_url, r.rating,
        r.estimated_delivery_min, r.delivery_fee, r.min_order_amount, r.is_open,
        ST_Distance(r.location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography) AS distance_m
    FROM food.restaurants r
    WHERE r.is_active = TRUE AND r.is_verified = TRUE
      AND ST_DWithin(r.location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography, p_radius_m)
    ORDER BY r.is_open DESC, r.is_featured DESC, distance_m ASC
    LIMIT p_limit;
$$;


-- ── Nearby taxi drivers ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION taxi.nearby_drivers(
    p_lat          DOUBLE PRECISION,
    p_lng          DOUBLE PRECISION,
    p_vehicle_type UUID    DEFAULT NULL,
    p_radius_m     INTEGER DEFAULT 3000
)
RETURNS TABLE (
    driver_id UUID, user_id UUID, vehicle_type_id UUID,
    vehicle_plate VARCHAR, vehicle_color VARCHAR,
    rating DECIMAL, distance_m DOUBLE PRECISION, heading DOUBLE PRECISION
)
LANGUAGE sql STABLE AS $$
    SELECT d.id, d.user_id, d.vehicle_type_id, d.vehicle_plate, d.vehicle_color,
        d.rating,
        ST_Distance(d.current_location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography) AS distance_m,
        d.heading
    FROM taxi.drivers d
    WHERE d.is_available = TRUE AND d.is_verified = TRUE AND d.is_active = TRUE AND NOT d.is_on_ride
      AND (p_vehicle_type IS NULL OR d.vehicle_type_id = p_vehicle_type)
      AND ST_DWithin(d.current_location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography, p_radius_m)
    ORDER BY distance_m ASC
    LIMIT 10;
$$;


-- ── Nearby delivery drivers ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION food.nearby_delivery_drivers(
    p_lat      DOUBLE PRECISION,
    p_lng      DOUBLE PRECISION,
    p_radius_m INTEGER DEFAULT 3000
)
RETURNS TABLE (driver_id UUID, user_id UUID, rating DECIMAL, distance_m DOUBLE PRECISION)
LANGUAGE sql STABLE AS $$
    SELECT d.id, d.user_id, d.rating,
        ST_Distance(d.current_location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography) AS distance_m
    FROM food.drivers d
    WHERE d.is_available = TRUE AND d.is_verified = TRUE AND d.is_active = TRUE AND d.is_online = TRUE
      AND ST_DWithin(d.current_location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography, p_radius_m)
    ORDER BY distance_m ASC
    LIMIT 10;
$$;


-- ── Calculate taxi fare ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION taxi.calculate_fare(
    p_vehicle_type_id UUID,
    p_distance_km     DECIMAL,
    p_duration_min    INTEGER,
    p_surge_mult      DECIMAL DEFAULT 1.0
)
RETURNS JSONB
LANGUAGE plpgsql STABLE AS $$
DECLARE
    v_vt       taxi.vehicle_types%ROWTYPE;
    v_base     DECIMAL; v_dist_fare DECIMAL; v_time_fare DECIMAL;
    v_subtotal DECIMAL; v_surge_amt DECIMAL; v_total     DECIMAL;
BEGIN
    SELECT * INTO v_vt FROM taxi.vehicle_types WHERE id = p_vehicle_type_id;
    v_base      := v_vt.base_fare;
    v_dist_fare := ROUND(p_distance_km * v_vt.per_km_rate, 3);
    v_time_fare := ROUND(p_duration_min * v_vt.per_min_rate, 3);
    v_subtotal  := v_base + v_dist_fare + v_time_fare;
    v_surge_amt := ROUND(v_subtotal * (p_surge_mult - 1), 3);
    v_total     := GREATEST(v_vt.min_fare, ROUND(v_subtotal + v_surge_amt, 3));
    RETURN jsonb_build_object(
        'base_fare', v_base, 'distance_fare', v_dist_fare, 'time_fare', v_time_fare,
        'surge_multiplier', p_surge_mult, 'surge_amount', v_surge_amt,
        'total_fare', v_total, 'currency', 'TND'
    );
END;
$$;


-- ── Compute tax ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.compute_tax(p_amount DECIMAL, p_app_context VARCHAR)
RETURNS JSONB
LANGUAGE plpgsql STABLE AS $$
DECLARE v_rate public.tax_rates%ROWTYPE; v_tax DECIMAL;
BEGIN
    SELECT * INTO v_rate FROM public.tax_rates
    WHERE is_active = TRUE AND is_default = FALSE
      AND (p_app_context = ANY(applies_to) OR 'all' = ANY(applies_to))
      AND valid_from <= CURRENT_DATE AND (valid_until IS NULL OR valid_until >= CURRENT_DATE)
    ORDER BY rate_percent DESC LIMIT 1;

    IF NOT FOUND THEN
        SELECT * INTO v_rate FROM public.tax_rates WHERE is_default = TRUE AND is_active = TRUE LIMIT 1;
    END IF;

    v_tax := ROUND(p_amount * v_rate.rate_percent / 100, 3);
    RETURN jsonb_build_object('tax_rate_id', v_rate.id, 'rate_percent', v_rate.rate_percent,
        'tax_amount', v_tax, 'total_with_tax', p_amount + v_tax);
END;
$$;


-- ── Zone helper ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_zone_for_point(
    p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_app_context VARCHAR DEFAULT 'global'
)
RETURNS UUID
LANGUAGE sql STABLE AS $$
    SELECT id FROM public.delivery_zones
    WHERE is_active = TRUE
      AND (app_context = 'global' OR app_context = p_app_context)
      AND ST_Within(ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geometry, boundary::geometry)
    LIMIT 1;
$$;


-- ── Feature flag evaluation ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_flag_enabled(p_flag_key VARCHAR, p_user_id UUID DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE v_flag public.feature_flags%ROWTYPE; v_hash INTEGER;
BEGIN
    SELECT * INTO v_flag FROM public.feature_flags WHERE key = p_flag_key;
    IF NOT FOUND OR NOT v_flag.is_enabled THEN RETURN FALSE; END IF;
    IF v_flag.rollout_percent = 100 THEN RETURN TRUE; END IF;
    IF v_flag.rollout_percent = 0 OR p_user_id IS NULL THEN RETURN FALSE; END IF;
    v_hash := ABS(('x' || SUBSTR(MD5(p_flag_key || p_user_id::TEXT), 1, 8))::BIT(32)::INTEGER) % 100;
    RETURN v_hash < v_flag.rollout_percent;
END;
$$;


-- ── Auto open/close restaurants based on operating hours ──────────────────────
CREATE OR REPLACE FUNCTION food.sync_restaurant_open_status()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_current_time TIME := (NOW() AT TIME ZONE 'Africa/Tunis')::TIME;
    v_current_day  SMALLINT := EXTRACT(DOW FROM NOW() AT TIME ZONE 'Africa/Tunis');
BEGIN
    UPDATE food.restaurants r SET is_open = FALSE
    WHERE is_active = TRUE AND is_open = TRUE
      AND NOT EXISTS (SELECT 1 FROM food.operating_hours oh WHERE oh.restaurant_id = r.id
            AND oh.day_of_week = v_current_day AND oh.is_closed = FALSE
            AND v_current_time BETWEEN oh.opens_at AND oh.closes_at)
      AND EXISTS (SELECT 1 FROM food.operating_hours WHERE restaurant_id = r.id);

    UPDATE food.restaurants r SET is_open = TRUE
    WHERE is_active = TRUE AND is_open = FALSE
      AND EXISTS (SELECT 1 FROM food.operating_hours oh WHERE oh.restaurant_id = r.id
            AND oh.day_of_week = v_current_day AND oh.is_closed = FALSE
            AND v_current_time BETWEEN oh.opens_at AND oh.closes_at);
END;
$$;


-- ── Auto open/close pharmacies ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION pharmacy.sync_pharmacy_open_status()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_current_time TIME := (NOW() AT TIME ZONE 'Africa/Tunis')::TIME;
    v_current_day  SMALLINT := EXTRACT(DOW FROM NOW() AT TIME ZONE 'Africa/Tunis');
BEGIN
    UPDATE pharmacy.pharmacies p SET is_open = FALSE
    WHERE is_active = TRUE AND is_open = TRUE AND is_24h = FALSE
      AND NOT EXISTS (SELECT 1 FROM pharmacy.operating_hours oh WHERE oh.pharmacy_id = p.id
            AND oh.day_of_week = v_current_day AND oh.is_closed = FALSE
            AND v_current_time BETWEEN oh.opens_at AND oh.closes_at)
      AND EXISTS (SELECT 1 FROM pharmacy.operating_hours WHERE pharmacy_id = p.id);

    UPDATE pharmacy.pharmacies p SET is_open = TRUE
    WHERE is_active = TRUE AND is_open = FALSE AND is_24h = FALSE
      AND EXISTS (SELECT 1 FROM pharmacy.operating_hours oh WHERE oh.pharmacy_id = p.id
            AND oh.day_of_week = v_current_day AND oh.is_closed = FALSE
            AND v_current_time BETWEEN oh.opens_at AND oh.closes_at);
END;
$$;


-- ── Release expired stock reservations ────────────────────────────────────────
CREATE OR REPLACE FUNCTION market.release_expired_reservations()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_count INTEGER;
BEGIN
    WITH expired AS (
        UPDATE market.stock_reservations SET is_released = TRUE
        WHERE is_released = FALSE AND expires_at < NOW()
        RETURNING product_id, quantity
    )
    UPDATE market.products p
    SET reserved_qty = GREATEST(0, reserved_qty - e.qty)
    FROM (SELECT product_id, SUM(quantity) as qty FROM expired GROUP BY product_id) e
    WHERE p.id = e.product_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION clothes.release_expired_reservations()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_count INTEGER;
BEGIN
    WITH expired AS (
        UPDATE clothes.stock_reservations SET is_released = TRUE
        WHERE is_released = FALSE AND expires_at < NOW()
        RETURNING variant_id, quantity
    )
    UPDATE clothes.product_variants v
    SET reserved_qty = GREATEST(0, reserved_qty - e.qty)
    FROM (SELECT variant_id, SUM(quantity) as qty FROM expired GROUP BY variant_id) e
    WHERE v.id = e.variant_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


-- ── Activate scheduled food orders ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION food.activate_scheduled_orders()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_count INTEGER;
BEGIN
    UPDATE food.orders SET status = 'pending_dispatch', updated_at = NOW()
    WHERE is_scheduled = TRUE AND status = 'scheduled'
      AND scheduled_for <= NOW() + INTERVAL '15 minutes';
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


-- ── [v4.1] Activate scheduled pharmacy orders ─────────────────────────────────
CREATE OR REPLACE FUNCTION pharmacy.activate_scheduled_orders()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_count INTEGER;
BEGIN
    UPDATE pharmacy.orders SET status = 'pending_dispatch', updated_at = NOW()
    WHERE is_scheduled = TRUE AND status = 'scheduled'
      AND scheduled_for <= NOW() + INTERVAL '15 minutes';
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


-- ── Daily stats snapshot ──────────────────────────────────────────────────────
-- [FIX v4.1] cancelled_orders now synced for all 5 apps on conflict
CREATE OR REPLACE FUNCTION public.compute_daily_stats(p_date DATE DEFAULT CURRENT_DATE - 1)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    INSERT INTO public.daily_stats (stat_date, app_context, orders_count, completed_orders,
        cancelled_orders, gmv, commission_rev, delivery_fees, avg_order_value)
    SELECT p_date, 'food', COUNT(*),
        COUNT(*) FILTER (WHERE status = 'delivered'),
        COUNT(*) FILTER (WHERE status = 'cancelled'),
        COALESCE(SUM(total) FILTER (WHERE status = 'delivered'), 0),
        COALESCE(SUM(c.commission_amt), 0),
        COALESCE(SUM(delivery_fee) FILTER (WHERE status = 'delivered'), 0),
        COALESCE(AVG(total) FILTER (WHERE status = 'delivered'), 0)
    FROM food.orders o LEFT JOIN public.commissions c ON c.reference_id = o.id AND c.app_context = 'food'
    WHERE o.created_at::DATE = p_date
    ON CONFLICT (stat_date, app_context) DO UPDATE SET
        orders_count = EXCLUDED.orders_count, completed_orders = EXCLUDED.completed_orders,
        cancelled_orders = EXCLUDED.cancelled_orders, gmv = EXCLUDED.gmv,
        commission_rev = EXCLUDED.commission_rev, delivery_fees = EXCLUDED.delivery_fees,
        avg_order_value = EXCLUDED.avg_order_value;

    INSERT INTO public.daily_stats (stat_date, app_context, orders_count, completed_orders,
        cancelled_orders, gmv, commission_rev, delivery_fees, avg_order_value)
    SELECT p_date, 'market', COUNT(*),
        COUNT(*) FILTER (WHERE status = 'delivered'),
        COUNT(*) FILTER (WHERE status = 'cancelled'),
        COALESCE(SUM(total) FILTER (WHERE status = 'delivered'), 0),
        COALESCE(SUM(c.commission_amt), 0),
        COALESCE(SUM(delivery_fee) FILTER (WHERE status = 'delivered'), 0),
        COALESCE(AVG(total) FILTER (WHERE status = 'delivered'), 0)
    FROM market.orders o LEFT JOIN public.commissions c ON c.reference_id = o.id AND c.app_context = 'market'
    WHERE o.created_at::DATE = p_date
    ON CONFLICT (stat_date, app_context) DO UPDATE SET
        orders_count = EXCLUDED.orders_count, completed_orders = EXCLUDED.completed_orders,
        cancelled_orders = EXCLUDED.cancelled_orders, gmv = EXCLUDED.gmv,
        commission_rev = EXCLUDED.commission_rev, delivery_fees = EXCLUDED.delivery_fees,
        avg_order_value = EXCLUDED.avg_order_value;

    INSERT INTO public.daily_stats (stat_date, app_context, orders_count, completed_orders,
        cancelled_orders, gmv, avg_order_value)
    SELECT p_date, 'taxi', COUNT(*),
        COUNT(*) FILTER (WHERE status = 'completed'),
        COUNT(*) FILTER (WHERE status = 'cancelled'),
        COALESCE(SUM(total_fare) FILTER (WHERE status = 'completed'), 0),
        COALESCE(AVG(total_fare) FILTER (WHERE status = 'completed'), 0)
    FROM taxi.rides WHERE created_at::DATE = p_date
    ON CONFLICT (stat_date, app_context) DO UPDATE SET
        orders_count = EXCLUDED.orders_count, completed_orders = EXCLUDED.completed_orders,
        cancelled_orders = EXCLUDED.cancelled_orders, gmv = EXCLUDED.gmv,
        avg_order_value = EXCLUDED.avg_order_value;

    INSERT INTO public.daily_stats (stat_date, app_context, orders_count, completed_orders,
        cancelled_orders, gmv, commission_rev, delivery_fees, avg_order_value)
    SELECT p_date, 'pharmacy', COUNT(*),
        COUNT(*) FILTER (WHERE status = 'delivered'),
        COUNT(*) FILTER (WHERE status = 'cancelled'),
        COALESCE(SUM(total) FILTER (WHERE status = 'delivered'), 0),
        COALESCE(SUM(c.commission_amt), 0),
        COALESCE(SUM(delivery_fee) FILTER (WHERE status = 'delivered'), 0),
        COALESCE(AVG(total) FILTER (WHERE status = 'delivered'), 0)
    FROM pharmacy.orders o LEFT JOIN public.commissions c ON c.reference_id = o.id AND c.app_context = 'pharmacy'
    WHERE o.created_at::DATE = p_date
    ON CONFLICT (stat_date, app_context) DO UPDATE SET
        orders_count = EXCLUDED.orders_count, completed_orders = EXCLUDED.completed_orders,
        cancelled_orders = EXCLUDED.cancelled_orders, gmv = EXCLUDED.gmv,
        commission_rev = EXCLUDED.commission_rev, delivery_fees = EXCLUDED.delivery_fees,
        avg_order_value = EXCLUDED.avg_order_value;

    INSERT INTO public.daily_stats (stat_date, app_context, orders_count, completed_orders,
        cancelled_orders, gmv, commission_rev, delivery_fees, avg_order_value)
    SELECT p_date, 'clothes', COUNT(*),
        COUNT(*) FILTER (WHERE status = 'delivered'),
        COUNT(*) FILTER (WHERE status = 'cancelled'),
        COALESCE(SUM(total) FILTER (WHERE status = 'delivered'), 0),
        COALESCE(SUM(c.commission_amt), 0),
        COALESCE(SUM(delivery_fee) FILTER (WHERE status = 'delivered'), 0),
        COALESCE(AVG(total) FILTER (WHERE status = 'delivered'), 0)
    FROM clothes.orders o LEFT JOIN public.commissions c ON c.reference_id = o.id AND c.app_context = 'clothes'
    WHERE o.created_at::DATE = p_date
    ON CONFLICT (stat_date, app_context) DO UPDATE SET
        orders_count = EXCLUDED.orders_count, completed_orders = EXCLUDED.completed_orders,
        cancelled_orders = EXCLUDED.cancelled_orders, gmv = EXCLUDED.gmv,
        commission_rev = EXCLUDED.commission_rev, delivery_fees = EXCLUDED.delivery_fees,
        avg_order_value = EXCLUDED.avg_order_value;
END;
$$;


-- ── Taxi: deactivate drivers with expired inspections ─────────────────────────
CREATE OR REPLACE FUNCTION taxi.check_driver_inspection_status()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE taxi.drivers d SET is_verified = FALSE
    WHERE is_verified = TRUE
      AND EXISTS (SELECT 1 FROM taxi.vehicle_inspections vi
                  WHERE vi.driver_id = d.id AND vi.expires_at < CURRENT_DATE AND vi.result = 'passed')
      AND NOT EXISTS (SELECT 1 FROM taxi.vehicle_inspections vi
                      WHERE vi.driver_id = d.id AND vi.expires_at >= CURRENT_DATE
                        AND vi.result IN ('passed', 'conditional_pass'));
END;
$$;


-- ── [ADD v4.1] get_user_email() — service_role only ───────────────────────────
CREATE OR REPLACE FUNCTION public.get_user_email(p_user_id UUID)
RETURNS TEXT LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT email FROM auth.users WHERE id = p_user_id;
$$;
REVOKE ALL    ON FUNCTION public.get_user_email(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_user_email(UUID) TO service_role;


-- ============================================================================
-- VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW food.orders_full AS
SELECT o.*, p.full_name AS customer_name, p.phone AS customer_phone,
    p.avatar_url AS customer_avatar,
    r.name AS restaurant_name, r.phone AS restaurant_phone, r.logo_url AS restaurant_logo,
    pt.status AS payment_tx_status, pt.provider AS payment_provider
FROM food.orders o
JOIN public.profiles p ON o.user_id = p.id
JOIN food.restaurants r ON o.restaurant_id = r.id
LEFT JOIN public.payment_transactions pt ON o.payment_transaction_id = pt.id;


CREATE OR REPLACE VIEW taxi.available_drivers AS
SELECT d.*, p.full_name AS driver_name, p.phone AS driver_phone, p.avatar_url AS driver_avatar,
    vt.name AS vehicle_type_name
FROM taxi.drivers d
JOIN public.profiles p ON d.user_id = p.id
JOIN taxi.vehicle_types vt ON d.vehicle_type_id = vt.id
WHERE d.is_available = TRUE AND d.is_verified = TRUE AND d.is_active = TRUE AND NOT d.is_on_ride;


CREATE OR REPLACE VIEW public.user_dashboard AS
SELECT p.id, p.full_name, p.phone, p.referral_code, p.is_active, p.is_banned, p.risk_score, p.created_at,
    w.balance AS wallet_balance, lp.total_points AS loyalty_points, lp.tier AS loyalty_tier,
    (SELECT COUNT(*) FROM food.orders     fo WHERE fo.user_id = p.id AND fo.status = 'delivered') AS food_orders,
    (SELECT COUNT(*) FROM market.orders   mo WHERE mo.user_id = p.id AND mo.status = 'delivered') AS market_orders,
    (SELECT COUNT(*) FROM taxi.rides      tr WHERE tr.passenger_id = p.id AND tr.status = 'completed') AS taxi_rides,
    (SELECT COUNT(*) FROM pharmacy.orders po WHERE po.user_id = p.id AND po.status = 'delivered') AS pharma_orders,
    (SELECT COUNT(*) FROM clothes.orders  co WHERE co.user_id = p.id AND co.status = 'delivered') AS clothes_orders,
    ARRAY(SELECT app_context || ':' || role FROM public.user_roles
          WHERE user_id = p.id AND is_active = TRUE ORDER BY app_context) AS roles
FROM public.profiles p
LEFT JOIN public.wallets w       ON p.id = w.user_id
LEFT JOIN public.loyalty_points lp ON p.id = lp.user_id;


CREATE OR REPLACE VIEW public.revenue_summary AS
SELECT app_context, DATE_TRUNC('month', created_at) AS month,
    COUNT(*) AS order_count, SUM(order_total) AS total_gmv,
    SUM(commission_amt) AS platform_revenue, SUM(vendor_payout) AS vendor_payouts,
    AVG(commission_rate) AS avg_commission_rate
FROM public.commissions
GROUP BY app_context, DATE_TRUNC('month', created_at)
ORDER BY month DESC, app_context;


CREATE OR REPLACE VIEW public.vendor_earnings_summary AS
SELECT c.vendor_id, p.full_name AS vendor_name, c.app_context,
    COUNT(*) AS total_orders,
    SUM(c.order_total) AS total_gmv, SUM(c.commission_amt) AS total_commission_paid,
    SUM(c.vendor_payout) AS total_earned,
    SUM(c.vendor_payout) FILTER (WHERE c.status = 'pending') AS pending_payout,
    SUM(c.vendor_payout) FILTER (WHERE c.status = 'settled') AS settled_payout
FROM public.commissions c
JOIN public.profiles p ON c.vendor_id = p.id
GROUP BY c.vendor_id, p.full_name, c.app_context;


CREATE OR REPLACE VIEW public.active_feature_flags AS
SELECT key, rollout_percent, conditions, variant_config
FROM public.feature_flags WHERE is_enabled = TRUE;


CREATE OR REPLACE VIEW public.open_disputes AS
SELECT d.*, p.full_name AS raised_by_name, p.phone AS raised_by_phone
FROM public.disputes d JOIN public.profiles p ON d.raised_by = p.id
WHERE d.status IN ('open', 'under_review') ORDER BY d.created_at ASC;


-- [FIX v4.1] Updated to use profiles.email (with get_user_email() fallback)
CREATE OR REPLACE VIEW public.pending_vendor_applications AS
SELECT va.*, p.full_name AS applicant_name, p.phone AS applicant_phone,
    COALESCE(p.email, public.get_user_email(va.user_id)) AS applicant_email
FROM public.vendor_applications va JOIN public.profiles p ON va.user_id = p.id
WHERE va.status IN ('pending', 'under_review') ORDER BY va.created_at ASC;


CREATE OR REPLACE VIEW public.driver_zone_availability AS
SELECT dz.name AS zone_name, dza.app_context,
    COUNT(dza.driver_id) FILTER (WHERE dza.is_active = TRUE) AS assigned_drivers,
    COUNT(fd.id) FILTER (WHERE fd.is_available = TRUE AND fd.is_online = TRUE) AS online_drivers
FROM public.delivery_zones dz
LEFT JOIN public.driver_zone_assignments dza ON dz.id = dza.zone_id
LEFT JOIN food.drivers fd ON fd.user_id = dza.driver_id AND dza.is_active = TRUE
GROUP BY dz.id, dz.name, dza.app_context;


CREATE OR REPLACE VIEW public.failed_webhooks AS
SELECT * FROM public.webhook_events
WHERE processed = FALSE AND processing_attempts > 0
ORDER BY received_at DESC;


CREATE OR REPLACE VIEW public.pending_returns AS
SELECT r.*, p.full_name AS customer_name, p.phone AS customer_phone
FROM public.return_requests r JOIN public.profiles p ON r.user_id = p.id
WHERE r.status IN ('pending', 'approved', 'collection_scheduled')
ORDER BY r.created_at ASC;


-- ============================================================================
-- pg_cron SCHEDULED JOBS
-- ============================================================================

SELECT cron.schedule('sync-restaurant-hours',   '* * * * *',   $$ SELECT food.sync_restaurant_open_status(); $$);
SELECT cron.schedule('sync-pharmacy-hours',     '* * * * *',   $$ SELECT pharmacy.sync_pharmacy_open_status(); $$);
SELECT cron.schedule('activate-scheduled-orders', '* * * * *', $$ SELECT food.activate_scheduled_orders(); $$);
SELECT cron.schedule('activate-scheduled-pharmacy-orders', '* * * * *', $$ SELECT pharmacy.activate_scheduled_orders(); $$);
SELECT cron.schedule('release-stock-reservations', '*/5 * * * *',
    $$ SELECT market.release_expired_reservations(); SELECT clothes.release_expired_reservations(); $$);
SELECT cron.schedule('compute-daily-stats',     '0 1 * * *',   $$ SELECT public.compute_daily_stats(CURRENT_DATE - 1); $$);
SELECT cron.schedule('check-driver-inspections','0 0 * * *',   $$ SELECT taxi.check_driver_inspection_status(); $$);
SELECT cron.schedule('expire-vendor-applications', '0 2 * * *', $$
    UPDATE public.vendor_applications
    SET status = 'rejected', rejection_reason = 'Auto-expired: no response within 30 days'
    WHERE status = 'pending' AND created_at < NOW() - INTERVAL '30 days';
$$);
SELECT cron.schedule('close-inactive-conversations', '0 3 * * *', $$
    UPDATE public.conversations SET is_active = FALSE, closed_at = NOW()
    WHERE is_active = TRUE
      AND id NOT IN (SELECT DISTINCT conversation_id FROM public.chat_messages WHERE created_at > NOW() - INTERVAL '24 hours')
      AND created_at < NOW() - INTERVAL '24 hours';
$$);

-- [FIX v4.1] Dollar-quote nesting fixed: uses $body$ for inner DO block
SELECT cron.schedule('create-audit-partition', '0 0 25 * *', $cron$
    DO $body$
    DECLARE
        v_next_month DATE := DATE_TRUNC('month', NOW()) + INTERVAL '1 month';
        v_start      TEXT := TO_CHAR(v_next_month, 'YYYY_MM');
        v_end_month  DATE := v_next_month + INTERVAL '1 month';
        v_sql        TEXT;
    BEGIN
        v_sql := FORMAT(
            'CREATE TABLE IF NOT EXISTS public.audit_log_%s PARTITION OF public.audit_log
             FOR VALUES FROM (%L) TO (%L);
             CREATE UNIQUE INDEX IF NOT EXISTS uidx_audit_log_%s_id ON public.audit_log_%s (id);',
            v_start, v_next_month, v_end_month, v_start, v_start
        );
        EXECUTE v_sql;
    END $body$;
$cron$);


-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================
INSERT INTO storage.buckets (id, name, public) VALUES
    ('avatars',          'avatars',          TRUE),
    ('restaurants',      'restaurants',      TRUE),
    ('food-items',       'food-items',       TRUE),
    ('market-products',  'market-products',  TRUE),
    ('pharmacies',       'pharmacies',       TRUE),
    ('medicines',        'medicines',        TRUE),
    ('clothes-stores',   'clothes-stores',   TRUE),
    ('clothes-products', 'clothes-products', TRUE),
    ('documents',        'documents',        FALSE),
    ('prescriptions',    'prescriptions',    FALSE),
    ('dispute-evidence', 'dispute-evidence', FALSE),
    ('banners',          'banners',          TRUE),
    ('chat-media',       'chat-media',       FALSE),
    ('return-evidence',  'return-evidence',  FALSE),
    ('inspections',      'inspections',      FALSE),
    ('vendor-docs',      'vendor-docs',      FALSE),
    ('order-evidence',   'order-evidence',   FALSE)   -- [v4.1]
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public read on public buckets" ON storage.objects FOR SELECT
USING (bucket_id IN ('avatars','restaurants','food-items','market-products',
    'pharmacies','medicines','clothes-stores','clothes-products','banners'));

CREATE POLICY "Authenticated upload own folder" ON storage.objects FOR INSERT
WITH CHECK (auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::TEXT);

CREATE POLICY "User manage own files" ON storage.objects FOR ALL
USING (auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::TEXT);


-- ============================================================================
-- SEED DATA
-- ============================================================================

INSERT INTO public.app_settings (key, value, app_context, description, is_public) VALUES
    ('currency',              '{"code":"TND","symbol":"DT","decimals":3}',          'global', 'Default currency',              TRUE),
    ('platform_commission',   '{"food":15,"market":12,"pharmacy":10,"clothes":15}', 'global', 'Commission % per app',          FALSE),
    ('delivery_radius_km',    '{"food":10,"pharmacy":5,"market":15,"clothes":20}',  'global', 'Max delivery radius km',        FALSE),
    ('min_order',             '{"food":5,"market":10,"pharmacy":3,"clothes":20}',   'global', 'Min order amounts TND',         TRUE),
    ('loyalty_points_rate',   '{"per_dinar":1,"redeem_rate":0.1}',                  'global', '1 point per TND, 0.1 TND/pt',  FALSE),
    ('surge_enabled',         '{"taxi":true,"food":false}',                         'global', 'Surge pricing flags',           FALSE),
    ('support_hours',         '{"start":"08:00","end":"22:00","tz":"Africa/Tunis"}','global', 'Support availability',          TRUE),
    ('dispatch_timeout_sec',  '{"food":45,"market":45,"pharmacy":45,"taxi":30}',    'global', 'Driver offer timeout seconds',  FALSE),
    ('dispatch_max_attempts', '{"food":5,"market":5,"pharmacy":5,"taxi":10}',       'global', 'Max dispatch attempts',         FALSE),
    ('dispatch_radius_expand','{"step_m":1000,"max_m":8000}',                       'global', 'Radius expansion on retry',     FALSE)
ON CONFLICT (key) DO NOTHING;

INSERT INTO food.categories (name, name_ar, name_fr, color, sort_order) VALUES
    ('Burgers',   'برغر',         'Burgers',      '#FF6B35', 1),
    ('Pizza',     'بيتزا',         'Pizza',        '#FF4757', 2),
    ('Sushi',     'سوشي',          'Sushi',        '#2ED573', 3),
    ('Sandwiches','ساندويش',       'Sandwichs',    '#FFA502', 4),
    ('Salads',    'سلطات',         'Salades',      '#7BED9F', 5),
    ('Desserts',  'حلويات',        'Desserts',     '#FF6B81', 6),
    ('Drinks',    'مشروبات',       'Boissons',     '#70A1FF', 7),
    ('Breakfast', 'فطور',          'Petit-déj',    '#ECCC68', 8),
    ('Seafood',   'مأكولات بحرية', 'Fruits de mer','#1E90FF', 9),
    ('Grills',    'مشاوي',         'Grillades',    '#FF7F50', 10),
    ('Tunisian',  'أكل تونسي',     'Tunisien',     '#C0392B', 11),
    ('Healthy',   'صحي',           'Healthy',      '#27AE60', 12)
ON CONFLICT DO NOTHING;

INSERT INTO food.cuisines (name, name_ar, name_fr) VALUES
    ('Tunisian',      'تونسي',  'Tunisien'),
    ('Italian',       'إيطالي', 'Italien'),
    ('American',      'أمريكي', 'Américain'),
    ('Japanese',      'ياباني', 'Japonais'),
    ('French',        'فرنسي',  'Français'),
    ('Lebanese',      'لبناني', 'Libanais'),
    ('Indian',        'هندي',   'Indien'),
    ('Chinese',       'صيني',   'Chinois'),
    ('Mexican',       'مكسيكي', 'Mexicain'),
    ('Turkish',       'تركي',   'Turc'),
    ('Mediterranean', 'متوسطي', 'Méditerranéen'),
    ('Fast Food',     'فاست فود','Fast Food')
ON CONFLICT (name) DO NOTHING;

INSERT INTO market.categories (name, name_ar, name_fr, sort_order) VALUES
    ('Fruits & Vegetables','فواكه وخضروات','Fruits & Légumes',   1),
    ('Meat & Poultry',     'لحوم ودواجن',  'Viande & Volaille',  2),
    ('Dairy & Eggs',       'ألبان وبيض',   'Laitier & Oeufs',    3),
    ('Bread & Bakery',     'خبز ومخبوزات', 'Pain & Boulangerie', 4),
    ('Beverages',          'مشروبات',       'Boissons',           5),
    ('Snacks',             'وجبات خفيفة',  'Snacks',             6),
    ('Cleaning',           'منظفات',        'Nettoyage',          7),
    ('Personal Care',      'عناية شخصية',  'Soins Personnels',   8),
    ('Baby Products',      'منتجات أطفال', 'Produits Bébé',      9),
    ('Electronics',        'إلكترونيات',   'Électronique',      10)
ON CONFLICT DO NOTHING;

INSERT INTO clothes.categories (name, name_ar, name_fr, sort_order) VALUES
    ('Men',         'رجال',           'Hommes',      1),
    ('Women',       'نساء',           'Femmes',      2),
    ('Kids',        'أطفال',          'Enfants',     3),
    ('Tops',        'قمصان وبلوزات',  'Hauts',       4),
    ('Bottoms',     'بناطيل وتنانير', 'Bas',         5),
    ('Dresses',     'فساتين',         'Robes',       6),
    ('Shoes',       'أحذية',          'Chaussures',  7),
    ('Bags',        'حقائب',          'Sacs',        8),
    ('Accessories', 'إكسسوارات',      'Accessoires', 9),
    ('Sportswear',  'ملابس رياضية',   'Sport',      10)
ON CONFLICT DO NOTHING;

INSERT INTO taxi.vehicle_types (name, name_ar, base_fare, per_km_rate, per_min_rate, min_fare, capacity, sort_order) VALUES
    ('Economy', 'اقتصادي', 1.500, 0.500, 0.100, 3.000, 4, 1),
    ('Comfort', 'مريح',    2.000, 0.700, 0.120, 4.000, 4, 2),
    ('XL',      'XL',      2.500, 0.900, 0.150, 5.000, 6, 3),
    ('Moto',    'موتو',    0.800, 0.300, 0.080, 1.500, 1, 4),
    ('Premium', 'فاخر',    3.500, 1.200, 0.200, 7.000, 4, 5)
ON CONFLICT DO NOTHING;

INSERT INTO pharmacy.categories (name, name_ar, name_fr, sort_order) VALUES
    ('Prescription Drugs','أدوية بوصفة',   'Médicaments',    1),
    ('OTC Drugs',         'بدون وصفة',      'Sans Ordonnance',2),
    ('Vitamins',          'فيتامينات',       'Vitamines',      3),
    ('Baby & Child',      'رعاية الأطفال',  'Bébé & Enfant',  4),
    ('Skin Care',         'العناية بالبشرة','Soins Peau',     5),
    ('Medical Devices',   'أجهزة طبية',     'Dispositifs',    6),
    ('Dental',            'العناية بالأسنان','Dentaire',       7),
    ('First Aid',         'إسعافات أولية',  'Premiers Soins', 8)
ON CONFLICT DO NOTHING;

INSERT INTO public.tax_rates (name, rate_percent, app_context, applies_to, country_code, is_default, valid_from) VALUES
    ('TVA Standard 19%', 19.00, 'global', ARRAY['food','market','clothes','taxi'], 'TN', TRUE,  '2024-01-01'),
    ('TVA Réduit 7%',     7.00, 'global', ARRAY['pharmacy'],                       'TN', FALSE, '2024-01-01'),
    ('Exonéré 0%',        0.00, 'global', ARRAY['all'],                             'TN', FALSE, '2024-01-01')
ON CONFLICT DO NOTHING;

INSERT INTO public.promo_codes (code, description, app_context, discount_type,
    discount_value, min_order_amount, max_discount, max_total_uses, valid_until, is_active) VALUES
    ('WELCOME10',  'Welcome 10% off any app',     'global',   'percentage', 10, 5,  5,  NULL, NOW() + INTERVAL '1 year',   TRUE),
    ('FOOD15',     '15% off food orders',         'food',     'percentage', 15, 10, 8,  500,  NOW() + INTERVAL '6 months', TRUE),
    ('FIRSTRIDE',  'First taxi ride 5 DT off',    'taxi',     'fixed',      5,  0,  5,  NULL, NOW() + INTERVAL '1 year',   TRUE),
    ('MARKET5',    '5 DT off groceries',          'market',   'fixed',      5,  20, 5,  200,  NOW() + INTERVAL '3 months', TRUE),
    ('PHARMACY10', '10% off pharmacy orders',     'pharmacy', 'percentage', 10, 15, 7,  100,  NOW() + INTERVAL '6 months', TRUE),
    ('CLOTHES20',  '20% off first clothes order', 'clothes',  'percentage', 20, 30, 15, 300,  NOW() + INTERVAL '6 months', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.banners (app_context, title, title_ar, image_url, position, is_active, valid_until) VALUES
    ('food',     'Order Now & Get 15% Off',  'اطلب الآن واحصل على خصم 15%', '', 1, TRUE, NOW() + INTERVAL '30 days'),
    ('market',   'Fresh Groceries Delivered','خضروات طازجة على بابك',        '', 1, TRUE, NOW() + INTERVAL '30 days'),
    ('taxi',     'Ride Safe, Arrive Fast',   'سافر بأمان، اوصل بسرعة',      '', 1, TRUE, NOW() + INTERVAL '30 days'),
    ('pharmacy', 'Medicines at Your Door',   'أدويتك على بابك',               '', 1, TRUE, NOW() + INTERVAL '30 days'),
    ('clothes',  'Latest Fashion Delivered', 'أحدث الموضة لبابك',             '', 1, TRUE, NOW() + INTERVAL '30 days')
ON CONFLICT DO NOTHING;

INSERT INTO public.feature_flags (key, description, is_enabled, rollout_percent, conditions) VALUES
    ('chat_enabled',            'In-app chat between user and driver',  TRUE,  100, '{}'),
    ('scheduled_orders',        'Scheduled/pre-order feature',          TRUE,  100, '{}'),
    ('surge_pricing',           'Dynamic surge pricing for taxi',       TRUE,  100, '{"app_contexts":["taxi"]}'),
    ('clothes_app',             'Clothes mini-app visible in home',     TRUE,  100, '{}'),
    ('wallet_topup',            'Wallet top-up via payment gateway',    TRUE,  100, '{}'),
    ('driver_tips',             'Tip option on delivery completion',    TRUE,  100, '{}'),
    ('prescription_upload',     'Prescription upload for pharmacy',     TRUE,  100, '{"app_contexts":["pharmacy"]}'),
    ('loyalty_redeem',          'Redeem loyalty points at checkout',    FALSE, 0,   '{}'),
    ('new_dispatch_algorithm',  'A/B: new radius-first dispatch',       FALSE, 50,  '{}'),
    ('instant_payment_confirm', 'Skip payment pending state',           FALSE, 20,  '{}')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.notification_templates
    (event_type, app_context, channel, title_en, title_ar, title_fr, body_en, body_ar, body_fr, variables, deep_link)
VALUES
('order.confirmed',       'food',   'push', 'Order Confirmed ✅',       'تم تأكيد طلبك ✅',      'Commande confirmée ✅',
 'Your order #{order_number} from {vendor_name} is confirmed!',
 'تم تأكيد طلبك #{order_number} من {vendor_name}!',
 'Votre commande #{order_number} de {vendor_name} est confirmée!',
 ARRAY['order_number','vendor_name'], '/orders/{order_id}'),
('order.preparing',       'food',   'push', '👨‍🍳 Preparing Your Order', 'جاري تحضير طلبك 👨‍🍳',  'En préparation 👨‍🍳',
 '{vendor_name} is preparing your order. ETA: {eta_minutes} min.',
 '{vendor_name} يحضر طلبك. الوقت المتوقع: {eta_minutes} دقيقة.',
 '{vendor_name} prépare votre commande. ETA: {eta_minutes} min.',
 ARRAY['vendor_name','eta_minutes'], '/orders/{order_id}'),
('order.driver_assigned', 'food',   'push', '🛵 Driver Assigned',        'تم تعيين السائق 🛵',     'Livreur assigné 🛵',
 '{driver_name} is picking up your order.',
 '{driver_name} في طريقه لاستلام طلبك.',
 '{driver_name} récupère votre commande.',
 ARRAY['driver_name','eta_minutes'], '/orders/{order_id}/tracking'),
('order.picked_up',       'food',   'push', '🏃 On the Way!',            'في الطريق إليك! 🏃',     'En route! 🏃',
 'Your order is on the way! ETA: {eta_minutes} min.',
 'طلبك في الطريق! وقت الوصول: {eta_minutes} دقيقة.',
 'Votre commande est en route! ETA: {eta_minutes} min.',
 ARRAY['eta_minutes'], '/orders/{order_id}/tracking'),
('order.delivered',       'food',   'push', '🎉 Order Delivered!',       'تم التوصيل! 🎉',         'Livré! 🎉',
 'Your order #{order_number} has been delivered. Enjoy your meal!',
 'تم توصيل طلبك #{order_number}. بالهناء والشفاء!',
 'Votre commande #{order_number} a été livrée. Bon appétit!',
 ARRAY['order_number'], '/orders/{order_id}/rate'),
('order.cancelled',       'food',   'push', 'Order Cancelled ❌',        'تم إلغاء الطلب ❌',       'Commande annulée ❌',
 'Your order #{order_number} was cancelled. Refund: {refund_amount} DT.',
 'تم إلغاء طلبك #{order_number}. سيتم استرداد {refund_amount} دينار.',
 'Commande #{order_number} annulée. Remboursement: {refund_amount} DT.',
 ARRAY['order_number','refund_amount'], '/orders'),
('ride.driver_assigned',  'taxi',   'push', '🚗 Driver Found!',          'تم إيجاد سائق! 🚗',      'Chauffeur trouvé! 🚗',
 '{driver_name} is on the way. {vehicle_color} {vehicle_model} · {vehicle_plate}.',
 '{driver_name} في طريقه إليك. {vehicle_color} {vehicle_model} · {vehicle_plate}.',
 '{driver_name} arrive. {vehicle_color} {vehicle_model} · {vehicle_plate}.',
 ARRAY['driver_name','vehicle_color','vehicle_model','vehicle_plate','eta_minutes'], '/taxi/{ride_id}/tracking'),
('ride.driver_arrived',   'taxi',   'push', '📍 Driver Arrived',         'وصل السائق 📍',           'Chauffeur arrivé 📍',
 'Your driver {driver_name} has arrived at the pickup point.',
 'وصل سائقك {driver_name} إلى نقطة الانطلاق.',
 'Votre chauffeur {driver_name} est arrivé.',
 ARRAY['driver_name'], '/taxi/{ride_id}/tracking'),
('ride.completed',        'taxi',   'push', '✅ Ride Complete',           'اكتملت الرحلة ✅',        'Course terminée ✅',
 'Ride completed. Total: {amount} DT. Rate your driver!',
 'اكتملت الرحلة. المجموع: {amount} دينار. قيّم سائقك!',
 'Course terminée. Total: {amount} DT. Notez votre chauffeur!',
 ARRAY['amount','ride_number'], '/taxi/{ride_id}/rate'),
('wallet.topup',          'global', 'push', '💰 Wallet Topped Up',       'تم شحن المحفظة 💰',       'Portefeuille rechargé 💰',
 'Your wallet has been topped up with {amount} DT.',
 'تم إضافة {amount} دينار إلى محفظتك.',
 'Votre portefeuille a été rechargé de {amount} DT.',
 ARRAY['amount'], '/wallet'),
('wallet.payment',        'global', 'push', '💳 Payment Made',           'تم الدفع 💳',             'Paiement effectué 💳',
 '{amount} DT paid for order #{order_number}. Balance: {balance} DT.',
 'تم دفع {amount} دينار للطلب #{order_number}. الرصيد: {balance} دينار.',
 '{amount} DT payé pour commande #{order_number}. Solde: {balance} DT.',
 ARRAY['amount','order_number','balance'], '/wallet'),
('promo.expiring_soon',   'global', 'push', '⏰ Promo Expiring Soon',    'الكود ينتهي قريباً ⏰',   'Promo expire bientôt ⏰',
 'Your promo code {promo_code} expires in 24 hours!',
 'كود الخصم {promo_code} ينتهي خلال 24 ساعة!',
 'Votre code promo {promo_code} expire dans 24h!',
 ARRAY['promo_code'], '/promos'),
('vendor.new_order',      'food',   'push', '🔔 New Order!',             'طلب جديد! 🔔',            'Nouvelle commande! 🔔',
 'New order #{order_number} · {item_count} items · {amount} DT. Accept now!',
 'طلب جديد #{order_number} · {item_count} عناصر · {amount} دينار.',
 'Nouvelle commande #{order_number} · {item_count} articles · {amount} DT.',
 ARRAY['order_number','item_count','amount'], '/vendor/orders/{order_id}'),
('vendor.payout_sent',    'global', 'push', '💸 Payout Sent!',           'تم إرسال المدفوعات! 💸',  'Virement envoyé! 💸',
 'Your payout of {amount} DT has been sent.',
 'تم إرسال {amount} دينار إلى حسابك.',
 'Votre virement de {amount} DT a été envoyé.',
 ARRAY['amount','period'], '/vendor/earnings'),
('driver.new_offer',      'food',   'push', '📦 New Delivery Offer',     'عرض توصيل جديد 📦',       'Nouvelle offre 📦',
 'New delivery from {vendor_name}. {distance_km}km away. Accept within {timeout}s!',
 'توصيل جديد من {vendor_name}. {distance_km}كم. اقبل خلال {timeout} ثانية!',
 'Nouvelle livraison de {vendor_name}. {distance_km}km. Acceptez dans {timeout}s!',
 ARRAY['vendor_name','distance_km','amount','timeout'], '/driver/offer/{order_id}'),
('driver.payout_sent',    'global', 'push', '💸 Earnings Paid!',         'تم دفع أرباحك! 💸',       'Gains versés! 💸',
 'Your earnings of {amount} DT have been paid.',
 'تم دفع أرباحك البالغة {amount} دينار.',
 'Vos gains de {amount} DT ont été versés.',
 ARRAY['amount'], '/driver/earnings')
ON CONFLICT (event_type, app_context, channel) DO NOTHING;

-- ============================================================================
-- END OF SCHEMA v4.1
-- ============================================================================
