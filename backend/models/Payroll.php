<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/Employee.php';

class Payroll {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getConnection();
    }

    /**
     * Tính toán hoặc cập nhật bảng lương tháng cho toàn bộ nhân sự 1 chi nhánh
     * Áp dụng chính xác 100% công thức từ file Excel hiện tại
     */
    public function calculateMonth(int $branchId, string $salaryType, int $month, int $year): array {
        $empModel = new Employee();
        $employees = $empModel->getList($branchId, $salaryType, 'ACTIVE');

        if (empty($employees)) {
            return [];
        }

        $startDate = sprintf('%04d-%02d-01', $year, $month);
        $daysInMonth = (int)date('t', strtotime($startDate));
        $endDate = sprintf('%04d-%02d-%02d', $year, $month, $daysInMonth);

        // Lấy cấu hình tham số của chi nhánh
        $cfgStmt = $this->db->prepare("SELECT * FROM system_config WHERE branch_id = :branch_id LIMIT 1");
        $cfgStmt->execute([':branch_id' => $branchId]);
        $config = $cfgStmt->fetch() ?: [
            'standard_work_days' => 26,
            'lunch_allowance' => 25000,
            'default_ot_rate' => 120000
        ];
        $stdDays = (int)($config['standard_work_days'] ?: 26);
        $lunchRate = (float)($config['lunch_allowance'] ?: 25000);

        $results = [];

        foreach ($employees as $emp) {
            $empId = (int)$emp['id'];

            // Lấy toàn bộ record chấm công trong tháng của nhân viên
            $attStmt = $this->db->prepare("
                SELECT * FROM daily_attendance 
                WHERE employee_id = :emp_id AND work_date BETWEEN :start_date AND :end_date
            ");
            $attStmt->execute([
                ':emp_id' => $empId,
                ':start_date' => $startDate,
                ':end_date' => $endDate
            ]);
            $attendanceList = $attStmt->fetchAll();

            // Lấy thông tin điều chỉnh lương (thưởng / khấu trừ) nếu đã có
            $prevStmt = $this->db->prepare("SELECT bonus, deductions, note FROM monthly_payroll WHERE employee_id = :emp_id AND month = :m AND year = :y");
            $prevStmt->execute([':emp_id' => $empId, ':m' => $month, ':y' => $year]);
            $prevPayroll = $prevStmt->fetch() ?: ['bonus' => 0, 'deductions' => 0, 'note' => ''];

            $bonus = (float)($prevPayroll['bonus'] ?? 0);
            $deductions = (float)($prevPayroll['deductions'] ?? 0);
            $note = $prevPayroll['note'] ?? '';

            if ($emp['salary_type'] === 'FIXED') {
                // TỔNG HỢP LƯƠNG CỨNG
                $totalDaysX = 0.0;
                $totalOtHours = 0.0;
                $otCount = 0;
                $lateCount = 0;
                $totalLateMinutes = 0;

                foreach ($attendanceList as $a) {
                    $sym = trim($a['salary_symbol'] ?? $a['work_symbol']);
                    if (in_array($sym, ['X', 'X + TC', 'X+TC'])) {
                        $totalDaysX += 1.0;
                    }
                    if (!empty($a['is_overtime'])) {
                        $otCount++;
                    }
                    $otH = (float)($a['ot_salary_hours'] ?: $a['ot_hours']);
                    if ($otH > 0) {
                        $totalOtHours += $otH;
                    }
                    $lateM = (int)($a['late_minutes'] ?? 0);
                    if ($lateM > 0) {
                        $lateCount++;
                        $totalLateMinutes += $lateM;
                    }
                }

                $baseSalary = (float)$emp['base_salary'];
                $otRate = (float)($emp['overtime_rate'] ?: $config['default_ot_rate']);
                
                // Công thức Excel: Lương theo ngày công = (Lương cơ bản / 26) * Ngày công thực tế
                $salaryByDays = $stdDays > 0 ? round(($baseSalary / $stdDays) * $totalDaysX) : 0;
                // Tiền tăng ca
                $otPay = round($totalOtHours * $otRate);
                // Phụ cấp cơm: 25k * số ngày công X
                $lunchPay = round($totalDaysX * $lunchRate);
                // Chuyên cần & Bán trú
                $attAllowance = (float)$emp['attendance_allowance'];
                $boardPay = (float)$emp['boarding_allowance'];

                $totalIncome = $salaryByDays + $otPay + $boardPay + $attAllowance + $lunchPay + $bonus;
                $netSalary = max(0, $totalIncome - $deductions);

                // Lưu vào CSDL monthly_payroll
                $this->savePayrollRecord([
                    'employee_id' => $empId,
                    'month' => $month,
                    'year' => $year,
                    'total_days_x' => $totalDaysX,
                    'total_ot_hours' => $totalOtHours,
                    'ot_count' => $otCount,
                    'total_slots' => 0,
                    'total_boarding_days' => 0,
                    'late_count' => $lateCount,
                    'total_late_minutes' => $totalLateMinutes,
                    'base_salary' => $baseSalary,
                    'salary_by_days' => $salaryByDays,
                    'salary_by_slots' => 0,
                    'ot_pay' => $otPay,
                    'boarding_pay' => $boardPay,
                    'attendance_allowance' => $attAllowance,
                    'lunch_allowance' => $lunchPay,
                    'bonus' => $bonus,
                    'total_income' => $totalIncome,
                    'deductions' => $deductions,
                    'net_salary' => $netSalary,
                    'note' => $note
                ]);

                $results[] = array_merge($emp, [
                    'total_days_x' => $totalDaysX,
                    'total_ot_hours' => $totalOtHours,
                    'ot_count' => $otCount,
                    'late_count' => $lateCount,
                    'total_late_minutes' => $totalLateMinutes,
                    'salary_by_days' => $salaryByDays,
                    'ot_pay' => $otPay,
                    'lunch_allowance' => $lunchPay,
                    'bonus' => $bonus,
                    'total_income' => $totalIncome,
                    'deductions' => $deductions,
                    'net_salary' => $netSalary
                ]);
            } else {
                // TỔNG HỢP LƯƠNG THEO GIỜ / THEO CA
                $totalSlots = 0.0;
                $boardingDays = 0;

                foreach ($attendanceList as $a) {
                    $slots = (float)($a['actual_slots'] ?: $a['total_slots']);
                    $totalSlots += $slots;
                    if (!empty($a['has_boarding'])) {
                        $boardingDays++;
                    }
                }

                $slotRate = (float)$emp['hourly_rate'];
                $boardRate = (float)$emp['boarding_allowance'];

                // Tiền lương theo ca
                $salaryBySlots = round($totalSlots * $slotRate);
                // Phụ cấp bán trú: Số ngày BT * Đơn giá BT
                $boardPay = round($boardingDays * $boardRate);
                $attAllowance = (float)$emp['attendance_allowance'];

                $totalIncome = $salaryBySlots + $boardPay + $attAllowance + $bonus;
                $netSalary = max(0, $totalIncome - $deductions);

                $this->savePayrollRecord([
                    'employee_id' => $empId,
                    'month' => $month,
                    'year' => $year,
                    'total_days_x' => 0,
                    'total_ot_hours' => 0,
                    'ot_count' => 0,
                    'total_slots' => $totalSlots,
                    'total_boarding_days' => $boardingDays,
                    'late_count' => 0,
                    'total_late_minutes' => 0,
                    'base_salary' => 0,
                    'salary_by_days' => 0,
                    'salary_by_slots' => $salaryBySlots,
                    'ot_pay' => 0,
                    'boarding_pay' => $boardPay,
                    'attendance_allowance' => $attAllowance,
                    'lunch_allowance' => 0,
                    'bonus' => $bonus,
                    'total_income' => $totalIncome,
                    'deductions' => $deductions,
                    'net_salary' => $netSalary,
                    'note' => $note
                ]);

                $results[] = array_merge($emp, [
                    'total_slots' => $totalSlots,
                    'total_boarding_days' => $boardingDays,
                    'salary_by_slots' => $salaryBySlots,
                    'boarding_pay' => $boardPay,
                    'bonus' => $bonus,
                    'total_income' => $totalIncome,
                    'deductions' => $deductions,
                    'net_salary' => $netSalary
                ]);
            }
        }

        return $results;
    }

    private function savePayrollRecord(array $d): void {
        $sql = "INSERT INTO monthly_payroll (
            employee_id, month, year, total_days_x, total_ot_hours, ot_count,
            total_slots, total_boarding_days, late_count, total_late_minutes,
            base_salary, salary_by_days, salary_by_slots, ot_pay, boarding_pay,
            attendance_allowance, lunch_allowance, bonus, total_income, deductions, net_salary, note
        ) VALUES (
            :employee_id, :month, :year, :total_days_x, :total_ot_hours, :ot_count,
            :total_slots, :total_boarding_days, :late_count, :total_late_minutes,
            :base_salary, :salary_by_days, :salary_by_slots, :ot_pay, :boarding_pay,
            :attendance_allowance, :lunch_allowance, :bonus, :total_income, :deductions, :net_salary, :note
        ) ON DUPLICATE KEY UPDATE
            total_days_x = VALUES(total_days_x),
            total_ot_hours = VALUES(total_ot_hours),
            ot_count = VALUES(ot_count),
            total_slots = VALUES(total_slots),
            total_boarding_days = VALUES(total_boarding_days),
            late_count = VALUES(late_count),
            total_late_minutes = VALUES(total_late_minutes),
            base_salary = VALUES(base_salary),
            salary_by_days = VALUES(salary_by_days),
            salary_by_slots = VALUES(salary_by_slots),
            ot_pay = VALUES(ot_pay),
            boarding_pay = VALUES(boarding_pay),
            attendance_allowance = VALUES(attendance_allowance),
            lunch_allowance = VALUES(lunch_allowance),
            bonus = VALUES(bonus),
            total_income = VALUES(total_income),
            deductions = VALUES(deductions),
            net_salary = VALUES(net_salary),
            note = VALUES(note)";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            ':employee_id' => $d['employee_id'],
            ':month' => $d['month'],
            ':year' => $d['year'],
            ':total_days_x' => $d['total_days_x'],
            ':total_ot_hours' => $d['total_ot_hours'],
            ':ot_count' => $d['ot_count'],
            ':total_slots' => $d['total_slots'],
            ':total_boarding_days' => $d['total_boarding_days'],
            ':late_count' => $d['late_count'],
            ':total_late_minutes' => $d['total_late_minutes'],
            ':base_salary' => $d['base_salary'],
            ':salary_by_days' => $d['salary_by_days'],
            ':salary_by_slots' => $d['salary_by_slots'],
            ':ot_pay' => $d['ot_pay'],
            ':boarding_pay' => $d['boarding_pay'],
            ':attendance_allowance' => $d['attendance_allowance'],
            ':lunch_allowance' => $d['lunch_allowance'],
            ':bonus' => $d['bonus'],
            ':total_income' => $d['total_income'],
            ':deductions' => $d['deductions'],
            ':net_salary' => $d['net_salary'],
            ':note' => $d['note']
        ]);
    }

    /**
     * Lấy chi tiết phiếu lương của 1 nhân viên
     */
    public function getPayslip(int $employeeId, int $month, int $year): ?array {
        $stmt = $this->db->prepare("
            SELECT p.*, e.employee_code, e.full_name, e.position, e.phone, e.salary_type, e.time_frame,
                   b.name as branch_name, b.address as branch_address
            FROM monthly_payroll p
            JOIN employees e ON p.employee_id = e.id
            JOIN branches b ON e.branch_id = b.id
            WHERE p.employee_id = :emp_id AND p.month = :m AND p.year = :y
            LIMIT 1
        ");
        $stmt->execute([':emp_id' => $employeeId, ':m' => $month, ':y' => $year]);
        $res = $stmt->fetch();
        return $res ?: null;
    }
}
