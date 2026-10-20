<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/google.php';

class User {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getConnection();
    }

    /**
     * Tìm hoặc tự động tạo tài khoản khi đăng nhập Google thành công
     */
    public function findOrCreateFromGoogle(array $googleData): array {
        global $DEFAULT_ADMIN_EMAILS;
        $email = $googleData['email'];
        $googleId = $googleData['google_id'];
        $name = $googleData['name'];
        $avatar = $googleData['avatar'];

        // Kiểm tra xem đã có user với email này chưa
        $stmt = $this->db->prepare("SELECT * FROM users WHERE email = :email LIMIT 1");
        $stmt->execute([':email' => $email]);
        $user = $stmt->fetch();

        if ($user) {
            // Cập nhật google_id, avatar và last_login
            $upd = $this->db->prepare("
                UPDATE users 
                SET google_id = :google_id, avatar = :avatar, name = :name, last_login = NOW() 
                WHERE id = :id
            ");
            $upd->execute([
                ':google_id' => $googleId,
                ':avatar' => $avatar,
                ':name' => !empty($user['name']) ? $user['name'] : $name,
                ':id' => $user['id']
            ]);
            $user['avatar'] = $avatar;
            $user['last_login'] = date('Y-m-d H:i:s');
            return $user;
        }

        // Tạo user mới
        $role = in_array($email, $DEFAULT_ADMIN_EMAILS) ? 'SUPER_ADMIN' : 'SUPER_ADMIN'; // Mặc định cấp quyền quản trị hoặc tùy chỉnh
        $ins = $this->db->prepare("
            INSERT INTO users (google_id, email, name, avatar, role, status, last_login)
            VALUES (:google_id, :email, :name, :avatar, :role, 'ACTIVE', NOW())
        ");
        $ins->execute([
            ':google_id' => $googleId,
            ':email' => $email,
            ':name' => $name,
            ':avatar' => $avatar,
            ':role' => $role
        ]);

        $newId = $this->db->lastInsertId();
        return $this->getById((int)$newId);
    }

    public function getById(int $id): ?array {
        $stmt = $this->db->prepare("SELECT * FROM users WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $id]);
        $res = $stmt->fetch();
        return $res ?: null;
    }

    public function getAll(): array {
        $stmt = $this->db->query("SELECT id, google_id, email, name, avatar, role, branch_id, status, last_login, created_at FROM users ORDER BY id DESC");
        return $stmt->fetchAll();
    }
}
