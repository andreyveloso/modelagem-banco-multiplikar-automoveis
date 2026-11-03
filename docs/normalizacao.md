# Normalização do ERP Multiplikar Automóveis

Base: README, seções 8 e 11–15. Implementação: [schema.sql](../sql/ddl/schema.sql).
As estruturas “antes” abaixo ilustram traduções diretas inadequadas do DER; não são apresentadas como tabelas que já existiam no repositório.

## 1. Primeira forma normal: formas de pagamento da venda

**Estrutura antes**

```text
VENDA(id_venda, id_comprador, valor_base, desconto, acrescimo, taxas,
      formas_pagamento = {PIX, FINANCIAMENTO}, valor_recebido, ...)
```

Exemplo real da massa: venda 3, total R$ 80.000,00, formas Pix e financiamento.
O financiamento de R$ 60.000,00 já integra os R$ 80.000,00 recebidos.

**Dependência funcional**

```text
id_venda → id_comprador, valor_base, desconto, acrescimo, taxas, valor_recebido, ...
id_venda ↠ codigo_forma                  (dependência multivalorada)
codigo_forma → descricao                (no catálogo de formas)
```

**Problema**

A célula contém uma coleção, em vez de um único valor do domínio. Colunas `forma1`,
`forma2` também criariam um grupo repetitivo e um limite artificial. Listas de texto
permitiriam duplicatas como `PIX, PIX`, dificultando junções e integridade referencial.

**Correção depois**

```text
VENDA(id_venda PK, id_comprador FK, valor_base, desconto, acrescimo, taxas, valor_recebido, ...)
FORMA_PAGAMENTO(codigo PK, descricao UNIQUE)
VENDA_FORMA_PAGAMENTO(id_venda PK/FK, codigo_forma PK/FK)

(3, PIX)
(3, FINANCIAMENTO)
```

A PK composta impede repetir uma forma na mesma venda. O catálogo permite acrescentar
formas sem alterar colunas. A tabela associativa resolve a relação N:N entre vendas e
formas; representa o atributo multivalorado lógico, sem criar recebimentos individuais.
Valores e datas não são atributos dessa associação, respeitando RN19–RN21.

O mesmo tratamento de 1FN foi aplicado a `documentos_conferidos`: cada documento ocupa
uma linha em `VENDA_DOCUMENTO`. Componentes de endereço, condições técnicas, contrato,
scanner e cancelamento tornam-se colunas atômicas. Texto descritivo, como uma cláusula
contratual, é um valor do domínio; não funciona como lista de chaves.

## 2. Segunda forma normal: conferência documental por venda

**Estrutura antes**

```text
DOCUMENTACAO_VENDA(
    id_venda PK, tipo_documento PK,
    id_comprador, numero_contrato, data_registro,
    data_conferencia, reconhecimento_aplicavel,
    data_reconhecimento, justificativa_dispensa)
```

Na venda 2 seriam seis linhas, repetindo o comprador 7, o contrato CV-2 e sua data.

**Dependência funcional**

```text
(id_venda, tipo_documento) →
    data_conferencia, reconhecimento_aplicavel, data_reconhecimento, justificativa_dispensa
id_venda → id_comprador, numero_contrato, data_registro
```

**Problema**

Os dados da venda dependem de apenas parte da chave composta. Corrigir um contrato em
somente uma linha deixaria documentos da mesma negociação com contratos diferentes.
Excluir a última conferência poderia apagar a informação da própria venda.

**Correção depois**

```text
VENDA(id_venda PK, id_comprador FK, numero_contrato, data_registro, ...)
VENDA_DOCUMENTO(
    id_venda PK/FK, tipo_documento PK,
    data_conferencia, reconhecimento_aplicavel,
    data_reconhecimento, justificativa_dispensa)
```

Cada fato documental depende do par completo: “quando este documento foi conferido
nesta venda?”. Nome do comprador e contrato não se repetem nas conferências.
Não existe dependência geral `tipo_documento → reconhecimento_aplicavel`: ATPV e
contrato podem ter aplicabilidade registrada conforme o instrumento; eventual dispensa
exige justificativa. A política não presume firma em CNH ou comprovante de residência.

A decomposição é sem perda: a junção pela PK/FK `id_venda` recupera os dados da venda
em cada conferência existente. A FK impede conferir documento de venda inexistente.

## 3. Terceira forma normal: avaliação, laudo e veículo

**Estrutura antes**

```text
AVALIACAO(
    id_avaliacao PK, id_veiculo FK, id_laudo FK opcional,
    data, quilometragem, decisao_tecnica, ...)
```

As avaliações 4 e 9 da massa analisam o veículo 4 e consultam o laudo 4, antes e
depois do retorno. Reavaliações não devem duplicar o documento cautelar.

