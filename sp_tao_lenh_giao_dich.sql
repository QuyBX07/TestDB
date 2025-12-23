DELIMITER $$

/*
 * ------------------------------------------------------------
 * Stored Procedure: sp_tao_lenh_giao_dich
 *
 * Mô tả:
 *   Thực hiện tạo lệnh giao dịch cho khách hàng dựa trên CIF.
 *
 * Input:
 *   - p_cif           : CIF khách hàng
 *   - p_ma_lenh       : Mã lệnh giao dịch
 *   - p_gia_tri       : Giá trị giao dịch
 *   - p_ngay_dat_lenh : Ngày đặt lệnh giao dịch
 *
 * Output:
 *   - p_result : Kết quả xử lý lệnh
 *
 * Quy tắc nghiệp vụ:
 *   - Check thời hạn giao dịch
 *   - Check hạn mức giao dịch (HMGD)
 *
 *   + PASS & PASS  => Tạo lệnh giao dịch
 *   + Chỉ cần 1 FAIL => Hủy lệnh giao dịch
 *	 + INSERT thêm lệnh
 *   + UPDATE lại TGD của khách hàng 
 * ------------------------------------------------------------
 */
CREATE PROCEDURE sp_tao_lenh_giao_dich (
    IN  p_cif VARCHAR(50),
    IN  p_ma_lenh VARCHAR(50),
    IN  p_gia_tri DECIMAL(18,2),
    IN  p_ngay_dat_lenh DATE,
    OUT p_result VARCHAR(100)
)
proc_main: BEGIN

    /* ===============================
       Biến kết quả check
    ================================ */
    DECLARE v_kq_thoi_han VARCHAR(30);
    DECLARE v_kq_han_muc  VARCHAR(30);

    /* ===============================
       Hằng số kết quả
    ================================ */
    DECLARE c_PASS                VARCHAR(10)  DEFAULT 'PASS';
    DECLARE c_TAO_LENH_OK         VARCHAR(30)  DEFAULT 'TAO_LENH_THANH_CONG';
    DECLARE c_SYSTEM_ERROR        VARCHAR(30)  DEFAULT 'SYSTEM_ERROR';
    DECLARE c_HUY_LENH            VARCHAR(20)  DEFAULT 'HUY_LENH';

    /* ===============================
       Handler lỗi hệ thống
       - rollback transaction
       - trả kết quả SYSTEM_ERROR
    ================================ */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = c_SYSTEM_ERROR;
    END;

    /* ===============================
       1. Check thời hạn giao dịch
    ================================ */
    CALL sp_check_thoi_han_giao_dich(
        p_cif,
        p_ngay_dat_lenh,
        v_kq_thoi_han
    );

    /* ===============================
       2. Check hạn mức giao dịch
    ================================ */
    CALL sp_check_han_muc_giao_dich(
        p_cif,
        p_gia_tri,
        v_kq_han_muc
    );

    /* ===============================
       3. Tổng hợp kết quả nghiệp vụ
    ================================ */
    IF v_kq_thoi_han = c_PASS
       AND v_kq_han_muc = c_PASS THEN

        /* ===============================
           3.1 Bắt đầu transaction
        ================================ */
        START TRANSACTION;

        /* Insert lệnh giao dịch */
        INSERT INTO Lenh (
            id,
            ma_lenh,
            cif,
            gia_tri_giao_dich,
            ngay_dat_lenh
        )
        VALUES (
            UUID(),
            p_ma_lenh,
            p_cif,
            p_gia_tri,
            p_ngay_dat_lenh
        );

        /* Cập nhật tổng giao dịch (TGD) */
        UPDATE KhachHang
        SET tgd = tgd + p_gia_tri
        WHERE cif = p_cif;

        COMMIT;

        SET p_result = c_TAO_LENH_OK;

    ELSE
        /* ===============================
           3.2 Hủy lệnh – ghi rõ lý do
        ================================ */
        SET p_result = CONCAT(
            c_HUY_LENH,
            '|THOI_HAN=', IFNULL(v_kq_thoi_han, 'UNKNOWN'),
            '|HAN_MUC=',  IFNULL(v_kq_han_muc,  'UNKNOWN')
        );
    END IF;

END$$

DELIMITER ;
