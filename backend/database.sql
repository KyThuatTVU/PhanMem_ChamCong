-- ============================================================
-- HỆ THỐNG QUẢN LÝ NHÂN SỰ & CHẤM CÔNG HAPPYKIDS (2 CƠ SỞ)
-- Cơ sở 1: Chi nhánh Càng Long | Cơ sở 2: Chi nhánh Tân Nhựt
-- Chuẩn hóa: PHP 7.4 - 8.x + MySQL / MariaDB (Dễ import phpMyAdmin)
-- ============================================================

CREATE DATABASE IF NOT EXISTS `happykids_hrm` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `happykids_hrm`;

-- 1. BẢNG CƠ SỞ / CHI NHÁNH
DROP TABLE IF EXISTS `branches`;
CREATE TABLE `branches` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(150) NOT NULL,
    `address` VARCHAR(255) NULL,
    `phone` VARCHAR(50) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `branches` (`id`, `code`, `name`, `address`, `phone`) VALUES
(1, 'cang_long', 'Chi nhánh Càng Long', 'Càng Long, Trà Vinh', '094948029'),
(2, 'tan_nhut', 'Chi nhánh Tân Nhựt', 'Tân Nhựt, Bình Chánh, TP.HCM', '0912345678');

-- 2. BẢNG NGƯỜI DÙNG & TÀI KHOẢN (ĐĂNG NHẬP GOOGLE)
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `google_id` VARCHAR(100) NULL UNIQUE,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `name` VARCHAR(150) NOT NULL,
    `avatar` VARCHAR(500) NULL,
    `role` ENUM('SUPER_ADMIN', 'ADMIN_CANGLONG', 'ADMIN_TANNHUT', 'VIEWER') DEFAULT 'SUPER_ADMIN',
    `branch_id` INT NULL,
    `status` ENUM('ACTIVE', 'BLOCKED') DEFAULT 'ACTIVE',
    `last_login` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`branch_id`) REFERENCES `branches`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. BẢNG CẤU HÌNH THAM SỐ HỆ THỐNG
DROP TABLE IF EXISTS `system_config`;
CREATE TABLE `system_config` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `branch_id` INT NOT NULL,
    `standard_work_days` INT DEFAULT 26 COMMENT 'Số ngày công chuẩn trong tháng (26 ngày)',
    `standard_day_minutes` INT DEFAULT 480 COMMENT 'Thời gian chuẩn 1 ngày mặc định (480p = 8h)',
    `slot_duration_minutes` INT DEFAULT 90 COMMENT 'Thời gian 1 ca chuẩn lương giờ (90p)',
    `default_ot_rate` DECIMAL(12,2) DEFAULT 120000 COMMENT 'Đơn giá tăng ca mặc định (VNĐ/ca)',
    `default_slot_rate` DECIMAL(12,2) DEFAULT 120000 COMMENT 'Đơn giá ca chuẩn mặc định (VNĐ/ca)',
    `lunch_allowance` DECIMAL(12,2) DEFAULT 25000 COMMENT 'Phụ cấp cơm theo ngày công (VNĐ/ngày)',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`branch_id`) REFERENCES `branches`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `system_config` (`branch_id`, `standard_work_days`, `standard_day_minutes`, `slot_duration_minutes`, `default_ot_rate`, `default_slot_rate`, `lunch_allowance`) VALUES
(1, 26, 480, 90, 120000, 120000, 25000),
(2, 26, 480, 90, 120000, 120000, 25000);

