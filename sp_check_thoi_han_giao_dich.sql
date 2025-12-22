DELIMITER $$

/*
 * ============================================================
 * Stored Procedure: sp_check_thoi_han_giao_dich
 *
 * Mô tả:
 *   Kiểm tra thời hạn giao dịch của khách hàng dựa trên CIF
 *
 * Input:
 *   - p_cif           : CIF khách hàng
 *   - p_ngay_dat_lenh : Ngày đặt lệnh giao dịch
 *
 * Output:
 *   - p_result :
 *       PASS              : Thời hạn hợp lệ
 *       FAIL_EXPIRED      : HMGD đã hết hạn
 *       FAIL_NO_CUSTOMER  : Không tồn tại khách hàng
 *       FAIL_NO_HMGD      : Khách hàng chưa có HMGD
 *       FAIL_INVALID_INPUT: Input không hợp lệ
 *
 * Quy tắc nghiệp vụ:
 *   ThoiHan >= NgayDatLenh  => PASS
 *   ThoiHan <  NgayDatLenh => FAIL
 * ============================================================
 */
CREATE PROCEDURE sp_check_thoi_han_giao_dich (
    IN  p_cif VARCHAR(50),
    IN  p_ngay_dat_lenh DATE,
    OUT p_result VARCHAR(30)
)
proc_main: BEGIN

    /* ===============================
       Khai báo biến
    ================================ */
    DECLARE v_hmgd_id CHAR(36);
    DECLARE v_thoi_han DATE;

    /* ===============================
       Khai báo hằng số kết quả
    ================================ */
    DECLARE c_PASS VARCHAR(10) DEFAULT 'PASS';
    DECLARE c_FAIL_EXPIRED VARCHAR(20) DEFAULT 'FAIL';
    DECLARE c_FAIL_NO_CUSTOMER VARCHAR(30) DEFAULT 'FAIL_NO_CUSTOMER';
    DECLARE c_FAIL_NO_HMGD VARCHAR(30) DEFAULT 'FAIL_NO_HMGD';
    DECLARE c_FAIL_INVALID_INPUT VARCHAR(30) DEFAULT 'FAIL_INVALID_INPUT';

    /* ===============================
       1. Check input
    ================================ */
    IF p_cif IS NULL OR p_ngay_dat_lenh IS NULL THEN
        SET p_result = c_FAIL_INVALID_INPUT;
        LEAVE proc_main;
    END IF;

    /* ===============================
       2. Check khách hàng tồn tại
    ================================ */
    SELECT hmgd_id
    INTO v_hmgd_id
    FROM KhachHang
    WHERE cif = p_cif;

    IF v_hmgd_id IS NULL THEN
        SET p_result = c_FAIL_NO_CUSTOMER;
        LEAVE proc_main;
    END IF;

    /* ===============================
       3. Check HMGD tồn tại
    ================================ */
    SELECT thoi_han
    INTO v_thoi_han
    FROM HMGD
    WHERE id = v_hmgd_id;

    IF v_thoi_han IS NULL THEN
        SET p_result = c_FAIL_NO_HMGD;
        LEAVE proc_main;
    END IF;

    /* ===============================
       4. Check thời hạn giao dịch
    ================================ */
    IF v_thoi_han >= p_ngay_dat_lenh THEN
        SET p_result = c_PASS;
    ELSE
        SET p_result = c_FAIL_EXPIRED;
    END IF;

END$$

DELIMITER ;
