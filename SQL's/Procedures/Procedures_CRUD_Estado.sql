------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE INSERT

CREATE OR REPLACE PROCEDURE "proc_inserir_estado" (
  "p_nm_estado" IN "t_gsab_estado"."nm_estado"%TYPE,
  "p_nm_pais"   IN "t_gsab_pais"."nm_pais"%TYPE
) IS
  estado_exists EXCEPTION;
  v_estado_id   NUMBER;
  v_pais_id     NUMBER;
BEGIN
  -- 1) Verifica duplicidade
  BEGIN
    SELECT "id_estado" INTO v_estado_id
      FROM "t_gsab_estado"
     WHERE "nm_estado" = "p_nm_estado"
       AND "id_pais"   = (
         SELECT "id_pais"
           FROM "t_gsab_pais"
          WHERE "nm_pais" = "p_nm_pais"
       );
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL; -- Apenas indica que não encontrou
  END;

  IF v_estado_id IS NOT NULL THEN
    RAISE estado_exists;
  END IF;

  -- 2) Garante existência do país
  BEGIN
    SELECT "id_pais" INTO v_pais_id
      FROM "t_gsab_pais"
     WHERE "nm_pais" = "p_nm_pais";
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      proc_inserir_pais("p_nm_pais");
      SELECT "id_pais" INTO v_pais_id
        FROM "t_gsab_pais"
       WHERE "nm_pais" = "p_nm_pais";
  END;

  -- 3) Insere o estado
  INSERT INTO "t_gsab_estado" ("id_estado","nm_estado","id_pais") VALUES (
    seq_t_gsab_estado.NEXTVAL,
    "p_nm_estado",
    v_pais_id
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Estado inserido com sucesso: ' || "p_nm_estado");

EXCEPTION
  WHEN estado_exists THEN
    RAISE_APPLICATION_ERROR(-20001, 'Estado já cadastrado para esse país.');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20000, 'Erro ao inserir estado: ' || SQLERRM);
END "proc_inserir_estado";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE UPDATE

CREATE OR REPLACE PROCEDURE "proc_atualizar_estado" (
    "p_id_estado" IN "t_gsab_estado"."id_estado"%TYPE,
    "p_nm_estado" IN "t_gsab_estado"."nm_estado"%TYPE,
    "p_nm_pais"   IN "t_gsab_pais"."nm_pais"%TYPE
) IS
    estado_nao_encontrado EXCEPTION;
    duplicado_estado      EXCEPTION;
    v_pais_id             NUMBER;
    v_estado_existente    NUMBER;
BEGIN
    -- 1) Verifica se o estado existe
    BEGIN
        SELECT "id_estado" INTO v_estado_existente
          FROM "t_gsab_estado"
         WHERE "id_estado" = "p_id_estado";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE estado_nao_encontrado;
    END;

    -- 2) Verifica duplicidade para novo nome + país
    BEGIN
        SELECT "id_estado" INTO v_estado_existente
          FROM "t_gsab_estado" e
          JOIN "t_gsab_pais" p
            ON e."id_pais" = p."id_pais"
         WHERE e."nm_estado" = "p_nm_estado"
           AND p."nm_pais"   = "p_nm_pais"
           AND e."id_estado" <> "p_id_estado";
        RAISE duplicado_estado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- Sem duplicidade
    END;

    -- 3) Garante existência do país alvo
    BEGIN
        SELECT "id_pais" INTO v_pais_id
          FROM "t_gsab_pais"
         WHERE "nm_pais" = "p_nm_pais";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            proc_inserir_pais("p_nm_pais");
            SELECT "id_pais" INTO v_pais_id
              FROM "t_gsab_pais"
             WHERE "nm_pais" = "p_nm_pais";
    END;

    -- 4) Atualiza o estado
    UPDATE "t_gsab_estado"
       SET "nm_estado" = "p_nm_estado",
           "id_pais"   = v_pais_id
     WHERE "id_estado" = "p_id_estado";
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estado atualizado com sucesso. ID = ' || "p_id_estado");

EXCEPTION
    WHEN estado_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Estado com ID ' || "p_id_estado" || ' não encontrado.');
    WHEN duplicado_estado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Já existe outro estado com esse nome neste país.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Erro ao atualizar estado: ' || SQLERRM);
END "proc_atualizar_estado";
/
------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE DELETE

CREATE OR REPLACE PROCEDURE "proc_excluir_estado" (
    "p_id_estado" IN "t_gsab_estado"."id_estado"%TYPE
) IS
    estado_nao_encontrado EXCEPTION;
    estado_em_uso         EXCEPTION;
    v_id_estado           NUMBER;
    v_tem_vinculo         NUMBER;
BEGIN
    -- 1. Verifica se o estado existe
    BEGIN
        SELECT "id_estado"
          INTO v_id_estado
          FROM "t_gsab_estado"
         WHERE "id_estado" = "p_id_estado";
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE estado_nao_encontrado;
    END;

    -- 2. Verifica vínculo com cidade
    BEGIN
        SELECT 1
          INTO v_tem_vinculo
          FROM "t_gsab_cidade"
         WHERE "id_estado" = v_id_estado
           AND ROWNUM = 1;
        RAISE estado_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 3. Verifica vínculo com endereço
    BEGIN
        SELECT 1
          INTO v_tem_vinculo
          FROM "t_gsab_endereco" e
          JOIN "t_gsab_cidade" c
            ON e."id_cidade" = c."id_cidade"
         WHERE c."id_estado" = v_id_estado
           AND ROWNUM = 1;
        RAISE estado_em_uso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- 4. Exclui o estado
    DELETE FROM "t_gsab_estado"
     WHERE "id_estado" = v_id_estado;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Estado excluído com sucesso. ID: ' || "p_id_estado");

EXCEPTION
    WHEN estado_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20070, 'Estado com ID ' || "p_id_estado" || ' não encontrado.');
    WHEN estado_em_uso THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20071, 'Não é possível excluir o estado. Há cidades ou endereços vinculados.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20072, 'Erro ao excluir estado: ' || SQLERRM);
END "proc_excluir_estado";
/