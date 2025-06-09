from queue import Full
from key import USER, PASS 
import oracledb

dsn = oracledb.makedsn('oracle.fiap.com.br', 1521, service_name='orcl')
connection = oracledb.connect(user=USER, password=PASS, dsn=dsn)


cursor = connection.cursor()

pais = [
            ('Brasil',),
            ('Estados Unidos',), 
            ('Alemanha',),
            ('França',),
            ('Japão',),
            ('China',),
            ('Índia',),
            ('Rússia',),
            ('Canadá',),
            ('Austrália',)
]

estado = [
            ('São Paulo', 1),
            ('Rio de Janeiro', 1),
            ('Minas Gerais', 1),
            ('Bahia', 1),
            ('Paraná', 1),
            ('Santa Catarina', 1),
            ('Rio Grande do Sul', 1),
            ('Distrito Federal', 1),
            ('Espírito Santo', 1),
            ('Ceará', 1)
]

cidade = [
            ('São Paulo', 1),
            ('Rio de Janeiro', 2),
            ('Belo Horizonte', 3),
            ('Salvador', 4),
            ('Curitiba', 5),
            ('Florianópolis', 6),
            ('Porto Alegre', 7),
            ('Brasília', 8),
            ('Vitória', 9),
            ('Fortaleza', 10)
]

endereco = [
            ('01000-000', 'Avenida Paulista', 1000, 'Apto 101', 1),
            ('20000-000', 'Avenida Atlântica', 2000, 'Sala 202', 2),
            ('30000-000', 'Rua da Liberdade', 3000, 'Casa 303', 3),
            ('40000-000', 'Avenida Sete de Setembro', 4000, 'Bloco 404', 4),
            ('50000-000', 'Rua XV de Novembro', 5000, 'Lote 505', 5),
            ('60000-000', 'Avenida das Torres', 6000, 'Quadra 606', 6),
            ('70000-000', 'Rua do Comércio', 7000, 'Ponto Comercial 707', 7),
            ('80000-000', 'Avenida Brasil', 8000, 'Loja 808', 8),
            ('90000-000', 'Rua das Flores', 9000, 'Chácara 909', 9),
            ('01010-010', 'Avenida das Américas', 1010, 'Galpão 1011', 10)
]

pessoa = [
            ('João Silva', '123.456.789-00', '01/01/1990', 'Nenhuma', 'N', 'Maria Silva', '99999-9999', 1),
            ('Ana Souza', '234.567.890-11', '02/02/1992', 'Alergia a pólen', 'N', 'Carlos Souza', '88888-8888', 2),
            ('Pedro Oliveira', '345.678.901-22', '03/03/1994', 'Diabetes tipo 1', 'N', 'Fernanda Oliveira', '77777-7777', 3),
            ('Maria Santos', '456.789.012-33', '04/04/1996', 'Hipertensão arterial', 'N', 'Roberto Santos', '66666-6666', 4),
            ('Lucas Costa', '567.890.123-44', '05/05/1998', 'Nenhuma', 'S', 'Juliana Costa', '55555-5555', 5),
            ('Fernanda Lima', '678.901.234-55', '06/06/2000', 'Asma brônquica leve', 'N', 'André Lima', '44444-4444', 6),
            ('Ricardo Almeida', '789.012.345-66', '07/07/2002', 'Nenhuma', 'N', 'Patrícia Almeida', '33333-3333', 7),
            ('Camila Pereira', '890.123.456-77', '08/08/2004', 'Alergia a lactose moderada, intolerância à lactose leve e alergia a glúten leve.', 'N','Eduardo Pereira','22222-2222' ,8),
            ('Bruno Rocha','901.234.567-88','09/09/2006','Nenhuma','S','Tatiane Rocha','11111-1111' ,9),
            ('Larissa Martins','012.345.678-99','10/10/2008','Hipotireoidismo leve','N','Gustavo Martins','00000-0000' ,10)
]

