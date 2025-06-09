------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_estoque_recurso" (
    "p_qt_disponivel"     IN "t_gsab_estoque_recurso"."qt_disponivel"%TYPE,
    "p_dt_atualizacao"    IN "t_gsab_estoque_recurso"."dt_atualizacao"%TYPE,

    -- Dados do abrigo
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

    -- Dados do recurso
    "p_ds_recurso"        IN "t_gsab_recurso"."ds_recurso"%TYPE,
    "p_qt_pessoa_dia"     IN "t_gsab_recurso"."qt_pessoa_dia"%TYPE,
    "p_st_consumivel"     IN "t_gsab_recurso"."st_consumivel"%TYPE,

    "p_estoque_id"        OUT NUMBER
) IS
    "v_id_abrigo"   NUMBER;
    "v_id_recurso"  NUMBER;
BEGIN
    -- 1. Verifica ou insere o abrigo
    BEGIN
        SELECT "id_abrigo" INTO "v_id_abrigo"
          FROM "t_gsab_abrigo"
         WHERE "nm_abrigo" = "p_nm_abrigo";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_abrigo"(
                "p_nm_abrigo", "p_nr_capacidade", "p_nr_ocupacao_atual",
                "p_ds_cep", "p_ds_logradouro", "p_nr_numero", "p_ds_complemento",
                "p_nm_cidade", "p_nm_estado", "p_nm_pais", "v_id_abrigo"
            );
    END;

    -- 2. Verifica ou insere o recurso
    BEGIN
        SELECT "id_recurso" INTO "v_id_recurso"
          FROM "t_gsab_recurso"
         WHERE "ds_recurso" = "p_ds_recurso";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_recurso"(
                "p_ds_recurso", "p_qt_pessoa_dia", "p_st_consumivel", "v_id_recurso"
            );
    END;

    -- 3. Insere o estoque do recurso
    INSERT INTO "t_gsab_estoque_recurso" (
        "id_estoque", "qt_disponivel", "dt_atualizacao",
        "id_abrigo", "id_recurso"
    ) VALUES (
        seq_t_gsab_estoque_recurso.NEXTVAL,
        "p_qt_disponivel", "p_dt_atualizacao",
        "v_id_abrigo", "v_id_recurso"
    );

    COMMIT;
    "p_estoque_id" := seq_t_gsab_estoque_recurso.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Estoque de recurso inserido. ID: ' || "p_estoque_id");

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20017, 'Erro ao inserir estoque de recurso: ' || SQLERRM);
END "proc_inserir_estoque_recurso";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

CREATE OR REPLACE PROCEDURE "proc_atualizar_estoque_recurso" (
    "p_id_estoque"         IN "t_gsab_estoque_recurso"."id_estoque"%TYPE,
    "p_qt_disponivel"      IN "t_gsab_estoque_recurso"."qt_disponivel"%TYPE,
    "p_dt_atualizacao"     IN "t_gsab_estoque_recurso"."dt_atualizacao"%TYPE,

    -- Dados do abrigo
    "p_nm_abrigo"          IN "t_gsab_abrigo"."nm_abrigo"%TYPE,
    "p_nr_capacidade"      IN "t_gsab_abrigo"."nr_capacidade"%TYPE,
    "p_nr_ocupacao_atual"  IN "t_gsab_abrigo"."nr_ocupacao_atual"%TYPE,
    "p_ds_cep"             IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"      IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"          IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"     IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"          IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"          IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"            IN "t_gsab_pais"."nm_pais"%TYPE,

    -- Dados do recurso
    "p_ds_recurso"         IN "t_gsab_recurso"."ds_recurso"%TYPE,
    "p_qt_pessoa_dia"      IN "t_gsab_recurso"."qt_pessoa_dia"%TYPE,
    "p_st_consumivel"      IN "t_gsab_recurso"."st_consumivel"%TYPE
) IS
    "v_id_abrigo"   NUMBER;
    "v_id_recurso"  NUMBER;
    estoque_nao_encontrado EXCEPTION;
BEGIN
    -- 1. Verifica se o estoque existe
    BEGIN
        SELECT "id_estoque"
          INTO "v_id_abrigo"
          FROM "t_gsab_estoque_recurso"
         WHERE "id_estoque" = "p_id_estoque";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE estoque_nao_encontrado;
    END;

    -- 2. Verifica ou insere o abrigo
    BEGIN
        SELECT "id_abrigo" INTO "v_id_abrigo"
          FROM "t_gsab_abrigo"
         WHERE "nm_abrigo" = "p_nm_abrigo";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_abrigo"(
                "p_nm_abrigo", "p_nr_capacidade", "p_nr_ocupacao_atual",
                "p_ds_cep", "p_ds_logradouro", "p_nr_numero", "p_ds_complemento",
                "p_nm_cidade", "p_nm_estado", "p_nm_pais", "v_id_abrigo"
            );
    END;

    -- 3. Verifica ou insere o recurso
    BEGIN
        SELECT "id_recurso" INTO "v_id_recurso"
          FROM "t_gsab_recurso"
         WHERE "ds_recurso" = "p_ds_recurso";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "proc_inserir_recurso"(
                "p_ds_recurso", "p_qt_pessoa_dia", "p_st_consumivel", "v_id_recurso"
            );
    END;

    -- 4. Atualiza o estoque
    UPDATE "t_gsab_estoque_recurso"
       SET "qt_disponivel"   = "p_qt_disponivel",
           "dt_atualizacao"  = "p_dt_atualizacao",
           "id_abrigo"       = "v_id_abrigo",
           "id_recurso"      = "v_id_recurso"
     WHERE "id_estoque" = "p_id_estoque";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estoque de recurso atualizado com sucesso. ID: ' || "p_id_estoque");

EXCEPTION
    WHEN estoque_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20070, 'Estoque com ID ' || "p_id_estoque" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20071, 'Erro ao atualizar estoque de recurso: ' || SQLERRM);
END "proc_atualizar_estoque_recurso";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_estoque_recurso" (
    "p_id_estoque" IN "t_gsab_estoque_recurso"."id_estoque"%TYPE
) IS
    estoque_nao_encontrado EXCEPTION;
    v_id_existente NUMBER;
BEGIN
    -- 1. Verifica se o estoque existe
    BEGIN
        SELECT "id_estoque"
          INTO v_id_existente
          FROM "t_gsab_estoque_recurso"
         WHERE "id_estoque" = "p_id_estoque";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE estoque_nao_encontrado;
    END;

    -- 2. Exclui o estoque
    DELETE FROM "t_gsab_estoque_recurso"
     WHERE "id_estoque" = "p_id_estoque";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estoque de recurso excluído com sucesso. ID: ' || "p_id_estoque");

EXCEPTION
    WHEN estoque_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20072, 'Estoque com ID ' || "p_id_estoque" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20073, 'Erro ao excluir estoque de recurso: ' || SQLERRM);
END "proc_excluir_estoque_recurso";
/