**Dependência funcional**

```text
id_avaliacao → id_veiculo, data, quilometragem, decisao_tecnica, ...
id_avaliacao → id_laudo                  (quando há consulta a um laudo)
id_laudo → id_veiculo                   (todo laudo pertence a um único veículo)
```

**Problema**

Na parte dos registros com laudo, o veículo também depende transitivamente do laudo,
que não é chave de Avaliação: o mesmo laudo pode atender várias avaliações. Alterar
um dos vínculos isoladamente poderia fazer uma avaliação consultar laudo de outro carro.
Uma FK simples para LAUDO prova a existência do laudo, mas não a igualdade dos veículos.

**Correção depois**

```text
AVALIACAO(id_avaliacao PK, id_veiculo FK, data, quilometragem, decisao_tecnica, ...)
LAUDO(id_laudo PK, id_veiculo FK, referencia_documental, data_emissao, situacao, resultado)
AVALIACAO_LAUDO(id_avaliacao PK/FK, id_laudo FK)
```

A existência de uma linha em AVALIACAO_LAUDO representa a consulta opcional.
Sua PK `id_avaliacao` garante no máximo um laudo por avaliação, enquanto `id_laudo`
pode se repetir. Nessa relação, a única dependência não trivial é
`id_avaliacao → id_laudo`, com determinante chave. Avaliação não armazena mais o
determinante intermediário `id_laudo`.

A junção com a tabela de vínculo recupera as consultas; um `LEFT JOIN` preserva
avaliações ainda sem laudo. As FKs impedem referências órfãs. Os triggers
`avaliacao_laudo_bi` e `avaliacao_laudo_bu` comparam `AVALIACAO.id_veiculo` e `LAUDO.id_veiculo`
durante a gravação do vínculo, e o trigger `laudo_bu` repete a verificação quando o laudo é alterado.
Portanto, a decomposição mantém a relação opcional e a integridade sem replicar
o veículo em uma terceira tabela. A decomposição elimina a redundância; a igualdade de veículo exigida pela RN08 é garantida pelos triggers MySQL `avaliacao_laudo_bi`, `avaliacao_laudo_bu` e `laudo_bu`, verificados na gravação.

## Verificação do restante do modelo

| Relações | Dependências e decisão |
|---|---|
| PESSOA | Identificador e par tipo/número do documento são chaves candidatas. Nome, contato e endereço ficam centralizados. Não se pressupõe que cidade sozinha determine UF. |
| FUNCIONARIO | `id_funcionario` e `id_pessoa` são chaves candidatas pelo vínculo único adotado no README. Nome e contato são obtidos de PESSOA. |
| Veículo | Identificador determina características. Não se assume `modelo → marca`: o nome de modelo não é um identificador global no levantamento. Placa e chassi são únicos quando conhecidos. |
| ATENDIMENTO | Identificador determina contato, interessado, responsável e interesse; dados cadastrais não são copiados. |
| ENTRADA | Identificador determina o evento; `id_avaliacao` é outra chave candidata, obrigatória e única. Por isso a igualdade do veículo avaliado não introduz dependência de determinante não chave. Valor aceito pertence ao evento, não a Veículo. |
| VENDA | Identificador e entrada principal são chaves candidatas. Comprador e funcionário são referências; nomes não são copiados. Um financiamento opcional permanece como grupo de campos atômicos da venda, conforme RN21. Banco não determina valor, aprovação ou data. |
| OCORRENCIA_GARANTIA | Identificador determina reclamação, análise e solução. Cliente e veículo são obtidos pela venda; não são gravados novamente. |
| DESPESA | Identificador determina data, categoria, descrição, valor e veículo; categoria não determina o valor. |
| FORMA_PAGAMENTO | Código e descrição única são chaves candidatas. |
| VENDA_FORMA_PAGAMENTO | Relação formada somente pela chave composta; não há atributos dependentes de uma parte dela. |
| VENDA_DOCUMENTO | Os dados de conferência/reconhecimento dependem da chave composta completa. |
| AVALIACAO_LAUDO | A chave da avaliação determina o laudo consultado. Não contém cópia do veículo. |

**Por que VENDA não foi dividida.** VENDA tem 38 colunas, mas a decomposição em `VENDA_FINANCIAMENTO`, `VENDA_SCANNER` e `VENDA_CANCELAMENTO` não é necessária: cada grupo depende somente de `id_venda`, com no máximo um financiamento, um scanner pré-entrega e um cancelamento por venda (RN21, RN23 e RN28). Não há dependência transitiva nem grupo repetitivo, então a 3FN se mantém. A separação criaria tabelas 1:1 opcionais só por organização e exigiria junções. Se o escopo passar a aceitar vários financiamentos ou várias passagens de scanner, esses dados devem virar tabelas próprias.

