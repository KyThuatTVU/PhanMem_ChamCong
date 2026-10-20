<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../models/Payroll.php';

$method = $_SERVER['REQUEST_METHOD'];
$payrollModel = new Payroll();
$action = $_GET['action'] ?? 'summary';

switch ($method) {
    case 'GET':
        if ($action === 'payslip') {
            $employeeId = (int)($_GET['employee_id'] ?? 0);
            $month = (int)($_GET['month'] ?? date('n'));
            $year = (int)($_GET['year'] ?? date('Y'));

            if ($employeeId <= 0) {
                jsonResponse('error', null, 'Thiếu employee_id', 400);
            }

            $payslip = $payrollModel->getPayslip($employeeId, $month, $year);
            if (!$payslip) {
                // Thử tính trước rồi lấy lại
                $empModel = new Employee();
                $emp = $empModel->getById($employeeId);
                if ($emp) {
                    $payrollModel->calculateMonth((int)$emp['branch_id'], $emp['salary_type'], $month, $year);
                    $payslip = $payrollModel->getPayslip($employeeId, $month, $year);
                }
            }

            if (!$payslip) {
                jsonResponse('error', null, 'Chưa có dữ liệu phiếu lương cho nhân viên này', 404);
            }
            jsonResponse('success', $payslip);
        } else {
            // Tổng hợp bảng lương cả chi nhánh
            $branchId = (int)($_GET['branch_id'] ?? 1);
            $salaryType = $_GET['salary_type'] ?? 'FIXED';
            $month = (int)($_GET['month'] ?? date('n'));
            $year = (int)($_GET['year'] ?? date('Y'));

            try {
                $summary = $payrollModel->calculateMonth($branchId, $salaryType, $month, $year);
                jsonResponse('success', [
                    'branch_id' => $branchId,
                    'salary_type' => $salaryType,
                    'month' => $month,
                    'year' => $year,
                    'payroll_list' => $summary
                ]);
            } catch (Exception $e) {
                jsonResponse('error', null, 'Lỗi tính toán bảng lương: ' . $e->getMessage(), 500);
            }
        }
        break;

    case 'POST':
        // Cập nhật điều chỉnh (Thưởng / Khấu trừ / Ghi chú)
        $data = getJsonInput();
        $employeeId = (int)($data['employee_id'] ?? 0);
        $month = (int)($data['month'] ?? date('n'));
        $year = (int)($data['year'] ?? date('Y'));

        if ($employeeId <= 0) {
            jsonResponse('error', null, 'Thiếu employee_id', 400);
        }

        try {
            $db = Database::getConnection();
            $stmt = $db->prepare("
                UPDATE monthly_payroll 
                SET bonus = :bonus, deductions = :deductions, note = :note,
                    total_income = (salary_by_days + salary_by_slots + ot_pay + boarding_pay + attendance_allowance + lunch_allowance + :bonus),
                    net_salary = GREATEST(0, (salary_by_days + salary_by_slots + ot_pay + boarding_pay + attendance_allowance + lunch_allowance + :bonus) - :deductions)
                WHERE employee_id = :emp_id AND month = :m AND year = :y
            ");
            $stmt->execute([
                ':bonus' => (float)($data['bonus'] ?? 0),
                ':deductions' => (float)($data['deductions'] ?? 0),
                ':note' => $data['note'] ?? '',
                ':emp_id' => $employeeId,
                ':m' => $month,
                ':y' => $year
            ]);

            jsonResponse('success', null, 'Đã cập nhật điều chỉnh lương thành công');
        } catch (Exception $e) {
            jsonResponse('error', null, 'Lỗi cập nhật điều chỉnh: ' . $e->getMessage(), 500);
        }
        break;

    default:
        jsonResponse('error', null, 'Phương thức không được hỗ trợ', 405);
}
