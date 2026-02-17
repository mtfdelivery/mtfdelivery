-- ============================================================================
-- MTF Delivery - Complete Supabase Database Schema (Production Ready)
-- ============================================================================
-- Version: 2.0
-- Last Updated: 2026-02-17
-- Description: Full-featured food delivery application with support for
--              customers, restaurants, drivers, orders, payments, and more.
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- For advanced geolocation features (optional)

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) NOT NULL,
    avatar_url TEXT,
    role VARCHAR(50) DEFAULT 'customer', -- customer, admin, driver, restaurant_owner
    referral_code VARCHAR(50) UNIQUE,
    referred_by UUID REFERENCES users(id) ON DELETE SET NULL,
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

-- ============================================================================
-- ADDRESSES TABLE
-- ============================================================================
CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL, -- Home, Work, Other
    address TEXT NOT NULL,
    name VARCHAR(255), -- Contact name at address
    phone VARCHAR(50), -- Contact phone
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    plus_code VARCHAR(50),
    street_number VARCHAR(50),
    house VARCHAR(255),
    floor VARCHAR(50),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own addresses" ON addresses FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own addresses" ON addresses FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own addresses" ON addresses FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own addresses" ON addresses FOR DELETE USING (user_id = auth.uid());

-- ============================================================================
-- CATEGORIES TABLE
-- ============================================================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    icon_url TEXT NOT NULL,
    color VARCHAR(20) NOT NULL, -- Hex color code
    item_count INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view categories" ON categories FOR SELECT USING (is_active = true);

-- ============================================================================
-- CUISINES TABLE
-- ============================================================================
CREATE TABLE cuisines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE cuisines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view cuisines" ON cuisines FOR SELECT USING (is_active = true);

-- ============================================================================
-- RESTAURANTS TABLE
-- ============================================================================
CREATE TABLE restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    image_url TEXT,
    logo_url TEXT,
    description TEXT,
    rating DECIMAL(3,2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    cuisine VARCHAR(100) NOT NULL,
    cuisine_types TEXT[], -- Array of cuisine types
    delivery_time INTEGER NOT NULL, -- in minutes
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    min_order DECIMAL(10,2) DEFAULT 0,
    distance DECIMAL(10,2), -- in km
    price_range VARCHAR(10), -- $, $$, $$$
    is_featured BOOLEAN DEFAULT false,
    is_open BOOLEAN DEFAULT true,
    address TEXT NOT NULL,
    opening_hours VARCHAR(100),
    phone VARCHAR(50),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    average_preparation_time INTEGER DEFAULT 30,
    accepts_cash BOOLEAN DEFAULT true,
    accepts_card BOOLEAN DEFAULT true,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    packaging_fee DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active restaurants" ON restaurants FOR SELECT USING (is_active = true);
CREATE POLICY "Restaurant owners can view own restaurants" ON restaurants FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "Restaurant owners can update own restaurants" ON restaurants FOR UPDATE USING (owner_id = auth.uid());

-- ============================================================================
-- RESTAURANT CUISINES TABLE (Many-to-Many)
-- ============================================================================
CREATE TABLE restaurant_cuisines (
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    cuisine_id UUID REFERENCES cuisines(id) ON DELETE CASCADE,
    PRIMARY KEY (restaurant_id, cuisine_id)
);

ALTER TABLE restaurant_cuisines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view restaurant cuisines" ON restaurant_cuisines FOR SELECT USING (true);

-- ============================================================================
-- RESTAURANT HOURS TABLE
-- ============================================================================
CREATE TABLE restaurant_hours (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL, -- 0-6 (Sunday-Saturday)
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE restaurant_hours ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view restaurant hours" ON restaurant_hours FOR SELECT USING (true);
CREATE POLICY "Restaurant owners can manage hours" ON restaurant_hours FOR ALL 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

-- ============================================================================
-- RESTAURANT STAFF TABLE
-- ============================================================================
CREATE TABLE restaurant_staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL, -- manager, staff, chef
    permissions JSONB, -- {"can_edit_menu": true, "can_accept_orders": true}
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id, user_id)
);

ALTER TABLE restaurant_staff ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurant owners can manage staff" ON restaurant_staff FOR ALL 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));
CREATE POLICY "Staff can view own assignments" ON restaurant_staff FOR SELECT USING (user_id = auth.uid());

-- ============================================================================
-- MENU CATEGORIES TABLE
-- ============================================================================
CREATE TABLE menu_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE menu_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active menu categories" ON menu_categories FOR SELECT USING (is_active = true);
CREATE POLICY "Restaurant owners can manage menu categories" ON menu_categories FOR ALL 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

-- ============================================================================
-- FOOD ITEMS TABLE
-- ============================================================================
CREATE TABLE food_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    menu_category_id UUID REFERENCES menu_categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2), -- For showing discounts
    category VARCHAR(100) NOT NULL, -- Appetizers, Main Course, etc.
    is_vegetarian BOOLEAN DEFAULT false,
    is_vegan BOOLEAN DEFAULT false,
    is_spicy BOOLEAN DEFAULT false,
    is_popular BOOLEAN DEFAULT false,
    rating DECIMAL(3,2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    ingredients TEXT[], -- Array of ingredients
    preparation_time INTEGER DEFAULT 15, -- in minutes
    calories INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view available food items" ON food_items FOR SELECT 
    USING (is_active = true AND is_available = true);
CREATE POLICY "Restaurant owners can manage own food items" ON food_items FOR ALL 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

-- ============================================================================
-- FOOD ADDONS TABLE
-- ============================================================================
CREATE TABLE food_addons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    food_item_id UUID NOT NULL REFERENCES food_items(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food_addons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view available food addons" ON food_addons FOR SELECT USING (is_available = true);
CREATE POLICY "Restaurant owners can manage food addons" ON food_addons FOR ALL 
    USING (food_item_id IN (
        SELECT id FROM food_items WHERE restaurant_id IN (
            SELECT id FROM restaurants WHERE owner_id = auth.uid()
        )
    ));

-- ============================================================================
-- DRIVERS TABLE
-- ============================================================================
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type VARCHAR(50), -- car, motorcycle, bicycle
    vehicle_number VARCHAR(50),
    license_number VARCHAR(100),
    bank_account VARCHAR(255),
    id_card_url TEXT,
    license_url TEXT,
    vehicle_photo_url TEXT,
    is_available BOOLEAN DEFAULT false,
    current_latitude DOUBLE PRECISION,
    current_longitude DOUBLE PRECISION,
    rating DECIMAL(3,2) DEFAULT 5.0,
    total_deliveries INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drivers can view own profile" ON drivers FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Drivers can update own profile" ON drivers FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Anyone can view available drivers" ON drivers FOR SELECT USING (is_available = true AND is_verified = true);

-- ============================================================================
-- DRIVER LOCATIONS TABLE (Real-time tracking)
-- ============================================================================
CREATE TABLE driver_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drivers can insert own locations" ON driver_locations FOR INSERT 
    WITH CHECK (driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid()));

-- ============================================================================
-- DELIVERY ZONES TABLE
-- ============================================================================
CREATE TABLE delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    polygon_coordinates JSONB, -- GeoJSON polygon
    delivery_fee DECIMAL(10,2) NOT NULL,
    min_order DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE delivery_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active delivery zones" ON delivery_zones FOR SELECT USING (is_active = true);
CREATE POLICY "Restaurant owners can manage delivery zones" ON delivery_zones FOR ALL 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

-- ============================================================================
-- CART ITEMS TABLE
-- ============================================================================
CREATE TABLE cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_item_id UUID NOT NULL REFERENCES food_items(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, food_item_id)
);

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own cart" ON cart_items FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- CART ITEM ADDONS TABLE
-- ============================================================================
CREATE TABLE cart_item_addons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_item_id UUID NOT NULL REFERENCES cart_items(id) ON DELETE CASCADE,
    addon_id UUID NOT NULL REFERENCES food_addons(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cart_item_id, addon_id)
);

