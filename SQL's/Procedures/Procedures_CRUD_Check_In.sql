------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

    CREATE OR REPLACE PROCEDURE "proc_inserir_check_in" (
    "p_dt_entrada"  IN "t_gsab_check_in"."dt_entrada"%TYPE,
    "p_dt_saida"    IN "t_gsab_check_in"."dt_saida"%TYPE,
    "p_id_abrigo"   IN "t_gsab_check_in"."id_abrigo"%TYPE,
    "p_id_pessoa"   IN "t_gsab_check_in"."id_pessoa"%TYPE,
    "p_id_checkin"  OUT NUMBER
) IS
BEGIN
    -- Insere o check-in (confiança nas FKs para garantir integridade)
    INSERT INTO "t_gsab_check_in" (
        "id_checkin", "dt_entrada", "dt_saida",
        "id_abrigo", "id_pessoa"
    ) VALUES (
        seq_t_gsab_check_in.NEXTVAL,
        "p_dt_entrada", "p_dt_saida",
        "p_id_abrigo", "p_id_pessoa"
    );

    COMMIT;

    "p_id_checkin" := seq_t_gsab_check_in.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Check-in inserido. ID: ' || "p_id_checkin");

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'Erro ao inserir check-in: ' || SQLERRM);
END "proc_inserir_check_in";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

    CREATE OR REPLACE PROCEDURE "proc_atualizar_check_in" (
    "p_id_checkin"  IN "t_gsab_check_in"."id_checkin"%TYPE,
    "p_dt_entrada"  IN "t_gsab_check_in"."dt_entrada"%TYPE,
    "p_dt_saida"    IN "t_gsab_check_in"."dt_saida"%TYPE,
    "p_id_abrigo"   IN "t_gsab_check_in"."id_abrigo"%TYPE,
    "p_id_pessoa"   IN "t_gsab_check_in"."id_pessoa"%TYPE
) IS
    checkin_nao_encontrado EXCEPTION;
    v_checkin_id NUMBER;
BEGIN
    -- Verifica se o check-in existe
    BEGIN
        SELECT "id_checkin"
          INTO v_checkin_id
          FROM "t_gsab_check_in"
         WHERE "id_checkin" = "p_id_checkin";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE checkin_nao_encontrado;
    END;

    -- Atualiza o check-in
    UPDATE "t_gsab_check_in"
       SET "dt_entrada" = "p_dt_entrada",
           "dt_saida"   = "p_dt_saida",
           "id_abrigo"  = "p_id_abrigo",
           "id_pessoa"  = "p_id_pessoa"
     WHERE "id_checkin" = "p_id_checkin";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Check-in atualizado com sucesso. ID: ' || "p_id_checkin");

EXCEPTION
    WHEN checkin_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20050, 'Check-in com ID ' || "p_id_checkin" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20051, 'Erro ao atualizar check-in: ' || SQLERRM);
END "proc_atualizar_check_in";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_checkin" (
    "p_id_checkin" IN "t_gsab_check_in"."id_checkin"%TYPE
) IS
    v_id_existente NUMBER;
    checkin_nao_encontrado EXCEPTION;
BEGIN
    -- 1. Verifica se o check-in existe
    BEGIN
        SELECT "id_checkin"
          INTO v_id_existente
          FROM "t_gsab_check_in"
         WHERE "id_checkin" = "p_id_checkin";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE checkin_nao_encontrado;
    END;

    -- 2. Exclui o check-in
    DELETE FROM "t_gsab_check_in"
     WHERE "id_checkin" = "p_id_checkin";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Check-in excluído com sucesso. ID: ' || "p_id_checkin");

EXCEPTION
    WHEN checkin_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20052, 'Check-in com ID ' || "p_id_checkin" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20053, 'Erro ao excluir check-in: ' || SQLERRM);
END "proc_excluir_checkin";
/