tipoUsuario = [
            ('Administrador',),
            ('Cidadão',),
            ('Voluntário',),
]
usuario = [
            ('João Silva', 'joao.silva@gmail.com', 'senha123', 'codigo_google_1', 1, 1),
            ('Ana Souza', 'aninha2021@gmail.com', 'senha456', 'codigo_google_2', 2, 2),
            ('Pedro Oliveira', 'pedro_oliveira@hotmail.com', 'senha789', 'codigo_google_3', 1, 3),
            ('Maria Santos', 'masa.2015@gmail.com', 'senha101112', 'codigo_google_4', 2, 4),
            ('Lucas Costa', 'lucas_atacante@gmai.com', 'senha131415', 'codigo_google_5', 3, 5)
]

abrigo = [
            ('Abrigo Esperança', 100, 50, 1),
            ('Abrigo Luz do Sol', 80, 30, 2),
            ('Abrigo Refúgio da Paz', 120, 70, 3),
            ('Abrigo Sorriso Feliz', 90, 40, 4),
            ('Abrigo Nova Vida', 110, 60, 5),
            ('Abrigo Esperança Renovada', 70, 20, 6),
            ('Abrigo Caminho da Luz', 50, 10, 7),
            ('Abrigo Coração Amigo', 30, 5, 8),
            ('Abrigo Mãos Solidárias', 40, 15, 9),
            ('Abrigo Abraço Fraterno', 60, 25, 10)
                    
]

checkIn = [
            ('01/01/2023', None, 1, 1),
            ('02/01/2023', '05/01/2023', 2, 2),
            ('03/01/2023', None, 3, 3),
            ('04/01/2023', '06/01/2023', 4, 4),
            ('05/01/2023', None, 5, 5),
            ('06/01/2023', '08/01/2023', 6, 6),
            ('07/01/2023', None, 7, 7),
            ('08/01/2023', '10/01/2023', 8, 8),
            ('09/01/2023', None, 9, 9),
            ('10/01/2023', '12/01/2023', 10, 10)
]

estoqueRecurso = [
            (50, '01/01/2023', 1, 1),
            (30, '02/01/2023', 2, 2),
            (70, '03/01/2023', 3, 3),
            (40, '04/01/2023', 4, 4),
            (60, '05/01/2023', 5, 5),
            (20, '06/01/2023', 6, 6),
            (10, '07/01/2023', 7, 7),
            (5, '08/01/2023', 8, 8),
            (15, '09/01/2023', 9, 9),
            (25, '10/01/2023', 10, 10)
]

