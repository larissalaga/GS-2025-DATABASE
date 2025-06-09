------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_abrigo" (
    "p_nm_abrigo"         IN "t_gsab_abrigo"."nm_abrigo"%TYPE,
    "p_nr_capacidade"     IN "t_gsab_abrigo"."nr_capacidade"%TYPE,
    "p_nr_ocupacao_atual" IN "t_gsab_abrigo"."nr_ocupacao_atual"%TYPE,
    "p_ds_cep"            IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"     IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"         IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"    IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"         IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"         IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"           IN "t_gsab_pais"."nm_pais"%TYPE,
    "p_abrigo_id"         OUT NUMBER
) IS
    "v_endereco_id" NUMBER;
BEGIN
    -- 1. Insere ou localiza endereço
    "proc_inserir_endereco"(
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero",
        "p_ds_complemento", "p_nm_cidade", "p_nm_estado",
        "p_nm_pais", "v_endereco_id"
    );

    -- 2. Insere o abrigo
    INSERT INTO "t_gsab_abrigo" (
        "id_abrigo", "nm_abrigo", "nr_capacidade",
        "nr_ocupacao_atual", "id_endereco"
    ) VALUES (
        seq_t_gsab_abrigo.NEXTVAL, "p_nm_abrigo",
        "p_nr_capacidade", "p_nr_ocupacao_atual", "v_endereco_id"
    );

    COMMIT;
    "p_abrigo_id" := seq_t_gsab_abrigo.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Abrigo inserido com sucesso. ID: ' || "p_abrigo_id");

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20014, 'Erro ao inserir abrigo: ' || SQLERRM);
END "proc_inserir_abrigo";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

    CREATE OR REPLACE PROCEDURE "proc_atualizar_abrigo" (
    "p_id_abrigo"        IN "t_gsab_abrigo"."id_abrigo"%TYPE,
    "p_nm_abrigo"        IN "t_gsab_abrigo"."nm_abrigo"%TYPE,
    "p_nr_capacidade"    IN "t_gsab_abrigo"."nr_capacidade"%TYPE,
    "p_nr_ocupacao_atual" IN "t_gsab_abrigo"."nr_ocupacao_atual"%TYPE,
    "p_ds_cep"           IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"    IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"        IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"   IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"        IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"        IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"          IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    "v_endereco_id"  NUMBER;
    "v_id_existente" NUMBER;
    abrigo_nao_encontrado EXCEPTION;
BEGIN
    -- 1. Verifica se o abrigo existe
    BEGIN
        SELECT "id_abrigo"
          INTO "v_id_existente"
          FROM "t_gsab_abrigo"
         WHERE "id_abrigo" = "p_id_abrigo";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE abrigo_nao_encontrado;
    END;

    -- 2. Insere ou localiza o endereço
    "proc_inserir_endereco"(
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero",
        "p_ds_complemento", "p_nm_cidade", "p_nm_estado",
        "p_nm_pais", "v_endereco_id"
    );

    -- 3. Atualiza o abrigo
    UPDATE "t_gsab_abrigo"
       SET "nm_abrigo"         = "p_nm_abrigo",
           "nr_capacidade"     = "p_nr_capacidade",
           "nr_ocupacao_atual" = "p_nr_ocupacao_atual",
           "id_endereco"       = "v_endereco_id"
     WHERE "id_abrigo" = "p_id_abrigo";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Abrigo atualizado com sucesso. ID: ' || "p_id_abrigo");

EXCEPTION
    WHEN abrigo_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20060, 'Abrigo com ID ' || "p_id_abrigo" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20061, 'Erro ao atualizar abrigo: ' || SQLERRM);
END "proc_atualizar_abrigo";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_abrigo" (
    "p_id_abrigo" IN "t_gsab_abrigo"."id_abrigo"%TYPE
) IS
    "v_id_existente" NUMBER;
    abrigo_nao_encontrado EXCEPTION;
BEGIN
    -- 1. Verifica se o abrigo existe
    BEGIN
        SELECT "id_abrigo"
          INTO "v_id_existente"
          FROM "t_gsab_abrigo"
         WHERE "id_abrigo" = "p_id_abrigo";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE abrigo_nao_encontrado;
    END;

    -- 2. Exclui registros dependentes
    -- Estoques vinculados
    FOR recurso IN (
        SELECT "id_estoque"
          FROM "t_gsab_estoque_recurso"
         WHERE "id_abrigo" = "p_id_abrigo"
    ) LOOP
        "proc_excluir_estoque_recurso"(recurso."id_estoque");
    END LOOP;

    -- Check-ins vinculados
    FOR checkin IN (
        SELECT "id_checkin"
          FROM "t_gsab_check_in"
         WHERE "id_abrigo" = "p_id_abrigo"
    ) LOOP
        "proc_excluir_checkin"(checkin."id_checkin");
    END LOOP;

    -- 3. Exclui o abrigo
    DELETE FROM "t_gsab_abrigo"
     WHERE "id_abrigo" = "p_id_abrigo";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Abrigo excluído com sucesso. ID: ' || "p_id_abrigo");

EXCEPTION
    WHEN abrigo_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20062, 'Abrigo com ID ' || "p_id_abrigo" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20063, 'Erro ao excluir abrigo: ' || SQLERRM);
END "proc_excluir_abrigo";
/
