------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_usuario" (
    "p_nm_usuario"         IN "t_gsab_usuario"."nm_usuario"%TYPE,
    "p_ds_email"           IN "t_gsab_usuario"."ds_email"%TYPE,
    "p_ds_senha"           IN "t_gsab_usuario"."ds_senha"%TYPE,
    "p_ds_codigo_google"   IN "t_gsab_usuario"."ds_codigo_google"%TYPE,
    "p_id_tipo_usuario"    IN "t_gsab_usuario"."id_tipo_usuario"%TYPE,

    -- Dados da pessoa
    "p_nm_pessoa"          IN "t_gsab_pessoa"."nm_pessoa"%TYPE,
    "p_nr_cpf"             IN "t_gsab_pessoa"."nr_cpf"%TYPE,
    "p_dt_nascimento"      IN "t_gsab_pessoa"."dt_nascimento"%TYPE,
    "p_ds_condicao_medica" IN "t_gsab_pessoa"."ds_condicao_medica"%TYPE,
    "p_st_desaparecido"    IN "t_gsab_pessoa"."st_desaparecido"%TYPE,
    "p_nm_emergencial"     IN "t_gsab_pessoa"."nm_emergencial"%TYPE,
    "p_contato_emergencia" IN "t_gsab_pessoa"."contato_emergencia"%TYPE,
    "p_id_endereco"        IN "t_gsab_pessoa"."id_endereco"%TYPE,

    "p_id_usuario"         OUT NUMBER
) IS
    "v_id_tipo_usuario"  NUMBER;
    "v_id_pessoa"        NUMBER;
BEGIN
    -- 1. Verifica se o tipo de usuário existe
    BEGIN
        SELECT "id_tipo_usuario" INTO "v_id_tipo_usuario"
          FROM "t_gsab_tipo_usuario"
         WHERE "id_tipo_usuario" = "p_id_tipo_usuario";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Tipo de usuário inexistente.');
    END;

    -- 2. Verifica se a pessoa já existe (por CPF)
    BEGIN
        SELECT "id_pessoa" INTO "v_id_pessoa"
          FROM "t_gsab_pessoa"
         WHERE "nr_cpf" = "p_nr_cpf";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Pessoa não encontrada → cria nova pessoa
            "proc_inserir_pessoa"(
                "p_nm_pessoa",
                "p_nr_cpf",
                "p_dt_nascimento",
                "p_ds_condicao_medica",
                "p_st_desaparecido",
                "p_nm_emergencial",
                "p_contato_emergencia",
                "p_id_endereco",
                "v_id_pessoa"
            );
    END;

    -- 3. Insere o usuário
    INSERT INTO "t_gsab_usuario" (
        "id_usuario", "nm_usuario", "ds_email",
        "ds_senha", "ds_codigo_google",
        "id_tipo_usuario", "id_pessoa"
    ) VALUES (
        seq_t_gsab_usuario.NEXTVAL,
        "p_nm_usuario", "p_ds_email", "p_ds_senha",
        "p_ds_codigo_google", "p_id_tipo_usuario", "v_id_pessoa"
    );

    COMMIT;

    "p_id_usuario" := seq_t_gsab_usuario.CURRVAL;
    DBMS_OUTPUT.PUT_LINE('Usuário inserido. ID: ' || "p_id_usuario");

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Erro ao inserir usuário: ' || SQLERRM);
END "proc_inserir_usuario";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

CREATE OR REPLACE PROCEDURE "proc_atualizar_usuario" (
    "p_nr_cpf"             IN "t_gsab_pessoa"."nr_cpf"%TYPE,
    "p_nm_usuario"         IN "t_gsab_usuario"."nm_usuario"%TYPE,
    "p_ds_email"           IN "t_gsab_usuario"."ds_email"%TYPE,
    "p_ds_senha"           IN "t_gsab_usuario"."ds_senha"%TYPE,
    "p_ds_codigo_google"   IN "t_gsab_usuario"."ds_codigo_google"%TYPE,
    "p_id_tipo_usuario"    IN "t_gsab_usuario"."id_tipo_usuario"%TYPE,

    -- Dados da pessoa
    "p_nm_pessoa"          IN "t_gsab_pessoa"."nm_pessoa"%TYPE,
    "p_dt_nascimento"      IN "t_gsab_pessoa"."dt_nascimento"%TYPE,
    "p_ds_condicao_medica" IN "t_gsab_pessoa"."ds_condicao_medica"%TYPE,
    "p_st_desaparecido"    IN "t_gsab_pessoa"."st_desaparecido"%TYPE,
    "p_nm_emergencial"     IN "t_gsab_pessoa"."nm_emergencial"%TYPE,
    "p_contato_emergencia" IN "t_gsab_pessoa"."contato_emergencia"%TYPE,
    "p_id_endereco"        IN "t_gsab_pessoa"."id_endereco"%TYPE
) IS
    "v_id_tipo_usuario"  NUMBER;
    "v_id_pessoa"        NUMBER;
    tipo_usuario_invalido  EXCEPTION;
    usuario_nao_encontrado EXCEPTION;
