<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../helpers/auth.php';
require_once __DIR__ . '/../models/User.php';

$input = getJsonInput();
$credential = $input['credential'] ?? '';
$action = $_GET['action'] ?? 'login';

if ($action === 'logout') {
    AuthHelper::logout();
    jsonResponse('success', null, 'Đã đăng xuất thành công');
}

// Chế độ DEV TEST (cho phép đăng nhập nhanh tài khoản quản trị khi đang thử nghiệm cục bộ)
if (!empty($input['is_dev_test'])) {
    $devUser = [
        'id' => 1,
        'google_id' => 'dev_admin_happykids',
        'email' => 'admin@happykids.edu.vn',
        'name' => 'Quản Trị Viên HappyKids',
        'avatar' => 'https://ui-avatars.com/api/?name=HappyKids+Admin&background=1B365D&color=fff',
        'role' => 'SUPER_ADMIN',
        'branch_id' => 1
    ];
    try {
        $userModel = new User();
        $user = $userModel->findOrCreateFromGoogle($devUser);
        AuthHelper::setCurrentUser($user);
        jsonResponse('success', $user, 'Đăng nhập chế độ thử nghiệm thành công');
    } catch (Throwable $e) {
        // Nếu DB chưa bật, vẫn cho phép đăng nhập dev user
        AuthHelper::setCurrentUser($devUser);
        jsonResponse('success', $devUser, 'Đăng nhập chế độ thử nghiệm (Offline Mode) thành công');
    }
}

if (empty($credential)) {
    jsonResponse('error', null, 'Thiếu thông tin xác thực Google (credential)', 400);
}

// Xác thực Google ID Token
$googleData = AuthHelper::verifyGoogleIdToken($credential);

if (!$googleData) {
    jsonResponse('error', null, 'Xác thực Google ID Token không hợp lệ hoặc đã hết hạn', 401);
}

try {
    $userModel = new User();
    $user = $userModel->findOrCreateFromGoogle($googleData);
    AuthHelper::setCurrentUser($user);

    jsonResponse('success', [
        'user' => $user,
        'session_id' => session_id()
    ], 'Đăng nhập Google thành công');
} catch (Exception $e) {
    jsonResponse('error', null, 'Lỗi hệ thống khi đăng nhập: ' . $e->getMessage(), 500);
}
