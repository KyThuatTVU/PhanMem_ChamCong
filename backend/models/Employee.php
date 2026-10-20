<?php
require_once __DIR__ . '/../config/database.php';

class Employee {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getConnection();
    }

    public function getList(int $branchId = 0, string $salaryType = '', string $status = 'ACTIVE'): array {
        $sql = "SELECT e.*, b.name as branch_name, b.code as branch_code 
                FROM employees e
                JOIN branches b ON e.branch_id = b.id
                WHERE 1=1";
        $params = [];

        if ($branchId > 0) {
            $sql .= " AND e.branch_id = :branch_id";
            $params[':branch_id'] = $branchId;
        }
        if (!empty($salaryType)) {
            $sql .= " AND e.salary_type = :salary_type";
            $params[':salary_type'] = $salaryType;
        }
        if (!empty($status)) {
            $sql .= " AND e.status = :status";
            $params[':status'] = $status;
        }

        $sql .= " ORDER BY e.branch_id ASC, e.salary_type ASC, e.employee_code ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    public function getById(int $id): ?array {
        $stmt = $this->db->prepare("
            SELECT e.*, b.name as branch_name, b.code as branch_code 
            FROM employees e
            JOIN branches b ON e.branch_id = b.id
            WHERE e.id = :id LIMIT 1
        ");
        $stmt->execute([':id' => $id]);
        $res = $stmt->fetch();
        return $res ?: null;
    }

    public function create(array $data): int {
        $sql = "INSERT INTO employees (
            branch_id, employee_code, full_name, position, phone, salary_type,
            base_salary, hourly_rate, overtime_rate, attendance_allowance, boarding_allowance,
            other_allowance, time_frame, standard_hours, default_time_in, default_time_out,
            work_schedule, status, notes
        ) VALUES (
            :branch_id, :employee_code, :full_name, :position, :phone, :salary_type,
            :base_salary, :hourly_rate, :overtime_rate, :attendance_allowance, :boarding_allowance,
            :other_allowance, :time_frame, :standard_hours, :default_time_in, :default_time_out,
            :work_schedule, :status, :notes
        )";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            ':branch_id' => $data['branch_id'] ?? 1,
            ':employee_code' => trim($data['employee_code']),
            ':full_name' => trim($data['full_name']),
            ':position' => $data['position'] ?? '',
            ':phone' => $data['phone'] ?? '',
            ':salary_type' => $data['salary_type'] ?? 'FIXED',
            ':base_salary' => $data['base_salary'] ?? 0,
            ':hourly_rate' => $data['hourly_rate'] ?? 0,
            ':overtime_rate' => $data['overtime_rate'] ?? 120000,
            ':attendance_allowance' => $data['attendance_allowance'] ?? 0,
            ':boarding_allowance' => $data['boarding_allowance'] ?? 0,
            ':other_allowance' => $data['other_allowance'] ?? 0,
            ':time_frame' => $data['time_frame'] ?? '',
            ':standard_hours' => $data['standard_hours'] ?? 8.0,
            ':default_time_in' => !empty($data['default_time_in']) ? $data['default_time_in'] : null,
            ':default_time_out' => !empty($data['default_time_out']) ? $data['default_time_out'] : null,
            ':work_schedule' => $data['work_schedule'] ?? 'Thứ 2 - Thứ 7',
            ':status' => $data['status'] ?? 'ACTIVE',
            ':notes' => $data['notes'] ?? ''
        ]);

        return (int)$this->db->lastInsertId();
    }

    public function update(int $id, array $data): bool {
        $sql = "UPDATE employees SET 
            branch_id = :branch_id,
            employee_code = :employee_code,
            full_name = :full_name,
            position = :position,
            phone = :phone,
            salary_type = :salary_type,
            base_salary = :base_salary,
            hourly_rate = :hourly_rate,
            overtime_rate = :overtime_rate,
            attendance_allowance = :attendance_allowance,
            boarding_allowance = :boarding_allowance,
            other_allowance = :other_allowance,
            time_frame = :time_frame,
            standard_hours = :standard_hours,
            default_time_in = :default_time_in,
            default_time_out = :default_time_out,
            work_schedule = :work_schedule,
            status = :status,
            notes = :notes
        WHERE id = :id";

        $stmt = $this->db->prepare($sql);
        return $stmt->execute([
            ':branch_id' => $data['branch_id'] ?? 1,
            ':employee_code' => trim($data['employee_code']),
            ':full_name' => trim($data['full_name']),
            ':position' => $data['position'] ?? '',
            ':phone' => $data['phone'] ?? '',
            ':salary_type' => $data['salary_type'] ?? 'FIXED',
            ':base_salary' => $data['base_salary'] ?? 0,
            ':hourly_rate' => $data['hourly_rate'] ?? 0,
            ':overtime_rate' => $data['overtime_rate'] ?? 120000,
            ':attendance_allowance' => $data['attendance_allowance'] ?? 0,
            ':boarding_allowance' => $data['boarding_allowance'] ?? 0,
            ':other_allowance' => $data['other_allowance'] ?? 0,
            ':time_frame' => $data['time_frame'] ?? '',
            ':standard_hours' => $data['standard_hours'] ?? 8.0,
            ':default_time_in' => !empty($data['default_time_in']) ? $data['default_time_in'] : null,
            ':default_time_out' => !empty($data['default_time_out']) ? $data['default_time_out'] : null,
            ':work_schedule' => $data['work_schedule'] ?? 'Thứ 2 - Thứ 7',
            ':status' => $data['status'] ?? 'ACTIVE',
            ':notes' => $data['notes'] ?? '',
            ':id' => $id
        ]);
    }

    public function delete(int $id, bool $permanent = false): bool {
        if ($permanent) {
            $stmt = $this->db->prepare("DELETE FROM employees WHERE id = :id");
            return $stmt->execute([':id' => $id]);
        }
        // Soft delete: chuyển status thành RESIGNED
        $stmt = $this->db->prepare("UPDATE employees SET status = 'RESIGNED' WHERE id = :id");
        return $stmt->execute([':id' => $id]);
    }
}
