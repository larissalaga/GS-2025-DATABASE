/*
DROP TABLE "t_gsab_estoque_recurso" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_estoque_recurso;
DROP TABLE "t_gsab_recurso" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_recurso;
DROP TABLE "t_gsab_abrigo" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_abrigo;
DROP TABLE "t_gsab_check_in" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_check_in;
DROP TABLE "t_gsab_usuario" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_usuario;
DROP TABLE "t_gsab_tipo_usuario" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_tipo_usuario;
DROP TABLE "t_gsab_pessoa" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_pessoa;
DROP TABLE "t_gsab_endereco" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_endereco;
DROP TABLE "t_gsab_cidade" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_cidade;
DROP TABLE "t_gsab_estado" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_estado;
DROP TABLE "t_gsab_pais" CASCADE CONSTRAINTS;
DROP SEQUENCE seq_t_gsab_pais;
*/
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_pais;

CREATE TABLE "t_gsab_pais" (
    "id_pais"  NUMBER NOT NULL,
    "nm_pais"  VARCHAR2(100 CHAR) NOT NULL,
    CONSTRAINT "pk_gsab_pais" PRIMARY KEY ("id_pais")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_estado;

CREATE TABLE "t_gsab_estado" (
    "id_estado"  NUMBER NOT NULL,
    "nm_estado"  VARCHAR2(100 CHAR) NOT NULL,
    "id_pais"    NUMBER NOT NULL,
    CONSTRAINT "pk_gsab_estado" PRIMARY KEY ("id_estado"),
    CONSTRAINT "fk_estado_pais" FOREIGN KEY ("id_pais") REFERENCES "t_gsab_pais" ("id_pais")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_cidade;

CREATE TABLE "t_gsab_cidade" (
    "id_cidade"  NUMBER NOT NULL,
    "nm_cidade"  VARCHAR2(100 CHAR) NOT NULL,
    "id_estado"  NUMBER NOT NULL,
    CONSTRAINT "pk_gsab_cidade" PRIMARY KEY ("id_cidade"),
    CONSTRAINT "fk_cidade_estado" FOREIGN KEY ("id_estado") REFERENCES "t_gsab_estado" ("id_estado")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_endereco;

CREATE TABLE "t_gsab_endereco" (
    "id_endereco"     NUMBER NOT NULL,
    "ds_cep"          VARCHAR2(11 CHAR) NOT NULL,
    "ds_logradouro"   VARCHAR2(100 CHAR) NOT NULL,
    "nr_numero"       NUMBER NOT NULL,
    "ds_complemento"  VARCHAR2(100 CHAR) NOT NULL,
    "id_cidade"       NUMBER NOT NULL,
    CONSTRAINT "pk_gsab_endereco" PRIMARY KEY ("id_endereco"),
    CONSTRAINT "fk_endereco_cidade" FOREIGN KEY ("id_cidade") REFERENCES "t_gsab_cidade" ("id_cidade")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_pessoa;

CREATE TABLE "t_gsab_pessoa" (
    "id_pessoa"           NUMBER NOT NULL,
    "nm_pessoa"           VARCHAR2(100 CHAR) NOT NULL,
    "nr_cpf"              VARCHAR2(14 CHAR) NOT NULL,
    "dt_nascimento"       DATE NOT NULL,
    "ds_condicao_medica"  CLOB NOT NULL,
    "st_desaparecido"     CHAR(1 CHAR) NOT NULL,
    "nm_emergencial"      VARCHAR2(100 CHAR) NOT NULL,
    "contato_emergencia"  VARCHAR2(100 CHAR) NOT NULL,
    "id_endereco"         NUMBER NOT NULL,
    CONSTRAINT "pk_gsab_pessoa" PRIMARY KEY ("id_pessoa"),
    CONSTRAINT "fk_pessoa_endereco" FOREIGN KEY ("id_endereco") REFERENCES "t_gsab_endereco" ("id_endereco")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_tipo_usuario;

CREATE TABLE "t_gsab_tipo_usuario" (
    "id_tipo_usuario"  NUMBER NOT NULL,
    "ds_tipo_usuario"  VARCHAR2(20 CHAR) NOT NULL,
    CONSTRAINT "pk_tipo_usuario" PRIMARY KEY ("id_tipo_usuario")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_usuario;

CREATE TABLE "t_gsab_usuario" (
    "id_usuario"        NUMBER NOT NULL,
    "nm_usuario"        VARCHAR2(100 CHAR) NOT NULL,
    "ds_email"          VARCHAR2(100 CHAR) NOT NULL,
    "ds_senha"          VARCHAR2(100) NOT NULL,
    "ds_codigo_google"  VARCHAR2(120 CHAR) NOT NULL,
    "id_tipo_usuario"   NUMBER NOT NULL,
    "id_pessoa"         NUMBER NOT NULL,
    CONSTRAINT "pk_usuario" PRIMARY KEY ("id_usuario"),
    CONSTRAINT "fk_usuario_pessoa" FOREIGN KEY ("id_pessoa") REFERENCES "t_gsab_pessoa" ("id_pessoa"),
    CONSTRAINT "fk_usuario_tipo" FOREIGN KEY ("id_tipo_usuario") REFERENCES "t_gsab_tipo_usuario" ("id_tipo_usuario")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_abrigo;

CREATE TABLE "t_gsab_abrigo" (
    "id_abrigo"          NUMBER NOT NULL,
    "nm_abrigo"          VARCHAR2(100 CHAR) NOT NULL,
    "nr_capacidade"      NUMBER NOT NULL,
    "nr_ocupacao_atual"  NUMBER NOT NULL,
    "id_endereco"        NUMBER NOT NULL,
    CONSTRAINT "pk_gsab_abrigo" PRIMARY KEY ("id_abrigo"),
    CONSTRAINT "fk_abrigo_endereco" FOREIGN KEY ("id_endereco") REFERENCES "t_gsab_endereco" ("id_endereco")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_check_in;

CREATE TABLE "t_gsab_check_in" (
    "id_checkin"  NUMBER NOT NULL,
    "dt_entrada"  DATE NOT NULL,
    "dt_saida"    DATE,
    "id_abrigo"   NUMBER NOT NULL,
    "id_pessoa"   NUMBER NOT NULL,
    CONSTRAINT "pk_check_in" PRIMARY KEY ("id_checkin"),
    CONSTRAINT "fk_checkin_abrigo" FOREIGN KEY ("id_abrigo") REFERENCES "t_gsab_abrigo" ("id_abrigo"),
    CONSTRAINT "fk_checkin_pessoa" FOREIGN KEY ("id_pessoa") REFERENCES "t_gsab_pessoa" ("id_pessoa")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_recurso;

CREATE TABLE "t_gsab_recurso" (
    "id_recurso"     NUMBER NOT NULL,
    "ds_recurso"     VARCHAR2(100 CHAR) NOT NULL,
    "qt_pessoa_dia"  NUMBER NOT NULL,
    "st_consumivel"  CHAR(1) NOT NULL,
    CONSTRAINT "pk_gsab_recurso" PRIMARY KEY ("id_recurso")
);
------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE seq_t_gsab_estoque_recurso;

CREATE TABLE "t_gsab_estoque_recurso" (
    "id_estoque"      NUMBER NOT NULL,
    "qt_disponivel"   NUMBER NOT NULL,
    "dt_atualizacao"  DATE NOT NULL,
    "id_abrigo"       NUMBER NOT NULL,
    "id_recurso"      NUMBER NOT NULL,
    CONSTRAINT "pk_estoque_recurso" PRIMARY KEY ("id_estoque"),
    CONSTRAINT "fk_estoque_abrigo" FOREIGN KEY ("id_abrigo") REFERENCES "t_gsab_abrigo" ("id_abrigo"),
    CONSTRAINT "fk_estoque_recurso" FOREIGN KEY ("id_recurso") REFERENCES "t_gsab_recurso" ("id_recurso")
);
------------------------------------------------------------------------------------------------------------------------