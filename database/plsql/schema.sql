-- Vehicle Service Management System - PL/SQL Database Schema

-- 1. Drop existing tables safely using PL/SQL block
DECLARE
  PROCEDURE drop_table_if_exists(p_table_name VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ' || p_table_name || ' CASCADE CONSTRAINTS';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE != -942 THEN -- ORA-00942: table or view does not exist
        RAISE;
      END IF;
  END;

  PROCEDURE drop_seq_if_exists(p_seq_name VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE \'DROP SEQUENCE \' || p_seq_name;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE != -2289 THEN -- ORA-02289: sequence does not exist
        RAISE;
      END IF;
  END;

BEGIN
  drop_table_if_exists('SESSIONS');
  drop_table_if_exists('AUDIT_LOGS');
  drop_seq_if_exists('AUDIT_LOGS_SEQ');
  drop_table_if_exists('WARNINGS');
  drop_seq_if_exists('WARNINGS_SEQ');
  drop_table_if_exists('PAYMENTS');
  drop_seq_if_exists('PAYMENTS_SEQ');
  drop_table_if_exists('COMPLAINTS');
  drop_seq_if_exists('COMPLAINTS_SEQ');
  drop_table_if_exists('SERVICE_PARTS');
  drop_seq_if_exists('SERVICE_PARTS_SEQ');
  drop_table_if_exists('SERVICES');
  drop_seq_if_exists('SERVICES_SEQ');
  drop_table_if_exists('PARTS');
  drop_seq_if_exists('PARTS_SEQ');
  drop_table_if_exists('BOOKINGS');
  drop_seq_if_exists('BOOKINGS_SEQ');
  drop_table_if_exists('WORKSHOPS');
  drop_seq_if_exists('WORKSHOPS_SEQ');
  drop_table_if_exists('VEHICLES');
  drop_seq_if_exists('VEHICLES_SEQ');
  drop_table_if_exists('USERS');
  drop_seq_if_exists('USERS_SEQ');
END;
/

-- 2. Create tables 

-- Table 1: USERS
CREATE TABLE users (
    id NUMBER(20) PRIMARY KEY,
    name VARCHAR2(255) NOT NULL,
    email VARCHAR2(255) NOT NULL UNIQUE,
    email_verified_at TIMESTAMP NULL,
    password VARCHAR2(255) NOT NULL,
    remember_token VARCHAR2(100) NULL,
    role VARCHAR2(50) DEFAULT 'owner' NOT NULL CHECK (role IN ('owner', 'workshop', 'admin')),
    phone VARCHAR2(50) NULL,
    national_id VARCHAR2(50) NULL,          -- National ID / civil registration number (added 2026-06-29)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL
);

-- Table 2: VEHICLES
CREATE TABLE vehicles (
    id NUMBER(20) PRIMARY KEY,
    user_id NUMBER(20) NOT NULL,
    make VARCHAR2(255) NOT NULL,
    model VARCHAR2(255) NOT NULL,
    year NUMBER(4) NOT NULL,
    registration_number VARCHAR2(255) NOT NULL UNIQUE,
    chassis_number VARCHAR2(255) NOT NULL UNIQUE,
    color VARCHAR2(255) NULL,
    fuel_type VARCHAR2(50) DEFAULT 'petrol' NOT NULL CHECK (fuel_type IN ('petrol', 'diesel', 'electric', 'hybrid')),
    mileage NUMBER(10) DEFAULT 0 NOT NULL,
    status VARCHAR2(50) DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_vehicles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table 3: WORKSHOPS
CREATE TABLE workshops (
    id NUMBER(20) PRIMARY KEY,
    user_id NUMBER(20) NOT NULL,
    name VARCHAR2(255) NOT NULL,
    owner_name VARCHAR2(255) NOT NULL,
    phone VARCHAR2(255) NOT NULL,
    email VARCHAR2(255) NULL,
    address CLOB NOT NULL,
    latitude NUMBER(10, 7) NULL,
    longitude NUMBER(10, 7) NULL,
    city VARCHAR2(255) NOT NULL,
    license_number VARCHAR2(255) UNIQUE NULL,
    service_categories CLOB NOT NULL, -- Stored as comma-separated values or JSON
    status VARCHAR2(50) DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'inactive', 'suspended')),
    description CLOB NULL,
    bank_account VARCHAR2(255) NULL,        -- IBAN / bank account for workshop payouts (added 2026-06-29)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_workshops_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table 4: BOOKINGS
CREATE TABLE bookings (
    id NUMBER(20) PRIMARY KEY,
    user_id NUMBER(20) NOT NULL,
    vehicle_id NUMBER(20) NOT NULL,
    workshop_id NUMBER(20) NOT NULL,
    booking_date DATE NOT NULL,
    booking_time VARCHAR2(8) NULL, -- Format 'HH24:MI:SS'
    service_type VARCHAR2(255) NOT NULL,
    problem_description CLOB NULL,
    status VARCHAR2(50) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'approved', 'in_progress', 'completed', 'cancelled')),
    notes CLOB NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_bookings_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_bookings_workshop FOREIGN KEY (workshop_id) REFERENCES workshops(id) ON DELETE CASCADE
);

