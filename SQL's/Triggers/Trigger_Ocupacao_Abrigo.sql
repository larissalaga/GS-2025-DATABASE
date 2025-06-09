CREATE OR REPLACE TRIGGER "trg_atualiza_ocupacao_checkin"
AFTER INSERT OR UPDATE OR DELETE ON "t_gsab_check_in"
FOR EACH ROW
DECLARE
    v_ocupacao NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_ocupacao
      FROM "t_gsab_check_in"
     WHERE "id_abrigo" = :NEW."id_abrigo"
       AND "dt_saida" IS NULL;

    UPDATE "t_gsab_abrigo"
       SET "nr_ocupacao_atual" = v_ocupacao
     WHERE "id_abrigo" = :NEW."id_abrigo";
END;
/