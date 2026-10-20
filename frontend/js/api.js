/**
 * API WRAPPER: KẾT NỐI TRỰC TIẾP VỚI BACKEND PHP REST API & DATABASE MYSQL
 * 100% dữ liệu thực từ Cơ Sở Dữ Liệu
 */

const API_BASE = '../../backend/api';

const api = {
  // Lấy dữ liệu từ Database (GET)
  async get(endpoint, params = {}) {
    const url = new URL(`${API_BASE}/${endpoint}`, window.location.origin + window.location.pathname);
    Object.keys(params).forEach(key => {
      if (params[key] !== undefined && params[key] !== null) {
        url.searchParams.append(key, params[key]);
      }
    });

    try {
      const response = await fetch(url.toString(), {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' }
      });
      return await response.json();
    } catch (error) {
      console.error(`[Database API Error] GET ${endpoint}:`, error);
      return { 
        status: 'error', 
        message: 'Không thể kết nối đến máy chủ PHP/MySQL. Vui lòng kiểm tra Apache & MySQL trong XAMPP.' 
      };
    }
  },

  // Gửi dữ liệu tạo mới vào Database (POST)
  async post(endpoint, body = {}) {
    const url = `${API_BASE}/${endpoint}`;
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      });
      return await response.json();
    } catch (error) {
      console.error(`[Database API Error] POST ${endpoint}:`, error);
      return { 
        status: 'error', 
        message: 'Không thể gửi dữ liệu lên máy chủ PHP/MySQL.' 
      };
    }
  },

  // Cập nhật dữ liệu vào Database (PUT)
  async put(endpoint, body = {}) {
    const url = `${API_BASE}/${endpoint}`;
    try {
      const response = await fetch(url, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      });
      return await response.json();
    } catch (error) {
      console.error(`[Database API Error] PUT ${endpoint}:`, error);
      return { 
        status: 'error', 
        message: 'Không thể cập nhật dữ liệu vào Database.' 
      };
    }
  },

  // Xóa dữ liệu trong Database (DELETE)
  async delete(endpoint, params = {}) {
    const url = new URL(`${API_BASE}/${endpoint}`, window.location.origin + window.location.pathname);
    Object.keys(params).forEach(key => url.searchParams.append(key, params[key]));

    try {
      const response = await fetch(url.toString(), {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' }
      });
      return await response.json();
    } catch (error) {
      console.error(`[Database API Error] DELETE ${endpoint}:`, error);
      return { 
        status: 'error', 
        message: 'Không thể xóa dữ liệu trong Database.' 
      };
    }
  }
};
