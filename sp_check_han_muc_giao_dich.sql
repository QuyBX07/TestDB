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
CREATE PROCEDURE sp_check_han_muc_giao_dich (
    IN  p_cif VARCHAR(50),                 -- CIF khách hàng (input)
    IN  p_gia_tri_giao_dich DECIMAL(18,2), -- Giá trị giao dịch mới (input)
    OUT p_result VARCHAR(20)               -- Kết quả kiểm tra (output)
)
BEGIN
    /* -------------------------------
       Khai báo biến nội bộ
    -------------------------------- */
    DECLARE v_tgd DECIMAL(18,2);       -- Tổng giao dịch hiện tại
    DECLARE v_han_muc DECIMAL(18,2);   -- Hạn mức giao dịch

    /* -------------------------------
       Khai báo hằng số kết quả
    -------------------------------- */
    DECLARE c_PASS VARCHAR(10) DEFAULT 'PASS';
    DECLARE c_FAIL_INVALID_INPUT VARCHAR(20) DEFAULT 'INVALID_INPUT';
    DECLARE c_FAIL_NO_DATA VARCHAR(20) DEFAULT 'FAIL_NO_DATA';
    DECLARE c_FAIL_OVER_LIMIT VARCHAR(20) DEFAULT 'FAIL';

    /* -------------------------------
       Check input NULL
    -------------------------------- */
    IF p_cif IS NULL OR p_gia_tri_giao_dich IS NULL THEN
        SET p_result = c_FAIL_INVALID_INPUT;
        LEAVE proc_end;
    END IF;

    /* -------------------------------
       Lấy TGD và hạn mức HMGD theo CIF
    -------------------------------- */
    SELECT k.tgd, h.gia_tri
    INTO v_tgd, v_han_muc
    FROM KhachHang k
    LEFT JOIN HMGD h ON k.hmgd_id = h.id
    WHERE k.cif = p_cif;

    /* -------------------------------
       Check không tồn tại khách hàng
       hoặc không có HMGD
    -------------------------------- */
    IF v_tgd IS NULL OR v_han_muc IS NULL THEN
        SET p_result = c_FAIL_NO_DATA;
        LEAVE proc_end;
    END IF;

    /* -------------------------------
       So sánh hạn mức giao dịch
    -------------------------------- */
    IF (v_tgd + p_gia_tri_giao_dich) <= v_han_muc THEN
        SET p_result = c_PASS;
    ELSE
        SET p_result = c_FAIL_OVER_LIMIT;
    END IF;

    proc_end: BEGIN END;
END$$

DELIMITER ;