ALTER TABLE cart_item_addons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own cart addons" ON cart_item_addons FOR ALL 
    USING (cart_item_id IN (SELECT id FROM cart_items WHERE user_id = auth.uid()));

-- ============================================================================
-- ORDERS TABLE
-- ============================================================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE SET NULL,
    driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, preparing, out_for_delivery, delivered, cancelled
    order_type VARCHAR(20) DEFAULT 'delivery', -- delivery, pickup
    subtotal DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    tax DECIMAL(10,2) DEFAULT 0,
    discount DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    delivery_address_id UUID REFERENCES addresses(id),
    delivery_address TEXT, -- Denormalized for order history
    payment_method VARCHAR(50) NOT NULL, -- cash, card, wallet
    payment_status VARCHAR(50) DEFAULT 'pending', -- pending, paid, failed, refunded
    promo_code VARCHAR(50),
    special_instructions TEXT,
    estimated_delivery TIMESTAMP WITH TIME ZONE,
    scheduled_for TIMESTAMP WITH TIME ZONE,
    is_scheduled BOOLEAN DEFAULT false,
    preparation_time INTEGER,
    delivered_at TIMESTAMP WITH TIME ZONE,
    cancelled_by VARCHAR(50),
    cancellation_reason TEXT,
    driver_name VARCHAR(255),
    driver_phone VARCHAR(50),
    driver_avatar TEXT,
    driver_rating DECIMAL(3,2),
    tracking_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own orders" ON orders FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own orders" ON orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Restaurant owners can view own restaurant orders" ON orders FOR SELECT 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));
CREATE POLICY "Restaurant owners can update own restaurant orders" ON orders FOR UPDATE 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));
CREATE POLICY "Drivers can view assigned orders" ON orders FOR SELECT 
    USING (driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid()));
CREATE POLICY "Drivers can update assigned orders" ON orders FOR UPDATE 
    USING (driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid()));

-- ============================================================================
-- ORDER ITEMS TABLE
-- ============================================================================
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    food_item_id UUID NOT NULL REFERENCES food_items(id) ON DELETE SET NULL,
    food_item_name VARCHAR(255) NOT NULL, -- Denormalized
    food_item_image TEXT,
    price DECIMAL(10,2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own order items" ON order_items FOR SELECT 
    USING (order_id IN (SELECT id FROM orders WHERE user_id = auth.uid()));
CREATE POLICY "Restaurant owners can view own restaurant order items" ON order_items FOR SELECT 
    USING (order_id IN (
        SELECT id FROM orders WHERE restaurant_id IN (
            SELECT id FROM restaurants WHERE owner_id = auth.uid()
        )
    ));

-- ============================================================================
-- ORDER ITEM ADDONS TABLE
-- ============================================================================
CREATE TABLE order_item_addons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
    addon_id UUID REFERENCES food_addons(id) ON DELETE SET NULL,
    addon_name VARCHAR(255) NOT NULL,
    addon_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE order_item_addons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own order item addons" ON order_item_addons FOR SELECT 
    USING (order_item_id IN (
        SELECT id FROM order_items WHERE order_id IN (
            SELECT id FROM orders WHERE user_id = auth.uid()
        )
    ));

-- ============================================================================
-- ORDER STATUS HISTORY TABLE
-- ============================================================================
CREATE TABLE order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own order status history" ON order_status_history FOR SELECT 
    USING (order_id IN (SELECT id FROM orders WHERE user_id = auth.uid()));
CREATE POLICY "Restaurant owners can view order status history" ON order_status_history FOR SELECT 
    USING (order_id IN (
        SELECT id FROM orders WHERE restaurant_id IN (
            SELECT id FROM restaurants WHERE owner_id = auth.uid()
        )
    ));

-- ============================================================================
-- REVIEWS TABLE
-- ============================================================================
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    food_item_id UUID REFERENCES food_items(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    images TEXT[], -- Array of image URLs
    helpful_count INTEGER DEFAULT 0,
    reply TEXT, -- Restaurant owner reply
    reply_at TIMESTAMP WITH TIME ZONE,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view visible reviews" ON reviews FOR SELECT USING (is_visible = true);
CREATE POLICY "Users can insert own reviews" ON reviews FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE USING (user_id = auth.uid());

-- ============================================================================
-- FAVORITES TABLE
-- ============================================================================
CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    food_item_id UUID REFERENCES food_items(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, restaurant_id, food_item_id)
);

ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own favorites" ON favorites FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- COUPONS TABLE
-- ============================================================================
CREATE TABLE coupons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL, -- percentage, fixed
    discount_value DECIMAL(10,2) NOT NULL,
    min_order_amount DECIMAL(10,2),
    max_discount DECIMAL(10,2),
    max_uses INTEGER,
    max_uses_per_user INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    applicable_to VARCHAR(50) DEFAULT 'all', -- all, restaurant_id, user_id
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT USING (is_active = true);

-- ============================================================================
-- USER COUPON USAGE TABLE
-- ============================================================================
CREATE TABLE user_coupon_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    discount_amount DECIMAL(10,2) NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE user_coupon_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own coupon usage" ON user_coupon_usage FOR SELECT USING (user_id = auth.uid());

-- ============================================================================
-- PROMO BANNERS TABLE
-- ============================================================================
CREATE TABLE promo_banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    subtitle TEXT,
    image_url TEXT NOT NULL,
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE SET NULL,
    promo_code VARCHAR(50),
    discount_percentage DECIMAL(5,2),
    min_order_amount DECIMAL(10,2),
    max_discount DECIMAL(10,2),
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE promo_banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active promo banners" ON promo_banners FOR SELECT USING (is_active = true);

-- ============================================================================
-- HOME SERVICES TABLE
-- ============================================================================
CREATE TABLE home_services (
    id VARCHAR(50) PRIMARY KEY, -- courier, restaurants, groceries, boutiques, pharmacies
    name VARCHAR(100) NOT NULL,
    icon_url TEXT NOT NULL,
    route VARCHAR(100) NOT NULL,
    is_available BOOLEAN DEFAULT false,
    size VARCHAR(20) DEFAULT 'small', -- large, small
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE home_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view home services" ON home_services FOR SELECT USING (true);

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    type VARCHAR(50), -- order, promotion, system
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());

-- ============================================================================
-- DEVICE TOKENS TABLE (Push Notifications)
-- ============================================================================
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL, -- ios, android, web
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, token)
);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own device tokens" ON device_tokens FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- USER WALLETS TABLE
-- ============================================================================
CREATE TABLE user_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallet" ON user_wallets FOR SELECT USING (user_id = auth.uid());

