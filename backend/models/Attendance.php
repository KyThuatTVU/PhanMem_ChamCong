<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/Employee.php';

class Attendance {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getConnection();
    }

    /**
     * Lấy dữ liệu chấm công chi tiết theo 1 ngày cụ thể (Bảng chi tiết giờ vào/ra chuẩn như file Excel)
     */
    public function getDayAttendance(int $branchId, string $salaryType, string $workDate): array {
        $empModel = new Employee();
        $employees = $empModel->getList($branchId, $salaryType, 'ACTIVE');

        if (empty($employees)) {
            return [];
        }

        $sql = "SELECT a.* 
                FROM daily_attendance a
                JOIN employees e ON a.employee_id = e.id
                WHERE e.branch_id = :branch_id 
                  AND e.salary_type = :salary_type
                  AND a.work_date = :work_date";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            ':branch_id' => $branchId,
            ':salary_type' => $salaryType,
            ':work_date' => $workDate
        ]);
        $records = $stmt->fetchAll();

        // Index by employee_id
        $attMap = [];
        foreach ($records as $r) {
            $attMap[$r['employee_id']] = $r;
        }

        // Merge with employee master list
        $result = [];
        foreach ($employees as $emp) {
            $empId = $emp['id'];
            $att = $attMap[$empId] ?? null;
            $emp['attendance'] = $att;
            $result[] = $emp;
        }

        return $result;
    }

    /**
     * Lấy dữ liệu chấm công cả tháng của 1 chi nhánh (Ma trận ngày 1 -> 31)
     */
    public function getMonthMatrix(int $branchId, string $salaryType, int $month, int $year): array {
        $empModel = new Employee();
        $employees = $empModel->getList($branchId, $salaryType, 'ACTIVE');

        if (empty($employees)) {
            return [];
        }

        $startDate = sprintf('%04d-%02d-01', $year, $month);
        $daysInMonth = (int)date('t', strtotime($startDate));
        $endDate = sprintf('%04d-%02d-%02d', $year, $month, $daysInMonth);

        // Lấy toàn bộ record chấm công trong tháng của chi nhánh
        $sql = "SELECT a.* 
                FROM daily_attendance a
                JOIN employees e ON a.employee_id = e.id
                WHERE e.branch_id = :branch_id 
                  AND e.salary_type = :salary_type
                  AND a.work_date BETWEEN :start_date AND :end_date";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            ':branch_id' => $branchId,
            ':salary_type' => $salaryType,
            ':start_date' => $startDate,
            ':end_date' => $endDate
        ]);
        $records = $stmt->fetchAll();

        // Gom nhóm theo employee_id và day
        $matrix = [];
        foreach ($records as $r) {
            $empId = $r['employee_id'];
            $day = (int)date('j', strtotime($r['work_date']));
            $matrix[$empId][$day] = $r;
        }

        // Ghép vào danh sách nhân viên
        $result = [];
        foreach ($employees as $emp) {
            $empId = $emp['id'];
            $emp['attendance_days'] = $matrix[$empId] ?? [];
            $result[] = $emp;
        }

        return $result;
    }

    /**
     * Lưu hoặc cập nhật chấm công của 1 nhân viên trong 1 ngày cụ thể
     * Tự động tính toán số phút trễ, số giờ tăng ca hoặc quy đổi số ca dạy 90 phút
     */
    public function saveDailyRecord(array $data): array {
        $employeeId = (int)$data['employee_id'];
        $workDate = trim($data['work_date']);

        $empModel = new Employee();
        $emp = $empModel->getById($employeeId);
        if (!$emp) {
            throw new Exception("Không tìm thấy hồ sơ giáo viên ID $employeeId");
        }

        $salaryType = $emp['salary_type'];

        if ($salaryType === 'FIXED') {
            // XỬ LÝ LƯƠNG CỨNG
            $timeIn = !empty($data['time_in']) ? $data['time_in'] : null;
            $timeOut = !empty($data['time_out']) ? $data['time_out'] : null;
            $workSymbol = !empty($data['work_symbol']) ? trim($data['work_symbol']) : '-';
            $isOt = !empty($data['is_overtime']) ? 1 : 0;
            $notes = $data['notes'] ?? '';

            // Tính phút trễ
            $lateMinutes = 0;
            if ($timeIn && !empty($emp['default_time_in'])) {
                $secIn = strtotime("1970-01-01 $timeIn");
                $secDefIn = strtotime("1970-01-01 " . $emp['default_time_in']);
                if ($secIn > $secDefIn) {
                    $lateMinutes = (int)round(($secIn - $secDefIn) / 60);
                }
            }

            // Tính số giờ làm và tăng ca
            $otHours = 0.0;
            if ($timeIn && $timeOut) {
                $secIn = strtotime("1970-01-01 $timeIn");
                $secOut = strtotime("1970-01-01 $timeOut");
                if ($secOut < $secIn) {
                    $secOut += 86400; // Qua đêm
                }
                $workedHours = ($secOut - $secIn) / 3600.0;
                $stdHours = (float)($emp['standard_hours'] ?: 8.0);

                if ($isOt || $workedHours > $stdHours) {
                    $otHours = round(max(0, $workedHours - $stdHours), 2);
                    if ($otHours > 0) {
                        $isOt = 1;
                    }
                }

                if ($workSymbol === '-' || empty($workSymbol)) {
                    $workSymbol = $isOt ? 'X + TC' : 'X';
                }
            }

            $salarySymbol = in_array($workSymbol, ['X', 'X + TC', 'P', 'K']) ? $workSymbol : '-';
            $otSalaryHours = ($isOt && $otHours > 0) ? $otHours : 0.0;
            $confirmStatus = ($timeIn && $timeOut) ? 'Đã xác nhận' : 'Chưa nhập';

            $sql = "INSERT INTO daily_attendance (
                employee_id, work_date, time_in, time_out, late_minutes, is_overtime,
                ot_hours, work_symbol, salary_symbol, ot_salary_hours, confirmation_status, notes
            ) VALUES (
                :employee_id, :work_date, :time_in, :time_out, :late_minutes, :is_overtime,
                :ot_hours, :work_symbol, :salary_symbol, :ot_salary_hours, :confirmation_status, :notes
            ) ON DUPLICATE KEY UPDATE
                time_in = VALUES(time_in),
                time_out = VALUES(time_out),
                late_minutes = VALUES(late_minutes),
                is_overtime = VALUES(is_overtime),
                ot_hours = VALUES(ot_hours),
                work_symbol = VALUES(work_symbol),
                salary_symbol = VALUES(salary_symbol),
                ot_salary_hours = VALUES(ot_salary_hours),
                confirmation_status = VALUES(confirmation_status),
                notes = VALUES(notes)";

            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':employee_id' => $employeeId,
                ':work_date' => $workDate,
                ':time_in' => $timeIn,
                ':time_out' => $timeOut,
                ':late_minutes' => $lateMinutes,
                ':is_overtime' => $isOt,
                ':ot_hours' => $otHours,
                ':work_symbol' => $workSymbol,
                ':salary_symbol' => $salarySymbol,
                ':ot_salary_hours' => $otSalaryHours,
                ':confirmation_status' => $confirmStatus,
                ':notes' => $notes
            ]);

            return [
                'employee_id' => $employeeId,
                'work_date' => $workDate,
                'work_symbol' => $workSymbol,
                'late_minutes' => $lateMinutes,
                'ot_hours' => $otHours,
                'is_overtime' => $isOt,
                'status' => $confirmStatus
            ];
        } else {
            // XỬ LÝ LƯƠNG THEO GIỜ (3 CA)
            $mIn = !empty($data['morning_in']) ? $data['morning_in'] : null;
            $mOut = !empty($data['morning_out']) ? $data['morning_out'] : null;
            $aIn = !empty($data['afternoon_in']) ? $data['afternoon_in'] : null;
            $aOut = !empty($data['afternoon_out']) ? $data['afternoon_out'] : null;
            $eIn = !empty($data['evening_in']) ? $data['evening_in'] : null;
            $eOut = !empty($data['evening_out']) ? $data['evening_out'] : null;
            $hasBoarding = !empty($data['has_boarding']) ? 1 : 0;
            $notes = $data['notes'] ?? '';

            // Tính phút từng ca
            $calcMins = function($in, $out) {
                if (!$in || !$out) return 0;
                $diff = (strtotime("1970-01-01 $out") - strtotime("1970-01-01 $in")) / 60;
                return max(0, (int)round($diff));
            };

            $mMins = $calcMins($mIn, $mOut);
            $aMins = $calcMins($aIn, $aOut);
            $eMins = $calcMins($eIn, $eOut);
            $totMins = $mMins + $aMins + $eMins;

            // Quy đổi số ca (90 phút = 1 ca)
            $totSlots = round($totMins / 90.0, 2);
            $actualSlots = isset($data['actual_slots']) ? (float)$data['actual_slots'] : $totSlots;
            $confirmStatus = ($totMins > 0 || $hasBoarding) ? 'Đã xác nhận' : 'Chưa nhập';

            $sql = "INSERT INTO daily_attendance (
                employee_id, work_date, morning_in, morning_out, morning_minutes,
                afternoon_in, afternoon_out, afternoon_minutes, evening_in, evening_out, evening_minutes,
                total_minutes, total_slots, has_boarding, actual_slots, confirmation_status, notes
            ) VALUES (
                :employee_id, :work_date, :morning_in, :morning_out, :morning_minutes,
                :afternoon_in, :afternoon_out, :afternoon_minutes, :evening_in, :evening_out, :evening_minutes,
                :total_minutes, :total_slots, :has_boarding, :actual_slots, :confirmation_status, :notes
            ) ON DUPLICATE KEY UPDATE
                morning_in = VALUES(morning_in),
                morning_out = VALUES(morning_out),
                morning_minutes = VALUES(morning_minutes),
                afternoon_in = VALUES(afternoon_in),
                afternoon_out = VALUES(afternoon_out),
                afternoon_minutes = VALUES(afternoon_minutes),
                evening_in = VALUES(evening_in),
                evening_out = VALUES(evening_out),
                evening_minutes = VALUES(evening_minutes),
                total_minutes = VALUES(total_minutes),
                total_slots = VALUES(total_slots),
                has_boarding = VALUES(has_boarding),
                actual_slots = VALUES(actual_slots),
                confirmation_status = VALUES(confirmation_status),
                notes = VALUES(notes)";

            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':employee_id' => $employeeId,
                ':work_date' => $workDate,
                ':morning_in' => $mIn,
                ':morning_out' => $mOut,
                ':morning_minutes' => $mMins,
                ':afternoon_in' => $aIn,
                ':afternoon_out' => $aOut,
                ':afternoon_minutes' => $aMins,
                ':evening_in' => $eIn,
                ':evening_out' => $eOut,
                ':evening_minutes' => $eMins,
                ':total_minutes' => $totMins,
                ':total_slots' => $totSlots,
                ':has_boarding' => $hasBoarding,
                ':actual_slots' => $actualSlots,
                ':confirmation_status' => $confirmStatus,
                ':notes' => $notes
            ]);

            return [
                'employee_id' => $employeeId,
                'work_date' => $workDate,
                'total_minutes' => $totMins,
                'total_slots' => $totSlots,
                'has_boarding' => $hasBoarding,
                'actual_slots' => $actualSlots,
                'status' => $confirmStatus
            ];
        }
    }
}
