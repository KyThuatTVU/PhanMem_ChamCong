<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../helpers/auth.php';

$user = AuthHelper::getCurrentUser();

if (!$user) {
    jsonResponse('unauthenticated', null, 'Chưa đăng nhập', 401);
}

jsonResponse('success', $user, 'Đã xác thực');
