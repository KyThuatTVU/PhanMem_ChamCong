/**
 * LOGIC TRANG QUẢN LÝ HỒ SƠ GIÁO VIÊN
 */

let currentBranchId = 1;
let currentSalaryTypeFilter = '';
let allEmployees = [];

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
      loadEmployees();
    });
  }

  // Bộ lọc loại lương
  document.getElementById('filter-all')?.addEventListener('click', () => setFilter(''));
  document.getElementById('filter-fixed')?.addEventListener('click', () => setFilter('FIXED'));
  document.getElementById('filter-hourly')?.addEventListener('click', () => setFilter('HOURLY'));

  // Tìm kiếm
  document.getElementById('input-search')?.addEventListener('input', (e) => {
    filterAndRender(e.target.value.toLowerCase().trim());
  });

  // Modal Thêm mới
  document.getElementById('btn-add-employee')?.addEventListener('click', openAddModal);
  document.getElementById('btn-save-employee')?.addEventListener('click', saveEmployee);

  // Thay đổi Loại lương trong Form -> ẩn/hiện trường lương
  document.getElementById('emp-form-salary-type')?.addEventListener('change', (e) => {
    toggleSalaryFields(e.target.value);
  });

  document.getElementById('btn-logout')?.addEventListener('click', () => auth.logout());
  document.getElementById('btn-toggle-sidebar')?.addEventListener('click', () => {
    document.querySelector('.app-sidebar')?.classList.toggle('show');
  });

  await loadEmployees();
});

function setFilter(type) {
  currentSalaryTypeFilter = type;
  document.querySelectorAll('.tab-pill').forEach(btn => btn.classList.remove('active'));
  if (!type) document.getElementById('filter-all')?.classList.add('active');
  if (type === 'FIXED') document.getElementById('filter-fixed')?.classList.add('active');
  if (type === 'HOURLY') document.getElementById('filter-hourly')?.classList.add('active');
  filterAndRender();
}

async function loadEmployees() {
  const branchName = currentBranchId === 1 ? 'Chi nhánh Càng Long' : 'Chi nhánh Tân Nhựt';
  document.getElementById('page-branch-title').textContent = `Hồ Sơ Giáo Viên — ${branchName}`;

  const tbody = document.getElementById('employee-tbody');
  tbody.innerHTML = `<tr><td colspan="9" style="text-align: center; padding: 40px; color: var(--color-text-secondary);">Đang nạp dữ liệu...</td></tr>`;

  const res = await api.get('employees.php', { branch_id: currentBranchId });
  if (res.status === 'success' && res.data) {
    allEmployees = res.data;
    filterAndRender();
  } else {
    tbody.innerHTML = `<tr><td colspan="9" style="text-align: center; padding: 40px; color: var(--color-danger);">Lỗi: ${res.message}</td></tr>`;
  }
}

