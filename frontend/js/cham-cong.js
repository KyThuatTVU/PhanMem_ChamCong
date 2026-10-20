/**
 * LOGIC TRANG CHẤM CÔNG CHI TIẾT THEO NGÀY (EXCEL FORM) & MA TRẬN THÁNG
 */

let currentBranchId = 1;
let currentSalaryType = 'FIXED';
let currentMode = 'daily'; // 'daily' hoặc 'matrix'
let currentWorkDate = '2026-10-20'; // Mặc định ngày 20/10/2026
let currentMonth = 10;
let currentYear = 2026;
let dailyEmployeesList = [];
let matrixData = null;

const DAY_NAMES = ['CHỦ NHẬT', 'THỨ HAI', 'THỨ BA', 'THỨ TƯ', 'THỨ NĂM', 'THỨ SÁU', 'THỨ BẢY'];

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
      refreshView();
    });
  }

  // Chuyển chế độ xem: Theo Ngày vs Ma Trận
  document.getElementById('view-mode-daily')?.addEventListener('click', () => setMode('daily'));
  document.getElementById('view-mode-matrix')?.addEventListener('click', () => setMode('matrix'));

  // Chuyển Tab Lương Cứng vs Lương Giờ
  document.getElementById('tab-fixed')?.addEventListener('click', () => setSalaryType('FIXED'));
  document.getElementById('tab-hourly')?.addEventListener('click', () => setSalaryType('HOURLY'));

  // Điều khiển ngày (Daily View)
  const dateInput = document.getElementById('input-daily-date');
  if (dateInput) {
    dateInput.value = currentWorkDate;
    dateInput.addEventListener('change', (e) => {
      currentWorkDate = e.target.value;
      loadDailyAttendance();
    });
  }

  document.getElementById('btn-today')?.addEventListener('click', () => {
    const today = new Date();
    currentWorkDate = today.toISOString().split('T')[0];
    dateInput.value = currentWorkDate;
    loadDailyAttendance();
  });

  document.getElementById('btn-prev-day')?.addEventListener('click', () => changeDay(-1));
  document.getElementById('btn-next-day')?.addEventListener('click', () => changeDay(1));

  // Điều khiển tháng / năm (Matrix View)
  document.getElementById('select-month')?.addEventListener('change', (e) => {
    currentMonth = parseInt(e.target.value);
    loadMatrixAttendance();
  });
  document.getElementById('select-year')?.addEventListener('change', (e) => {
    currentYear = parseInt(e.target.value);
    loadMatrixAttendance();
  });

  // Nút Lưu Toàn Bộ Bảng Ngày
  document.getElementById('btn-save-all-daily')?.addEventListener('click', saveAllDailyRecords);

  document.getElementById('btn-logout')?.addEventListener('click', () => auth.logout());
  document.getElementById('btn-toggle-sidebar')?.addEventListener('click', () => {
    document.querySelector('.app-sidebar')?.classList.toggle('show');
  });

  refreshView();
});

function changeDay(offset) {
  const [y, m, d] = currentWorkDate.split('-').map(Number);
  const dt = new Date(y, m - 1, d + offset);
  currentWorkDate = dt.toISOString().split('T')[0];
  document.getElementById('input-daily-date').value = currentWorkDate;
  loadDailyAttendance();
}

function setMode(mode) {
  currentMode = mode;
  document.getElementById('view-mode-daily')?.classList.toggle('active', mode === 'daily');
  document.getElementById('view-mode-matrix')?.classList.toggle('active', mode === 'matrix');

  document.getElementById('section-daily-view').style.display = mode === 'daily' ? 'block' : 'none';
  document.getElementById('section-matrix-view').style.display = mode === 'matrix' ? 'block' : 'none';

  document.getElementById('group-filter-daily').style.display = mode === 'daily' ? 'flex' : 'none';
  document.getElementById('group-filter-matrix').style.display = mode === 'matrix' ? 'flex' : 'none';
  document.getElementById('btn-save-all-daily').style.display = mode === 'daily' ? 'inline-flex' : 'none';

  refreshView();
}

