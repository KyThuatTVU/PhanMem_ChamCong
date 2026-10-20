/**
 * LOGIC TRANG DASHBOARD TỔNG QUAN
 */

document.addEventListener('DOMContentLoaded', async () => {
  // 1. Kiểm tra xác thực
  await auth.checkSession();
  utils.initIcons();

  // 2. Chạy đồng hồ thời gian thực
  initLiveClock();

  // 3. Xử lý chuyển đổi chi nhánh
  const branchSelect = document.getElementById('sidebar-branch-select');
  const currentBranchId = utils.getCurrentBranchId();
  if (branchSelect) {
    branchSelect.value = currentBranchId;
    branchSelect.addEventListener('change', (e) => {
      utils.setCurrentBranchId(e.target.value);
      loadDashboardData();
    });
  }

  // 4. Xử lý nút đăng xuất & toggle sidebar trên di động
  document.getElementById('btn-logout')?.addEventListener('click', () => auth.logout());
  document.getElementById('btn-toggle-sidebar')?.addEventListener('click', () => {
    document.querySelector('.app-sidebar')?.classList.toggle('show');
  });

  // 5. Nạp dữ liệu
  await loadDashboardData();
});

function initLiveClock() {
  const clockEl = document.getElementById('live-clock');
  const dateEl = document.getElementById('current-date-text');

  const update = () => {
    const now = new Date();
    const timeStr = now.toLocaleTimeString('vi-VN', { hour12: false });
    const dateStr = now.toLocaleDateString('vi-VN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
    if (clockEl) clockEl.textContent = timeStr;
    if (dateEl) dateEl.textContent = dateStr.charAt(0).toUpperCase() + dateStr.slice(1);
  };
  update();
  setInterval(update, 1000);
}

async function loadDashboardData() {
  const branchId = utils.getCurrentBranchId();
  const branchName = branchId === 1 ? 'Chi nhánh Càng Long' : 'Chi nhánh Tân Nhựt';
  const pageTitle = document.getElementById('page-branch-title');
  if (pageTitle) pageTitle.textContent = branchName;

  // Lấy danh sách giáo viên của chi nhánh
  const res = await api.get('employees.php', { branch_id: branchId });
  const tbody = document.getElementById('quick-employee-tbody');

  if (res.status === 'success' && res.data) {
    const employees = res.data;
    const fixedCount = employees.filter(e => e.salary_type === 'FIXED').length;
    const hourlyCount = employees.filter(e => e.salary_type === 'HOURLY').length;

    // Cập nhật số liệu thống kê KPI
    document.getElementById('stat-total-emp').textContent = employees.length;
    document.getElementById('stat-fixed-emp').textContent = fixedCount;
    document.getElementById('stat-hourly-emp').textContent = hourlyCount;

    // Render bảng tóm tắt
    if (employees.length === 0) {
      tbody.innerHTML = `<tr><td colspan="8" style="text-align:center; padding: 30px; color: var(--color-text-secondary);">Chưa có dữ liệu giáo viên cho chi nhánh này.</td></tr>`;
      return;
    }

    tbody.innerHTML = employees.map(emp => {
      const isFixed = emp.salary_type === 'FIXED';
      const salaryDisplay = isFixed 
        ? `${utils.formatCurrency(emp.base_salary)} / tháng`
        : `${utils.formatCurrency(emp.hourly_rate)} / ca`;
      const typeBadge = isFixed
        ? `<span class="badge badge-success">Lương cứng</span>`
        : `<span class="badge badge-warning">Lương theo giờ</span>`;

      return `
        <tr>
          <td><strong style="color: var(--color-primary);">${emp.employee_code}</strong></td>
          <td><strong>${emp.full_name}</strong></td>
          <td>${emp.position || '-'}</td>
          <td>${emp.phone || '-'}</td>
          <td>${typeBadge}</td>
          <td><strong>${salaryDisplay}</strong></td>
          <td><span style="font-size: 12px; color: var(--color-text-secondary);">${emp.time_frame || '-'}</span></td>
          <td>
            <a href="cham-cong.html" class="btn btn-secondary btn-sm" title="Vào chấm công">
              <i data-lucide="calendar"></i> Chấm công
            </a>
          </td>
        </tr>
      `;
    }).join('');

    utils.initIcons();
  } else {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align:center; padding: 30px; color: var(--color-danger);">Lỗi tải danh sách giáo viên: ${res.message}</td></tr>`;
  }
}
