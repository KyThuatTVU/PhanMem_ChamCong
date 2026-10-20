<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../models/Attendance.php';

$method = $_SERVER['REQUEST_METHOD'];
$attModel = new Attendance();

switch ($method) {
    case 'GET':
        $branchId = (int)($_GET['branch_id'] ?? 1);
        $salaryType = $_GET['salary_type'] ?? 'FIXED';
        $view = $_GET['view'] ?? '';
        $workDate = $_GET['work_date'] ?? '';

        try {
            if ($view === 'daily' || !empty($workDate)) {
                // CHẾ ĐỘ XEM CHI TIẾT TỪNG GIỜ THEO NGÀY (GIỐNG SHEET EXCEL)
                $dateToFetch = !empty($workDate) ? $workDate : date('Y-m-d');
                $list = $attModel->getDayAttendance($branchId, $salaryType, $dateToFetch);
                jsonResponse('success', [
                    'branch_id' => $branchId,
                    'salary_type' => $salaryType,
                    'work_date' => $dateToFetch,
                    'employees' => $list
                ]);
            } else {
                // CHẾ ĐỘ XEM MA TRẬN CẢ THÁNG (1 -> 31 NGÀY)
                $month = (int)($_GET['month'] ?? date('n'));
                $year = (int)($_GET['year'] ?? date('Y'));
                $matrix = $attModel->getMonthMatrix($branchId, $salaryType, $month, $year);
                jsonResponse('success', [
                    'branch_id' => $branchId,
                    'salary_type' => $salaryType,
                    'month' => $month,
                    'year' => $year,
                    'days_in_month' => (int)date('t', strtotime("$year-$month-01")),
                    'employees' => $matrix
                ]);
            }
        } catch (Exception $e) {
            jsonResponse('error', null, 'Lỗi lấy dữ liệu chấm công: ' . $e->getMessage(), 500);
        }
        break;

    case 'POST':
        $data = getJsonInput();

        // Xử lý lưu hàng loạt (Batch save cả bảng ngày)
        if (!empty($data['batch']) && is_array($data['batch'])) {
            try {
                $savedCount = 0;
                foreach ($data['batch'] as $row) {
                    if (!empty($row['employee_id']) && !empty($row['work_date'])) {
                        $attModel->saveDailyRecord($row);
                        $savedCount++;
                    }
                }
                jsonResponse('success', ['saved_count' => $savedCount], 'Đã lưu chấm công toàn bộ giáo viên thành công');
            } catch (Exception $e) {
                jsonResponse('error', null, 'Lỗi lưu hàng loạt: ' . $e->getMessage(), 500);
            }
        }

        if (empty($data['employee_id']) || empty($data['work_date'])) {
            jsonResponse('error', null, 'Thiếu employee_id hoặc work_date', 400);
        }

        try {
            $saved = $attModel->saveDailyRecord($data);
            jsonResponse('success', $saved, 'Đã lưu chấm công thành công');
        } catch (Exception $e) {
            jsonResponse('error', null, 'Lỗi khi lưu chấm công: ' . $e->getMessage(), 500);
        }
        break;

    default:
        jsonResponse('error', null, 'Phương thức không được hỗ trợ', 405);
}
