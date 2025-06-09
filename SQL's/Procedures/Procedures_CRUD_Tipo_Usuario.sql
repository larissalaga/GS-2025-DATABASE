------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_tipo_usuario" (
    "p_ds_tipo_usuario"  IN "t_gsab_tipo_usuario"."ds_tipo_usuario"%TYPE,
    "p_id_tipo_usuario"  OUT NUMBER
) IS
BEGIN
    -- Insere o tipo de usuário
    INSERT INTO "t_gsab_tipo_usuario" (
        "id_tipo_usuario",
        "ds_tipo_usuario"
    ) VALUES (
        seq_t_gsab_tipo_usuario.NEXTVAL,
        "p_ds_tipo_usuario"
    );

    COMMIT;

    "p_id_tipo_usuario" := seq_t_gsab_tipo_usuario.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Tipo de usuário inserido. ID: ' || "p_id_tipo_usuario");

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao inserir tipo de usuário: ' || SQLERRM);
END "proc_inserir_tipo_usuario";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

    CREATE OR REPLACE PROCEDURE "proc_atualizar_tipo_usuario" (
    "p_id_tipo_usuario"  IN "t_gsab_tipo_usuario"."id_tipo_usuario"%TYPE,
    "p_ds_tipo_usuario"  IN "t_gsab_tipo_usuario"."ds_tipo_usuario"%TYPE
) IS
    v_id_tipo_usuario_existente  NUMBER;
    tipo_usuario_nao_encontrado  EXCEPTION;
BEGIN
    -- 1. Verifica se o tipo de usuário existe
    BEGIN
        SELECT "id_tipo_usuario"
          INTO v_id_tipo_usuario_existente
          FROM "t_gsab_tipo_usuario"
         WHERE "id_tipo_usuario" = "p_id_tipo_usuario";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE tipo_usuario_nao_encontrado;
    END;

    -- 2. Executa o update
    UPDATE "t_gsab_tipo_usuario"
       SET "ds_tipo_usuario" = "p_ds_tipo_usuario"
     WHERE "id_tipo_usuario" = "p_id_tipo_usuario";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Tipo de usuário atualizado. ID: ' || "p_id_tipo_usuario");

EXCEPTION
    WHEN tipo_usuario_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20040, 'Tipo de usuário com ID ' || "p_id_tipo_usuario" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20041, 'Erro ao atualizar tipo de usuário: ' || SQLERRM);
END "proc_atualizar_tipo_usuario";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_tipo_usuario" (
    "p_id_tipo_usuario" IN "t_gsab_tipo_usuario"."id_tipo_usuario"%TYPE
) IS
    tipo_usuario_nao_encontrado EXCEPTION;
    tipo_usuario_em_uso EXCEPTION;
    v_id_existente NUMBER;
    v_vinculo_existente NUMBER;
BEGIN
    -- 1. Verifica se o tipo de usuário existe
    BEGIN
        SELECT "id_tipo_usuario"
          INTO v_id_existente
          FROM "t_gsab_tipo_usuario"
         WHERE "id_tipo_usuario" = "p_id_tipo_usuario";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE tipo_usuario_nao_encontrado;
    END;

    -- 2. Verifica se está em uso por algum usuário
    BEGIN
        SELECT 1
          INTO v_vinculo_existente
          FROM "t_gsab_usuario"
         WHERE "id_tipo_usuario" = "p_id_tipo_usuario"
           AND ROWNUM = 1;
        RAISE tipo_usuario_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 3. Exclui o tipo de usuário
    DELETE FROM "t_gsab_tipo_usuario"
     WHERE "id_tipo_usuario" = "p_id_tipo_usuario";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Tipo de usuário excluído com sucesso. ID: ' || "p_id_tipo_usuario");

EXCEPTION
    WHEN tipo_usuario_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20042, 'Tipo de usuário com ID ' || "p_id_tipo_usuario" || ' não encontrado.');
    WHEN tipo_usuario_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20043, 'Não é possível excluir o tipo de usuário. Existem usuários vinculados.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20044, 'Erro ao excluir tipo de usuário: ' || SQLERRM);
END "proc_excluir_tipo_usuario";
/