-- ============================================================================
-- WALLET TRANSACTIONS TABLE
-- ============================================================================
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- credit, debit, refund, bonus
    amount DECIMAL(10,2) NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    description TEXT,
    balance_after DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallet transactions" ON wallet_transactions FOR SELECT USING (user_id = auth.uid());

-- ============================================================================
-- PAYMENT TRANSACTIONS TABLE
-- ============================================================================
CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255),
    status VARCHAR(50) NOT NULL, -- pending, completed, failed, refunded
    gateway_response JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own payment transactions" ON payment_transactions FOR SELECT 
    USING (order_id IN (SELECT id FROM orders WHERE user_id = auth.uid()));

-- ============================================================================
-- EARNINGS TABLE (For Drivers & Restaurants)
-- ============================================================================
CREATE TABLE earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL,
    commission DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, completed, paid_out
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE earnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own earnings" ON earnings FOR SELECT USING (user_id = auth.uid());

-- ============================================================================
-- DRIVER EARNINGS SUMMARY TABLE
-- ============================================================================
CREATE TABLE driver_earnings_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID UNIQUE NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    today_earnings DECIMAL(10,2) DEFAULT 0,
    week_earnings DECIMAL(10,2) DEFAULT 0,
    month_earnings DECIMAL(10,2) DEFAULT 0,
    total_earnings DECIMAL(10,2) DEFAULT 0,
    pending_payout DECIMAL(10,2) DEFAULT 0,
    total_deliveries_today INTEGER DEFAULT 0,
    total_deliveries_week INTEGER DEFAULT 0,
    total_deliveries_month INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE driver_earnings_summary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drivers can view own earnings summary" ON driver_earnings_summary FOR SELECT 
    USING (driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid()));

-- ============================================================================
-- RESTAURANT EARNINGS SUMMARY TABLE
-- ============================================================================
CREATE TABLE restaurant_earnings_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID UNIQUE NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    today_revenue DECIMAL(10,2) DEFAULT 0,
    week_revenue DECIMAL(10,2) DEFAULT 0,
    month_revenue DECIMAL(10,2) DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    today_orders INTEGER DEFAULT 0,
    week_orders INTEGER DEFAULT 0,
    month_orders INTEGER DEFAULT 0,
    pending_payout DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE restaurant_earnings_summary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurant owners can view own earnings" ON restaurant_earnings_summary FOR SELECT 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

-- ============================================================================
-- PAYOUT REQUESTS TABLE
-- ============================================================================
CREATE TABLE payout_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    bank_account VARCHAR(255),
    payment_method VARCHAR(50), -- bank_transfer, mobile_money, paypal
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, rejected
    rejection_reason TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE payout_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own payout requests" ON payout_requests FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create own payout requests" ON payout_requests FOR INSERT WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- SUPPORT TICKETS TABLE
-- ============================================================================
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    category VARCHAR(100) NOT NULL, -- order_issue, payment, technical, other
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'open', -- open, in_progress, resolved, closed
    priority VARCHAR(20) DEFAULT 'normal', -- low, normal, high, urgent
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own support tickets" ON support_tickets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create support tickets" ON support_tickets FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own support tickets" ON support_tickets FOR UPDATE USING (user_id = auth.uid());

-- ============================================================================
-- SUPPORT MESSAGES TABLE
-- ============================================================================
CREATE TABLE support_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    attachments TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own support messages" ON support_messages FOR SELECT 
    USING (ticket_id IN (SELECT id FROM support_tickets WHERE user_id = auth.uid()));
CREATE POLICY "Users can insert support messages" ON support_messages FOR INSERT 
    WITH CHECK (ticket_id IN (SELECT id FROM support_tickets WHERE user_id = auth.uid()));

-- ============================================================================
-- REFERRAL CODES TABLE
-- ============================================================================
CREATE TABLE referral_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(50) UNIQUE NOT NULL,
    referral_bonus DECIMAL(10,2) DEFAULT 10.00,
    referee_bonus DECIMAL(10,2) DEFAULT 10.00,
    total_referrals INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own referral codes" ON referral_codes FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Anyone can view active referral codes" ON referral_codes FOR SELECT USING (is_active = true);

-- ============================================================================
-- REFERRALS TABLE
-- ============================================================================
CREATE TABLE referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referral_code VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, completed
    referrer_reward DECIMAL(10,2),
    referee_reward DECIMAL(10,2),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(referee_id)
);

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own referrals" ON referrals FOR SELECT 
    USING (referrer_id = auth.uid() OR referee_id = auth.uid());

-- ============================================================================
-- SUBSCRIPTION PLANS TABLE
-- ============================================================================
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    duration_days INTEGER NOT NULL,
    commission_rate DECIMAL(5,2), -- Platform commission %
    features JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active subscription plans" ON subscription_plans FOR SELECT USING (is_active = true);

-- ============================================================================
-- RESTAURANT SUBSCRIPTIONS TABLE
-- ============================================================================
CREATE TABLE restaurant_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'active', -- active, expired, cancelled
    auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE restaurant_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurant owners can view own subscriptions" ON restaurant_subscriptions FOR SELECT 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

-- ============================================================================
-- COMMISSION SETTINGS TABLE
-- ============================================================================
CREATE TABLE commission_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    commission_type VARCHAR(50) NOT NULL, -- percentage, fixed
    commission_value DECIMAL(10,2) NOT NULL,
    applies_to VARCHAR(50) DEFAULT 'all', -- all, delivery, pickup
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE commission_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurant owners can view own commission settings" ON commission_settings FOR SELECT 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

-- ============================================================================
-- ORDER ANALYTICS TABLE
-- ============================================================================
CREATE TABLE order_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    total_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    total_commission DECIMAL(10,2) DEFAULT 0,
    avg_order_value DECIMAL(10,2) DEFAULT 0,
    avg_delivery_time INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(date, restaurant_id, driver_id)
);

ALTER TABLE order_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurant owners can view own analytics" ON order_analytics FOR SELECT 
    USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));
CREATE POLICY "Drivers can view own analytics" ON order_analytics FOR SELECT 
    USING (driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid()));

-- ============================================================================
-- APP SETTINGS TABLE
-- ============================================================================
CREATE TABLE app_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view app settings" ON app_settings FOR SELECT USING (true);

-- ============================================================================
-- APP VERSIONS TABLE
-- ============================================================================
CREATE TABLE app_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform VARCHAR(20) NOT NULL, -- ios, android
    app_type VARCHAR(20) NOT NULL, -- customer, restaurant, driver
    version VARCHAR(20) NOT NULL,
    build_number INTEGER NOT NULL,
    min_supported_version VARCHAR(20) NOT NULL,
    force_update BOOLEAN DEFAULT false,
    release_notes TEXT,
    download_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active app versions" ON app_versions FOR SELECT USING (is_active = true);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_referral_code ON users(referral_code);