recurso = [
            ('Cesta básica', 1/7, 'S'),                     # média de 1 por semana → ~0.14/dia
            ('Cobertor', 0, 'N'),                           # item não consumível
            ('Kit de higiene', 1/5, 'S'),                   # 1 kit dura ~5 dias → 0.2
            ('Roupas', 0, 'N'),                             # não consumível
            ('Calçados', 0, 'N'),                           # não consumível
            ('Produtos de limpeza', 0.05, 'S'),             # uso coletivo diluído
            ('Medicamentos', 0.1, 'S'),                     # média aproximada
            ('Ração para animais', 0.2, 'S'),               # depende do animal, mas média
            ('Brinquedos', 0, 'N'),                         # não consumível
            ('Colchões', 0, 'N'),                           # não consumível
            ('Água potável', 3, 'S'),                       # média 3L/dia por pessoa
            ('Fraldas', 2, 'S'),                            # estimativa por criança/bebê
            ('Lençol', 0, 'N'),                             # não consumível
            ('Máscaras descartáveis', 1, 'S'),             # 1 por dia
            ('Papel higiênico', 0.5, 'S'),                  # média por pessoa
            ('Toalha', 0, 'N'),                             # não consumível
            ('Sabonete líquido comunitário', 0.05, 'S'),    # uso coletivo
            ('Desinfetante', 0.02, 'S'),                    # uso coletivo
            ('Álcool em gel', 0.01, 'S'),                   # uso coletivo
            ('Kit de primeiros socorros', 0, 'N')           # não consumível

]

            

           
try:
    for paisItem in pais:
        cursor.execute('INSERT INTO "t_gsab_pais" VALUES (seq_t_gsab_pais.NEXTVAL, :1)', paisItem)
        connection.commit()
        print("País inserido com sucesso!")

    for estadoItem in estado:
        cursor.execute('INSERT INTO "t_gsab_estado" VALUES (seq_t_gsab_estado.NEXTVAL, :1, :2)', estadoItem)
        connection.commit()
        print("Estado inserido com sucesso!")

    for cidadeItem in cidade:
        cursor.execute('INSERT INTO "t_gsab_cidade" VALUES (seq_t_gsab_cidade.NEXTVAL, :1, :2)', cidadeItem)
        connection.commit()
        print("Cidade inserida com sucesso!")

    for enderecoItem in endereco:
        cursor.execute('INSERT INTO "t_gsab_endereco" VALUES (seq_t_gsab_endereco.NEXTVAL, :1, :2, :3, :4, :5)', enderecoItem)
        connection.commit()
        print("Endereço inserido com sucesso!")

    for pessoaItem in pessoa:
        cursor.execute('INSERT INTO "t_gsab_pessoa" VALUES (seq_t_gsab_pessoa.NEXTVAL, :1, :2, TO_DATE(:3, \'DD/MM/YYYY\'), :4, :5, :6, :7, :8)', pessoaItem)
        connection.commit()
        print("Pessoa inserida com sucesso!")

    for tipoUsuarioItem in tipoUsuario:
        cursor.execute('INSERT INTO "t_gsab_tipo_usuario" VALUES (seq_t_gsab_tipo_usuario.NEXTVAL, :1)', tipoUsuarioItem)
        connection.commit()
        print("Tipo de usuário inserido com sucesso!")

    for usuarioItem in usuario:
        cursor.execute('INSERT INTO "t_gsab_usuario" VALUES (seq_t_gsab_usuario.NEXTVAL, :1, :2, :3, :4, :5, :6)', usuarioItem)
        connection.commit()
        print("Usuário inserido com sucesso!")

    for abrigoItem in abrigo:
        cursor.execute('INSERT INTO "t_gsab_abrigo" VALUES (seq_t_gsab_abrigo.NEXTVAL, :1, :2, :3, :4)', abrigoItem)
        connection.commit()
        print("Abrigo inserido com sucesso!")

    for checkInItem in checkIn:
        cursor.execute('INSERT INTO "t_gsab_check_in" VALUES (seq_t_gsab_check_in.NEXTVAL, TO_DATE(:1, \'DD/MM/YYYY\'), TO_DATE(:2, \'DD/MM/YYYY\'), :3, :4)', checkInItem)
        connection.commit()
        print("Check-in inserido com sucesso!")
    
    for recursoItem in recurso:
        cursor.execute('INSERT INTO "t_gsab_recurso" VALUES (seq_t_gsab_recurso.NEXTVAL, :1, :2, :3)', recursoItem)
        connection.commit()
        print("Recurso inserido com sucesso!")

    for estoqueRecursoItem in estoqueRecurso:
        cursor.execute('INSERT INTO "t_gsab_estoque_recurso" VALUES (seq_t_gsab_estoque_recurso.NEXTVAL, :1, TO_DATE(:2, \'DD/MM/YYYY\'), :3, :4)', estoqueRecursoItem)
        connection.commit()
        print("Estoque de recurso inserido com sucesso!")

    

except oracledb.DatabaseError as e:
    error, = e.args
    print(f"Erro no banco de dados: {error.code} - {error.message}")
    connection.rollback() 
finally:
    cursor.close()
    connection.close()

