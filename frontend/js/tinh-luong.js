/**
 * LOGIC TRANG TÍNH LƯƠNG & XUẤT BẢNG LƯƠNG
 */

let currentBranchId = 1;
let currentSalaryType = 'FIXED';
let currentMonth = 10;
let currentYear = 2026;
let payrollList = [];

document.addEventListener('DOMContentLoaded', async () => {
  await auth.checkSession();
  utils.initIcons();

  currentBranchId = utils.getCurrentBranchId();
  const branchSelect = document.getElementById('sidebar-branch-select');
  if (branchSelect) {
    branchSelect.value = currentBranchId;
    branchSelect.addEventListener('change', (e) => {
      currentBranchId = parseInt(e.target.value);
      utils.setCurrentBranchId(currentBranchId);
      loadPayroll();
    });
  }

  document.getElementById('select-month')?.addEventListener('change', (e) => {
    currentMonth = parseInt(e.target.value);
    loadPayroll();
  });
  document.getElementById('select-year')?.addEventListener('change', (e) => {
    currentYear = parseInt(e.target.value);
    loadPayroll();
  });

  document.getElementById('tab-fixed')?.addEventListener('click', () => switchTab('FIXED'));
  document.getElementById('tab-hourly')?.addEventListener('click', () => switchTab('HOURLY'));

  document.getElementById('btn-recalculate')?.addEventListener('click', () => {
    utils.showToast('Đang tính lại lương...', 'info');
    loadPayroll();
  });

  document.getElementById('btn-save-adjustment')?.addEventListener('click', saveAdjustment);

  document.getElementById('btn-logout')?.addEventListener('click', () => auth.logout());
  document.getElementById('btn-toggle-sidebar')?.addEventListener('click', () => {
    document.querySelector('.app-sidebar')?.classList.toggle('show');
  });

  await loadPayroll();
});

function switchTab(type) {
  currentSalaryType = type;
  document.querySelectorAll('.tab-pill').forEach(b => b.classList.remove('active'));
  if (type === 'FIXED') {
    document.getElementById('tab-fixed')?.classList.add('active');
  } else {
    document.getElementById('tab-hourly')?.classList.add('active');
  }
  loadPayroll();
}

async function loadPayroll() {
  const branchName = currentBranchId === 1 ? 'Chi nhánh Càng Long' : 'Chi nhánh Tân Nhựt';
  const typeText = currentSalaryType === 'FIXED' ? 'Lương Cứng' : 'Lương Theo Giờ';
  document.getElementById('page-branch-title').textContent = `Bảng Lương — ${branchName} (${typeText})`;
  document.getElementById('payroll-card-title').textContent = `Bảng Lương Tháng ${currentMonth}/${currentYear} — ${typeText}`;

  const thead = document.getElementById('payroll-thead');
  const tbody = document.getElementById('payroll-tbody');
  tbody.innerHTML = `<tr><td colspan="15" style="text-align: center; padding: 40px; color: var(--color-text-secondary);">Đang tính toán lương...</td></tr>`;

  const res = await api.get('payroll.php', {
    branch_id: currentBranchId,
    salary_type: currentSalaryType,
    month: currentMonth,
    year: currentYear
  });

  if (res.status === 'success' && res.data) {
    payrollList = res.data.payroll_list || [];
    renderPayrollTable();
  } else {
    tbody.innerHTML = `<tr><td colspan="15" style="text-align: center; padding: 40px; color: var(--color-danger);">Lỗi: ${res.message}</td></tr>`;
  }
}

