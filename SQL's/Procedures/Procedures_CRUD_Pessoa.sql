------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_pessoa" (
    "p_nm_pessoa"           IN "t_gsab_pessoa"."nm_pessoa"%TYPE,
    "p_nr_cpf"              IN "t_gsab_pessoa"."nr_cpf"%TYPE,
    "p_dt_nascimento"       IN "t_gsab_pessoa"."dt_nascimento"%TYPE,
    "p_ds_condicao_medica"  IN "t_gsab_pessoa"."ds_condicao_medica"%TYPE,
    "p_st_desaparecido"     IN "t_gsab_pessoa"."st_desaparecido"%TYPE,
    "p_nm_emergencial"      IN "t_gsab_pessoa"."nm_emergencial"%TYPE,
    "p_contato_emergencia"  IN "t_gsab_pessoa"."contato_emergencia"%TYPE,
    "p_ds_cep"              IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"       IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"           IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"      IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"           IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"           IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"             IN "t_gsab_pais"."nm_pais"%TYPE,
    "p_pessoa_id"           OUT NUMBER
) IS
    "v_endereco_id"     NUMBER;
    cpf_ja_cadastrado   EXCEPTION;
BEGIN
    -- 1. Verifica se o CPF já existe
    BEGIN
        SELECT "id_pessoa"
          INTO "p_pessoa_id"
          FROM "t_gsab_pessoa"
         WHERE "nr_cpf" = "p_nr_cpf";

        RAISE cpf_ja_cadastrado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- CPF não existe, prossiga
    END;

    -- 2. Chama proc para inserir ou buscar endereço
    "proc_inserir_endereco"(
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero",
        "p_ds_complemento", "p_nm_cidade", "p_nm_estado",
        "p_nm_pais", "v_endereco_id"
    );

    -- 3. Insere pessoa
    INSERT INTO "t_gsab_pessoa" (
        "id_pessoa",
        "nm_pessoa",
        "nr_cpf",
        "dt_nascimento",
        "ds_condicao_medica",
        "st_desaparecido",
        "nm_emergencial",
        "contato_emergencia",
        "id_endereco"
    ) VALUES (
        seq_t_gsab_pessoa.NEXTVAL,
        "p_nm_pessoa",
        "p_nr_cpf",
        "p_dt_nascimento",
        "p_ds_condicao_medica",
        "p_st_desaparecido",
        "p_nm_emergencial",
        "p_contato_emergencia",
        "v_endereco_id"
    );

    COMMIT;
    "p_pessoa_id" := seq_t_gsab_pessoa.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Pessoa inserida com sucesso. ID: ' || "p_pessoa_id");

EXCEPTION
    WHEN cpf_ja_cadastrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'CPF já cadastrado: ' || "p_nr_cpf");
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Erro ao inserir pessoa: ' || SQLERRM);
END "proc_inserir_pessoa";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

    CREATE OR REPLACE PROCEDURE "proc_atualizar_pessoa" (
    "p_nr_cpf"              IN "t_gsab_pessoa"."nr_cpf"%TYPE,
    "p_nm_pessoa"           IN "t_gsab_pessoa"."nm_pessoa"%TYPE,
    "p_dt_nascimento"       IN "t_gsab_pessoa"."dt_nascimento"%TYPE,
    "p_ds_condicao_medica"  IN "t_gsab_pessoa"."ds_condicao_medica"%TYPE,
    "p_st_desaparecido"     IN "t_gsab_pessoa"."st_desaparecido"%TYPE,
    "p_nm_emergencial"      IN "t_gsab_pessoa"."nm_emergencial"%TYPE,
    "p_contato_emergencia"  IN "t_gsab_pessoa"."contato_emergencia"%TYPE,
    "p_ds_cep"              IN "t_gsab_endereco"."ds_cep"%TYPE,
    "p_ds_logradouro"       IN "t_gsab_endereco"."ds_logradouro"%TYPE,
    "p_nr_numero"           IN "t_gsab_endereco"."nr_numero"%TYPE,
    "p_ds_complemento"      IN "t_gsab_endereco"."ds_complemento"%TYPE,
    "p_nm_cidade"           IN "t_gsab_cidade"."nm_cidade"%TYPE,
    "p_nm_estado"           IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"             IN "t_gsab_pais"."nm_pais"%TYPE

) IS
    "v_pessoa_id"    NUMBER;
    "v_endereco_id"  NUMBER;
    pessoa_nao_encontrada EXCEPTION;
BEGIN
    -- 1. Verifica se a pessoa existe pelo CPF
    BEGIN
        SELECT "id_pessoa"
          INTO "v_pessoa_id"
          FROM "t_gsab_pessoa"
         WHERE "nr_cpf" = "p_nr_cpf";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pessoa_nao_encontrada;
    END;

    -- 2. Chama procedure para inserir ou obter o endereço atualizado
    "proc_inserir_endereco"(
        "p_ds_cep", "p_ds_logradouro", "p_nr_numero",
        "p_ds_complemento", "p_nm_cidade", "p_nm_estado",
        "p_nm_pais", "v_endereco_id"
    );

    -- 3. Atualiza a pessoa
    UPDATE "t_gsab_pessoa"
       SET "nm_pessoa"           = "p_nm_pessoa",
           "dt_nascimento"       = "p_dt_nascimento",
           "ds_condicao_medica"  = "p_ds_condicao_medica",
           "st_desaparecido"     = "p_st_desaparecido",
           "nm_emergencial"      = "p_nm_emergencial",
           "contato_emergencia"  = "p_contato_emergencia",
           "id_endereco"         = "v_endereco_id"
     WHERE "id_pessoa" = "v_pessoa_id";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Pessoa atualizada com sucesso. ID: ' || "v_pessoa_id");

EXCEPTION
    WHEN pessoa_nao_encontrada THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, 'Pessoa com CPF ' || "p_nr_cpf" || ' não encontrada.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20021, 'Erro ao atualizar pessoa: ' || SQLERRM);
END "proc_atualizar_pessoa";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_pessoa" (
    "p_id_pessoa" IN "t_gsab_pessoa"."id_pessoa"%TYPE
) IS
    v_id_existente NUMBER;
    pessoa_nao_encontrada EXCEPTION;
BEGIN
    -- 1. Verifica se a pessoa existe
    BEGIN
        SELECT "id_pessoa"
          INTO v_id_existente
          FROM "t_gsab_pessoa"
         WHERE "id_pessoa" = "p_id_pessoa";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pessoa_nao_encontrada;
    END;

    -- 2. Remove check-ins vinculados (se houver)
    FOR checkin IN (
        SELECT "id_checkin"
          FROM "t_gsab_check_in"
         WHERE "id_pessoa" = "p_id_pessoa"
    ) LOOP
        "proc_excluir_checkin"(checkin."id_checkin");
    END LOOP;

    -- 3. Remove o usuário vinculado (se houver)
    FOR usuario IN (
        SELECT "id_usuario"
          FROM "t_gsab_usuario"
         WHERE "id_pessoa" = "p_id_pessoa"
    ) LOOP
        "proc_excluir_usuario"(usuario."id_usuario");
    END LOOP;

    -- 4. Remove o registro da pessoa
    DELETE FROM "t_gsab_pessoa"
     WHERE "id_pessoa" = "p_id_pessoa";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Pessoa excluída com sucesso. ID: ' || "p_id_pessoa");

EXCEPTION
    WHEN pessoa_nao_encontrada THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20022, 'Pessoa com ID ' || "p_id_pessoa" || ' não encontrada.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20023, 'Erro ao excluir pessoa: ' || SQLERRM);
END "proc_excluir_pessoa";
/