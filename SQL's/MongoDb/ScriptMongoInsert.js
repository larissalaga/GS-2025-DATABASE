db.createCollection("tipo_operacao")
db.createCollection("relatorios")
db.createCollection("imagens")


db.logs.insertOne({
  tipo_operacao: "insercao_checkin",
  usuario: "admin@gsab.com",
  data_hora: new Date(),
  descricao: "Check-in para id_pessoa 102",
  origem: "API"
});


db.relatorio.insertOne({
  id_pessoa: 102,
  relato: "Estou bem, mas preocupado com minha família.",
  data_hora: new Date(),
  responsavel_cadastro: "voluntario@gsab.com"
});

db.imagens.insertOne({
  tipo_imagem: "foto_documento",
  id_pessoa: 102,
  nome_arquivo: "doc_102.jpg",
  data_upload: new Date(),
  tamanho_kb: 340,
  resolucao: "1024x768"
});
