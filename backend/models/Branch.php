<?php
require_once __DIR__ . '/../config/database.php';

class Branch {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getConnection();
    }

    public function getAll(): array {
        $stmt = $this->db->query("SELECT * FROM branches ORDER BY id ASC");
        return $stmt->fetchAll();
    }

    public function getById(int $id): ?array {
        $stmt = $this->db->prepare("SELECT * FROM branches WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $id]);
        $res = $stmt->fetch();
        return $res ?: null;
    }

    public function getByCode(string $code): ?array {
        $stmt = $this->db->prepare("SELECT * FROM branches WHERE code = :code LIMIT 1");
        $stmt->execute([':code' => $code]);
        $res = $stmt->fetch();
        return $res ?: null;
    }
}
