DELIMITER $$

/*
 * ------------------------------------------------------------
 * Stored Procedure: sp_check_han_muc_giao_dich
 * Mô tả:
 *   Kiểm tra hạn mức giao dịch của khách hàng dựa trên CIF
 *
 * Input:
 *   - p_cif               : CIF khách hàng
 *   - p_gia_tri_giao_dich : Giá trị giao dịch mới
 *
 * Output:
 *   - p_result : Kết quả kiểm tra
 *
 * Quy tắc nghiệp vụ:
 *   TGD + Giá trị GD <= Hạn mức  => PASS
 *   TGD + Giá trị GD >  Hạn mức  => FAIL
 * ------------------------------------------------------------
 */
DELIMITER $$

CREATE PROCEDURE sp_check_han_muc_giao_dich (
    IN  p_cif VARCHAR(50),
    IN  p_gia_tri_giao_dich DECIMAL(18,2),
    OUT p_result VARCHAR(20)
)
proc_main: BEGIN

    /* ===============================
       Khai báo biến nội bộ
    ================================ */
    DECLARE v_tgd DECIMAL(18,2);
    DECLARE v_han_muc DECIMAL(18,2);

    /* ===============================
       Hằng số kết quả
    ================================ */
    DECLARE c_PASS VARCHAR(10) DEFAULT 'PASS';
    DECLARE c_FAIL_INVALID_INPUT VARCHAR(20) DEFAULT 'INVALID_INPUT';
    DECLARE c_FAIL_NO_DATA VARCHAR(20) DEFAULT 'FAIL_NO_DATA';
    DECLARE c_FAIL_OVER_LIMIT VARCHAR(20) DEFAULT 'FAIL_OVER_LIMIT';

    /* ===============================
       1. Validate input
    ================================ */
    IF p_cif IS NULL
       OR TRIM(p_cif) = ''
       OR p_gia_tri_giao_dich IS NULL
       OR p_gia_tri_giao_dich <= 0 THEN

        SET p_result = c_FAIL_INVALID_INPUT;
        LEAVE proc_main;
    END IF;

    /* ===============================
       2. Lấy TGD và hạn mức theo CIF
       (dùng để xác định trạng thái KH/HMGD)
    ================================ */
    SELECT k.tgd, h.gia_tri
    INTO v_tgd, v_han_muc
    FROM KhachHang k
    LEFT JOIN HMGD h ON k.hmgd_id = h.id
    WHERE k.cif = p_cif;

    /* ===============================
       3. Check dữ liệu khách hàng / HMGD
       - KH không tồn tại
       - KH chưa có HMGD
       - HMGD chưa cấu hình hạn mức
    ================================ */
    IF v_tgd IS NULL OR v_han_muc IS NULL THEN
        SET p_result = c_FAIL_NO_DATA;
        LEAVE proc_main;
    END IF;
    
     /* ===============================
       4. Check dữ liệu bất thường
       - Tổng giao dịch âm là trạng thái sai hệ thống
    ================================ */
    IF v_tgd < 0 THEN
        SET p_result = c_FAIL_NO_DATA;
        LEAVE proc_main;
    END IF;

    /* ===============================
       5. So sánh hạn mức giao dịch
    ================================ */
    IF (v_tgd + p_gia_tri_giao_dich) <= v_han_muc THEN
        SET p_result = c_PASS;
    ELSE
        SET p_result = c_FAIL_OVER_LIMIT;
    END IF;

END$$

DELIMITER ;
