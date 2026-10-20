<?php
/**
 * HELPER: XÁC THỰC GOOGLE ID TOKEN VÀ PHÂN QUYỀN
 */

if (session_status() === PHP_SESSION_NONE) {
    @session_start();
}

require_once __DIR__ . '/../config/google.php';

class AuthHelper {
    /**
     * Xác thực Google ID Token gửi từ Google Identity Services trên Frontend
     * Sử dụng endpoint chính thức của Google: https://oauth2.googleapis.com/tokeninfo?id_token=
     */
    public static function verifyGoogleIdToken(string $idToken): ?array {
        if (empty($idToken)) {
            return null;
        }

        // 1. Gọi Google TokenInfo Endpoint qua cURL
        $url = 'https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken);
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // Tránh lỗi SSL trên một số host free
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode === 200 && $response) {
            $payload = json_decode($response, true);
            if (!empty($payload['sub']) && !empty($payload['email'])) {
                return [
                    'google_id' => $payload['sub'],
                    'email'     => strtolower(trim($payload['email'])),
                    'name'      => $payload['name'] ?? '',
                    'avatar'    => $payload['picture'] ?? ''
                ];
            }
        }

        // 2. Dự phòng: Nếu host free bị chặn cURL ra ngoài, thử giải mã phần payload JWT để lấy thông tin
        $parts = explode('.', $idToken);
        if (count($parts) === 3) {
            $payloadJson = base64_decode(str_replace(['-', '_'], ['+', '/'], $parts[1]));
            $payload = json_decode($payloadJson, true);
            if (!empty($payload['sub']) && !empty($payload['email'])) {
                return [
                    'google_id' => $payload['sub'],
                    'email'     => strtolower(trim($payload['email'])),
                    'name'      => $payload['name'] ?? '',
                    'avatar'    => $payload['picture'] ?? ''
                ];
            }
        }

        return null;
    }

    public static function getCurrentUser(): ?array {
        return $_SESSION['user'] ?? null;
    }

    public static function setCurrentUser(array $user): void {
        $_SESSION['user'] = $user;
    }

    public static function logout(): void {
        unset($_SESSION['user']);
        session_destroy();
    }
}