Não foram criadas tabelas apenas para substituir todos os textos por códigos:
os domínios do levantamento não trazem atributos independentes de cargo, categoria
de despesa, marca ou situação documental do laudo.

## Atributos derivados e limites da afirmação de 3FN

As relações de fatos acima estão em 3FN segundo as dependências do levantamento.
`situacao_atual`, `situacao_financeira`, `situacao_documental`, total das trocas e
datas de início/fim de garantia são calculados em views.

`VENDA.valor_total` é uma coluna derivada **controlada** pelo próprio banco:
`GENERATED ALWAYS AS (valor_base - desconto + acrescimo + taxas) VIRTUAL`.
Se fosse tratado como fato independente, introduziria redundância e não seria
correto afirmar 3FN estrita de todas as colunas físicas. Aqui a relação de fatos
não depende dele: o MySQL calcula valor_total como coluna gerada (virtual, calculada na leitura) e rejeita atribuição manual. A expressão
evita divergência entre valor armazenado e componentes da negociação.

Normalização não substitui as regras entre operações. RN13 (ciclos), RN22 (conclusão)
e igualdade dos veículos de avaliação/laudo exigem índices ou restrições adicionais,
documentados no [modelo lógico](modelo-logico.md).

## Extensão

Na extensão aditiva ([01-ddl-propostas-caixa.sql](../sql/extensao/01-ddl-propostas-caixa.sql) e [03-ddl-crm.sql](../sql/extensao/03-ddl-crm.sql)), enquanto `VENDA` mantém `formas_pagamento` como lista simples de códigos para respeitar RN19 e RO12, a fase pré-contratual (`PROPOSTA`) precisa discriminar quanto entra por cada meio de pagamento e em quantos dias o recurso vira caixa (`D+0` vs. `D+x`).

**Estrutura antes**

```text
PROPOSTA(id_proposta, id_atendimento, id_entrada, rotulo, versao, valor_total,
         condicoes_pagamento = {(PIX, 11000.00, 0), (FINANCIAMENTO, 44000.00, 15)}, ...)
```

Exemplo real da massa ([02-massa-propostas-caixa.sql](../sql/extensao/02-massa-propostas-caixa.sql)): proposta 2 (alternativa `B`, versão 1, para o Kwid consignado da entrada 10, total R$ 55.000,00), composta por R$ 11.000,00 à vista em Pix (`D+0`) e R$ 44.000,00 financiados com recebimento previsto em `D+15`.

**Dependência funcional**

```text
id_proposta → id_atendimento, id_entrada, id_funcionario, rotulo, versao, valor_base, desconto, acrescimo, taxas, ...
id_proposta ↠ codigo_forma                              (dependência multivalorada)
(id_proposta, codigo_forma) → valor, prazo_previsto_dias
```

**Problema**

Guardar um conjunto de tuplas `(forma, valor, prazo)` dentro de uma coluna de `PROPOSTA` ou abrir grupos repetitivos (`forma1`, `valor1`, `prazo1`, `forma2`, `valor2`, `prazo2`) viola a 1FN, impede validar a chave estrangeira contra o catálogo `FORMA_PAGAMENTO` e inviabiliza somar em SQL o caixa imediato (`prazo_previsto_dias = 0`) separado do caixa a prazo (`prazo_previsto_dias > 0`) e verificar que a composição fecha exatamente com `valor_total` (RN35).

**Correção depois**

```text
PROPOSTA(id_proposta PK, id_atendimento FK, id_entrada FK, id_funcionario FK, rotulo, versao, valor_total, ...)
PROPOSTA_CONDICAO(id_proposta PK/FK, codigo_forma PK/FK, valor, prazo_previsto_dias)

(2, PIX,           11000.00,  0)
(2, FINANCIAMENTO, 44000.00, 15)
```

Cada condição ocupa uma linha atômica identificada por `(id_proposta, codigo_forma)`, com `valor` e `prazo_previsto_dias` dependentes da chave composta inteira (2FN) e sem dependências transitivas (3FN). Veículos ofertados como parte de pagamento na proposta seguem decomposição análoga em `PROPOSTA_TROCA(id_proposta PK/FK, id_avaliacao PK/FK, valor_oferecido)`.

Os demais casos da extensão — decomposição em 2FN dos fatores explicativos do CRM (`CLASSIFICACAO_LEAD` e `CLASSIFICACAO_FATOR`), preservação da 3FN em `PROPOSTA` (sem duplicar `id_pessoa` nem `id_veiculo`) e cálculo derivado da prestação Price em `vw_simulacao_parcela` —, bem como o quadro de verificação de todas as tabelas novas, estão documentados na seção 5 de [extensao-inovacao.md](extensao-inovacao.md).
