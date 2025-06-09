CREATE OR REPLACE TRIGGER "trg_valida_estoque_nao_negativo"
BEFORE INSERT OR UPDATE ON "t_gsab_estoque_recurso"
FOR EACH ROW
DECLARE
    v_ds_recurso VARCHAR2(100);
BEGIN
    IF :NEW."qt_disponivel" < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'A quantidade disponível não pode ser negativa.');
    ELSIF :NEW."qt_disponivel" = 0 THEN
        SELECT "ds_recurso"
          INTO v_ds_recurso
          FROM "t_gsab_recurso"
         WHERE "id_recurso" = :NEW."id_recurso";

        RAISE_APPLICATION_ERROR(-20002, 'O recurso "' || v_ds_recurso || '" acabou no estoque.');
    END IF;
END;
/


DROP TRIGGER "trg_valida_estoque_nao_negativo";

-- Trigger que atualiza a ocupação do abrigo após check-in ou check-out
DROP TRIGGER "trg_atualiza_ocupacao_checkin";