-- Addresses indexes
CREATE INDEX idx_addresses_user_id ON addresses(user_id);
CREATE INDEX idx_addresses_is_default ON addresses(user_id, is_default) WHERE is_default = true;

-- Categories indexes
CREATE INDEX idx_categories_is_active ON categories(is_active);
CREATE INDEX idx_categories_sort_order ON categories(sort_order);

-- Restaurants indexes
CREATE INDEX idx_restaurants_cuisine ON restaurants(cuisine);
CREATE INDEX idx_restaurants_is_featured ON restaurants(is_featured) WHERE is_featured = true;
CREATE INDEX idx_restaurants_is_open ON restaurants(is_open) WHERE is_open = true;
CREATE INDEX idx_restaurants_location ON restaurants(latitude, longitude);
CREATE INDEX idx_restaurants_rating ON restaurants(rating DESC);
CREATE INDEX idx_restaurants_owner_id ON restaurants(owner_id);

-- Restaurant hours indexes
CREATE INDEX idx_restaurant_hours_restaurant_id ON restaurant_hours(restaurant_id);
CREATE INDEX idx_restaurant_hours_day_of_week ON restaurant_hours(day_of_week);

-- Restaurant staff indexes
CREATE INDEX idx_restaurant_staff_restaurant_id ON restaurant_staff(restaurant_id);
CREATE INDEX idx_restaurant_staff_user_id ON restaurant_staff(user_id);

-- Menu categories indexes
CREATE INDEX idx_menu_categories_restaurant_id ON menu_categories(restaurant_id);
CREATE INDEX idx_menu_categories_sort_order ON menu_categories(sort_order);

-- Food items indexes
CREATE INDEX idx_food_items_restaurant_id ON food_items(restaurant_id);
CREATE INDEX idx_food_items_menu_category_id ON food_items(menu_category_id);
CREATE INDEX idx_food_items_category ON food_items(category);
CREATE INDEX idx_food_items_is_popular ON food_items(is_popular) WHERE is_popular = true;
CREATE INDEX idx_food_items_is_available ON food_items(is_available) WHERE is_available = true;
CREATE INDEX idx_food_items_price ON food_items(price);

-- Food addons indexes
CREATE INDEX idx_food_addons_food_item_id ON food_addons(food_item_id);

-- Drivers indexes
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_is_available ON drivers(is_available) WHERE is_available = true;
CREATE INDEX idx_drivers_is_verified ON drivers(is_verified) WHERE is_verified = true;

-- Driver locations indexes
CREATE INDEX idx_driver_locations_driver_id ON driver_locations(driver_id);
CREATE INDEX idx_driver_locations_timestamp ON driver_locations(timestamp DESC);

-- Cart items indexes
CREATE INDEX idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX idx_cart_items_food_item_id ON cart_items(food_item_id);
CREATE INDEX idx_cart_items_restaurant_id ON cart_items(restaurant_id);
CREATE INDEX idx_cart_items_created_at ON cart_items(created_at DESC);

-- Cart item addons indexes
CREATE INDEX idx_cart_item_addons_cart_item_id ON cart_item_addons(cart_item_id);

