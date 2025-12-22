DELIMITER $$

CREATE PROCEDURE sp_tao_lenh_giao_dich (
    IN  p_cif VARCHAR(50),
    IN  p_ma_lenh VARCHAR(50),
    IN  p_gia_tri DECIMAL(18,2),
    IN  p_ngay_dat_lenh DATE,
    OUT p_result VARCHAR(30)
)
proc_main: BEGIN

    DECLARE v_kq_thoi_han VARCHAR(30);
    DECLARE v_kq_han_muc VARCHAR(30);

    /* -------------------------------
       1. Check thời hạn giao dịch
    -------------------------------- */
    CALL sp_check_thoi_han_giao_dich(
        p_cif,
        p_ngay_dat_lenh,
        v_kq_thoi_han
    );

    /* -------------------------------
       2. Check hạn mức giao dịch
    -------------------------------- */
    CALL sp_check_han_muc_giao_dich(
        p_cif,
        p_gia_tri,
        v_kq_han_muc
    );

    /* -------------------------------
       3. Xử lý kết quả
    -------------------------------- */
    IF v_kq_thoi_han = 'PASS'
       AND v_kq_han_muc = 'PASS' THEN

        /* 3.1 Insert lệnh giao dịch */
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

        /* 3.2 Cập nhật tổng giao dịch (TGD) */
        UPDATE KhachHang
        SET tgd = tgd + p_gia_tri
        WHERE cif = p_cif;

        SET p_result = 'TAO_LENH_THANH_CONG';

    ELSE
        /* Không insert, không update */
        SET p_result = 'HUY_LENH';
    END IF;

END$$

DELIMITER ;
