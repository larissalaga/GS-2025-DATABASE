------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_recurso" (
    "p_ds_recurso"     IN "t_gsab_recurso"."ds_recurso"%TYPE,
    "p_qt_pessoa_dia"  IN "t_gsab_recurso"."qt_pessoa_dia"%TYPE,
    "p_st_consumivel"  IN "t_gsab_recurso"."st_consumivel"%TYPE,
    "p_recurso_id"     OUT NUMBER
) IS
    "v_existente" NUMBER;
BEGIN
    -- 1. Verifica se já existe um recurso com essa descrição (ignora maiúsculas/minúsculas)
    SELECT COUNT(*) INTO "v_existente"
      FROM "t_gsab_recurso"
     WHERE UPPER("ds_recurso") = UPPER("p_ds_recurso");

    IF "v_existente" > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Recurso já cadastrado: ' || "p_ds_recurso");
    END IF;

    -- 2. Insere o recurso
    INSERT INTO "t_gsab_recurso" (
        "id_recurso", "ds_recurso", "qt_pessoa_dia", "st_consumivel"
    ) VALUES (
        seq_t_gsab_recurso.NEXTVAL,
        "p_ds_recurso", "p_qt_pessoa_dia", "p_st_consumivel"
    );

    COMMIT;
    "p_recurso_id" := seq_t_gsab_recurso.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Recurso inserido com sucesso. ID: ' || "p_recurso_id");

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Erro ao inserir recurso: ' || SQLERRM);
END "proc_inserir_recurso";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

CREATE OR REPLACE PROCEDURE "proc_atualizar_recurso" (
    "p_id_recurso"     IN "t_gsab_recurso"."id_recurso"%TYPE,
    "p_ds_recurso"     IN "t_gsab_recurso"."ds_recurso"%TYPE,
    "p_qt_pessoa_dia"  IN "t_gsab_recurso"."qt_pessoa_dia"%TYPE,
    "p_st_consumivel"  IN "t_gsab_recurso"."st_consumivel"%TYPE
) IS
    v_id_existente     NUMBER;
    recurso_nao_encontrado EXCEPTION;
BEGIN
    -- 1. Verifica se o recurso existe
    BEGIN
        SELECT "id_recurso"
          INTO v_id_existente
          FROM "t_gsab_recurso"
         WHERE "id_recurso" = "p_id_recurso";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE recurso_nao_encontrado;
    END;

    -- 2. Atualiza os dados do recurso
    UPDATE "t_gsab_recurso"
       SET "ds_recurso"     = "p_ds_recurso",
           "qt_pessoa_dia"  = "p_qt_pessoa_dia",
           "st_consumivel"  = "p_st_consumivel"
     WHERE "id_recurso" = "p_id_recurso";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Recurso atualizado com sucesso. ID: ' || "p_id_recurso");

EXCEPTION
    WHEN recurso_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20080, 'Recurso com ID ' || "p_id_recurso" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20081, 'Erro ao atualizar recurso: ' || SQLERRM);
END "proc_atualizar_recurso";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_recurso" (
    "p_id_recurso" IN "t_gsab_recurso"."id_recurso"%TYPE
) IS
    recurso_nao_encontrado EXCEPTION;
    recurso_em_uso EXCEPTION;
    v_id_existente NUMBER;
    v_vinculado NUMBER;
BEGIN
    -- 1. Verifica se o recurso existe
    BEGIN
        SELECT "id_recurso"
          INTO v_id_existente
          FROM "t_gsab_recurso"
         WHERE "id_recurso" = "p_id_recurso";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE recurso_nao_encontrado;
    END;

    -- 2. Verifica se o recurso está vinculado ao estoque
    BEGIN
        SELECT 1
          INTO v_vinculado
          FROM "t_gsab_estoque_recurso"
         WHERE "id_recurso" = "p_id_recurso"
           AND ROWNUM = 1;
        RAISE recurso_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- recurso não está vinculado, pode continuar
    END;

    -- 3. Exclui o recurso
    DELETE FROM "t_gsab_recurso"
     WHERE "id_recurso" = "p_id_recurso";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Recurso excluído com sucesso. ID: ' || "p_id_recurso");

EXCEPTION
    WHEN recurso_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20082, 'Recurso com ID ' || "p_id_recurso" || ' não encontrado.');
    WHEN recurso_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20084, 'Não é possível excluir o recurso. Ele está vinculado ao estoque.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20083, 'Erro ao excluir recurso: ' || SQLERRM);
END "proc_excluir_recurso";
/