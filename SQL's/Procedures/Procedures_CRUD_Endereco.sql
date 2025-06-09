------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_endereco" (
    "p_ds_cep"          IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"   IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"       IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"  IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"       IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"       IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"         IN "t_gsab_pais"."nm_pais"%TYPE,
    "p_endereco_id"     OUT NUMBER
) IS
    "v_cidade_id"   NUMBER;
BEGIN
    -- 1. Seleciona ou cria a cidade + estado + país
    BEGIN
        SELECT "id_cidade" INTO "v_cidade_id"
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
            -- Invoca a criação modular: cidade → estado → país
            "proc_inserir_cidade"(
                "p_nm_cidade",
                "p_nm_estado",
                "p_nm_pais"
            );
            SELECT "id_cidade" INTO "v_cidade_id"
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
    END;

    -- 2. Insere o endereço (endereços duplicados são permitidos)
    INSERT INTO "t_gsab_endereco" (
        "id_endereco", "ds_cep", "ds_logradouro",
        "nr_numero", "ds_complemento", "id_cidade"
    ) VALUES (
        seq_t_gsab_endereco.NEXTVAL,
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero",
        "p_ds_complemento", "v_cidade_id"
    );
    COMMIT;

    "p_endereco_id" := seq_t_gsab_endereco.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Endereço inserido. ID: ' || "p_endereco_id");

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20000, 'Erro ao inserir endereço: ' || SQLERRM);
END "proc_inserir_endereco";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

CREATE OR REPLACE PROCEDURE "proc_atualizar_endereco" (
    "p_id_endereco"       IN "t_gsab_endereco"."id_endereco"%TYPE,
    "p_ds_cep"            IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"     IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"         IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"    IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"         IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"         IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"           IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    endereco_nao_encontrado EXCEPTION;
    v_cidade_id            NUMBER;
BEGIN
    -- 1) Verifica se o endereço existe
    BEGIN
        SELECT "id_endereco" INTO v_cidade_id
          FROM "t_gsab_endereco"
         WHERE "id_endereco" = "p_id_endereco";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE endereco_nao_encontrado;
    END;

    -- 2) Seleciona ou cria a cidade + estado + país
    BEGIN
        SELECT "id_cidade" INTO v_cidade_id
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
            "proc_inserir_cidade"(
                "p_nm_cidade",
                "p_nm_estado",
                "p_nm_pais"
            );
            SELECT "id_cidade" INTO v_cidade_id
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
    END;

    -- 3) Atualiza o endereço
    UPDATE "t_gsab_endereco"
       SET "ds_cep"          = "p_ds_cep",
           "ds_logradouro"   = "p_ds_logradouro",
           "nr_numero"       = "p_nr_numero",
           "ds_complemento"  = "p_ds_complemento",
           "id_cidade"       = v_cidade_id
     WHERE "id_endereco" = "p_id_endereco";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Endereço atualizado com sucesso. ID = ' || "p_id_endereco");

EXCEPTION
    WHEN endereco_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, 'Endereço com ID ' || "p_id_endereco" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20031, 'Erro ao atualizar endereço: ' || SQLERRM);
END "proc_atualizar_endereco";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_endereco" (
    "p_id_endereco" IN "t_gsab_endereco"."id_endereco"%TYPE
) IS
    endereco_nao_encontrado EXCEPTION;
    endereco_em_uso         EXCEPTION;
    v_id_endereco           NUMBER;
    v_tem_vinculo           NUMBER;
BEGIN
    -- 1. Verifica se o endereço existe
    BEGIN
        SELECT "id_endereco" INTO v_id_endereco
          FROM "t_gsab_endereco"
         WHERE "id_endereco" = "p_id_endereco";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE endereco_nao_encontrado;
    END;

    -- 2. Verifica vínculo com pessoa
    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_pessoa"
         WHERE "id_endereco" = v_id_endereco
           AND ROWNUM = 1;
        RAISE endereco_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 3. Verifica vínculo com abrigo
    BEGIN
        SELECT 1 INTO v_tem_vinculo
          FROM "t_gsab_abrigo"
         WHERE "id_endereco" = v_id_endereco
           AND ROWNUM = 1;
        RAISE endereco_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 4. Exclusão permitida
    DELETE FROM "t_gsab_endereco"
     WHERE "id_endereco" = v_id_endereco;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Endereço excluído com sucesso. ID: ' || "p_id_endereco");

EXCEPTION
    WHEN endereco_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20094, 'Endereço com ID ' || "p_id_endereco" || ' não encontrado.');
    WHEN endereco_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20095, 'Não é possível excluir o endereço. Ele está vinculado a pessoa ou abrigo.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20096, 'Erro ao excluir endereço: ' || SQLERRM);
END "proc_excluir_endereco";
/