-- 4. BẢNG HỒ SƠ GIÁO VIÊN / NHÂN SỰ
DROP TABLE IF EXISTS `employees`;
CREATE TABLE `employees` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `branch_id` INT NOT NULL,
    `employee_code` VARCHAR(20) NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `position` VARCHAR(100) NULL COMMENT 'Chức vụ / Bộ phận',
    `phone` VARCHAR(30) NULL,
    `salary_type` ENUM('FIXED', 'HOURLY') NOT NULL COMMENT 'FIXED = Lương cứng, HOURLY = Lương theo giờ',
    `base_salary` DECIMAL(12,2) DEFAULT 0 COMMENT 'Mức lương tháng (Lương cứng)',
    `hourly_rate` DECIMAL(12,2) DEFAULT 0 COMMENT 'Đơn giá ca (Lương giờ)',
    `overtime_rate` DECIMAL(12,2) DEFAULT 120000 COMMENT 'Đơn giá tăng ca / ca tối',
    `attendance_allowance` DECIMAL(12,2) DEFAULT 0 COMMENT 'Phụ cấp chuyên cần',
    `boarding_allowance` DECIMAL(12,2) DEFAULT 0 COMMENT 'Phụ cấp Bán Trú (đơn giá hoặc cố định)',
    `other_allowance` DECIMAL(12,2) DEFAULT 0 COMMENT 'Phụ cấp khác',
    `time_frame` VARCHAR(100) NULL COMMENT 'Khung giờ hợp đồng (VD: 8:00 - 17:30)',
    `standard_hours` DECIMAL(4,2) DEFAULT 8.00 COMMENT 'Giờ chuẩn/ngày hoặc số ca chuẩn/buổi',
    `default_time_in` TIME NULL COMMENT 'Giờ vào quy định',
    `default_time_out` TIME NULL COMMENT 'Giờ ra quy định',
    `work_schedule` VARCHAR(100) DEFAULT 'Thứ 2 - Thứ 7',
    `status` ENUM('ACTIVE', 'LEAVE', 'RESIGNED') DEFAULT 'ACTIVE' COMMENT 'Trạng thái làm việc',
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_branch_code_type` (`branch_id`, `employee_code`, `salary_type`),
    FOREIGN KEY (`branch_id`) REFERENCES `branches`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. BẢNG CHẤM CÔNG HÀNG NGÀY (DAILY ATTENDANCE)
DROP TABLE IF EXISTS `daily_attendance`;
CREATE TABLE `daily_attendance` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `employee_id` INT NOT NULL,
    `work_date` DATE NOT NULL,
    
    -- Dành cho Lương Cứng
    `time_in` TIME NULL,
    `time_out` TIME NULL,
    `late_minutes` INT DEFAULT 0 COMMENT 'Số phút đi trễ',
    `is_overtime` TINYINT(1) DEFAULT 0 COMMENT 'Có tăng ca không',
    `ot_hours` DECIMAL(5,2) DEFAULT 0 COMMENT 'Số giờ tăng ca',
    `work_symbol` VARCHAR(10) DEFAULT '-' COMMENT 'Ký hiệu công: X, X+TC, P, K, Thiếu, -',
    `salary_symbol` VARCHAR(10) DEFAULT '-' COMMENT 'Ký hiệu tính lương',
    `ot_salary_hours` DECIMAL(5,2) DEFAULT 0 COMMENT 'Giờ TC tính lương',
    
    -- Dành cho Lương Theo Giờ (3 ca Sáng - Chiều - Tối)
    `morning_in` TIME NULL,
    `morning_out` TIME NULL,
    `morning_minutes` INT DEFAULT 0,
    `afternoon_in` TIME NULL,
    `afternoon_out` TIME NULL,
    `afternoon_minutes` INT DEFAULT 0,
    `evening_in` TIME NULL,
    `evening_out` TIME NULL,
    `evening_minutes` INT DEFAULT 0,
    `total_minutes` INT DEFAULT 0,
    `total_slots` DECIMAL(5,2) DEFAULT 0 COMMENT 'Tổng số ca (Tổng phút / 90)',
    `has_boarding` TINYINT(1) DEFAULT 0 COMMENT 'Trực Bán Trú (BT)',
    `actual_slots` DECIMAL(5,2) DEFAULT 0 COMMENT 'Số ca thực tế / chốt tính lương',
    
    `confirmation_status` VARCHAR(50) DEFAULT 'Chưa nhập',
    `notes` VARCHAR(255) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_emp_date` (`employee_id`, `work_date`),
    FOREIGN KEY (`employee_id`) REFERENCES `employees`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. BẢNG LƯƠNG TỔNG HỢP THÁNG & PHIẾU LƯƠNG (MONTHLY PAYROLL)
