------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_cidade" (
    "p_nm_cidade" IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado" IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"   IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    cidade_exists EXCEPTION;
    "v_cidade_id" NUMBER;
    "v_estado_id" NUMBER;
BEGIN
    -- Tenta encontrar a cidade
    BEGIN
        SELECT "id_cidade"
          INTO "v_cidade_id"
          FROM "t_gsab_cidade"
         WHERE "nm_cidade" = "p_nm_cidade"
           AND "id_estado" = (
               SELECT "id_estado"
                 FROM "t_gsab_estado"
                WHERE "nm_estado" = "p_nm_estado"
                  AND "id_pais" = (
                      SELECT "id_pais"
                        FROM "t_gsab_pais"
                       WHERE "nm_pais" = "p_nm_pais"
                  )
           );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Se a cidade não existe, garante estado e país
            "proc_inserir_estado"("p_nm_estado", "p_nm_pais");

            -- Recupera o ID do estado recém criado ou existente
            SELECT "id_estado" INTO "v_estado_id"
              FROM "t_gsab_estado"
             WHERE "nm_estado" = "p_nm_estado"
               AND "id_pais" = (
                   SELECT "id_pais"
                     FROM "t_gsab_pais"
                    WHERE "nm_pais" = "p_nm_pais"
               );
    END;

    -- Se encontrou cidade, retorna erro de duplicidade
    IF "v_cidade_id" IS NOT NULL THEN
        RAISE cidade_exists;
    END IF;

    -- Insere a nova cidade
    INSERT INTO "t_gsab_cidade" (
        "id_cidade",
        "nm_cidade",
        "id_estado"
    ) VALUES (
        seq_t_gsab_cidade.NEXTVAL,
        "p_nm_cidade",
        "v_estado_id"
    );
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Cidade inserida com sucesso: ' || "p_nm_cidade");

EXCEPTION
    WHEN cidade_exists THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cidade já cadastrada para esse estado.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'Erro ao inserir cidade: ' || SQLERRM);
END "proc_inserir_cidade";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

    CREATE OR REPLACE PROCEDURE "proc_atualizar_cidade" (
    "p_id_cidade"  IN "t_gsab_cidade"."id_cidade"%TYPE,
    "p_nm_cidade"  IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"  IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"    IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    cidade_nao_encontrada EXCEPTION;
    duplicado_cidade      EXCEPTION;
    v_estado_id           NUMBER;
    v_cidade_exists       NUMBER;
BEGIN
    -- 1. Verifica se a cidade existe por ID
    BEGIN
        SELECT "id_cidade" INTO v_cidade_exists
          FROM "t_gsab_cidade"
         WHERE "id_cidade" = "p_id_cidade";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE cidade_nao_encontrada;
    END;

    -- 2. Verifica duplicidade no novo nome + estado + país, excluindo ela mesma
    BEGIN
        SELECT c."id_cidade" INTO v_cidade_exists
          FROM "t_gsab_cidade" c
          JOIN "t_gsab_estado" e
            ON c."id_estado" = e."id_estado"
          JOIN "t_gsab_pais" p
            ON e."id_pais" = p."id_pais"
         WHERE c."nm_cidade" = "p_nm_cidade"
           AND e."nm_estado" = "p_nm_estado"
           AND p."nm_pais" = "p_nm_pais"
           AND c."id_cidade" <> "p_id_cidade";
        RAISE duplicado_cidade;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 3. Confirma existência do estado (e país)
    BEGIN
        SELECT e."id_estado" INTO v_estado_id
          FROM "t_gsab_estado" e
          JOIN "t_gsab_pais" p
            ON e."id_pais" = p."id_pais"
         WHERE e."nm_estado" = "p_nm_estado"
           AND p."nm_pais" = "p_nm_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Insere o estado e país conforme padrão
            "proc_inserir_estado"("p_nm_estado", "p_nm_pais");
            SELECT e."id_estado" INTO v_estado_id
              FROM "t_gsab_estado" e
              JOIN "t_gsab_pais" p
                ON e."id_pais" = p."id_pais"
             WHERE e."nm_estado" = "p_nm_estado"
               AND p."nm_pais" = "p_nm_pais";
    END;

    -- 4. Executa o update
    UPDATE "t_gsab_cidade"
       SET "nm_cidade" = "p_nm_cidade",
           "id_estado" = v_estado_id
     WHERE "id_cidade" = "p_id_cidade";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cidade atualizada com sucesso. ID = ' || "p_id_cidade");

EXCEPTION
    WHEN cidade_nao_encontrada THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, 'Cidade com ID ' || "p_id_cidade" || ' não encontrada.');
    WHEN duplicado_cidade THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20021, 'Já existe outra cidade com esse nome neste estado e país.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20022, 'Erro ao atualizar cidade: ' || SQLERRM);
END "proc_atualizar_cidade";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_cidade" (
    "p_id_cidade" IN "t_gsab_cidade"."id_cidade"%TYPE
) IS
    cidade_nao_encontrada EXCEPTION;
    cidade_em_uso         EXCEPTION;
    v_id_cidade           NUMBER;
    v_tem_vinculo         NUMBER;
BEGIN
    -- 1. Verifica se a cidade existe
    BEGIN
        SELECT "id_cidade"
          INTO v_id_cidade
          FROM "t_gsab_cidade"
         WHERE "id_cidade" = "p_id_cidade";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE cidade_nao_encontrada;
    END;

    -- 2. Verifica vínculo com endereço
    BEGIN
        SELECT 1
          INTO v_tem_vinculo
          FROM "t_gsab_endereco"
         WHERE "id_cidade" = v_id_cidade
           AND ROWNUM = 1;
        RAISE cidade_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 3. Exclui a cidade
    DELETE FROM "t_gsab_cidade"
     WHERE "id_cidade" = v_id_cidade;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cidade excluída com sucesso. ID: ' || "p_id_cidade");

EXCEPTION
    WHEN cidade_nao_encontrada THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20050, 'Cidade com ID ' || "p_id_cidade" || ' não encontrada.');
    WHEN cidade_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20051, 'Não é possível excluir a cidade. Há endereços vinculados.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20052, 'Erro ao excluir cidade: ' || SQLERRM);
END "proc_excluir_cidade";
/