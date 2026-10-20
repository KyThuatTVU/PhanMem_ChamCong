<?php
require_once __DIR__ . '/../config/database.php';

class Setting {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getConnection();
    }

    public function getByBranch(int $branchId): array {
        $stmt = $this->db->prepare("SELECT * FROM system_config WHERE branch_id = :branch_id LIMIT 1");
        $stmt->execute([':branch_id' => $branchId]);
        $cfg = $stmt->fetch();
        if (!$cfg) {
            // Khởi tạo mặc định nếu chưa có
            $ins = $this->db->prepare("
                INSERT INTO system_config (branch_id, standard_work_days, standard_day_minutes, slot_duration_minutes, default_ot_rate, default_slot_rate, lunch_allowance)
                VALUES (:b, 26, 480, 90, 120000, 120000, 25000)
            ");
            $ins->execute([':b' => $branchId]);
            return $this->getByBranch($branchId);
        }
        return $cfg;
    }

    public function update(int $branchId, array $data): bool {
        $stmt = $this->db->prepare("
            UPDATE system_config SET
                standard_work_days = :std_days,
                standard_day_minutes = :std_mins,
                slot_duration_minutes = :slot_mins,
                default_ot_rate = :ot_rate,
                default_slot_rate = :slot_rate,
                lunch_allowance = :lunch_rate
            WHERE branch_id = :branch_id
        ");
        return $stmt->execute([
            ':std_days' => (int)($data['standard_work_days'] ?? 26),
            ':std_mins' => (int)($data['standard_day_minutes'] ?? 480),
            ':slot_mins' => (int)($data['slot_duration_minutes'] ?? 90),
            ':ot_rate' => (float)($data['default_ot_rate'] ?? 120000),
            ':slot_rate' => (float)($data['default_slot_rate'] ?? 120000),
            ':lunch_rate' => (float)($data['lunch_allowance'] ?? 25000),
            ':branch_id' => $branchId
        ]);
    }
}