DROP TABLE IF EXISTS `monthly_payroll`;
CREATE TABLE `monthly_payroll` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `employee_id` INT NOT NULL,
    `month` INT NOT NULL COMMENT '1-12',
    `year` INT NOT NULL COMMENT '2026',
    
    -- Thống kê công trong tháng
    `total_days_x` DECIMAL(5,2) DEFAULT 0 COMMENT 'Tổng ngày công X thực tế',
    `total_ot_hours` DECIMAL(5,2) DEFAULT 0 COMMENT 'Tổng giờ tăng ca',
    `ot_count` INT DEFAULT 0 COMMENT 'Số lần tăng ca',
    `total_slots` DECIMAL(6,2) DEFAULT 0 COMMENT 'Tổng số ca dạy (Lương giờ)',
    `total_boarding_days` INT DEFAULT 0 COMMENT 'Số buổi bán trú (BT)',
    `late_count` INT DEFAULT 0 COMMENT 'Số lần đi trễ',
    `total_late_minutes` INT DEFAULT 0 COMMENT 'Tổng phút trễ',
    
    -- Các khoản thu nhập
    `base_salary` DECIMAL(12,2) DEFAULT 0 COMMENT 'Mức lương cơ bản thỏa thuận',
    `salary_by_days` DECIMAL(12,2) DEFAULT 0 COMMENT 'Lương theo ngày công: (Lương CB / 26) * Ngày công',
    `salary_by_slots` DECIMAL(12,2) DEFAULT 0 COMMENT 'Lương theo ca: Số ca * Đơn giá ca',
    `ot_pay` DECIMAL(12,2) DEFAULT 0 COMMENT 'Tiền tăng ca',
    `boarding_pay` DECIMAL(12,2) DEFAULT 0 COMMENT 'Phụ cấp Bán Trú',
    `attendance_allowance` DECIMAL(12,2) DEFAULT 0 COMMENT 'Chuyên cần',
    `lunch_allowance` DECIMAL(12,2) DEFAULT 0 COMMENT 'Phụ cấp cơm: 25k * Số ngày công',
    `bonus` DECIMAL(12,2) DEFAULT 0 COMMENT 'Thưởng',
    `total_income` DECIMAL(12,2) DEFAULT 0 COMMENT 'Tổng thu nhập',
    
    -- Khấu trừ & Thực lĩnh
    `deductions` DECIMAL(12,2) DEFAULT 0 COMMENT 'Các khoản khấu trừ / phạt trễ',
    `net_salary` DECIMAL(12,2) DEFAULT 0 COMMENT 'Thực lĩnh',
    
    `status` ENUM('DRAFT', 'CONFIRMED', 'PAID') DEFAULT 'DRAFT',
    `note` TEXT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_emp_month_year` (`employee_id`, `month`, `year`),
    FOREIGN KEY (`employee_id`) REFERENCES `employees`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- DỮ LIỆU SEED: DANH SÁCH GIÁO VIÊN CỦA 2 CƠ SỞ (TRÍCH XUẤT TỪ FILE EXCEL)
-- ============================================================

-- A. CƠ SỞ CÀNG LONG - LƯƠNG CỨNG
INSERT INTO `employees` (`branch_id`, `employee_code`, `full_name`, `position`, `phone`, `salary_type`, `base_salary`, `hourly_rate`, `overtime_rate`, `attendance_allowance`, `boarding_allowance`, `time_frame`, `standard_hours`, `default_time_in`, `default_time_out`) VALUES
(1, 'GV001', 'Nguyễn Thị Khánh Vy', 'GV Bán Trú & Ca Tối', '094948029', 'FIXED', 7500000, 150000, 120000, 500000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00'),
(1, 'GV002', 'Nguyễn Thị Thùy Linh', 'Giáo viên Bán Trú', '0339172169', 'FIXED', 7000000, 0, 120000, 300000, 0, '07:00 - 10:30 (3h30)', 3.50, '07:00:00', '10:30:00'),
(1, 'GV003', 'Nguyễn Thị Ngọc Trâm', 'Giáo viên Bán Trú', '0903123456', 'FIXED', 6800000, 0, 120000, 300000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00'),
(1, 'GV004', 'Trần Thị Như Ý', 'GV Bán Trú & Ca Tối', '0911223344', 'FIXED', 7200000, 150000, 120000, 400000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00'),
(1, 'GV005', 'Nguyễn Huyền Phương Tuyền', 'Giáo viên Bán Trú', '0765937501', 'FIXED', 7500000, 0, 120000, 500000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00'),
(1, 'GV006', 'Tô Thị Cẩm Tú', 'Giáo viên Bán Trú', '0868402029', 'FIXED', 7500000, 0, 120000, 500000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00'),
(1, 'GV007', 'Nguyễn Tường Vi', 'Giáo viên Bán Trú', '0933445566', 'FIXED', 7000000, 0, 120000, 300000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00'),
(1, 'GV008', 'Hồ Thị Anh Thư', 'Giáo viên Bán Trú', '0977889900', 'FIXED', 6800000, 0, 120000, 300000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00'),
(1, 'GV009', 'Dương Mỹ Duyên', 'Giáo viên Bán Trú', '0912887766', 'FIXED', 7200000, 0, 120000, 400000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00'),
(1, 'GV014', 'Ngô Thanh Ngân', 'Giáo viên Bán Trú', '0899156642', 'FIXED', 7000000, 0, 120000, 300000, 0, '8:00 - 17:30 (9h30)', 9.50, '08:00:00', '17:30:00');

-- B. CƠ SỞ CÀNG LONG - LƯƠNG THEO GIỜ
INSERT INTO `employees` (`branch_id`, `employee_code`, `full_name`, `position`, `phone`, `salary_type`, `base_salary`, `hourly_rate`, `overtime_rate`, `attendance_allowance`, `boarding_allowance`, `time_frame`, `standard_hours`, `default_time_in`, `default_time_out`) VALUES
(1, 'GV010', 'Nguyễn Huỳnh Mỹ Ngọc', 'GV Ca Buổi Tối', '0909112233', 'HOURLY', 0, 120000, 0, 0, 0, '17:30 - 19:00 (1 ca)', 1.00, '17:30:00', '19:00:00'),
(1, 'GV011', 'Nguyễn Thị Tuyết Loan', 'GV Ca Sáng', '0938112233', 'HOURLY', 0, 120000, 0, 0, 0, '08:30 - 10:00 (1 ca)', 1.00, '08:30:00', '10:00:00'),
(1, 'GV012', 'Ong Thị Mỹ Huyền', 'GV Ca Buổi Tối', '0949112233', 'HOURLY', 0, 120000, 0, 0, 0, '17:30 - 19:00 (1 ca)', 1.00, '17:30:00', '19:00:00'),
(1, 'GV013', 'Võ Thị Ngọc Thi', 'GV Ca Linh Động', '0974835460', 'HOURLY', 0, 150000, 0, 0, 0, 'Linh động (1 ca/buổi)', 1.00, NULL, NULL),
(1, 'GV014_GIO', 'Nguyễn Thị Kim Hương', 'GV Ca Linh Động', '0947028419', 'HOURLY', 0, 100000, 0, 0, 0, 'Linh động (1.5h/ca)', 1.00, NULL, NULL);

-- C. CƠ SỞ TÂN NHỰT - LƯƠNG CỨNG
INSERT INTO `employees` (`branch_id`, `employee_code`, `full_name`, `position`, `phone`, `salary_type`, `base_salary`, `hourly_rate`, `overtime_rate`, `attendance_allowance`, `boarding_allowance`, `time_frame`, `standard_hours`, `default_time_in`, `default_time_out`) VALUES
(2, 'GV001', 'Cô Hiền', 'Giáo viên Bán Trú & Ca Tối', '0912345678', 'FIXED', 6000000, 120000, 120000, 1000000, 0, '17:30 - 19:00 (1,5h)', 1.50, '17:30:00', '19:00:00'),
(2, 'GV002', 'Cô My', 'Giáo viên Bán Trú', '0987654321', 'FIXED', 7000000, 0, 120000, 300000, 500000, '06:30 - 17:00 (8h30)', 8.50, '08:30:00', '17:00:00');

-- D. CƠ SỞ TÂN NHỰT - LƯƠNG THEO GIỜ
INSERT INTO `employees` (`branch_id`, `employee_code`, `full_name`, `position`, `phone`, `salary_type`, `base_salary`, `hourly_rate`, `overtime_rate`, `attendance_allowance`, `boarding_allowance`, `time_frame`, `standard_hours`, `default_time_in`, `default_time_out`) VALUES
(2, 'GV001', 'Cô Vi', 'GV Ca Tối', '0901234567', 'HOURLY', 0, 120000, 0, 0, 0, '17:00 - 18:30 (1 ca)', 1.00, '17:00:00', '18:30:00'),
(2, 'GV002', 'Cô Loan', 'GV Ca Tối', '0902345678', 'HOURLY', 0, 120000, 0, 0, 0, '17:00 - 18:30 (1 ca)', 1.00, '17:00:00', '18:30:00'),
(2, 'GV003', 'Cô Hồng', 'GV Ca Tối', '0903456789', 'HOURLY', 0, 120000, 0, 0, 0, '17:00 - 20:00 (2 ca)', 2.00, '17:00:00', '20:00:00'),
(2, 'GV004', 'Cô Nhi', 'GV Ca Chiều - Tối', '0904567890', 'HOURLY', 0, 150000, 0, 0, 0, '14:30 - 19:30 (2 ca)', 2.00, '14:30:00', '19:30:00');


-- ============================================================
-- DỮ LIỆU ĐẦY ĐỦ THÁNG 10/2026 TRÍCH XUẤT TỪ CẢ 4 FILE EXCEL
-- NGÀY TRÍCH XUẤT: 20/10/2026 (KHÔNG BỎ SÓT BẤT KỲ DÒNG/Ô NÀO)
-- ============================================================
USE `happykids_hrm`;


-- ---------------------------------------------------------
-- 1. CHẤM CÔNG HÀNG NGÀY: CL_CUNG (Branch 1, FIXED)
-- ---------------------------------------------------------
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-01', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-01', '07:13:00', '10:41:00', 13, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-01', '06:45:00', '17:29:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-01', '07:38:00', '19:09:00', 0, 1,
    2.02, 'X + TC', 'X + TC', 2.02, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-01', '07:48:00', '17:29:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-01', '06:53:00', '16:34:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-01', '07:52:00', '17:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-01', '07:37:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-01', '07:30:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-01', '07:03:00', '16:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-02', '07:40:00', '19:06:00', 0, 1,
    1.93, 'X + TC', 'X + TC', 1.93, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-02', '07:00:00', '10:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-02', '06:47:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-02', '07:40:00', '17:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-02', '07:46:00', '17:37:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-02', '06:50:00', '16:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-02', '07:40:00', '17:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-02', '07:34:00', '17:37:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-02', '07:30:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-02', '07:15:00', '16:35:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-03', '07:43:00', '16:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-03', '07:00:00', '10:51:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-03', '06:49:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-03', '07:43:00', '19:13:00', 0, 1,
    2.0, 'X + TC', 'X + TC', 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-03', '07:56:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-03', '06:55:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-03', '07:42:00', '17:37:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-03', '07:35:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-03', '07:30:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-03', '07:10:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-04', NULL, NULL, 0, 1,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-05', '06:49:00', '17:28:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-05', '07:00:00', '10:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-05', '06:45:00', '17:28:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-05', '07:37:00', '17:00:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-05', '07:00:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-05', '07:50:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-05', '07:45:00', '17:34:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-05', '07:20:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-05', '07:20:00', '17:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-05', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-06', '07:43:00', '17:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-06', '07:00:00', '10:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-06', '06:48:00', '17:34:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-06', '07:38:00', '19:05:00', 0, 1,
    1.95, 'X + TC', 'X + TC', 1.95, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-06', '06:56:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-06', '07:52:00', '17:35:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-06', '07:44:00', '17:38:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-06', '07:26:00', '17:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-06', '07:21:00', '17:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-06', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-07', '07:42:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-07', '07:00:00', '10:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-07', '06:46:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-07', '07:36:00', '17:30:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-07', '06:47:00', '16:38:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-07', '06:50:00', '16:37:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-07', '07:47:00', '17:44:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-07', '07:26:00', '17:35:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-07', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-07', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-08', '08:00:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', ''
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-08', '06:57:00', '10:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-08', '06:41:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-08', '07:34:00', '17:30:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-08', '07:01:00', '16:29:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-08', '06:52:00', '16:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-08', '07:46:00', '17:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-08', '07:34:00', '17:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-08', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-08', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-09', '07:57:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-09', '06:59:00', '10:28:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-09', '06:44:00', '17:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-09', '07:34:00', '17:30:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-09', '06:50:00', '16:35:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-09', '06:51:00', '16:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-09', '07:49:00', '17:35:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-09', '07:35:00', '17:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-09', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-09', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-10', '08:00:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-10', '06:59:00', '10:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-10', '06:46:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-10', '07:36:00', '17:44:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-10', '06:59:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-10', '06:48:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-10', '07:51:00', '17:44:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-10', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-10', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-10', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-12', '07:49:00', '19:01:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-12', '06:58:00', '10:52:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-12', '06:43:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-12', '07:41:00', '19:10:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-12', '07:51:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-12', '06:50:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-12', '07:50:00', '17:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-12', '07:33:00', '17:34:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-12', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-12', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-13', '07:45:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-13', '06:54:00', '10:54:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-13', '06:57:00', '17:29:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-13', '07:53:00', '19:14:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-13', '06:59:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-13', '06:51:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-13', '07:51:00', '17:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-13', '07:37:00', '17:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-13', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-13', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-14', NULL, NULL, 0, 0,
    0.0, 'P', 'P', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-14', '07:00:00', '10:42:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-14', '06:48:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-14', '07:35:00', '19:24:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-14', '06:56:00', '16:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-14', '06:50:00', '16:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-14', '07:50:00', '17:36:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-14', '07:39:00', '19:24:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-14', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-14', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-15', '06:37:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-15', '07:00:00', '10:43:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-15', '06:43:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-15', '07:36:00', '19:07:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-15', '06:51:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-15', '06:44:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-15', '07:52:00', '17:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-15', '07:37:00', '19:07:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-15', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-15', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-16', '07:38:00', '19:02:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-16', '07:00:00', '10:54:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-16', '06:23:00', '17:00:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-16', '07:38:00', '19:04:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-16', '06:50:00', '16:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-16', '06:50:00', '16:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-16', '07:49:00', '17:35:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-16', '07:38:00', '17:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-16', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-16', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-17', NULL, NULL, 0, 0,
    0.0, 'P', 'P', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-17', '08:00:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-17', '06:47:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-17', '07:30:00', '17:35:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-17', '06:54:00', '16:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-17', '06:47:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-17', '07:35:00', '17:35:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-17', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-17', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-17', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-19', '07:47:00', '19:06:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-19', '07:00:00', '10:48:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-19', '06:46:00', '17:30:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-19', '07:41:00', '19:06:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-19', '06:49:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-19', '06:46:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-19', '07:47:00', '17:39:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-19', '07:36:00', '17:38:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-19', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-19', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-20', '07:35:00', '17:29:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-20', '06:58:00', '10:57:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-20', '06:39:00', '17:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-20', '07:39:00', '19:01:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-20', '06:59:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-20', '06:40:00', '16:31:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-20', '07:39:00', '17:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-20', '07:37:00', '19:01:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-20', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-20', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    1, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    2, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    3, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    4, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    5, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    6, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    7, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    8, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    9, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    10, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);

-- ---------------------------------------------------------
-- 2. TỔNG HỢP LƯƠNG THÁNG 10: CL_CUNG
-- ---------------------------------------------------------
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    1, 10, 2026, 16.0, 6.43, 4,
    0, 0, 0, 0,
    7500000.0, 4615385.0, 0, 480000.0, 0.0,
    500000.0, 400000.0, 0.0, 5995385.0, 0.0, 5995385.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    2, 10, 2026, 17.0, 0.0, 0,
    0, 0, 1, 13,
    7000000.0, 4576923.0, 0, 0.0, 0.0,
    300000.0, 425000.0, 0.0, 5301923.0, 0.0, 5301923.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    3, 10, 2026, 17.0, 0.0, 0,
    0, 0, 0, 0,
    6800000.0, 4446154.0, 0, 0.0, 0.0,
    300000.0, 425000.0, 0.0, 5171154.0, 0.0, 5171154.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    4, 10, 2026, 17.0, 20.97, 13,
    0, 0, 0, 0,
    7200000.0, 4707692.0, 0, 1560000.0, 0.0,
    400000.0, 425000.0, 0.0, 7092692.0, 0.0, 7092692.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    5, 10, 2026, 17.0, 0.0, 0,
    0, 0, 0, 0,
    7500000.0, 4903846.0, 0, 0.0, 0.0,
    500000.0, 425000.0, 0.0, 5828846.0, 0.0, 5828846.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    6, 10, 2026, 17.0, 0.0, 0,
    0, 0, 0, 0,
    7500000.0, 4903846.0, 0, 0.0, 0.0,
    500000.0, 425000.0, 0.0, 5828846.0, 0.0, 5828846.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    7, 10, 2026, 17.0, 0.0, 0,
    0, 0, 0, 0,
    7000000.0, 4576923.0, 0, 0.0, 0.0,
    300000.0, 425000.0, 0.0, 5301923.0, 0.0, 5301923.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    8, 10, 2026, 15.0, 4.5, 3,
    0, 0, 0, 0,
    6800000.0, 3923077.0, 0, 360000.0, 0.0,
    300000.0, 375000.0, 0.0, 4958077.0, 0.0, 4958077.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    9, 10, 2026, 5.0, 0.0, 0,
    0, 0, 0, 0,
    7200000.0, 1384615.0, 0, 0.0, 0.0,
    400000.0, 125000.0, 0.0, 1909615.0, 0.0, 1909615.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    10, 10, 2026, 3.0, 0.0, 0,
    0, 0, 0, 0,
    7000000.0, 807692.0, 0, 0.0, 0.0,
    300000.0, 75000.0, 0.0, 1182692.0, 0.0, 1182692.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';

-- ---------------------------------------------------------
-- 1. CHẤM CÔNG HÀNG NGÀY: CL_GIO (Branch 1, HOURLY)
-- ---------------------------------------------------------
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-01', NULL, NULL, 0,
    NULL, NULL, 0, '17:04:00', '19:10:00', 126,
    126, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca Tối (17g30-19g) - 126p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-01', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', 'Nghỉ phép (P)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-01', NULL, NULL, 0,
    NULL, NULL, 0, '17:19:00', '19:10:00', 111,
    111, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca Tối (17g30-19g) - 111p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-01', NULL, NULL, 0,
    NULL, NULL, 0, '17:02:00', '19:00:00', 118,
    118, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca Tối (17g30-19g) - 118p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-01', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-02', NULL, NULL, 0,
    NULL, NULL, 0, '17:15:00', '19:17:00', 122,
    122, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca tối 122p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-02', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', 'Ca sáng 90p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-02', NULL, NULL, 0,
    NULL, NULL, 0, '17:22:00', '19:19:00', 117,
    117, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca tối 117p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-02', NULL, NULL, 0,
    NULL, NULL, 0, '17:15:00', '19:08:00', 113,
    113, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca tối 113p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-02', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-03', NULL, NULL, 0,
    NULL, NULL, 0, '17:02:00', '19:22:00', 140,
    140, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca tối 140p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-03', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', 'Ca sáng 90p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-03', NULL, NULL, 0,
    NULL, NULL, 0, '17:25:00', '19:23:00', 118,
    118, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca tối 118p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-03', '08:00:00', '09:30:00', 90,
    NULL, NULL, 90, NULL, NULL, 134,
    314, 3.0, 0, 3.0, 'Đã xác nhận', '2 ca trong ngày = 195p (2 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-03', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-04', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 113,
    113, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-04', NULL, NULL, 105,
    NULL, NULL, 0, NULL, NULL, 0,
    105, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-04', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 102,
    102, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-04', NULL, NULL, 131,
    NULL, NULL, 93, NULL, NULL, 96,
    320, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-04', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-05', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-05', NULL, NULL, 100,
    NULL, NULL, 0, NULL, NULL, 125,
    225, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-05', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 133,
    133, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-05', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 90,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-05', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-06', NULL, NULL, 149,
    NULL, NULL, 0, NULL, NULL, 0,
    149, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-06', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 114,
    114, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-06', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 127,
    127, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-06', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 107,
    107, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-06', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-07', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-07', NULL, NULL, 105,
    NULL, NULL, 0, NULL, NULL, 0,
    105, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-07', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 120,
    120, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-07', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 121,
    121, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-07', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-08', NULL, NULL, 151,
    NULL, NULL, 0, NULL, NULL, 0,
    151, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-08', NULL, NULL, 101,
    NULL, NULL, 0, NULL, NULL, 0,
    101, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-08', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 124,
    124, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-08', NULL, NULL, 104,
    NULL, NULL, 0, NULL, NULL, 0,
    104, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-08', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-09', NULL, NULL, 150,
    NULL, NULL, 0, NULL, NULL, 0,
    150, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-09', NULL, NULL, 103,
    NULL, NULL, 0, NULL, NULL, 121,
    224, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-09', NULL, NULL, 0,
    NULL, NULL, 133, NULL, NULL, 0,
    133, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-09', NULL, NULL, 0,
    NULL, NULL, 96, NULL, NULL, 99,
    195, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-09', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-11', NULL, NULL, 117,
    NULL, NULL, 0, NULL, NULL, 173,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-11', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', 'Nghỉ việc từ hôm nay'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-11', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 109,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-11', NULL, NULL, 107,
    NULL, NULL, 100, NULL, NULL, 101,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-11', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 121,
    121, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 113,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 105,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 131,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 129,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 107,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 113,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 95, NULL, NULL, 100,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 114,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-18', NULL, NULL, 130,
    NULL, NULL, 92, NULL, NULL, 99,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-18', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-18', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 110,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-18', NULL, NULL, 120,
    NULL, NULL, 95, NULL, NULL, 98,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-18', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-19', '07:45:00', '10:47:00', 182,
    NULL, NULL, 0, '17:27:00', '19:07:00', 100,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-19', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-19', NULL, NULL, 0,
    NULL, NULL, 0, '17:16:00', '19:22:00', 126,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-19', NULL, NULL, 0,
    NULL, NULL, 0, '17:17:00', '19:18:00', 121,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-19', NULL, NULL, 0,
    NULL, NULL, 0, '17:30:00', '19:06:00', 96,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-20', '07:48:00', '10:30:00', 162,
    NULL, NULL, 0, '17:07:00', '19:02:00', 115,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-20', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-20', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-20', NULL, NULL, 0,
    NULL, NULL, 0, '17:24:00', '19:11:00', 107,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-20', NULL, NULL, 0,
    NULL, NULL, 0, '17:06:00', '19:03:00', 117,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    11, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    12, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    13, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    14, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    15, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);

-- ---------------------------------------------------------
-- 2. TỔNG HỢP LƯƠNG THÁNG 10: CL_GIO
-- ---------------------------------------------------------
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    11, 10, 2026, 0, 0, 0,
    32.0, 0, 0, 0,
    0, 0, 3840000.0, 0, 0.0,
    0, 0, 0.0, 3840000.0, 0.0, 3840000.0, NULL, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    12, 10, 2026, 0, 0, 0,
    10.0, 0, 0, 0,
    0, 0, 1200000.0, 0, 0.0,
    0, 0, 0.0, 1200000.0, 0.0, 1200000.0, NULL, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    13, 10, 2026, 0, 0, 0,
    18.0, 0, 0, 0,
    0, 0, 2160000.0, 0, 0.0,
    0, 0, 0.0, 2160000.0, 0.0, 2160000.0, NULL, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    14, 10, 2026, 0, 0, 0,
    33.0, 0, 0, 0,
    0, 0, 4950000.0, 0, 0.0,
    0, 0, 0.0, 4950000.0, 0.0, 4950000.0, NULL, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    15, 10, 2026, 0, 0, 0,
    2.0, 0, 0, 0,
    0, 0, 200000.0, 0, 0.0,
    0, 0, 0.0, 200000.0, 0.0, 200000.0, NULL, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';

-- ---------------------------------------------------------
-- 1. CHẤM CÔNG HÀNG NGÀY: TN_CUNG (Branch 2, FIXED)
-- ---------------------------------------------------------
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-01', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-01', '08:42:00', '17:12:00', 12, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-02', NULL, NULL, 0, 1,
    0.0, 'P', 'P', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-02', '06:23:00', '16:45:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-03', '16:45:00', '18:32:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-03', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-04', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-05', '15:18:00', '20:03:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-05', '06:23:00', '17:06:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-06', '16:46:00', '18:33:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-06', '06:23:00', '16:52:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-07', '16:46:00', '20:00:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-07', '06:24:00', '16:55:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-08', '13:45:00', '15:30:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-08', '06:24:00', '16:58:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-09', '07:47:00', '16:09:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-09', '06:24:00', '17:19:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-10', '07:44:00', '17:04:00', 0, 1,
    1.0, 'X + TC', 'X + TC', 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-10', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-11', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-12', '07:44:00', '16:01:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-12', '06:23:00', '17:04:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-13', '07:48:00', '17:01:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-13', '06:21:00', '17:02:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-14', '07:48:00', '16:00:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-14', '06:23:00', '17:00:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-15', '07:43:00', '17:04:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-15', '06:23:00', '16:55:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-16', '07:44:00', '16:59:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-16', '06:23:00', '17:02:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-17', '07:42:00', '16:56:00', 0, 0,
    0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-17', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-18', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-19', '07:50:00', '16:57:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-19', '06:22:00', '16:59:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-20', '07:44:00', '16:58:00', 0, 1,
    1.5, 'X + TC', 'X + TC', 1.5, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-20', '06:23:00', '17:02:00', 0, 0,
    0.0, 'X', 'X', 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-21', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-22', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-23', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-24', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-25', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-26', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-27', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-28', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-29', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-30', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    16, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    17, '2026-10-31', NULL, NULL, 0, 0,
    0.0, '-', '-', 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);

-- ---------------------------------------------------------
-- 2. TỔNG HỢP LƯƠNG THÁNG 10: TN_CUNG
-- ---------------------------------------------------------
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    16, 10, 2026, 16.0, 11.5, 8,
    0, 0, 0, 0,
    6000000.0, 3692308.0, 0, 960000.0, 0.0,
    1000000.0, 400000.0, 0.0, 6052308.0, 0.0, 6052308.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    17, 10, 2026, 14.0, 0.0, 0,
    0, 0, 1, 12,
    7000000.0, 3769231.0, 0, 0.0, 500000.0,
    300000.0, 350000.0, 0.0, 4919231.0, 0.0, 4919231.0, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';

-- ---------------------------------------------------------
-- 1. CHẤM CÔNG HÀNG NGÀY: TN_GIO (Branch 2, HOURLY)
-- ---------------------------------------------------------
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-01', NULL, NULL, 0,
    NULL, NULL, 0, '16:54:00', '18:30:00', 96,
    96, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca Tối T3,5,7 (16h54-18h30) 96p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-01', NULL, NULL, 0,
    NULL, NULL, 0, '16:56:00', '18:30:00', 94,
    94, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca Tối T3,5,7 (16h56-18h30) 94p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-01', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', 'Nghỉ / Lịch T2,4,6'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-01', NULL, NULL, 0,
    '14:27:00', '18:22:00', 235, NULL, NULL, 0,
    210, 2.33, 0, 2.33, 'Đã xác nhận', '3.5 giờ = 2 ca + 1 ca gãy (30p)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-02', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', 'Nghỉ (Lịch T3,5,7)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-02', NULL, NULL, 0,
    NULL, NULL, 0, '16:43:00', '20:18:00', 215,
    215, 2.0, 0, 2.0, 'Đã xác nhận', 'Làm thế Cô Hiền (16h43-20h18) 215p (2 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-02', NULL, NULL, 0,
    NULL, NULL, 0, '16:44:00', '20:17:00', 213,
    213, 2.0, 0, 2.0, 'Đã xác nhận', 'Ca Tối T2,4,6 (16h44-20h17) 213p (2 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-02', NULL, NULL, 0,
    '14:28:00', '20:01:00', 333, NULL, NULL, 0,
    300, 3.33, 0, 3.33, 'Đã xác nhận', '5.0 giờ = 3 ca + 1 ca gãy (30p)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-03', NULL, NULL, 0,
    NULL, NULL, 0, '16:57:00', '18:37:00', 100,
    100, 1.0, 0, 1.0, 'Đã xác nhận', 'Ca Tối T3,5,7 (16h57-18h37) 100p (1 ca)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-03', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', 'Nghỉ (Lịch T3,5,7)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-03', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', 'Nghỉ (Lịch T2,4,6)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-03', NULL, NULL, 0,
    '14:26:00', '20:09:00', 343, NULL, NULL, 0,
    300, 3.33, 0, 3.33, 'Đã xác nhận', '5.0 giờ = 3 ca + 1 ca gãy (30p)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-04', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-04', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-04', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-04', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-05', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-05', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-05', NULL, NULL, 0,
    NULL, NULL, 0, '16:58:00', '20:00:00', 182,
    182, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-05', NULL, NULL, 0,
    '14:30:00', '20:00:00', 330, NULL, NULL, 0,
    270, 3.0, 0, 3.0, 'Đã xác nhận', '4.5 giờ = 3 ca chuẩn'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-06', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-06', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-06', NULL, NULL, 0,
    NULL, NULL, 0, '16:50:00', '18:37:00', 107,
    107, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-06', NULL, NULL, 0,
    '14:29:00', '20:05:00', 336, NULL, NULL, 0,
    240, 2.67, 0, 2.67, 'Đã xác nhận', '4.0 giờ = 2 ca + 1 ca gãy (1h)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-07', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-07', NULL, NULL, 0,
    NULL, NULL, 0, '16:48:00', '20:00:00', 192,
    192, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-07', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-07', NULL, NULL, 0,
    '16:30:00', '20:00:00', 210, NULL, NULL, 0,
    180, 2.0, 0, 2.0, 'Đã xác nhận', '3.0 giờ = 2 ca chuẩn'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-08', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-08', NULL, NULL, 0,
    NULL, NULL, 0, '16:52:00', '18:33:00', 101,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-08', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-08', NULL, NULL, 0,
    '15:00:00', '20:00:00', 300, NULL, NULL, 0,
    240, 2.67, 0, 2.67, 'Đã xác nhận', '4.0 giờ = 2 ca + 1 ca gãy (1h)'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-09', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-09', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-09', NULL, NULL, 0,
    NULL, NULL, 0, '17:00:00', '20:00:00', 180,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-09', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, '16:57:00', '18:40:00', 103,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, '17:01:00', '18:40:00', 99,
    99, 1.0, 1, 1.0, 'Đã xác nhận', 'BT'
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-10', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-11', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-11', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-11', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-11', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, '16:44:00', '20:02:00', 198,
    198, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-12', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    360, 4.0, 0, 4.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, '16:55:00', '18:57:00', 122,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, '16:55:00', '18:40:00', 105,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-13', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    360, 4.0, 0, 4.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, '17:00:00', '20:02:00', 182,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-14', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    360, 4.0, 0, 4.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, '16:55:00', '18:34:00', 99,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, '16:52:00', '18:33:00', 101,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-15', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    360, 4.0, 0, 4.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 0, '16:56:00', '20:07:00', 191,
    191, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-16', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    300, 3.33, 0, 3.33, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, '16:54:00', '18:52:00', 118,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, '16:56:00', '18:35:00', 99,
    99, 1.0, 1, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-17', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-18', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-18', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-18', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-18', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-19', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-19', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-19', NULL, NULL, 0,
    NULL, NULL, 0, '16:53:00', '20:00:00', 187,
    180, 2.0, 0, 2.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-19', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    270, 3.0, 0, 3.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-20', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-20', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-20', NULL, NULL, 0,
    NULL, NULL, 0, '16:44:00', '18:30:00', 106,
    90, 1.0, 0, 1.0, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-20', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    330, 3.67, 0, 3.67, 'Đã xác nhận', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-21', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-22', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-23', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-24', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-25', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-26', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-27', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-28', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-29', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-30', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    18, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    19, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    20, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);
INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    21, '2026-10-31', NULL, NULL, 0,
    NULL, NULL, 0, NULL, NULL, 0,
    0, 0.0, 0, 0.0, 'Chưa nhập', NULL
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);

-- ---------------------------------------------------------
-- 2. TỔNG HỢP LƯƠNG THÁNG 10: TN_GIO
-- ---------------------------------------------------------
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    18, 10, 2026, 0, 0, 0,
    7.0, 0, 0, 0,
    0, 0, 840000.0, 0, 0.0,
    0, 0, 0.0, 840000.0, 0.0, 840000.0, NULL, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    19, 10, 2026, 0, 0, 0,
    11.0, 0, 0, 0,
    0, 0, 1320000.0, 0, 0.0,
    0, 0, 0.0, 1320000.0, 0.0, 1320000.0, 'Có 2 buổi Bán Trú (BT)', 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    20, 10, 2026, 0, 0, 0,
    15.0, 0, 0, 0,
    0, 0, 1800000.0, 0, 0.0,
    0, 0, 0.0, 1800000.0, 0.0, 1800000.0, NULL, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';
INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    21, 10, 2026, 0, 0, 0,
    48.33, 0, 0, 0,
    0, 0, 7250000.0, 0, 0.0,
    0, 0, 0.0, 7250000.0, 0.0, 7250000.0, NULL, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';