function setSalaryType(type) {
  currentSalaryType = type;
  document.getElementById('tab-fixed')?.classList.toggle('active', type === 'FIXED');
  document.getElementById('tab-hourly')?.classList.toggle('active', type === 'HOURLY');

  document.getElementById('daily-table-fixed').style.display = type === 'FIXED' ? 'table' : 'none';
  document.getElementById('daily-table-hourly').style.display = type === 'HOURLY' ? 'table' : 'none';

  refreshView();
}

function refreshView() {
  const branchName = currentBranchId === 1 ? 'Chi nhánh Càng Long' : 'Chi nhánh Tân Nhựt';
  const typeText = currentSalaryType === 'FIXED' ? 'Lương Cứng' : 'Lương Theo Giờ';
  document.getElementById('page-branch-title').textContent = `${branchName} — ${typeText}`;

  if (currentMode === 'daily') {
    loadDailyAttendance();
  } else {
    loadMatrixAttendance();
  }
}

// =========================================================================
// 1. CHẾ ĐỘ XEM CHI TIẾT THEO NGÀY (CHUẨN FORM EXCEL TRONG ẢNH)
// =========================================================================
async function loadDailyAttendance() {
  const [y, m, d] = currentWorkDate.split('-').map(Number);
  const dateObj = new Date(y, m - 1, d);
  const dayOfWeekName = DAY_NAMES[dateObj.getDay()];

  // Cập nhật banner giống hệt ảnh Excel
  document.getElementById('daily-banner-title').textContent = `📅 NGÀY ${String(d).padStart(2, '0')}/${String(m).padStart(2, '0')}/${y} - ${dayOfWeekName}`;

  const tbodyFixed = document.getElementById('daily-tbody-fixed');
  const tbodyHourly = document.getElementById('daily-tbody-hourly');

  if (currentSalaryType === 'FIXED') {
    tbodyFixed.innerHTML = `<tr><td colspan="13" style="padding: 30px; text-align: center;">Đang nạp dữ liệu chi tiết ngày...</td></tr>`;
  } else {
    tbodyHourly.innerHTML = `<tr><td colspan="19" style="padding: 30px; text-align: center;">Đang nạp dữ liệu chi tiết ca...</td></tr>`;
  }

  const res = await api.get('attendance.php', {
    view: 'daily',
    branch_id: currentBranchId,
    salary_type: currentSalaryType,
    work_date: currentWorkDate
  });

  if (res.status === 'success' && res.data) {
    dailyEmployeesList = res.data.employees || [];
    if (currentSalaryType === 'FIXED') {
      renderDailyFixedTable(dailyEmployeesList);
    } else {
      renderDailyHourlyTable(dailyEmployeesList);
    }
  } else {
    const errMsg = `<tr><td colspan="20" style="padding: 30px; text-align: center; color: var(--color-danger);">Lỗi nạp dữ liệu: ${res.message}</td></tr>`;
    if (currentSalaryType === 'FIXED') tbodyFixed.innerHTML = errMsg;
    else tbodyHourly.innerHTML = errMsg;
  }
}

