<?php
/**
 * CẤU HÌNH ĐĂNG NHẬP BẰNG GOOGLE (GOOGLE OAUTH2 / GOOGLE IDENTITY SERVICES)
 * Bạn có thể lấy Client ID từ Google Cloud Console (Credentials -> OAuth 2.0 Client IDs)
 */

define('GOOGLE_CLIENT_ID', getenv('GOOGLE_CLIENT_ID') ?: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com');
define('GOOGLE_CLIENT_SECRET', getenv('GOOGLE_CLIENT_SECRET') ?: '');

// Danh sách email quản trị viên mặc định (nếu đăng nhập lần đầu bằng Google sẽ được cấp quyền SUPER_ADMIN)
$DEFAULT_ADMIN_EMAILS = [
    'admin@happykids.edu.vn',
    'kythuat@happykids.edu.vn'
];