function filterAndRender(searchTerm = '') {
  let list = allEmployees;
  if (currentSalaryTypeFilter) {
    list = list.filter(e => e.salary_type === currentSalaryTypeFilter);
  }
  if (searchTerm) {
    list = list.filter(e => 
      e.full_name.toLowerCase().includes(searchTerm) || 
      e.employee_code.toLowerCase().includes(searchTerm) ||
      (e.phone && e.phone.includes(searchTerm))
    );
  }

  const tbody = document.getElementById('employee-tbody');
  if (list.length === 0) {
    tbody.innerHTML = `<tr><td colspan="9" style="text-align: center; padding: 30px; color: var(--color-text-secondary);">Không tìm thấy giáo viên nào phù hợp.</td></tr>`;
    return;
  }

  tbody.innerHTML = list.map(emp => {
    const isFixed = emp.salary_type === 'FIXED';
    const typeBadge = isFixed 
      ? `<span class="badge badge-success">Lương cứng</span>` 
      : `<span class="badge badge-warning">Lương theo giờ</span>`;
    const salaryDisplay = isFixed 
      ? `${utils.formatCurrency(emp.base_salary)} / tháng` 
      : `${utils.formatCurrency(emp.hourly_rate)} / ca`;
    
    // Gộp các phụ cấp
    const allowances = [];
    if (emp.attendance_allowance > 0) allowances.push(`CC: ${utils.formatCurrency(emp.attendance_allowance)}`);
    if (emp.boarding_allowance > 0) allowances.push(`BT: ${utils.formatCurrency(emp.boarding_allowance)}`);
    const allowStr = allowances.length > 0 ? allowances.join(', ') : '-';

    return `
      <tr>
        <td><strong style="color: var(--color-primary);">${emp.employee_code}</strong></td>
        <td><strong>${emp.full_name}</strong></td>
        <td>${emp.position || '-'}</td>
        <td>${emp.phone || '-'}</td>
        <td>${typeBadge}</td>
        <td><strong>${salaryDisplay}</strong></td>
        <td><span style="font-size: 12px; color: var(--color-text-secondary);">${allowStr}</span></td>
        <td><span style="font-size: 12px; color: var(--color-text-secondary);">${emp.time_frame || '-'}</span></td>
        <td style="text-align: right;">
          <button class="btn btn-secondary btn-sm" onclick="openEditModal(${emp.id})" title="Chỉnh sửa hồ sơ">
            <i data-lucide="edit-2"></i>
          </button>
          <button class="btn btn-secondary btn-sm" onclick="deleteEmployee(${emp.id})" title="Chuyển trạng thái nghỉ việc" style="color: var(--color-danger);">
            <i data-lucide="trash-2"></i>
          </button>
        </td>
      </tr>
    `;
  }).join('');

  utils.initIcons();
}

function toggleSalaryFields(type) {
  if (type === 'FIXED') {
    document.getElementById('group-base-salary').style.display = 'block';
    document.getElementById('group-hourly-rate').style.display = 'none';
  } else {
    document.getElementById('group-base-salary').style.display = 'none';
    document.getElementById('group-hourly-rate').style.display = 'block';
  }
}

function openAddModal() {
  document.getElementById('emp-modal-title').textContent = 'Thêm Hồ Sơ Giáo Viên Mới';
  document.getElementById('emp-form-id').value = '';
  document.getElementById('emp-form-code').value = '';
  document.getElementById('emp-form-name').value = '';
  document.getElementById('emp-form-position').value = '';
  document.getElementById('emp-form-phone').value = '';
  document.getElementById('emp-form-salary-type').value = 'FIXED';
  document.getElementById('emp-form-base-salary').value = '';
  document.getElementById('emp-form-hourly-rate').value = '';
  document.getElementById('emp-form-ot-rate').value = '120000';
  document.getElementById('emp-form-att-rate').value = '';
  document.getElementById('emp-form-board-rate').value = '';
  document.getElementById('emp-form-time-frame').value = '8:00 - 17:30 (9h30)';
  document.getElementById('emp-form-std-hours').value = '8.0';
  document.getElementById('emp-form-time-in').value = '08:00';
  document.getElementById('emp-form-time-out').value = '17:30';

  toggleSalaryFields('FIXED');
  document.getElementById('employee-modal').classList.add('active');
}

window.openEditModal = function(id) {
  const emp = allEmployees.find(e => e.id == id);
  if (!emp) return;

  document.getElementById('emp-modal-title').textContent = `Chỉnh Sửa: ${emp.full_name} (${emp.employee_code})`;
  document.getElementById('emp-form-id').value = emp.id;
  document.getElementById('emp-form-code').value = emp.employee_code;
  document.getElementById('emp-form-name').value = emp.full_name;
  document.getElementById('emp-form-position').value = emp.position || '';
  document.getElementById('emp-form-phone').value = emp.phone || '';
  document.getElementById('emp-form-salary-type').value = emp.salary_type;
  document.getElementById('emp-form-base-salary').value = emp.base_salary || '';
  document.getElementById('emp-form-hourly-rate').value = emp.hourly_rate || '';
  document.getElementById('emp-form-ot-rate').value = emp.overtime_rate || '120000';
  document.getElementById('emp-form-att-rate').value = emp.attendance_allowance || '';
  document.getElementById('emp-form-board-rate').value = emp.boarding_allowance || '';
  document.getElementById('emp-form-time-frame').value = emp.time_frame || '';
  document.getElementById('emp-form-std-hours').value = emp.standard_hours || '8.0';
  document.getElementById('emp-form-time-in').value = emp.default_time_in ? emp.default_time_in.substring(0, 5) : '';
  document.getElementById('emp-form-time-out').value = emp.default_time_out ? emp.default_time_out.substring(0, 5) : '';

  toggleSalaryFields(emp.salary_type);
  document.getElementById('employee-modal').classList.add('active');
};

