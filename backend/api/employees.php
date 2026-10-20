<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../models/Employee.php';

$method = $_SERVER['REQUEST_METHOD'];
$empModel = new Employee();

switch ($method) {
    case 'GET':
        if (!empty($_GET['id'])) {
            $emp = $empModel->getById((int)$_GET['id']);
            if (!$emp) {
                jsonResponse('error', null, 'Không tìm thấy giáo viên', 404);
            }
            jsonResponse('success', $emp);
        } else {
            $branchId = (int)($_GET['branch_id'] ?? 0);
            $salaryType = $_GET['salary_type'] ?? '';
            $status = $_GET['status'] ?? 'ACTIVE';

            $list = $empModel->getList($branchId, $salaryType, $status);
            jsonResponse('success', $list);
        }
        break;

    case 'POST':
        $data = getJsonInput();
        if (empty($data['employee_code']) || empty($data['full_name'])) {
            jsonResponse('error', null, 'Mã GV và Họ tên là bắt buộc', 400);
        }
        try {
            $id = $empModel->create($data);
            jsonResponse('success', ['id' => $id], 'Thêm hồ sơ giáo viên thành công', 201);
        } catch (Exception $e) {
            jsonResponse('error', null, 'Lỗi khi thêm hồ sơ: ' . $e->getMessage(), 500);
        }
        break;

    case 'PUT':
        $data = getJsonInput();
        $id = (int)($data['id'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) {
            jsonResponse('error', null, 'Thiếu ID giáo viên cần cập nhật', 400);
        }
        try {
            $empModel->update($id, $data);
            jsonResponse('success', ['id' => $id], 'Cập nhật hồ sơ giáo viên thành công');
        } catch (Exception $e) {
            jsonResponse('error', null, 'Lỗi khi cập nhật hồ sơ: ' . $e->getMessage(), 500);
        }
        break;

    case 'DELETE':
        $id = (int)($_GET['id'] ?? 0);
        $permanent = !empty($_GET['permanent']) && $_GET['permanent'] == '1';
        if ($id <= 0) {
            jsonResponse('error', null, 'Thiếu ID giáo viên cần xóa', 400);
        }
        try {
            $empModel->delete($id, $permanent);
            $msg = $permanent ? 'Đã xóa vĩnh viễn giáo viên khỏi cơ sở dữ liệu' : 'Đã chuyển trạng thái sang nghỉ việc';
            jsonResponse('success', null, $msg);
        } catch (Exception $e) {
            jsonResponse('error', null, 'Lỗi khi xóa hồ sơ: ' . $e->getMessage(), 500);
        }
        break;

    default:
        jsonResponse('error', null, 'Phương thức không được hỗ trợ', 405);
}
