/**
 * LOGIC TRANG CHẤM CÔNG MA TRẬN
 */

let currentBranchId = 1;
let currentSalaryType = 'FIXED';
let currentMonth = 10;
let currentYear = 2026;
let currentMatrixData = null;
let currentEditingEmp = null;

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
      loadAttendanceMatrix();
    });
  }

  // Chọn tháng / năm
  document.getElementById('select-month')?.addEventListener('change', (e) => {
    currentMonth = parseInt(e.target.value);
    loadAttendanceMatrix();
  });
  document.getElementById('select-year')?.addEventListener('change', (e) => {
    currentYear = parseInt(e.target.value);
    loadAttendanceMatrix();
  });

  // Chuyển Tab Lương Cứng <-> Lương Giờ
  document.getElementById('tab-fixed')?.addEventListener('click', () => switchTab('FIXED'));
  document.getElementById('tab-hourly')?.addEventListener('click', () => switchTab('HOURLY'));

  // Nút Lưu trong Modal
  document.getElementById('btn-save-attendance')?.addEventListener('click', handleSaveAttendance);

  // Đăng xuất & Toggle Sidebar
  document.getElementById('btn-logout')?.addEventListener('click', () => auth.logout());
  document.getElementById('btn-toggle-sidebar')?.addEventListener('click', () => {
    document.querySelector('.app-sidebar')?.classList.toggle('show');
  });

  // Tải dữ liệu ban đầu
  await loadAttendanceMatrix();
});

function switchTab(type) {
  currentSalaryType = type;
  document.querySelectorAll('.tab-pill').forEach(btn => btn.classList.remove('active'));
  if (type === 'FIXED') {
    document.getElementById('tab-fixed')?.classList.add('active');
  } else {
    document.getElementById('tab-hourly')?.classList.add('active');
  }
  loadAttendanceMatrix();
}

async function loadAttendanceMatrix() {
  const branchName = currentBranchId === 1 ? 'Chi nhánh Càng Long' : 'Chi nhánh Tân Nhựt';
  const typeText = currentSalaryType === 'FIXED' ? 'Lương Cứng' : 'Lương Theo Giờ';
  document.getElementById('page-branch-title').textContent = `${branchName} — ${typeText}`;
  document.getElementById('matrix-title').textContent = `Ma trận ngày công — Tháng ${currentMonth}/${currentYear} (${typeText})`;

  const tbody = document.getElementById('matrix-tbody');
  tbody.innerHTML = `<tr><td colspan="40" style="text-align: center; padding: 40px; color: var(--color-text-secondary);">Đang nạp dữ liệu ma trận...</td></tr>`;

  const res = await api.get('attendance.php', {
    branch_id: currentBranchId,
    salary_type: currentSalaryType,
    month: currentMonth,
    year: currentYear
  });

  if (res.status === 'success' && res.data) {
    currentMatrixData = res.data;
    renderMatrixTable(res.data);
  } else {
    tbody.innerHTML = `<tr><td colspan="40" style="text-align: center; padding: 40px; color: var(--color-danger);">Lỗi nạp dữ liệu: ${res.message}</td></tr>`;
  }
}