window.closeEmployeeModal = function() {
  document.getElementById('employee-modal').classList.remove('active');
};

async function saveEmployee() {
  const id = document.getElementById('emp-form-id').value;
  const code = document.getElementById('emp-form-code').value.trim();
  const name = document.getElementById('emp-form-name').value.trim();

  if (!code || !name) {
    utils.showToast('Vui lòng điền Mã GV và Họ tên', 'error');
    return;
  }

  const payload = {
    branch_id: currentBranchId,
    employee_code: code,
    full_name: name,
    position: document.getElementById('emp-form-position').value.trim(),
    phone: document.getElementById('emp-form-phone').value.trim(),
    salary_type: document.getElementById('emp-form-salary-type').value,
    base_salary: parseFloat(document.getElementById('emp-form-base-salary').value) || 0,
    hourly_rate: parseFloat(document.getElementById('emp-form-hourly-rate').value) || 0,
    overtime_rate: parseFloat(document.getElementById('emp-form-ot-rate').value) || 120000,
    attendance_allowance: parseFloat(document.getElementById('emp-form-att-rate').value) || 0,
    boarding_allowance: parseFloat(document.getElementById('emp-form-board-rate').value) || 0,
    time_frame: document.getElementById('emp-form-time-frame').value.trim(),
    standard_hours: parseFloat(document.getElementById('emp-form-std-hours').value) || 8.0,
    default_time_in: document.getElementById('emp-form-time-in').value || null,
    default_time_out: document.getElementById('emp-form-time-out').value || null
  };

  let res;
  if (id) {
    payload.id = parseInt(id);
    res = await api.put('employees.php', payload);
  } else {
    res = await api.post('employees.php', payload);
  }

  if (res.status === 'success') {
    utils.showToast(id ? 'Cập nhật thành công!' : 'Thêm giáo viên mới thành công!', 'success');
    closeEmployeeModal();
    await loadEmployees();
  } else {
    utils.showToast(res.message || 'Lỗi khi lưu dữ liệu', 'error');
  }
}

window.deleteEmployee = async function(id) {
  const emp = allEmployees.find(e => e.id == id);
  const name = emp ? `${emp.full_name} (${emp.employee_code})` : 'giáo viên này';

  const choice = prompt(
    `Bạn muốn xử lý hồ sơ "${name}":\n` +
    `1. Nhập '1' để chuyển trạng thái [NGHỈ VIỆC] (Lưu lại lịch sử chấm công các tháng cũ - Khuyên dùng)\n` +
    `2. Nhập '2' để [XÓA VĨNH VIỄN] khỏi cơ sở dữ liệu (Dành cho trường hợp nhập nhầm)\n` +
    `Hoặc bấm Cancel / Hủy để quay lại.`
  );

  if (choice === '1') {
    const res = await api.delete('employees.php', { id: id });
    if (res.status === 'success') {
      utils.showToast('Đã chuyển giáo viên sang trạng thái nghỉ việc', 'success');
      await loadEmployees();
    } else {
      utils.showToast(res.message || 'Lỗi khi cập nhật trạng thái', 'error');
    }
  } else if (choice === '2') {
    if (!confirm(`CẢNH BÁO: Bạn có chắc chắn muốn XÓA VĨNH VIỄN "${name}"? Toàn bộ dữ liệu liên quan sẽ bị xóa sạch.`)) return;

    const res = await api.delete('employees.php', { id: id, permanent: 1 });
    if (res.status === 'success') {
      utils.showToast('Đã xóa vĩnh viễn giáo viên khỏi Database', 'success');
      await loadEmployees();
    } else {
      utils.showToast(res.message || 'Lỗi khi xóa', 'error');
    }
  }
};