-- Orders indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_restaurant_id ON orders(restaurant_id);
CREATE INDEX idx_orders_driver_id ON orders(driver_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_scheduled_for ON orders(scheduled_for) WHERE is_scheduled = true;

-- Order items indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_food_item_id ON order_items(food_item_id);

-- Order item addons indexes
CREATE INDEX idx_order_item_addons_order_item_id ON order_item_addons(order_item_id);

-- Order status history indexes
CREATE INDEX idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX idx_order_status_history_created_at ON order_status_history(created_at DESC);

-- Reviews indexes
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_order_id ON reviews(order_id);
CREATE INDEX idx_reviews_restaurant_id ON reviews(restaurant_id);
CREATE INDEX idx_reviews_food_item_id ON reviews(food_item_id);
CREATE INDEX idx_reviews_driver_id ON reviews(driver_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- Favorites indexes
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_restaurant_id ON favorites(restaurant_id);
CREATE INDEX idx_favorites_food_item_id ON favorites(food_item_id);

-- Coupons indexes
CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_coupons_is_active ON coupons(is_active) WHERE is_active = true;
CREATE INDEX idx_coupons_restaurant_id ON coupons(restaurant_id);

-- User coupon usage indexes
CREATE INDEX idx_user_coupon_usage_user_id ON user_coupon_usage(user_id);
CREATE INDEX idx_user_coupon_usage_coupon_id ON user_coupon_usage(coupon_id);
CREATE INDEX idx_user_coupon_usage_order_id ON user_coupon_usage(order_id);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Device tokens indexes
CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_is_active ON device_tokens(is_active) WHERE is_active = true;

-- Wallet indexes
CREATE INDEX idx_user_wallets_user_id ON user_wallets(user_id);

-- Wallet transactions indexes
CREATE INDEX idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_transactions_order_id ON wallet_transactions(order_id);
CREATE INDEX idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);

-- Payment transactions indexes
CREATE INDEX idx_payment_transactions_order_id ON payment_transactions(order_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_created_at ON payment_transactions(created_at DESC);

-- Earnings indexes
CREATE INDEX idx_earnings_user_id ON earnings(user_id);
CREATE INDEX idx_earnings_order_id ON earnings(order_id);
CREATE INDEX idx_earnings_status ON earnings(status);
CREATE INDEX idx_earnings_created_at ON earnings(created_at DESC);

-- Driver earnings summary indexes
CREATE INDEX idx_driver_earnings_summary_driver_id ON driver_earnings_summary(driver_id);

-- Restaurant earnings summary indexes
CREATE INDEX idx_restaurant_earnings_summary_restaurant_id ON restaurant_earnings_summary(restaurant_id);

-- Payout requests indexes
CREATE INDEX idx_payout_requests_user_id ON payout_requests(user_id);
CREATE INDEX idx_payout_requests_status ON payout_requests(status);
CREATE INDEX idx_payout_requests_created_at ON payout_requests(created_at DESC);

-- Support tickets indexes
CREATE INDEX idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_support_tickets_created_at ON support_tickets(created_at DESC);

-- Support messages indexes
CREATE INDEX idx_support_messages_ticket_id ON support_messages(ticket_id);
CREATE INDEX idx_support_messages_created_at ON support_messages(created_at DESC);

-- Referral codes indexes
CREATE INDEX idx_referral_codes_user_id ON referral_codes(user_id);
CREATE INDEX idx_referral_codes_code ON referral_codes(code);

-- Referrals indexes
CREATE INDEX idx_referrals_referrer_id ON referrals(referrer_id);
CREATE INDEX idx_referrals_referee_id ON referrals(referee_id);
CREATE INDEX idx_referrals_status ON referrals(status);

-- Restaurant subscriptions indexes
CREATE INDEX idx_restaurant_subscriptions_restaurant_id ON restaurant_subscriptions(restaurant_id);
CREATE INDEX idx_restaurant_subscriptions_status ON restaurant_subscriptions(status);

-- Order analytics indexes
CREATE INDEX idx_order_analytics_date ON order_analytics(date DESC);
CREATE INDEX idx_order_analytics_restaurant_id ON order_analytics(restaurant_id);
CREATE INDEX idx_order_analytics_driver_id ON order_analytics(driver_id);

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_addresses_updated_at BEFORE UPDATE ON addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cuisines_updated_at BEFORE UPDATE ON cuisines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_restaurants_updated_at BEFORE UPDATE ON restaurants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menu_categories_updated_at BEFORE UPDATE ON menu_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_food_items_updated_at BEFORE UPDATE ON food_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_promo_banners_updated_at BEFORE UPDATE ON promo_banners
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_home_services_updated_at BEFORE UPDATE ON home_services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_coupons_updated_at BEFORE UPDATE ON coupons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cart_items_updated_at BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_wallets_updated_at BEFORE UPDATE ON user_wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_device_tokens_updated_at BEFORE UPDATE ON device_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCTION TO GENERATE ORDER NUMBER
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    order_count INTEGER;
    order_num VARCHAR(50);
BEGIN
    SELECT COUNT(*) + 1 INTO order_count FROM orders WHERE DATE(created_at) = CURRENT_DATE;
    order_num := 'MTF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(order_count::TEXT, 6, '0');
    NEW.order_number := order_num;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for order number generation
CREATE TRIGGER generate_order_number_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    WHEN (NEW.order_number IS NULL)
    EXECUTE FUNCTION generate_order_number();

-- ============================================================================
-- FUNCTION TO UPDATE ORDER STATUS HISTORY
-- ============================================================================
CREATE OR REPLACE FUNCTION update_order_status_history()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO order_status_history (order_id, status, note)
        VALUES (NEW.id, NEW.status, 'Status changed from ' || OLD.status || ' to ' || NEW.status);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER track_order_status_changes
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_order_status_history();

-- ============================================================================
-- FUNCTION TO GENERATE REFERRAL CODE
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER AS $$
DECLARE
    ref_code VARCHAR(50);
BEGIN
    IF NEW.referral_code IS NULL THEN
        ref_code := UPPER(SUBSTRING(NEW.name FROM 1 FOR 3)) || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        NEW.referral_code := ref_code;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER generate_user_referral_code
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION generate_referral_code();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Popular Restaurants View
CREATE OR REPLACE VIEW popular_restaurants AS
SELECT 
    r.*,
    COUNT(DISTINCT o.id) as order_count,
    COUNT(DISTINCT f.id) as food_items_count
FROM restaurants r
LEFT JOIN orders o ON r.id = o.restaurant_id
LEFT JOIN food_items f ON r.id = f.restaurant_id
WHERE r.is_active = true AND r.is_open = true
GROUP BY r.id
ORDER BY r.rating DESC, r.review_count DESC;

-- Order Summary View
CREATE OR REPLACE VIEW order_summary AS
SELECT 
    o.id,
    o.order_number,
    o.status,
    o.order_type,
    o.total,
    o.payment_method,
    o.payment_status,
    o.created_at,
    u.name as customer_name,
    u.phone as customer_phone,
    u.email as customer_email,
    r.name as restaurant_name,
    r.phone as restaurant_phone,
    d.name as driver_name,
    d.phone as driver_phone
FROM orders o
LEFT JOIN users u ON o.user_id = u.id
LEFT JOIN restaurants r ON o.restaurant_id = r.id
LEFT JOIN drivers dr ON o.driver_id = dr.id
LEFT JOIN users d ON dr.user_id = d.id;

-- Active Drivers View
CREATE OR REPLACE VIEW active_drivers AS
SELECT 
    d.*,
    u.name,
    u.phone,
    u.email,
    u.avatar_url
FROM drivers d
INNER JOIN users u ON d.user_id = u.id
WHERE d.is_available = true 
  AND d.is_verified = true 
  AND d.is_active = true
  AND u.is_active = true;

-- ============================================================================
-- SEED DATA: HOME SERVICES
-- ============================================================================
INSERT INTO home_services (id, name, icon_url, route, is_available, size, sort_order) VALUES
('courier', 'Coursier', 'https://cdn-icons-png.flaticon.com/512/2830/2830305.png', '/home/courier', true, 'large', 1),
('restaurants', 'Restaurants', 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png', '/home/restaurants', true, 'large', 2),
('groceries', 'Courses', 'https://cdn-icons-png.flaticon.com/512/3724/3724788.png', '/home/groceries', false, 'small', 3),
('boutiques', 'Boutiques', 'https://cdn-icons-png.flaticon.com/512/3225/3225194.png', '/home/boutiques', false, 'small', 4),
('pharmacies', 'Pharmacies', 'https://cdn-icons-png.flaticon.com/512/2382/2382533.png', '/home/pharmacies', false, 'small', 5)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SEED DATA: APP SETTINGS
-- ============================================================================
INSERT INTO app_settings (key, value, description) VALUES
('platform_commission', '{"percentage": 15, "type": "percentage"}'::jsonb, 'Default platform commission rate'),
('delivery_radius', '{"max_km": 20}'::jsonb, 'Maximum delivery radius in kilometers'),
('min_order_value', '{"amount": 5.00}'::jsonb, 'Minimum order value'),
('currency', '{"code": "USD", "symbol": "$"}'::jsonb, 'Default currency'),
('tax_rate', '{"percentage": 10}'::jsonb, 'Default tax rate percentage')
ON CONFLICT (key) DO NOTHING;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
-- 
-- DEPLOYMENT NOTES:
-- 1. Run this schema on a fresh Supabase project
-- 2. Configure Supabase Auth for email/phone authentication
-- 3. Set up storage buckets for: avatars, food_items, restaurants, documents
-- 4. Configure Realtime for: orders, driver_locations tables
-- 5. Set up Edge Functions for: payment processing, notifications, order matching
-- 6. Configure environment variables for payment gateways
-- 7. Set up scheduled functions for: analytics, earnings calculations, subscriptions
-- 
-- SECURITY CHECKLIST:
-- ✓ Row Level Security (RLS) enabled on all tables
-- ✓ Policies defined for customer, restaurant owner, and driver roles
-- ✓ Sensitive data (bank accounts, transactions) properly protected
-- ✓ Foreign key constraints to maintain data integrity
-- ✓ Indexes for query performance
-- ✓ Triggers for automatic updates and logging
-- 
-- ============================================================================
-- ============================================================================
-- MTF Delivery - Professional Add-ons & Enterprise Features
-- ============================================================================
-- These additional tables enhance the core schema with enterprise-grade features
-- Run this AFTER the main schema file
-- ============================================================================

-- ============================================================================
-- LOYALTY POINTS SYSTEM
-- ============================================================================
CREATE TABLE IF NOT EXISTS loyalty_programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    points_per_dollar DECIMAL(5,2) DEFAULT 1.00, -- How many points per $1 spent
    welcome_bonus INTEGER DEFAULT 100,
    birthday_bonus INTEGER DEFAULT 50,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_loyalty_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_points INTEGER DEFAULT 0,
    lifetime_points INTEGER DEFAULT 0,
    tier VARCHAR(50) DEFAULT 'bronze', -- bronze, silver, gold, platinum
    tier_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS loyalty_point_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL, -- Positive for earned, negative for redeemed
    type VARCHAR(50) NOT NULL, -- earned, redeemed, expired, bonus, adjustment
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    description TEXT,
    balance_after INTEGER NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Loyalty tier benefits
CREATE TABLE IF NOT EXISTS loyalty_tier_benefits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tier VARCHAR(50) NOT NULL, -- bronze, silver, gold, platinum
    min_lifetime_points INTEGER NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    free_delivery_threshold DECIMAL(10,2),
    priority_support BOOLEAN DEFAULT false,
    exclusive_deals BOOLEAN DEFAULT false,
    benefits JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE loyalty_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_loyalty_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tier_benefits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view loyalty programs" ON loyalty_programs FOR SELECT USING (is_active = true);
CREATE POLICY "Users can view own loyalty points" ON user_loyalty_points FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can view own loyalty transactions" ON loyalty_point_transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Anyone can view tier benefits" ON loyalty_tier_benefits FOR SELECT USING (true);

-- ============================================================================
-- SURGE PRICING / DYNAMIC PRICING
-- ============================================================================
CREATE TABLE IF NOT EXISTS surge_pricing_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    multiplier DECIMAL(5,2) NOT NULL, -- 1.5 = 50% increase
    day_of_week INTEGER[], -- Array of days (0-6)
    start_time TIME,
    end_time TIME,
    applies_to VARCHAR(50) DEFAULT 'all', -- all, delivery_fee, restaurant_id
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    min_orders_threshold INTEGER, -- Activate when orders exceed this
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS active_surge_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_name VARCHAR(255) NOT NULL,
    polygon_coordinates JSONB NOT NULL, -- GeoJSON polygon
    current_multiplier DECIMAL(5,2) NOT NULL,
    reason VARCHAR(255), -- 'High demand', 'Weather', 'Event'
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE surge_pricing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_surge_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view surge rules" ON surge_pricing_rules FOR SELECT USING (is_active = true);
CREATE POLICY "Anyone can view active surge zones" ON active_surge_zones FOR SELECT USING (true);

-- ============================================================================
-- IN-APP CHAT SYSTEM (Customer <-> Driver, Customer <-> Restaurant, Customer <-> Support)
-- ============================================================================
CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- customer_driver, customer_restaurant, customer_support
    participant_1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    participant_2_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'active', -- active, closed
    last_message_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text', -- text, image, location, audio
    media_url TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own conversations" ON chat_conversations FOR SELECT 
    USING (participant_1_id = auth.uid() OR participant_2_id = auth.uid());
CREATE POLICY "Users can create conversations" ON chat_conversations FOR INSERT 
    WITH CHECK (participant_1_id = auth.uid());
CREATE POLICY "Users can view own messages" ON chat_messages FOR SELECT 
    USING (conversation_id IN (
        SELECT id FROM chat_conversations 
        WHERE participant_1_id = auth.uid() OR participant_2_id = auth.uid()
    ));
CREATE POLICY "Users can send messages" ON chat_messages FOR INSERT 
    WITH CHECK (sender_id = auth.uid());

-- ============================================================================
-- SCHEDULED ORDERS & CATERING
-- ============================================================================
CREATE TABLE IF NOT EXISTS catering_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    serves_count INTEGER NOT NULL, -- Minimum people served
    price DECIMAL(10,2) NOT NULL,
    advance_notice_hours INTEGER DEFAULT 24, -- Minimum hours notice required
    items JSONB, -- Array of food items included
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE catering_packages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view catering packages" ON catering_packages FOR SELECT USING (is_available = true);

-- ============================================================================
-- GROUP ORDERS / SPLIT PAYMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID UNIQUE NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    organizer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invite_code VARCHAR(50) UNIQUE NOT NULL,
    deadline TIMESTAMP WITH TIME ZONE,
    max_participants INTEGER DEFAULT 10,
    status VARCHAR(50) DEFAULT 'open', -- open, closed, ordered
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS group_order_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_order_id UUID NOT NULL REFERENCES group_orders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    items JSONB, -- Their selected items
    subtotal DECIMAL(10,2) DEFAULT 0,
    payment_status VARCHAR(50) DEFAULT 'pending', -- pending, paid
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(group_order_id, user_id)
);

ALTER TABLE group_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_order_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view group orders they're in" ON group_orders FOR SELECT 
    USING (organizer_id = auth.uid() OR id IN (
        SELECT group_order_id FROM group_order_participants WHERE user_id = auth.uid()
    ));
CREATE POLICY "Users can create group orders" ON group_orders FOR INSERT 
    WITH CHECK (organizer_id = auth.uid());
CREATE POLICY "Users can view own participation" ON group_order_participants FOR SELECT 
    USING (user_id = auth.uid());
CREATE POLICY "Users can join group orders" ON group_order_participants FOR INSERT 
    WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- PEAK HOURS & RESTAURANT AVAILABILITY
-- ============================================================================
CREATE TABLE IF NOT EXISTS restaurant_peak_hours (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL, -- 0-6
    peak_start TIME NOT NULL,
    peak_end TIME NOT NULL,
    avg_wait_time INTEGER, -- Additional wait time in minutes
    discount_percentage DECIMAL(5,2), -- Off-peak discount
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE restaurant_peak_hours ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view peak hours" ON restaurant_peak_hours FOR SELECT USING (true);

-- ============================================================================
-- DRIVER SHIFT MANAGEMENT
-- ============================================================================
CREATE TABLE IF NOT EXISTS driver_shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    shift_start TIMESTAMP WITH TIME ZONE NOT NULL,
    shift_end TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, active, completed, cancelled
    break_duration INTEGER DEFAULT 0, -- Total break time in minutes
    total_deliveries INTEGER DEFAULT 0,
    total_earnings DECIMAL(10,2) DEFAULT 0,
    total_distance DECIMAL(10,2) DEFAULT 0, -- in km
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver_breaks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id UUID NOT NULL REFERENCES driver_shifts(id) ON DELETE CASCADE,
    break_start TIMESTAMP WITH TIME ZONE NOT NULL,
    break_end TIMESTAMP WITH TIME ZONE,
    duration INTEGER, -- in minutes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE driver_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_breaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drivers can view own shifts" ON driver_shifts FOR SELECT 
    USING (driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid()));
CREATE POLICY "Drivers can manage own breaks" ON driver_breaks FOR ALL 
    USING (shift_id IN (
        SELECT id FROM driver_shifts WHERE driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    ));

-- ============================================================================
-- RESTAURANT BUSY INDICATOR
-- ============================================================================
CREATE TABLE IF NOT EXISTS restaurant_capacity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID UNIQUE NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    current_orders_count INTEGER DEFAULT 0,
    max_concurrent_orders INTEGER DEFAULT 20,
    status VARCHAR(50) DEFAULT 'normal', -- normal, busy, very_busy, closed
    estimated_prep_time INTEGER, -- Current estimated prep time
    auto_pause_threshold INTEGER DEFAULT 25, -- Auto-pause at this many orders
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE restaurant_capacity ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view restaurant capacity" ON restaurant_capacity FOR SELECT USING (true);

-- ============================================================================
-- AUTOMATED PROMOTIONS ENGINE
-- ============================================================================
CREATE TABLE IF NOT EXISTS automated_promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    trigger_type VARCHAR(50) NOT NULL, -- first_order, inactive_user, birthday, milestone, weather
    trigger_conditions JSONB, -- {"inactive_days": 30, "min_previous_orders": 3}
    discount_type VARCHAR(20) NOT NULL, -- percentage, fixed, free_delivery
    discount_value DECIMAL(10,2) NOT NULL,
    max_discount DECIMAL(10,2),
    valid_duration_hours INTEGER DEFAULT 24,
    max_uses_per_user INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_automated_promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    promotion_id UUID NOT NULL REFERENCES automated_promotions(id) ON DELETE CASCADE,
    promo_code VARCHAR(50) UNIQUE NOT NULL,
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'active' -- active, used, expired
);

ALTER TABLE automated_promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_automated_promotions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active promotions" ON automated_promotions FOR SELECT USING (is_active = true);
CREATE POLICY "Users can view own auto promotions" ON user_automated_promotions FOR SELECT USING (user_id = auth.uid());

-- ============================================================================
-- FOOD ITEM VARIANTS (Size, Crust, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS food_item_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    food_item_id UUID NOT NULL REFERENCES food_items(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL, -- 'Size', 'Crust Type', 'Temperature'
    type VARCHAR(50) NOT NULL, -- single_select, multi_select
    is_required BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS food_item_variant_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    variant_id UUID NOT NULL REFERENCES food_item_variants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL, -- 'Small', 'Medium', 'Large'
    price_adjustment DECIMAL(10,2) DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE food_item_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_item_variant_options ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view variants" ON food_item_variants FOR SELECT USING (true);
CREATE POLICY "Anyone can view variant options" ON food_item_variant_options FOR SELECT USING (is_available = true);

-- Track selected variants in orders
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS selected_variants JSONB; -- Store variant selections
ALTER TABLE cart_items ADD COLUMN IF NOT EXISTS selected_variants JSONB;

-- ============================================================================
-- RESTAURANT TAGS & FILTERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS restaurant_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(50) NOT NULL, -- dietary, cuisine, feature, award
    icon_url TEXT,
    color VARCHAR(20),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS restaurant_tag_assignments (
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES restaurant_tags(id) ON DELETE CASCADE,
    PRIMARY KEY (restaurant_id, tag_id)
);

ALTER TABLE restaurant_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_tag_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view tags" ON restaurant_tags FOR SELECT USING (true);
CREATE POLICY "Anyone can view tag assignments" ON restaurant_tag_assignments FOR SELECT USING (true);

-- Popular tags: 'Halal', 'Vegan Options', 'Top Rated', 'Fast Delivery', 'New', 'Healthy', 'Award Winner'

-- ============================================================================
-- ORDER FEEDBACK & ISSUES
-- ============================================================================
CREATE TABLE IF NOT EXISTS order_issues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    issue_type VARCHAR(100) NOT NULL, -- wrong_item, missing_item, cold_food, late_delivery, quality
    description TEXT,
    images TEXT[],
    compensation_type VARCHAR(50), -- refund, credit, redelivery, none
    compensation_amount DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'reported', -- reported, investigating, resolved, rejected
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE order_issues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own order issues" ON order_issues FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can report order issues" ON order_issues FOR INSERT WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- SAVED PAYMENT METHODS (Tokenized)
-- ============================================================================
CREATE TABLE IF NOT EXISTS saved_payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    payment_type VARCHAR(50) NOT NULL, -- card, paypal, apple_pay, google_pay
    card_last_four VARCHAR(4),
    card_brand VARCHAR(50), -- visa, mastercard, amex
    card_expiry_month INTEGER,
    card_expiry_year INTEGER,
    payment_token TEXT NOT NULL, -- Encrypted token from payment gateway
    is_default BOOLEAN DEFAULT false,
    billing_address JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE saved_payment_methods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own payment methods" ON saved_payment_methods FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- ADMIN DASHBOARD METRICS (Real-time)
-- ============================================================================
CREATE TABLE IF NOT EXISTS daily_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE UNIQUE NOT NULL,
    total_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    total_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    active_restaurants INTEGER DEFAULT 0,
    active_drivers INTEGER DEFAULT 0,
    avg_order_value DECIMAL(10,2) DEFAULT 0,
    avg_delivery_time INTEGER DEFAULT 0,
    cancellation_rate DECIMAL(5,2) DEFAULT 0,
    customer_satisfaction DECIMAL(3,2) DEFAULT 0, -- Average rating
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- FRAUD DETECTION FLAGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS fraud_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    alert_type VARCHAR(100) NOT NULL, -- multiple_cancellations, payment_mismatch, fake_gps, promo_abuse
    severity VARCHAR(20) DEFAULT 'medium', -- low, medium, high, critical
    description TEXT,
    auto_detected BOOLEAN DEFAULT true,
    status VARCHAR(50) DEFAULT 'pending', -- pending, investigating, resolved, false_positive
    investigated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE fraud_alerts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INDEXES FOR NEW TABLES
-- ============================================================================
CREATE INDEX idx_loyalty_point_transactions_user_id ON loyalty_point_transactions(user_id);
CREATE INDEX idx_loyalty_point_transactions_created_at ON loyalty_point_transactions(created_at DESC);
CREATE INDEX idx_chat_conversations_order_id ON chat_conversations(order_id);
CREATE INDEX idx_chat_conversations_participants ON chat_conversations(participant_1_id, participant_2_id);
CREATE INDEX idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX idx_group_order_participants_group_order_id ON group_order_participants(group_order_id);
CREATE INDEX idx_driver_shifts_driver_id ON driver_shifts(driver_id);
CREATE INDEX idx_driver_shifts_status ON driver_shifts(status);
CREATE INDEX idx_restaurant_capacity_status ON restaurant_capacity(status);
CREATE INDEX idx_user_automated_promotions_user_id ON user_automated_promotions(user_id);
CREATE INDEX idx_user_automated_promotions_status ON user_automated_promotions(status);
CREATE INDEX idx_food_item_variants_food_item_id ON food_item_variants(food_item_id);
CREATE INDEX idx_food_item_variant_options_variant_id ON food_item_variant_options(variant_id);
CREATE INDEX idx_order_issues_order_id ON order_issues(order_id);
CREATE INDEX idx_order_issues_status ON order_issues(status);
CREATE INDEX idx_saved_payment_methods_user_id ON saved_payment_methods(user_id);
CREATE INDEX idx_fraud_alerts_user_id ON fraud_alerts(user_id);
CREATE INDEX idx_fraud_alerts_status ON fraud_alerts(status);
CREATE INDEX idx_fraud_alerts_severity ON fraud_alerts(severity);

-- ============================================================================
-- SEED DATA: LOYALTY TIER BENEFITS
-- ============================================================================
INSERT INTO loyalty_tier_benefits (tier, min_lifetime_points, discount_percentage, free_delivery_threshold, priority_support, exclusive_deals, benefits) VALUES
('bronze', 0, 0, NULL, false, false, '{"description": "Welcome to MTF Delivery!"}'::jsonb),
('silver', 1000, 5, 15.00, false, true, '{"description": "5% off all orders, Free delivery on orders over $15"}'::jsonb),
('gold', 5000, 10, 10.00, true, true, '{"description": "10% off all orders, Free delivery on orders over $10, Priority support"}'::jsonb),
('platinum', 15000, 15, NULL, true, true, '{"description": "15% off all orders, Always free delivery, Priority support, Exclusive deals"}'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SEED DATA: RESTAURANT TAGS
-- ============================================================================
INSERT INTO restaurant_tags (name, category, color, sort_order) VALUES
('Halal', 'dietary', '#00A86B', 1),
('Vegan Options', 'dietary', '#90EE90', 2),
('Gluten-Free', 'dietary', '#FFA500', 3),
('Top Rated', 'award', '#FFD700', 4),
('Fast Delivery', 'feature', '#FF6347', 5),
('New', 'feature', '#1E90FF', 6),
('Healthy', 'feature', '#32CD32', 7),
('Award Winner', 'award', '#FFD700', 8),
('Family Friendly', 'feature', '#FF69B4', 9),
('Late Night', 'feature', '#4B0082', 10)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- AUTOMATED FUNCTIONS
-- ============================================================================

-- Function to calculate loyalty points on order completion
CREATE OR REPLACE FUNCTION award_loyalty_points()
RETURNS TRIGGER AS $$
DECLARE
    points_earned INTEGER;
    current_balance INTEGER;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Calculate points (1 point per dollar by default)
        points_earned := FLOOR(NEW.total);
        
        -- Get current balance
        SELECT total_points INTO current_balance
        FROM user_loyalty_points
        WHERE user_id = NEW.user_id;
        
        -- If user doesn't have loyalty account, create one
        IF current_balance IS NULL THEN
            INSERT INTO user_loyalty_points (user_id, total_points, lifetime_points)
            VALUES (NEW.user_id, points_earned, points_earned);
            current_balance := 0;
        ELSE
            -- Update points
            UPDATE user_loyalty_points
            SET total_points = total_points + points_earned,
                lifetime_points = lifetime_points + points_earned,
                updated_at = NOW()
            WHERE user_id = NEW.user_id;
        END IF;
        
        -- Record transaction
        INSERT INTO loyalty_point_transactions (user_id, points, type, order_id, description, balance_after, expires_at)
        VALUES (
            NEW.user_id,
            points_earned,
            'earned',
            NEW.id,
            'Points earned from order ' || NEW.order_number,
            current_balance + points_earned,
            NOW() + INTERVAL '1 year'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER award_loyalty_points_trigger
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION award_loyalty_points();

-- Function to update restaurant capacity
CREATE OR REPLACE FUNCTION update_restaurant_capacity()
RETURNS TRIGGER AS $$
DECLARE
    active_orders INTEGER;
    max_orders INTEGER;
    new_status VARCHAR(50);
BEGIN
    -- Count active orders for this restaurant
    SELECT COUNT(*) INTO active_orders
    FROM orders
    WHERE restaurant_id = NEW.restaurant_id
    AND status IN ('pending', 'confirmed', 'preparing');
    
    -- Get max capacity
    SELECT max_concurrent_orders INTO max_orders
    FROM restaurant_capacity
    WHERE restaurant_id = NEW.restaurant_id;
    
    -- Determine status
    IF active_orders >= max_orders * 0.9 THEN
        new_status := 'very_busy';
    ELSIF active_orders >= max_orders * 0.6 THEN
        new_status := 'busy';
    ELSE
        new_status := 'normal';
    END IF;
    
    -- Update capacity
    UPDATE restaurant_capacity
    SET current_orders_count = active_orders,
        status = new_status,
        estimated_prep_time = CASE
            WHEN new_status = 'very_busy' THEN 45
            WHEN new_status = 'busy' THEN 30
            ELSE 15
        END,
        last_updated = NOW()
    WHERE restaurant_id = NEW.restaurant_id;
    
    -- Create capacity record if doesn't exist
    IF NOT FOUND THEN
        INSERT INTO restaurant_capacity (restaurant_id, current_orders_count, status)
        VALUES (NEW.restaurant_id, active_orders, new_status);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_restaurant_capacity_trigger
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_restaurant_capacity();

-- ============================================================================
-- VIEWS FOR ANALYTICS
-- ============================================================================

-- Top performing restaurants
CREATE OR REPLACE VIEW top_restaurants AS
SELECT 
    r.id,
    r.name,
    r.rating,
    COUNT(DISTINCT o.id) as total_orders,
    SUM(o.total) as total_revenue,
    AVG(o.total) as avg_order_value,
    COUNT(DISTINCT o.user_id) as unique_customers
FROM restaurants r
LEFT JOIN orders o ON r.id = o.restaurant_id AND o.status = 'delivered'
WHERE r.is_active = true
GROUP BY r.id
ORDER BY total_revenue DESC
LIMIT 20;

-- Top performing drivers
CREATE OR REPLACE VIEW top_drivers AS
SELECT 
    d.id,
    u.name,
    d.rating,
    d.total_deliveries,
    COUNT(DISTINCT o.id) as orders_this_month,
    AVG(EXTRACT(EPOCH FROM (o.delivered_at - o.created_at))/60) as avg_delivery_time_minutes,
    SUM(o.delivery_fee + COALESCE(o.tips, 0)) as total_earnings_this_month
FROM drivers d
INNER JOIN users u ON d.user_id = u.id
LEFT JOIN orders o ON d.id = o.driver_id 
    AND o.status = 'delivered'
    AND o.created_at >= DATE_TRUNC('month', CURRENT_DATE)
WHERE d.is_active = true AND d.is_verified = true
GROUP BY d.id, u.name, d.rating, d.total_deliveries
ORDER BY total_earnings_this_month DESC
LIMIT 20;

-- Customer insights
CREATE OR REPLACE VIEW customer_insights AS
SELECT 
    u.id,
    u.name,
    u.email,
    COUNT(DISTINCT o.id) as total_orders,
    SUM(o.total) as lifetime_value,
    AVG(o.total) as avg_order_value,
    MAX(o.created_at) as last_order_date,
    EXTRACT(DAY FROM (NOW() - MAX(o.created_at))) as days_since_last_order,
    lp.total_points as loyalty_points,
    lp.tier as loyalty_tier
FROM users u
LEFT JOIN orders o ON u.id = o.user_id AND o.status = 'delivered'
LEFT JOIN user_loyalty_points lp ON u.id = lp.user_id
WHERE u.role = 'customer' AND u.is_active = true
GROUP BY u.id, u.name, u.email, lp.total_points, lp.tier
ORDER BY lifetime_value DESC;

-- ============================================================================
-- END OF PROFESSIONAL ADD-ONS
-- ============================================================================