BEGIN
    -- 1. Verifica se o tipo de usuário existe
    BEGIN
        SELECT "id_tipo_usuario"
          INTO "v_id_tipo_usuario"
          FROM "t_gsab_tipo_usuario"
         WHERE "id_tipo_usuario" = "p_id_tipo_usuario";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE tipo_usuario_invalido;
    END;

    -- 2. Verifica se a pessoa existe (por CPF)
    BEGIN
        SELECT "id_pessoa"
          INTO "v_id_pessoa"
          FROM "t_gsab_pessoa"
         WHERE "nr_cpf" = "p_nr_cpf";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE usuario_nao_encontrado;
    END;

    -- 3. Atualiza dados da pessoa
    UPDATE "t_gsab_pessoa"
       SET "nm_pessoa"           = "p_nm_pessoa",
           "dt_nascimento"       = "p_dt_nascimento",
           "ds_condicao_medica"  = "p_ds_condicao_medica",
           "st_desaparecido"     = "p_st_desaparecido",
           "nm_emergencial"      = "p_nm_emergencial",
           "contato_emergencia"  = "p_contato_emergencia",
           "id_endereco"         = "p_id_endereco"
     WHERE "id_pessoa" = "v_id_pessoa";

    -- 4. Atualiza dados do usuário
    UPDATE "t_gsab_usuario"
       SET "nm_usuario"        = "p_nm_usuario",
           "ds_email"          = "p_ds_email",
           "ds_senha"          = "p_ds_senha",
           "ds_codigo_google"  = "p_ds_codigo_google",
           "id_tipo_usuario"   = "p_id_tipo_usuario"
     WHERE "id_pessoa" = "v_id_pessoa";

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Usuário atualizado com sucesso para o CPF: ' || "p_nr_cpf");

EXCEPTION
    WHEN tipo_usuario_invalido THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, 'Tipo de usuário inválido: ' || "p_id_tipo_usuario");
    WHEN usuario_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20031, 'Pessoa com CPF ' || "p_nr_cpf" || ' não encontrada.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20032, 'Erro ao atualizar usuário: ' || SQLERRM);
END "proc_atualizar_usuario";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_usuario" (
    "p_nr_cpf" IN "t_gsab_pessoa"."nr_cpf"%TYPE
) IS
    usuario_nao_encontrado EXCEPTION;
    v_id_pessoa   NUMBER;
    v_id_usuario  NUMBER;
BEGIN
    -- 1. Verifica se a pessoa existe (via CPF)
    BEGIN
        SELECT "id_pessoa"
          INTO v_id_pessoa
          FROM "t_gsab_pessoa"
         WHERE "nr_cpf" = "p_nr_cpf";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE usuario_nao_encontrado;
    END;

    -- 2. Seleciona o usuário vinculado (se existir)
    BEGIN
        SELECT "id_usuario"
          INTO v_id_usuario
          FROM "t_gsab_usuario"
         WHERE "id_pessoa" = v_id_pessoa;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE usuario_nao_encontrado;
    END;

    -- 3. Exclui o usuário, mantendo a pessoa
    DELETE FROM "t_gsab_usuario"
     WHERE "id_usuario" = v_id_usuario;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Usuário excluído com sucesso (pessoa mantida). CPF: ' || "p_nr_cpf");

EXCEPTION
    WHEN usuario_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20033, 'Usuário com CPF ' || "p_nr_cpf" || ' não encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20034, 'Erro ao excluir usuário: ' || SQLERRM);
END "proc_excluir_usuario";
/