-- Table 5: SERVICES
CREATE TABLE services (
    id NUMBER(20) PRIMARY KEY,
    booking_id NUMBER(20) NOT NULL,
    vehicle_id NUMBER(20) NOT NULL,
    workshop_id NUMBER(20) NOT NULL,
    service_date DATE NOT NULL,
    issue_description CLOB NOT NULL,
    repair_details CLOB NOT NULL,
    labor_cost NUMBER(10,2) DEFAULT 0.00 NOT NULL,
    parts_cost NUMBER(10,2) DEFAULT 0.00 NOT NULL, -- Auto-calculated by trigger
    total_cost NUMBER(10,2) DEFAULT 0.00 NOT NULL, -- Auto-calculated by trigger
    mileage_at_service NUMBER(10) NULL,
    next_service_date DATE NULL,
    technician_name VARCHAR2(255) NULL,
    status VARCHAR2(50) DEFAULT 'completed' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_services_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    CONSTRAINT fk_services_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_services_workshop FOREIGN KEY (workshop_id) REFERENCES workshops(id) ON DELETE CASCADE
);

-- Table 6: PARTS
CREATE TABLE parts (
    id NUMBER(20) PRIMARY KEY,
    name VARCHAR2(255) NOT NULL,
    part_number VARCHAR2(255) NULL,
    category VARCHAR2(255) NULL,
    unit_price NUMBER(10,2) DEFAULT 0.00 NOT NULL,
    unit VARCHAR2(50) DEFAULT 'piece' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL
);

-- Table 7: SERVICE_PARTS
CREATE TABLE service_parts (
    id NUMBER(20) PRIMARY KEY,
    service_id NUMBER(20) NOT NULL,
    part_id NUMBER(20) NOT NULL,
    quantity NUMBER(10) DEFAULT 1 NOT NULL,
    unit_price NUMBER(10,2) NOT NULL,
    total_price NUMBER(10,2) DEFAULT 0.00 NOT NULL, -- Auto-calculated by trigger
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_service_parts_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_service_parts_part FOREIGN KEY (part_id) REFERENCES parts(id) ON DELETE CASCADE
);

-- Table 8: COMPLAINTS
CREATE TABLE complaints (
    id NUMBER(20) PRIMARY KEY,
    user_id NUMBER(20) NOT NULL,
    workshop_id NUMBER(20) NULL,
    subject VARCHAR2(255) NOT NULL,
    message CLOB NOT NULL,
    type VARCHAR2(50) DEFAULT 'complaint' NOT NULL CHECK (type IN ('complaint', 'demand', 'request', 'feedback')),
    status VARCHAR2(50) DEFAULT 'open' NOT NULL CHECK (status IN ('open', 'in_review', 'resolved', 'closed')),
    admin_reply CLOB NULL,
    replied_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_complaints_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_complaints_workshop FOREIGN KEY (workshop_id) REFERENCES workshops(id) ON DELETE SET NULL
);