function renderMatrixTable(data) {
  const daysInMonth = data.days_in_month || 31;
  const employees = data.employees || [];
  const thead = document.getElementById('matrix-thead');
  const tbody = document.getElementById('matrix-tbody');
  const today = new Date();
  const isCurrentMonthYear = today.getMonth() + 1 === currentMonth && today.getFullYear() === currentYear;
  const todayDate = today.getDate();

  // 1. RENDER TIÊU ĐỀ BẢNG (THEAD)
  let headerHtml = `
    <tr>
      <th class="sticky-col-code text-left">Mã GV</th>
      <th class="sticky-col-name text-left">Họ và Tên</th>
  `;

  for (let d = 1; d <= daysInMonth; d++) {
    const dateObj = new Date(currentYear, currentMonth - 1, d);
    const dayOfWeek = dateObj.getDay(); // 0 = CN, 6 = T7
    let colClass = '';
    let dayName = `T${dayOfWeek + 1}`;
    if (dayOfWeek === 0) {
      colClass = 'day-sunday';
      dayName = 'CN';
    } else if (dayOfWeek === 6) {
      colClass = 'day-sat';
      dayName = 'T7';
    }
    if (isCurrentMonthYear && d === todayDate) {
      colClass += ' day-today';
    }

    headerHtml += `
      <th class="matrix-day-cell ${colClass}" title="Ngày ${d}/${currentMonth} (${dayName})">
        <div>${d}</div>
        <div style="font-size: 10px; font-weight: normal; color: inherit;">${dayName}</div>
      </th>
    `;
  }

  // Cột tổng hợp
  if (currentSalaryType === 'FIXED') {
    headerHtml += `
      <th style="background: var(--color-surface-muted);">Công (X)</th>
      <th style="background: var(--color-surface-muted);">Giờ TC</th>
      <th style="background: var(--color-surface-muted);">Trễ (p)</th>
    </tr>`;
  } else {
    headerHtml += `
      <th style="background: var(--color-surface-muted);">Tổng ca</th>
      <th style="background: var(--color-surface-muted);">Bán trú</th>
    </tr>`;
  }
  thead.innerHTML = headerHtml;

  // 2. RENDER DÒNG NHÂN VIÊN (TBODY)
  if (employees.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${daysInMonth + 5}" style="text-align: center; padding: 30px; color: var(--color-text-secondary);">Chưa có giáo viên thuộc diện ${currentSalaryType === 'FIXED' ? 'Lương cứng' : 'Lương giờ'} ở chi nhánh này.</td></tr>`;
    return;
  }

  let bodyHtml = '';
  employees.forEach(emp => {
    let rowXCount = 0;
    let rowOtHours = 0;
    let rowLateMins = 0;
    let rowTotalSlots = 0;
    let rowBoardingCount = 0;

    let cellsHtml = '';
    for (let d = 1; d <= daysInMonth; d++) {
      const att = emp.attendance_days[d];
      let cellText = '-';
      let cellClass = 'cell-none';

      if (currentSalaryType === 'FIXED') {
        if (att) {
          const sym = att.salary_symbol || att.work_symbol || '-';
          cellText = sym;
          if (sym === 'X') {
            cellClass = 'cell-x';
            rowXCount += 1;
          } else if (sym === 'X + TC' || sym === 'X+TC') {
            cellClass = 'cell-tc';
            rowXCount += 1;
            rowOtHours += parseFloat(att.ot_salary_hours || att.ot_hours || 0);
          } else if (sym === 'P') {
            cellClass = 'cell-leave';
          } else if (sym === 'K' || sym === 'Thiếu') {
            cellClass = 'cell-absent';
          }
          if (att.late_minutes > 0) {
            rowLateMins += parseInt(att.late_minutes);
          }
        }
      } else {
        // Lương giờ
        if (att) {
          const slots = parseFloat(att.actual_slots || att.total_slots || 0);
          const hasBt = parseInt(att.has_boarding || 0) === 1;
          if (slots > 0 && hasBt) {
            cellText = `${slots}+BT`;
            cellClass = 'cell-tc';
          } else if (slots > 0) {
            cellText = `${slots}`;
            cellClass = 'cell-x';
          } else if (hasBt) {
            cellText = 'BT';
            cellClass = 'cell-tc';
          }
          rowTotalSlots += slots;
          if (hasBt) rowBoardingCount++;
        }
      }

      cellsHtml += `
        <td class="matrix-day-cell ${cellClass}" onclick="openAttendanceModal(${emp.id}, ${d})" title="Nhấp để sửa ngày ${d}">
          ${cellText}
        </td>
      `;
    }

    // Các cột tổng hợp cuối dòng
    let summaryCols = '';
    if (currentSalaryType === 'FIXED') {
      summaryCols = `
        <td style="font-weight: 700; color: var(--color-accent);">${rowXCount}</td>
        <td style="font-weight: 700; color: var(--color-primary);">${rowOtHours > 0 ? rowOtHours + 'h' : '-'}</td>
        <td style="font-weight: 600; color: ${rowLateMins > 0 ? 'var(--color-warning)' : 'inherit'};">${rowLateMins > 0 ? rowLateMins + 'p' : '-'}</td>
      `;
    } else {
      summaryCols = `
        <td style="font-weight: 700; color: var(--color-accent);">${rowTotalSlots} ca</td>
        <td style="font-weight: 700; color: var(--color-primary);">${rowBoardingCount > 0 ? rowBoardingCount + ' buổi' : '-'}</td>
      `;
    }

    bodyHtml += `
      <tr>
        <td class="sticky-col-code text-left"><strong style="color: var(--color-primary);">${emp.employee_code}</strong></td>
        <td class="sticky-col-name text-left"><strong>${emp.full_name}</strong></td>
        ${cellsHtml}
        ${summaryCols}
      </tr>
    `;
  });

  tbody.innerHTML = bodyHtml;
}