// Render bảng Lương Cứng (Ảnh 1)
function renderDailyFixedTable(employees) {
  const tbody = document.getElementById('daily-tbody-fixed');
  if (employees.length === 0) {
    tbody.innerHTML = `<tr><td colspan="13" style="text-align: center; padding: 30px; color: var(--color-text-secondary);">Không có giáo viên lương cứng nào.</td></tr>`;
    return;
  }

  let html = '';
  employees.forEach((emp, index) => {
    const att = emp.attendance || {};
    const timeIn = att.time_in ? att.time_in.substring(0, 5) : '';
    const timeOut = att.time_out ? att.time_out.substring(0, 5) : '';
    const isEntered = Boolean(timeIn && timeOut);
    const rowClass = isEntered ? '' : 'row-unentered'; // Tô màu đỏ nếu chưa nhập giống hệt ảnh Excel

    // Tính thời gian làm việc
    let workDurationText = '-';
    let otHoursVal = att.ot_hours || 0;
    let lateMinsVal = att.late_minutes || 0;
    if (isEntered) {
      const [hIn, mIn] = timeIn.split(':').map(Number);
      const [hOut, mOut] = timeOut.split(':').map(Number);
      let diffMins = (hOut * 60 + mOut) - (hIn * 60 + mIn);
      if (diffMins < 0) diffMins += 1440;
      const hours = Math.floor(diffMins / 60);
      const mins = diffMins % 60;
      workDurationText = `${hours}h ${mins}p`;
    }

    const isOt = att.is_overtime == 1 || (att.work_symbol && att.work_symbol.includes('TC'));
    const workSymbol = att.work_symbol || (isEntered ? (isOt ? 'X + TC' : 'X') : '-');
    const confirmStatus = att.confirmation_status || (isEntered ? 'Đã xác nhận' : 'Chưa nhập');

    html += `
      <tr class="${rowClass}" id="fixed-row-${emp.id}">
        <td><strong>${index + 1}</strong></td>
        <td><strong style="color: var(--color-primary);">${emp.employee_code}</strong></td>
        <td class="text-left"><strong>${emp.full_name}</strong></td>
        <td class="text-left" style="font-size: 12px;">${emp.position || '-'}</td>
        <td style="font-size: 12px; font-weight: 500;">${emp.time_frame || '8:00 - 17:30 (9h30)'}</td>
        
        <td>
          <input type="time" class="cell-input-time" id="in-tin-${emp.id}" value="${timeIn}" 
                 onchange="onFixedInputChange(${emp.id})">
        </td>
        <td>
          <input type="time" class="cell-input-time" id="in-tout-${emp.id}" value="${timeOut}" 
                 onchange="onFixedInputChange(${emp.id})">
        </td>

        <td id="txt-duration-${emp.id}" style="font-weight: 600;">${workDurationText}</td>
        <td id="txt-late-${emp.id}" style="color: ${lateMinsVal > 0 ? '#B91C1C' : 'inherit'}; font-weight: 600;">${lateMinsVal}</td>
        
        <td>
          <select class="cell-select" id="sel-ot-${emp.id}" onchange="onFixedInputChange(${emp.id})">
            <option value="0" ${!isOt ? 'selected' : ''}>Không</option>
            <option value="1" ${isOt ? 'selected' : ''}>Có</option>
          </select>
        </td>

        <td id="txt-othours-${emp.id}" style="font-weight: 600;">${otHoursVal > 0 ? parseFloat(otHoursVal).toFixed(2) : '-'}</td>
        
        <td>
          <select class="cell-select" id="sel-sym-${emp.id}" style="font-weight: 700; color: var(--color-accent);" onchange="onFixedStatusChange(${emp.id})">
            <option value="X" ${workSymbol === 'X' ? 'selected' : ''}>X</option>
            <option value="X + TC" ${workSymbol === 'X + TC' ? 'selected' : ''}>X + TC</option>
            <option value="P" ${workSymbol === 'P' ? 'selected' : ''}>P</option>
            <option value="K" ${workSymbol === 'K' ? 'selected' : ''}>K</option>
            <option value="Thiếu" ${workSymbol === 'Thiếu' ? 'selected' : ''}>Thiếu</option>
            <option value="-" ${workSymbol === '-' ? 'selected' : ''}>-</option>
          </select>
        </td>

        <td id="txt-confirm-${emp.id}">
          <span class="${isEntered ? 'badge-excel-confirmed' : 'badge-excel-unentered'}">
            ${confirmStatus}
          </span>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

// Tự động tính toán khi gõ Giờ vào / Giờ ra lương cứng
window.onFixedInputChange = function(empId) {
  const emp = dailyEmployeesList.find(e => e.id == empId);
  if (!emp) return;

  const tin = document.getElementById(`in-tin-${empId}`).value;
  const tout = document.getElementById(`in-tout-${empId}`).value;
  const isOtSel = document.getElementById(`sel-ot-${empId}`).value === '1';
  const row = document.getElementById(`fixed-row-${empId}`);

  if (tin && tout) {
    row.classList.remove('row-unentered');
    document.getElementById(`txt-confirm-${empId}`).innerHTML = `<span class="badge-excel-confirmed">Đã xác nhận</span>`;

    // Tính phút đi làm
    const [hIn, mIn] = tin.split(':').map(Number);
    const [hOut, mOut] = tout.split(':').map(Number);
    let diffMins = (hOut * 60 + mOut) - (hIn * 60 + mIn);
    if (diffMins < 0) diffMins += 1440;
    const hours = Math.floor(diffMins / 60);
    const mins = diffMins % 60;
    document.getElementById(`txt-duration-${empId}`).textContent = `${hours}h ${mins}p`;

    // Tính đi trễ so với default_time_in (mặc định 08:00)
    let lateMins = 0;
    const defInStr = emp.default_time_in ? emp.default_time_in.substring(0, 5) : '08:00';
    const [defH, defM] = defInStr.split(':').map(Number);
    const inTotalMins = hIn * 60 + mIn;
    const defTotalMins = defH * 60 + defM;
    if (inTotalMins > defTotalMins) {
      lateMins = inTotalMins - defTotalMins;
    }
    document.getElementById(`txt-late-${empId}`).textContent = lateMins;
    document.getElementById(`txt-late-${empId}`).style.color = lateMins > 0 ? '#B91C1C' : 'inherit';

    // Tính số giờ tăng ca
    const stdHours = parseFloat(emp.standard_hours || 8.0);
    const workedHours = diffMins / 60.0;
    let otHours = 0.0;
    if (isOtSel || workedHours > stdHours) {
      otHours = Math.max(0, workedHours - stdHours);
      if (otHours > 0) {
        document.getElementById(`sel-ot-${empId}`).value = '1';
      }
    }
    document.getElementById(`txt-othours-${empId}`).textContent = otHours > 0 ? otHours.toFixed(2) : '-';

    // Đánh dấu ký hiệu công X hoặc X + TC (Thỏa giờ quy định)
    const symSel = document.getElementById(`sel-sym-${empId}`);
    if (otHours > 0 || isOtSel) {
      symSel.value = 'X + TC';
    } else {
      symSel.value = 'X';
    }

    // Tự động lưu dòng này xuống Database
    saveSingleDailyFixed(empId);
  } else {
    row.classList.add('row-unentered');
    document.getElementById(`txt-confirm-${empId}`).innerHTML = `<span class="badge-excel-unentered">Chưa nhập</span>`;
    document.getElementById(`txt-duration-${empId}`).textContent = '-';
    document.getElementById(`txt-late-${empId}`).textContent = '0';
    document.getElementById(`txt-othours-${empId}`).textContent = '-';
    document.getElementById(`sel-sym-${empId}`).value = '-';
  }
};

window.onFixedStatusChange = function(empId) {
  saveSingleDailyFixed(empId);
};

// Render bảng Lương Theo Giờ (Ảnh 2)
function renderDailyHourlyTable(employees) {
  const tbody = document.getElementById('daily-tbody-hourly');
  if (employees.length === 0) {
    tbody.innerHTML = `<tr><td colspan="19" style="text-align: center; padding: 30px; color: var(--color-text-secondary);">Không có giáo viên lương giờ nào.</td></tr>`;
    return;
  }

  let html = '';
  employees.forEach((emp, index) => {
    const att = emp.attendance || {};
    const sin = att.morning_in ? att.morning_in.substring(0, 5) : '';
    const sout = att.morning_out ? att.morning_out.substring(0, 5) : '';
    const smins = att.morning_minutes || 0;

    const cin = att.afternoon_in ? att.afternoon_in.substring(0, 5) : '';
    const cout = att.afternoon_out ? att.afternoon_out.substring(0, 5) : '';
    const cmins = att.afternoon_minutes || 0;

    const tin = att.evening_in ? att.evening_in.substring(0, 5) : '';
    const tout = att.evening_out ? att.evening_out.substring(0, 5) : '';
    const tmins = att.evening_minutes || 0;

    const totMins = att.total_minutes || 0;
    const totSlots = att.total_slots || 0;
    const actualSlots = att.actual_slots !== undefined && att.actual_slots !== null ? att.actual_slots : totSlots;
    const note = att.notes || '';

    const isEntered = Boolean(sin || sout || cin || cout || tin || tout || totMins > 0);
    const rowClass = isEntered ? '' : 'row-unentered'; // Hàng chưa nhập tô đỏ y hệt ảnh 2
    const confirmStatus = att.confirmation_status || (isEntered ? 'Đã xác nhận' : 'Chưa nhập');

    html += `
      <tr class="${rowClass}" id="hourly-row-${emp.id}">
        <td><strong>${index + 1}</strong></td>
        <td><strong style="color: var(--color-primary);">${emp.employee_code}</strong></td>
        <td class="text-left"><strong>${emp.full_name}</strong></td>
        <td class="text-left" style="font-size: 12px;">${emp.position || '-'}</td>
        <td style="font-size: 12px; font-weight: 500;">${emp.time_frame || 'Linh động (1 ca)'}</td>

        <!-- CA SÁNG -->
        <td><input type="time" class="cell-input-time" id="h-sin-${emp.id}" value="${sin}" onchange="onHourlyInputChange(${emp.id})"></td>
        <td><input type="time" class="cell-input-time" id="h-sout-${emp.id}" value="${sout}" onchange="onHourlyInputChange(${emp.id})"></td>
        <td id="txt-smins-${emp.id}" style="font-weight: 600;">${smins > 0 ? smins : '-'}</td>

        <!-- CA CHIỀU -->
        <td><input type="time" class="cell-input-time" id="h-cin-${emp.id}" value="${cin}" onchange="onHourlyInputChange(${emp.id})"></td>
        <td><input type="time" class="cell-input-time" id="h-cout-${emp.id}" value="${cout}" onchange="onHourlyInputChange(${emp.id})"></td>
        <td id="txt-cmins-${emp.id}" style="font-weight: 600;">${cmins > 0 ? cmins : '-'}</td>

        <!-- CA TỐI -->
        <td><input type="time" class="cell-input-time" id="h-tin-${emp.id}" value="${tin}" onchange="onHourlyInputChange(${emp.id})"></td>
        <td><input type="time" class="cell-input-time" id="h-tout-${emp.id}" value="${tout}" onchange="onHourlyInputChange(${emp.id})"></td>
        <td id="txt-tmins-${emp.id}" style="font-weight: 600;">${tmins > 0 ? tmins : '-'}</td>

        <!-- TỔNG PHÚT & TỔNG CA -->
        <td id="txt-totmins-${emp.id}" style="font-weight: 700; color: var(--color-secondary);">${totMins > 0 ? totMins : '-'}</td>
        <td id="txt-totslots-${emp.id}" style="font-weight: 700; color: var(--color-primary);">${totSlots > 0 ? parseFloat(totSlots).toFixed(1) : '-'}</td>

        <td id="txt-hconfirm-${emp.id}">
          <span class="${isEntered ? 'badge-excel-confirmed' : 'badge-excel-unentered'}">${confirmStatus}</span>
        </td>

        <!-- GHI CHÚ -->
        <td>
          <input type="text" class="form-control" id="h-note-${emp.id}" value="${note}" 
                 placeholder="Ghi chú ca..." style="padding: 4px 8px; font-size: 11.5px;" onchange="saveSingleDailyHourly(${emp.id})">
        </td>

        <!-- 👉 SỐ CA THỰC TẾ (CỐ ĐỊNH THEO Ý NGƯỜI DÙNG) -->
        <td style="background: #ECFEFF !important;">
          <input type="number" step="0.5" class="cell-input-number" id="h-actslots-${emp.id}" 
                 value="${actualSlots > 0 ? parseFloat(actualSlots).toFixed(1) : ''}" 
                 placeholder="0.0" title="Nếu nhiều ca quá thì điền cố định số ca thực tế vào đây" 
                 onchange="saveSingleDailyHourly(${emp.id})">
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

// Tự động tính toán khi nhập các ca sáng/chiều/tối
window.onHourlyInputChange = function(empId) {
  const calcMins = (inId, outId) => {
    const tin = document.getElementById(inId).value;
    const tout = document.getElementById(outId).value;
    if (!tin || !tout) return 0;
    const [hIn, mIn] = tin.split(':').map(Number);
    const [hOut, mOut] = tout.split(':').map(Number);
    let diff = (hOut * 60 + mOut) - (hIn * 60 + mIn);
    if (diff < 0) diff += 1440;
    return Math.max(0, diff);
  };

  const smins = calcMins(`h-sin-${empId}`, `h-sout-${empId}`);
  const cmins = calcMins(`h-cin-${empId}`, `h-cout-${empId}`);
  const tmins = calcMins(`h-tin-${empId}`, `h-tout-${empId}`);

  document.getElementById(`txt-smins-${empId}`).textContent = smins > 0 ? smins : '-';
  document.getElementById(`txt-cmins-${empId}`).textContent = cmins > 0 ? cmins : '-';
  document.getElementById(`txt-tmins-${empId}`).textContent = tmins > 0 ? tmins : '-';

  const totMins = smins + cmins + tmins;
  document.getElementById(`txt-totmins-${empId}`).textContent = totMins > 0 ? totMins : '-';

  // Quy đổi số ca: 90 phút = 1 ca
  const totSlots = totMins > 0 ? Math.round((totMins / 90.0) * 10) / 10 : 0;
  document.getElementById(`txt-totslots-${empId}`).textContent = totSlots > 0 ? totSlots.toFixed(1) : '-';

  const row = document.getElementById(`hourly-row-${empId}`);
  const actInput = document.getElementById(`h-actslots-${empId}`);

  if (totMins > 0) {
    row.classList.remove('row-unentered');
    document.getElementById(`txt-hconfirm-${empId}`).innerHTML = `<span class="badge-excel-confirmed">Đã xác nhận</span>`;
    // Nếu ô số ca thực tế chưa có người điền, tự động điền theo tổng ca
    if (!actInput.value) {
      actInput.value = totSlots.toFixed(1);
    }
  } else {
    row.classList.add('row-unentered');
    document.getElementById(`txt-hconfirm-${empId}`).innerHTML = `<span class="badge-excel-unentered">Chưa nhập</span>`;
  }

  saveSingleDailyHourly(empId);
};

// Lưu 1 dòng lương cứng
async function saveSingleDailyFixed(empId) {
  const tin = document.getElementById(`in-tin-${empId}`).value;
  const tout = document.getElementById(`in-tout-${empId}`).value;
  const isOt = parseInt(document.getElementById(`sel-ot-${empId}`).value);
  const sym = document.getElementById(`sel-sym-${empId}`).value;

  const payload = {
    employee_id: empId,
    work_date: currentWorkDate,
    time_in: tin || null,
    time_out: tout || null,
    is_overtime: isOt,
    work_symbol: sym
  };

  const res = await api.post('attendance.php', payload);
  if (res.status === 'success') {
    utils.showToast(`Đã lưu công ngày ${currentWorkDate}`, 'success');
  }
}

// Lưu 1 dòng lương giờ
async function saveSingleDailyHourly(empId) {
  const sin = document.getElementById(`h-sin-${empId}`).value;
  const sout = document.getElementById(`h-sout-${empId}`).value;
  const cin = document.getElementById(`h-cin-${empId}`).value;
  const cout = document.getElementById(`h-cout-${empId}`).value;
  const tin = document.getElementById(`h-tin-${empId}`).value;
  const tout = document.getElementById(`h-tout-${empId}`).value;
  const note = document.getElementById(`h-note-${empId}`).value.trim();
  const actVal = document.getElementById(`h-actslots-${empId}`).value;

  const payload = {
    employee_id: empId,
    work_date: currentWorkDate,
    morning_in: sin || null,
    morning_out: sout || null,
    afternoon_in: cin || null,
    afternoon_out: cout || null,
    evening_in: tin || null,
    evening_out: tout || null,
    notes: note,
    actual_slots: actVal !== '' ? parseFloat(actVal) : null
  };

  const res = await api.post('attendance.php', payload);
  if (res.status === 'success') {
    utils.showToast(`Đã lưu ca dạy ngày ${currentWorkDate}`, 'success');
  }
}

// Lưu toàn bộ bảng ngày khi bấm nút "Lưu Bảng Công Ngày"
async function saveAllDailyRecords() {
  utils.showToast('Đang lưu toàn bộ dữ liệu ngày...', 'info');

  const batch = [];
  if (currentSalaryType === 'FIXED') {
    dailyEmployeesList.forEach(emp => {
      const tin = document.getElementById(`in-tin-${emp.id}`)?.value;
      const tout = document.getElementById(`in-tout-${emp.id}`)?.value;
      const isOt = parseInt(document.getElementById(`sel-ot-${emp.id}`)?.value || '0');
      const sym = document.getElementById(`sel-sym-${emp.id}`)?.value || '-';
      batch.push({
        employee_id: emp.id,
        work_date: currentWorkDate,
        time_in: tin || null,
        time_out: tout || null,
        is_overtime: isOt,
        work_symbol: sym
      });
    });
  } else {
    dailyEmployeesList.forEach(emp => {
      const sin = document.getElementById(`h-sin-${emp.id}`)?.value;
      const sout = document.getElementById(`h-sout-${emp.id}`)?.value;
      const cin = document.getElementById(`h-cin-${emp.id}`)?.value;
      const cout = document.getElementById(`h-cout-${emp.id}`)?.value;
      const tin = document.getElementById(`h-tin-${emp.id}`)?.value;
      const tout = document.getElementById(`h-tout-${emp.id}`)?.value;
      const note = document.getElementById(`h-note-${emp.id}`)?.value.trim();
      const actVal = document.getElementById(`h-actslots-${emp.id}`)?.value;
      batch.push({
        employee_id: emp.id,
        work_date: currentWorkDate,
        morning_in: sin || null,
        morning_out: sout || null,
        afternoon_in: cin || null,
        afternoon_out: cout || null,
        evening_in: tin || null,
        evening_out: tout || null,
        notes: note,
        actual_slots: actVal !== '' ? parseFloat(actVal) : null
      });
    });
  }

  const res = await api.post('attendance.php', { batch: batch });
  if (res.status === 'success') {
    utils.showToast('Đã lưu thành công toàn bộ dữ liệu ngày vào Database!', 'success');
    await loadDailyAttendance();
  } else {
    utils.showToast(res.message || 'Lỗi khi lưu bảng ngày', 'error');
  }
}

// =========================================================================
// 2. CHẾ ĐỘ XEM BẢNG MA TRẬN CẢ THÁNG (1 -> 31 NGÀY)
// =========================================================================
async function loadMatrixAttendance() {
  const tbody = document.getElementById('matrix-tbody');
  tbody.innerHTML = `<tr><td colspan="40" style="text-align: center; padding: 40px; color: var(--color-text-secondary);">Đang nạp dữ liệu ma trận...</td></tr>`;

  const res = await api.get('attendance.php', {
    branch_id: currentBranchId,
    salary_type: currentSalaryType,
    month: currentMonth,
    year: currentYear
  });

  if (res.status === 'success' && res.data) {
    matrixData = res.data;
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

  let headerHtml = `
    <tr>
      <th class="sticky-col-code text-left">Mã GV</th>
      <th class="sticky-col-name text-left">Họ và Tên</th>
  `;

  for (let d = 1; d <= daysInMonth; d++) {
    const dateObj = new Date(currentYear, currentMonth - 1, d);
    const dayOfWeek = dateObj.getDay();
    let colClass = dayOfWeek === 0 ? 'day-sunday' : (dayOfWeek === 6 ? 'day-sat' : '');
    const dayName = dayOfWeek === 0 ? 'CN' : `T${dayOfWeek + 1}`;
    headerHtml += `
      <th class="matrix-day-cell ${colClass}">
        <div>${d}</div>
        <div style="font-size: 10px; font-weight: normal;">${dayName}</div>
      </th>
    `;
  }

  if (currentSalaryType === 'FIXED') {
    headerHtml += `<th>Công (X)</th><th>Giờ TC</th><th>Trễ (p)</th></tr>`;
  } else {
    headerHtml += `<th>Tổng ca</th><th>Bán trú</th></tr>`;
  }
  thead.innerHTML = headerHtml;

  if (employees.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${daysInMonth + 5}" style="text-align: center; padding: 30px;">Chưa có dữ liệu.</td></tr>`;
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
          if (att.late_minutes > 0) rowLateMins += parseInt(att.late_minutes);
        }
      } else {
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
        <td class="matrix-day-cell ${cellClass}" onclick="jumpToDailyDate(${d})" title="Nhấp để xem chi tiết ngày ${d}">
          ${cellText}
        </td>
      `;
    }

    let summaryCols = '';
    if (currentSalaryType === 'FIXED') {
      summaryCols = `
        <td style="font-weight: 700; color: var(--color-accent);">${rowXCount}</td>
        <td style="font-weight: 700; color: var(--color-primary);">${rowOtHours > 0 ? rowOtHours + 'h' : '-'}</td>
        <td style="font-weight: 600; color: ${rowLateMins > 0 ? '#B91C1C' : 'inherit'};">${rowLateMins > 0 ? rowLateMins + 'p' : '-'}</td>
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

window.jumpToDailyDate = function(day) {
  currentWorkDate = `${currentYear}-${String(currentMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  document.getElementById('input-daily-date').value = currentWorkDate;
  setMode('daily');
};