-- Table 9: PAYMENTS
CREATE TABLE payments (
    id NUMBER(20) PRIMARY KEY,
    user_id NUMBER(20) NOT NULL,
    service_id NUMBER(20) NOT NULL,
    workshop_id NUMBER(20) NOT NULL,
    total_amount NUMBER(10,2) NOT NULL,
    commission_rate NUMBER(5,2) DEFAULT 2.50 NOT NULL,
    commission_amount NUMBER(10,2) NOT NULL,
    workshop_amount NUMBER(10,2) NOT NULL,
    payment_method VARCHAR2(50) DEFAULT 'card' NOT NULL,
    transaction_id VARCHAR2(255) NOT NULL UNIQUE,
    status VARCHAR2(50) DEFAULT 'completed' NOT NULL CHECK (status IN ('completed', 'pending', 'failed', 'refunded')),
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_payments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_payments_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_payments_workshop FOREIGN KEY (workshop_id) REFERENCES workshops(id) ON DELETE CASCADE
);

-- Table 10: WARNINGS
CREATE TABLE warnings (
    id NUMBER(20) PRIMARY KEY,
    workshop_id NUMBER(20) NOT NULL,
    complaint_id NUMBER(20) NULL,
    admin_id NUMBER(20) NOT NULL,
    subject VARCHAR2(255) NOT NULL,
    warning_message CLOB NOT NULL,
    severity VARCHAR2(50) DEFAULT 'medium' NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    status VARCHAR2(50) DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'acknowledged', 'resolved')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_warnings_workshop FOREIGN KEY (workshop_id) REFERENCES workshops(id) ON DELETE CASCADE,
    CONSTRAINT fk_warnings_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE SET NULL,
    CONSTRAINT fk_warnings_admin FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table 11: AUDIT_LOGS
CREATE TABLE audit_logs (
    id NUMBER(20) PRIMARY KEY,
    user_id NUMBER(20) NULL,
    action VARCHAR2(255) NOT NULL,
    model_type VARCHAR2(255) NOT NULL,
    model_id NUMBER(20) NULL,
    old_values CLOB NULL, -- Stores JSON string
    new_values CLOB NULL, -- Stores JSON string
    ip_address VARCHAR2(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Table 12: SESSIONS
CREATE TABLE sessions (
    id VARCHAR2(255) PRIMARY KEY,
    user_id NUMBER(20) NULL,
    ip_address VARCHAR2(45) NULL,
    user_agent CLOB NULL,
    payload CLOB NOT NULL,
    last_activity NUMBER(10) NOT NULL,
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Sequences and Triggers for Auto-Increment --

CREATE SEQUENCE users_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER users_trg
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := users_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE vehicles_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER vehicles_trg
BEFORE INSERT ON vehicles
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := vehicles_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE workshops_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER workshops_trg
BEFORE INSERT ON workshops
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := workshops_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE bookings_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER bookings_trg
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := bookings_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE services_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER services_trg
BEFORE INSERT ON services
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := services_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE parts_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER parts_trg
BEFORE INSERT ON parts
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := parts_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE service_parts_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER service_parts_trg
BEFORE INSERT ON service_parts
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := service_parts_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE complaints_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER complaints_trg
BEFORE INSERT ON complaints
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := complaints_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE payments_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER payments_trg
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := payments_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE warnings_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER warnings_trg
BEFORE INSERT ON warnings
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := warnings_seq.NEXTVAL;
    END IF;
END;
/

CREATE SEQUENCE audit_logs_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

CREATE OR REPLACE TRIGGER audit_logs_trg
BEFORE INSERT ON audit_logs
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := audit_logs_seq.NEXTVAL;
    END IF;
END;
/

