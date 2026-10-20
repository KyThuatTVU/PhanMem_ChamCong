<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../models/Setting.php';

$method = $_SERVER['REQUEST_METHOD'];
$settingModel = new Setting();

switch ($method) {
    case 'GET':
        $branchId = (int)($_GET['branch_id'] ?? 1);
        $cfg = $settingModel->getByBranch($branchId);
        jsonResponse('success', $cfg);
        break;

    case 'POST':
        $data = getJsonInput();
        $branchId = (int)($data['branch_id'] ?? 1);
        try {
            $settingModel->update($branchId, $data);
            jsonResponse('success', null, 'Cập nhật cấu hình thành công');
        } catch (Exception $e) {
            jsonResponse('error', null, 'Lỗi cập nhật cấu hình: ' . $e->getMessage(), 500);
        }
        break;

    default:
        jsonResponse('error', null, 'Phương thức không được hỗ trợ', 405);
}
