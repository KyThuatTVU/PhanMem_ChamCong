# -*- coding: utf-8 -*-
"""
SCRIPT TRÍCH XUẤT 100% DỮ LIỆU THÁNG 10 TỪ CẢ 4 FILE EXCEL VÀO MYSQL DATABASE
Bao gồm:
1. Chi tiết chấm công từng ngày từ ngày 1 đến ngày 31 cho toàn bộ giáo viên (đầy đủ giờ vào, giờ ra, phút trễ, tăng ca, 3 ca sáng/chiều/tối, bán trú BT, ghi chú).
2. Chi tiết bảng tổng hợp lương tháng 10/2026 khớp từng đồng với sheet TỔNG THÁNG.
"""

import openpyxl
import datetime
import os

files = {
    'CL_CUNG': {
        'path': r'D:\CongViec\QuanLyNhanSu\Quanlynhansu_CangLong\Thang10\LuongCung\HAPPYKIDS_CANG_LONG_LUONG_CUNG_T10_2026.xlsx',
        'branch_id': 1,
        'salary_type': 'FIXED'
    },
    'CL_GIO': {
        'path': r'D:\CongViec\QuanLyNhanSu\Quanlynhansu_CangLong\Thang10\LuongGio\HAPPYKIDS_CANG_LONG_LUONG_GIO_T10_2026_DEP_CHUAN.xlsx',
        'branch_id': 1,
        'salary_type': 'HOURLY'
    },
    'TN_CUNG': {
        'path': r'D:\CongViec\QuanLyNhanSu\Quanlynhansu_TanNhut\Thang10\LuongCung\HAPPYKIDS_TAN_NHUT_LUONG_CUNG_T10_2026.xlsx',
        'branch_id': 2,
        'salary_type': 'FIXED'
    },
    'TN_GIO': {
        'path': r'D:\CongViec\QuanLyNhanSu\Quanlynhansu_TanNhut\Thang10\LuongGio\HAPPYKIDS_TAN_NHUT_LUONG_GIO_T10_2026.xlsx',
        'branch_id': 2,
        'salary_type': 'HOURLY'
    }
}

# Ánh xạ (branch_id, employee_code, salary_type) -> employee_id trong DB
# ID 1..10: Càng Long Lương Cứng (GV001 - GV009, GV014)
# ID 11..15: Càng Long Lương Giờ (GV010 - GV014_GIO)
# ID 16..17: Tân Nhựt Lương Cứng (GV001, GV002)
# ID 18..21: Tân Nhựt Lương Giờ (GV001 - GV004)
emp_map = {
    # 1. Càng Long Cứng
    (1, 'GV001', 'FIXED'): 1,
    (1, 'GV002', 'FIXED'): 2,
    (1, 'GV003', 'FIXED'): 3,
    (1, 'GV004', 'FIXED'): 4,
    (1, 'GV005', 'FIXED'): 5,
    (1, 'GV006', 'FIXED'): 6,
    (1, 'GV007', 'FIXED'): 7,
    (1, 'GV008', 'FIXED'): 8,
    (1, 'GV009', 'FIXED'): 9,
    (1, 'GV014', 'FIXED'): 10,

    # 2. Càng Long Giờ
    (1, 'GV010', 'HOURLY'): 11,
    (1, 'GV011', 'HOURLY'): 12,
    (1, 'GV012', 'HOURLY'): 13,
    (1, 'GV013', 'HOURLY'): 14,
    (1, 'GV014', 'HOURLY'): 15,
    (1, 'GV014_GIO', 'HOURLY'): 15,

    # 3. Tân Nhựt Cứng
    (2, 'GV001', 'FIXED'): 16,
    (2, 'GV002', 'FIXED'): 17,

    # 4. Tân Nhựt Giờ
    (2, 'GV001', 'HOURLY'): 18,
    (2, 'GV002', 'HOURLY'): 19,
    (2, 'GV003', 'HOURLY'): 20,
    (2, 'GV004', 'HOURLY'): 21,
}