function renderPayrollTable() {
  const thead = document.getElementById('payroll-thead');
  const tbody = document.getElementById('payroll-tbody');

  let totalExpense = 0;

  if (currentSalaryType === 'FIXED') {
    thead.innerHTML = `
      <tr>
        <th>Mã GV</th>
        <th>Họ và Tên</th>
        <th>Lương Cơ Bản</th>
        <th>Công (X)</th>
        <th>Lương Ngày Công</th>
        <th>Tiền TC</th>
        <th>Bán Trú</th>
        <th>Chuyên Cần</th>
        <th>Tiền Cơm</th>
        <th>Thưởng</th>
        <th>Khấu Trừ</th>
        <th>THỰC LĨNH</th>
        <th style="text-align: right;">Thao Tác</th>
      </tr>
    `;

    if (payrollList.length === 0) {
      tbody.innerHTML = `<tr><td colspan="13" style="text-align: center; padding: 30px; color: var(--color-text-secondary);">Chưa có dữ liệu tính lương.</td></tr>`;
      return;
    }

    tbody.innerHTML = payrollList.map(item => {
      totalExpense += parseFloat(item.net_salary || 0);
      return `
        <tr>
          <td><strong style="color: var(--color-primary);">${item.employee_code}</strong></td>
          <td><strong>${item.full_name}</strong></td>
          <td>${utils.formatCurrency(item.base_salary)}</td>
          <td><strong style="color: var(--color-accent);">${item.total_days_x} ngày</strong></td>
          <td><strong>${utils.formatCurrency(item.salary_by_days)}</strong></td>
          <td>${item.ot_pay > 0 ? utils.formatCurrency(item.ot_pay) : '-'}</td>
          <td>${item.boarding_pay > 0 ? utils.formatCurrency(item.boarding_pay) : '-'}</td>
          <td>${item.attendance_allowance > 0 ? utils.formatCurrency(item.attendance_allowance) : '-'}</td>
          <td>${item.lunch_allowance > 0 ? utils.formatCurrency(item.lunch_allowance) : '-'}</td>
          <td style="color: var(--color-accent);">${item.bonus > 0 ? '+' + utils.formatCurrency(item.bonus) : '-'}</td>
          <td style="color: var(--color-danger);">${item.deductions > 0 ? '-' + utils.formatCurrency(item.deductions) : '-'}</td>
          <td><strong style="font-size: 15px; color: var(--color-accent);">${utils.formatCurrency(item.net_salary)}</strong></td>
          <td style="text-align: right;">
            <button class="btn btn-secondary btn-sm" onclick="openAdjustmentModal(${item.id})" title="Thưởng / Khấu trừ">
              <i data-lucide="sliders"></i>
            </button>
            <a href="phieu-luong.html?employee_id=${item.id}&month=${currentMonth}&year=${currentYear}" target="_blank" class="btn btn-secondary btn-sm" title="In phiếu lương">
              <i data-lucide="printer"></i> Phiếu
            </a>
          </td>
        </tr>
      `;
    }).join('');
  } else {
    // LƯƠNG THEO GIỜ
    thead.innerHTML = `
      <tr>
        <th>Mã GV</th>
        <th>Họ và Tên</th>
        <th>Tổng Ca Dạy</th>
        <th>Đơn Giá / Ca</th>
        <th>Lương Theo Ca</th>
        <th>Phụ Cấp Bán Trú</th>
        <th>Thưởng</th>
        <th>Khấu Trừ</th>
        <th>THỰC LĨNH</th>
        <th style="text-align: right;">Thao Tác</th>
      </tr>
    `;

    if (payrollList.length === 0) {
      tbody.innerHTML = `<tr><td colspan="10" style="text-align: center; padding: 30px; color: var(--color-text-secondary);">Chưa có dữ liệu tính lương.</td></tr>`;
      return;
    }

    tbody.innerHTML = payrollList.map(item => {
      totalExpense += parseFloat(item.net_salary || 0);
      return `
        <tr>
          <td><strong style="color: var(--color-primary);">${item.employee_code}</strong></td>
          <td><strong>${item.full_name}</strong></td>
          <td><strong style="color: var(--color-accent);">${item.total_slots} ca</strong></td>
          <td>${utils.formatCurrency(item.hourly_rate)}</td>
          <td><strong>${utils.formatCurrency(item.salary_by_slots)}</strong></td>
          <td>${item.boarding_pay > 0 ? utils.formatCurrency(item.boarding_pay) + ` (${item.total_boarding_days} buổi)` : '-'}</td>
          <td style="color: var(--color-accent);">${item.bonus > 0 ? '+' + utils.formatCurrency(item.bonus) : '-'}</td>
          <td style="color: var(--color-danger);">${item.deductions > 0 ? '-' + utils.formatCurrency(item.deductions) : '-'}</td>
          <td><strong style="font-size: 15px; color: var(--color-accent);">${utils.formatCurrency(item.net_salary)}</strong></td>
          <td style="text-align: right;">
            <button class="btn btn-secondary btn-sm" onclick="openAdjustmentModal(${item.id})" title="Thưởng / Khấu trừ">
              <i data-lucide="sliders"></i>
            </button>
            <a href="phieu-luong.html?employee_id=${item.id}&month=${currentMonth}&year=${currentYear}" target="_blank" class="btn btn-secondary btn-sm" title="In phiếu lương">
              <i data-lucide="printer"></i> Phiếu
            </a>
          </td>
        </tr>
      `;
    }).join('');
  }

  document.getElementById('summary-total-cost').textContent = `Tổng chi lương: ${utils.formatCurrency(totalExpense)}`;
  utils.initIcons();
}

window.openAdjustmentModal = function(empId) {
  const item = payrollList.find(p => p.id == empId);
  if (!item) return;

  document.getElementById('adj-emp-id').value = empId;
  document.getElementById('adj-emp-name').textContent = `Điều Chỉnh Lương: ${item.full_name} (${item.employee_code})`;
  document.getElementById('adj-bonus').value = item.bonus || '';
  document.getElementById('adj-deductions').value = item.deductions || '';
  document.getElementById('adj-note').value = item.note || '';

  document.getElementById('adjustment-modal').classList.add('active');
};

window.closeAdjustmentModal = function() {
  document.getElementById('adjustment-modal').classList.remove('active');
};

async function saveAdjustment() {
  const empId = document.getElementById('adj-emp-id').value;
  const bonus = parseFloat(document.getElementById('adj-bonus').value) || 0;
  const deductions = parseFloat(document.getElementById('adj-deductions').value) || 0;
  const note = document.getElementById('adj-note').value.trim();

  const res = await api.post('payroll.php', {
    employee_id: empId,
    month: currentMonth,
    year: currentYear,
    bonus: bonus,
    deductions: deductions,
    note: note
  });

  if (res.status === 'success') {
    utils.showToast('Đã lưu điều chỉnh lương thành công!', 'success');
    closeAdjustmentModal();
    await loadPayroll();
  } else {
    utils.showToast(res.message || 'Lỗi khi lưu điều chỉnh', 'error');
  }
}
