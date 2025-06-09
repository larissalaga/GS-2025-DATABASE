------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_pais" (
    "p_nm_pais"      IN "t_gsab_pais"."nm_pais"%TYPE,
    "p_pais_id"      OUT NUMBER
) IS
    "v_dummy"        NUMBER;
BEGIN
    -- 1. Verifica se o país já existe
    BEGIN
        SELECT "id_pais" INTO "v_dummy"
          FROM "t_gsab_pais"
         WHERE "nm_pais" = "p_nm_pais";
        RAISE_APPLICATION_ERROR(-20020, 'País já cadastrado: ' || "p_nm_pais");
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- país não existe, prossegue
    END;

    -- 2. Insere o país
    INSERT INTO "t_gsab_pais" (
        "id_pais", "nm_pais"
    ) VALUES (
        seq_t_gsab_pais.NEXTVAL,
        "p_nm_pais"
    );

    COMMIT;
    "p_pais_id" := seq_t_gsab_pais.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('País inserido com sucesso. ID: ' || "p_pais_id");

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20021, 'Erro ao inserir país: ' || SQLERRM);
END "proc_inserir_pais";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

CREATE OR REPLACE PROCEDURE "proc_atualizar_pais" (
    "p_id_pais" IN "t_gsab_pais"."id_pais"%TYPE,
    "p_nm_pais" IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    pais_nao_encontrado EXCEPTION;
    v_id_existente NUMBER;
BEGIN
    -- Verifica se o país existe
    BEGIN
        SELECT "id_pais" INTO v_id_existente
          FROM "t_gsab_pais"
         WHERE "id_pais" = "p_id_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pais_nao_encontrado;
    END;

    -- Atualiza o nome do país
    UPDATE "t_gsab_pais"
       SET "nm_pais" = "p_nm_pais"
     WHERE "id_pais" = "p_id_pais";

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('País atualizado com sucesso: ID = ' || "p_id_pais");

EXCEPTION
    WHEN pais_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'País com ID ' || "p_id_pais" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Erro ao atualizar país: ' || SQLERRM);
END "proc_atualizar_pais";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE PAÍS

CREATE OR REPLACE PROCEDURE "proc_excluir_pais" (
    "p_id_pais" IN "t_gsab_pais"."id_pais"%TYPE
) IS
    pais_nao_encontrado EXCEPTION;
    pais_em_uso         EXCEPTION;
    v_id_pais           NUMBER;
    v_tem_vinculo       NUMBER;
BEGIN
    -- 1. Verifica se o país existe
    BEGIN
        SELECT "id_pais" INTO v_id_pais
          FROM "t_gsab_pais"
         WHERE "id_pais" = "p_id_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pais_nao_encontrado;
    END;

    -- 2. Verifica vínculo com estado
    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_estado"
         WHERE "id_pais" = v_id_pais
           AND ROWNUM = 1;
        RAISE pais_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 3. Verifica vínculo com cidade (através de estado)
    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_cidade" c
          JOIN "t_gsab_estado" e
            ON c."id_estado" = e."id_estado"
         WHERE e."id_pais" = v_id_pais
           AND ROWNUM = 1;
        RAISE pais_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 4. Verifica vínculo com endereço (através da cidade)
    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_endereco" en
          JOIN "t_gsab_cidade" c
            ON en."id_cidade" = c."id_cidade"
          JOIN "t_gsab_estado" e
            ON c."id_estado" = e."id_estado"
         WHERE e."id_pais" = v_id_pais
           AND ROWNUM = 1;
        RAISE pais_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 5. Executa exclusão do país
    DELETE FROM "t_gsab_pais"
     WHERE "id_pais" = v_id_pais;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('País excluído com sucesso. ID: ' || "p_id_pais");

EXCEPTION
    WHEN pais_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20080, 'País com ID ' || "p_id_pais" || ' não encontrado.');
    WHEN pais_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20081, 'Não é possível excluir o país. Existem vínculos com estado, cidade ou endereço.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20082, 'Erro ao excluir país: ' || SQLERRM);
END "proc_excluir_pais";
/