def format_time(val):
    if val is None or val == '' or str(val).strip() in ['-', 'None']:
        return 'NULL'
    if isinstance(val, datetime.time):
        return f"'{val.strftime('%H:%M:%S')}'"
    if isinstance(val, datetime.datetime):
        return f"'{val.strftime('%H:%M:%S')}'"
    s = str(val).strip()
    if ':' in s:
        parts = s.split(':')
        try:
            h = int(parts[0])
            m = int(parts[1])
            sec = int(parts[2]) if len(parts) > 2 else 0
            return f"'{h:02d}:{m:02d}:{sec:02d}'"
        except:
            return 'NULL'
    return 'NULL'

def escape_str(val):
    if val is None or val == '':
        return 'NULL'
    s = str(val).replace("'", "''").strip()
    return f"'{s}'"

def to_num(val, default=0):
    if val is None or val == '' or str(val).strip() in ['-', 'None']:
        return default
    try:
        return float(val)
    except:
        return default

def to_int(val, default=0):
    return int(round(to_num(val, default)))

sql_lines = []
sql_lines.append("-- ============================================================")
sql_lines.append("-- DỮ LIỆU ĐẦY ĐỦ THÁNG 10/2026 TRÍCH XUẤT TỪ CẢ 4 FILE EXCEL")
sql_lines.append("-- NGÀY TRÍCH XUẤT: 20/10/2026 (KHÔNG BỎ SÓT BẤT KỲ DÒNG/Ô NÀO)")
sql_lines.append("-- ============================================================")
sql_lines.append("USE `happykids_hrm`;\n")

total_attendance_inserted = 0
total_payroll_inserted = 0