// Mở Modal chấm công cho 1 ô ngày
window.openAttendanceModal = function(empId, day) {
  if (!currentMatrixData) return;
  const emp = currentMatrixData.employees.find(e => e.id == empId);
  if (!emp) return;

  currentEditingEmp = emp;
  const workDate = `${currentYear}-${String(currentMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  const att = emp.attendance_days[day] || {};

  document.getElementById('modal-emp-id').value = empId;
  document.getElementById('modal-work-date').value = workDate;
  document.getElementById('modal-emp-info').textContent = `Chấm Công: ${emp.full_name} (${emp.employee_code})`;
  document.getElementById('modal-date-display').textContent = `Ngày: ${day}/${currentMonth}/${currentYear}`;
  document.getElementById('modal-contract-hours').textContent = `Khung giờ hợp đồng: ${emp.time_frame || 'Theo quy định'} (${emp.standard_hours || 8}h)`;

  if (currentSalaryType === 'FIXED') {
    document.getElementById('modal-fixed-inputs').style.display = 'block';
    document.getElementById('modal-hourly-inputs').style.display = 'none';

    document.getElementById('modal-time-in').value = att.time_in ? att.time_in.substring(0, 5) : (emp.default_time_in ? emp.default_time_in.substring(0, 5) : '08:00');
    document.getElementById('modal-time-out').value = att.time_out ? att.time_out.substring(0, 5) : (emp.default_time_out ? emp.default_time_out.substring(0, 5) : '17:30');
    document.getElementById('modal-work-symbol').value = att.work_symbol || 'X';
    document.getElementById('modal-is-ot').value = att.is_overtime ? '1' : '0';
  } else {
    document.getElementById('modal-fixed-inputs').style.display = 'none';
    document.getElementById('modal-hourly-inputs').style.display = 'block';

    document.getElementById('modal-morning-in').value = att.morning_in ? att.morning_in.substring(0, 5) : '';
    document.getElementById('modal-morning-out').value = att.morning_out ? att.morning_out.substring(0, 5) : '';
    document.getElementById('modal-afternoon-in').value = att.afternoon_in ? att.afternoon_in.substring(0, 5) : '';
    document.getElementById('modal-afternoon-out').value = att.afternoon_out ? att.afternoon_out.substring(0, 5) : '';
    document.getElementById('modal-evening-in').value = att.evening_in ? att.evening_in.substring(0, 5) : '';
    document.getElementById('modal-evening-out').value = att.evening_out ? att.evening_out.substring(0, 5) : '';
    document.getElementById('modal-has-boarding').value = att.has_boarding ? '1' : '0';
    document.getElementById('modal-actual-slots').value = att.actual_slots || att.total_slots || '';
  }

  document.getElementById('modal-notes').value = att.notes || '';
  document.getElementById('attendance-modal').classList.add('active');
};

window.closeAttendanceModal = function() {
  document.getElementById('attendance-modal').classList.remove('active');
};

async function handleSaveAttendance() {
  const empId = document.getElementById('modal-emp-id').value;
  const workDate = document.getElementById('modal-work-date').value;

  const payload = {
    employee_id: empId,
    work_date: workDate,
    notes: document.getElementById('modal-notes').value
  };

  if (currentSalaryType === 'FIXED') {
    payload.time_in = document.getElementById('modal-time-in').value;
    payload.time_out = document.getElementById('modal-time-out').value;
    payload.work_symbol = document.getElementById('modal-work-symbol').value;
    payload.is_overtime = parseInt(document.getElementById('modal-is-ot').value);
  } else {
    payload.morning_in = document.getElementById('modal-morning-in').value;
    payload.morning_out = document.getElementById('modal-morning-out').value;
    payload.afternoon_in = document.getElementById('modal-afternoon-in').value;
    payload.afternoon_out = document.getElementById('modal-afternoon-out').value;
    payload.evening_in = document.getElementById('modal-evening-in').value;
    payload.evening_out = document.getElementById('modal-evening-out').value;
    payload.has_boarding = parseInt(document.getElementById('modal-has-boarding').value);
    const slots = document.getElementById('modal-actual-slots').value;
    if (slots !== '') payload.actual_slots = parseFloat(slots);
  }

  const res = await api.post('attendance.php', payload);
  if (res.status === 'success') {
    utils.showToast('Đã lưu chấm công thành công!', 'success');
    closeAttendanceModal();
    // Tải lại bảng
    await loadAttendanceMatrix();
  } else {
    utils.showToast(res.message || 'Lỗi khi lưu chấm công', 'error');
  }
}