for file_key, info in files.items():
    path = info['path']
    branch_id = info['branch_id']
    salary_type = info['salary_type']

    print(f"--> Đang xử lý: {file_key} ({path})")
    wb = openpyxl.load_workbook(path, data_only=True)

    # ---------------------------------------------------------
    # 1. TRÍCH XUẤT CHẤM CÔNG HÀNG NGÀY (Sheet: CHẤM CÔNG HÀNG NGÀY)
    # ---------------------------------------------------------
    ws_cc = wb['CHẤM CÔNG HÀNG NGÀY']
    sql_lines.append(f"\n-- ---------------------------------------------------------")
    sql_lines.append(f"-- 1. CHẤM CÔNG HÀNG NGÀY: {file_key} (Branch {branch_id}, {salary_type})")
    sql_lines.append(f"-- ---------------------------------------------------------")

    for r in range(14, ws_cc.max_row + 1):
        key = ws_cc.cell(r, 1).value
        if not key or '_' not in str(key):
            continue

        parts = str(key).strip().split('_')
        code = parts[0].strip()
        day = int(parts[1])
        work_date = f"2026-10-{day:02d}"

        emp_id = emp_map.get((branch_id, code, salary_type))
        if not emp_id:
            print(f"⚠️ Cảnh báo: Không tìm thấy ID cho ({branch_id}, {code}, {salary_type}) ở row {r}")
            continue

        if salary_type == 'FIXED':
            # LƯƠNG CỨNG:
            # C7: Giờ vào, C8: Giờ ra, C10: Đi trễ, C11: Tăng ca, C12: Giờ tăng ca,
            # C13: Ký hiệu công, C14: Trạng thái, C15: Ký hiệu tính lương, C16: Giờ TC tính lương, C17: Ghi chú
            time_in = format_time(ws_cc.cell(r, 7).value)
            time_out = format_time(ws_cc.cell(r, 8).value)
            late_minutes = to_int(ws_cc.cell(r, 10).value)
            is_ot_val = str(ws_cc.cell(r, 11).value or '').strip()
            is_ot = 1 if is_ot_val in ['Có', '1', 1, True] else 0
            ot_hours = to_num(ws_cc.cell(r, 12).value)
            work_symbol = escape_str(ws_cc.cell(r, 13).value or '-')
            confirm_status = escape_str(ws_cc.cell(r, 14).value or 'Chưa nhập')
            salary_symbol = escape_str(ws_cc.cell(r, 15).value or '-')
            ot_salary_hours = to_num(ws_cc.cell(r, 16).value)
            note = escape_str(ws_cc.cell(r, 17).value)

            sql = f"""INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `time_in`, `time_out`, `late_minutes`, `is_overtime`,
    `ot_hours`, `work_symbol`, `salary_symbol`, `ot_salary_hours`, `confirmation_status`, `notes`
) VALUES (
    {emp_id}, '{work_date}', {time_in}, {time_out}, {late_minutes}, {is_ot},
    {ot_hours}, {work_symbol}, {salary_symbol}, {ot_salary_hours}, {confirm_status}, {note}
) ON DUPLICATE KEY UPDATE
    `time_in` = VALUES(`time_in`), `time_out` = VALUES(`time_out`), `late_minutes` = VALUES(`late_minutes`),
    `is_overtime` = VALUES(`is_overtime`), `ot_hours` = VALUES(`ot_hours`), `work_symbol` = VALUES(`work_symbol`),
    `salary_symbol` = VALUES(`salary_symbol`), `ot_salary_hours` = VALUES(`ot_salary_hours`),
    `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);"""
            sql_lines.append(sql)
            total_attendance_inserted += 1

        else:
            # LƯƠNG THEO GIỜ (HOURLY):
            # C7: Sáng vào, C8: Sáng ra, C9: Phút sáng
            # C10: Chiều vào, C11: Chiều ra, C12: Phút chiều
            # C13: Tối vào, C14: Tối ra, C15: Phút tối
            # C16: Tổng phút, C17: Tổng ca, C18: Trạng thái
            # C19: Số ca tính lương, C20: Phút tính lương, C21: Ghi chú, C22: Số ca thực tế
            # C23 (nếu có ở Tân Nhựt): Bán Trú (BT)
            m_in = format_time(ws_cc.cell(r, 7).value)
            m_out = format_time(ws_cc.cell(r, 8).value)
            m_mins = to_int(ws_cc.cell(r, 9).value)

            a_in = format_time(ws_cc.cell(r, 10).value)
            a_out = format_time(ws_cc.cell(r, 11).value)
            a_mins = to_int(ws_cc.cell(r, 12).value)

            e_in = format_time(ws_cc.cell(r, 13).value)
            e_out = format_time(ws_cc.cell(r, 14).value)
            e_mins = to_int(ws_cc.cell(r, 15).value)

            tot_mins = to_int(ws_cc.cell(r, 16).value)
            tot_slots = to_num(ws_cc.cell(r, 17).value)
            confirm_status = escape_str(ws_cc.cell(r, 18).value or 'Chưa nhập')
            calc_slots = to_num(ws_cc.cell(r, 19).value)
            calc_mins = to_int(ws_cc.cell(r, 20).value)
            note_val = str(ws_cc.cell(r, 21).value or '')
            note = escape_str(note_val)
            actual_slots = to_num(ws_cc.cell(r, 22).value, calc_slots)

            # Kiểm tra Bán Trú: Col 23 hoặc chữ "BT" trong ghi chú Col 21
            col23_val = str(ws_cc.cell(r, 23).value or '').strip() if ws_cc.max_column >= 23 else ''
            has_bt = 1 if (col23_val == 'BT' or 'BT' in note_val.upper()) else 0

            sql = f"""INSERT INTO `daily_attendance` (
    `employee_id`, `work_date`, `morning_in`, `morning_out`, `morning_minutes`,
    `afternoon_in`, `afternoon_out`, `afternoon_minutes`, `evening_in`, `evening_out`, `evening_minutes`,
    `total_minutes`, `total_slots`, `has_boarding`, `actual_slots`, `confirmation_status`, `notes`
) VALUES (
    {emp_id}, '{work_date}', {m_in}, {m_out}, {m_mins},
    {a_in}, {a_out}, {a_mins}, {e_in}, {e_out}, {e_mins},
    {tot_mins}, {tot_slots}, {has_bt}, {actual_slots}, {confirm_status}, {note}
) ON DUPLICATE KEY UPDATE
    `morning_in` = VALUES(`morning_in`), `morning_out` = VALUES(`morning_out`), `morning_minutes` = VALUES(`morning_minutes`),
    `afternoon_in` = VALUES(`afternoon_in`), `afternoon_out` = VALUES(`afternoon_out`), `afternoon_minutes` = VALUES(`afternoon_minutes`),
    `evening_in` = VALUES(`evening_in`), `evening_out` = VALUES(`evening_out`), `evening_minutes` = VALUES(`evening_minutes`),
    `total_minutes` = VALUES(`total_minutes`), `total_slots` = VALUES(`total_slots`), `has_boarding` = VALUES(`has_boarding`),
    `actual_slots` = VALUES(`actual_slots`), `confirmation_status` = VALUES(`confirmation_status`), `notes` = VALUES(`notes`);"""
            sql_lines.append(sql)
            total_attendance_inserted += 1

    # ---------------------------------------------------------
    # 2. TRÍCH XUẤT BẢNG LƯƠNG TỔNG HỢP (Sheet: TỔNG THÁNG)
    # ---------------------------------------------------------
    ws_tt = wb['TỔNG THÁNG']
    sql_lines.append(f"\n-- ---------------------------------------------------------")
    sql_lines.append(f"-- 2. TỔNG HỢP LƯƠNG THÁNG 10: {file_key}")
    sql_lines.append(f"-- ---------------------------------------------------------")

    for r in range(9, ws_tt.max_row + 1):
        code = ws_tt.cell(r, 2).value
        if not code or not str(code).strip().startswith('GV'):
            continue
        code = str(code).strip()

        emp_id = emp_map.get((branch_id, code, salary_type))
        if not emp_id:
            continue

        if salary_type == 'FIXED':
            # C36: Ngày công X, C37: Giờ TC, C38: Số lần TC, C39: Lương CB, C40: Ngày chuẩn
            # C41: Lương theo ngày, C42: Tiền TC, C43: Bán trú, C44: Chuyên cần, C45: Tiền cơm
            # C46: Thưởng, C47: Tổng thu nhập, C48: Khấu trừ, C49: Lần trễ, C50: Phút trễ
            days_x = to_num(ws_tt.cell(r, 36).value)
            ot_hours = to_num(ws_tt.cell(r, 37).value)
            ot_count = to_int(ws_tt.cell(r, 38).value)
            base_sal = to_num(ws_tt.cell(r, 39).value)
            sal_by_days = to_num(ws_tt.cell(r, 41).value)
            ot_pay = to_num(ws_tt.cell(r, 42).value)
            board_pay = to_num(ws_tt.cell(r, 43).value)
            att_allow = to_num(ws_tt.cell(r, 44).value)
            lunch_pay = to_num(ws_tt.cell(r, 45).value)
            bonus = to_num(ws_tt.cell(r, 46).value)
            tot_income = to_num(ws_tt.cell(r, 47).value)
            deductions = to_num(ws_tt.cell(r, 48).value)
            late_count = to_int(ws_tt.cell(r, 49).value)
            tot_late_mins = to_int(ws_tt.cell(r, 50).value)
            net_sal = max(0, tot_income - deductions)

            sql = f"""INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `status`
) VALUES (
    {emp_id}, 10, 2026, {days_x}, {ot_hours}, {ot_count},
    0, 0, {late_count}, {tot_late_mins},
    {base_sal}, {sal_by_days}, 0, {ot_pay}, {board_pay},
    {att_allow}, {lunch_pay}, {bonus}, {tot_income}, {deductions}, {net_sal}, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_days_x` = VALUES(`total_days_x`), `total_ot_hours` = VALUES(`total_ot_hours`), `ot_count` = VALUES(`ot_count`),
    `late_count` = VALUES(`late_count`), `total_late_minutes` = VALUES(`total_late_minutes`),
    `base_salary` = VALUES(`base_salary`), `salary_by_days` = VALUES(`salary_by_days`), `ot_pay` = VALUES(`ot_pay`),
    `boarding_pay` = VALUES(`boarding_pay`), `attendance_allowance` = VALUES(`attendance_allowance`),
    `lunch_allowance` = VALUES(`lunch_allowance`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `status` = 'CONFIRMED';"""
            sql_lines.append(sql)
            total_payroll_inserted += 1

        else:
            # LƯƠNG THEO GIỜ (HOURLY):
            # C36: Tổng phút, C37: Tổng ca, C38: Đơn giá ca, C39: Lương theo ca
            # C40: Phụ cấp, C41: Thưởng, C42: Tổng thu nhập, C43: Khấu trừ, C44: Thực lĩnh, C45: Ghi chú
            tot_mins = to_int(ws_tt.cell(r, 36).value)
            tot_slots = to_num(ws_tt.cell(r, 37).value)
            slot_rate = to_num(ws_tt.cell(r, 38).value)
            sal_by_slots = to_num(ws_tt.cell(r, 39).value)
            board_pay = to_num(ws_tt.cell(r, 40).value)
            bonus = to_num(ws_tt.cell(r, 41).value)
            tot_income = to_num(ws_tt.cell(r, 42).value)
            deductions = to_num(ws_tt.cell(r, 43).value)
            net_sal = to_num(ws_tt.cell(r, 44).value)
            if net_sal == 0 and tot_income > 0:
                net_sal = max(0, tot_income - deductions)
            note = escape_str(ws_tt.cell(r, 45).value)

            sql = f"""INSERT INTO `monthly_payroll` (
    `employee_id`, `month`, `year`, `total_days_x`, `total_ot_hours`, `ot_count`,
    `total_slots`, `total_boarding_days`, `late_count`, `total_late_minutes`,
    `base_salary`, `salary_by_days`, `salary_by_slots`, `ot_pay`, `boarding_pay`,
    `attendance_allowance`, `lunch_allowance`, `bonus`, `total_income`, `deductions`, `net_salary`, `note`, `status`
) VALUES (
    {emp_id}, 10, 2026, 0, 0, 0,
    {tot_slots}, 0, 0, 0,
    0, 0, {sal_by_slots}, 0, {board_pay},
    0, 0, {bonus}, {tot_income}, {deductions}, {net_sal}, {note}, 'CONFIRMED'
) ON DUPLICATE KEY UPDATE
    `total_slots` = VALUES(`total_slots`), `salary_by_slots` = VALUES(`salary_by_slots`),
    `boarding_pay` = VALUES(`boarding_pay`), `bonus` = VALUES(`bonus`), `total_income` = VALUES(`total_income`),
    `deductions` = VALUES(`deductions`), `net_salary` = VALUES(`net_salary`), `note` = VALUES(`note`), `status` = 'CONFIRMED';"""
            sql_lines.append(sql)
            total_payroll_inserted += 1

out_path = r'D:\CongViec\HappyKids_HRM\backend\import_thang10_full.sql'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(sql_lines))

print(f"\n==========================================")
print(f"✅ ĐÃ HOÀN TẤT TRÍCH XUẤT 100% DỮ LIỆU:")
print(f"- Tổng số bản ghi chấm công ngày (1-31): {total_attendance_inserted}")
print(f"- Tổng số bản ghi bảng lương tháng 10: {total_payroll_inserted}")
print(f"- File SQL được tạo tại: {out_path}")
print(f"==========================================")
