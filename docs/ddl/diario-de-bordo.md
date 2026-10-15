# Diário de bordo — atividade de DDL

**Projeto:** ERP Multiplikar Automóveis  
**Recorte:** pessoa, funcionário, veículo, avaliação, entrada, venda e associação de veículos recebidos em troca  
**SGBD/dialeto usado nos testes:** SQLite 3.37 ou superior (tabelas `STRICT`)  
**Data:** ____/____/______  
**Integrantes presentes:** ______________________________________________

## Decisões e origem das regras

| Decisão implementada | Origem no projeto |
|---|---|
| O recorte contém sete tabelas relacionadas e a tabela associativa `venda_entrada_troca`. | Enunciado da atividade e modelo conceitual, seções 11–14. |
| Pessoa é identificada por CPF/CNPJ único; funcionário referencia uma pessoa. | RN01–RN03; dicionário E01–E02. |
| Entrada depende de avaliação aprovada, de interesse comercial e do mesmo veículo/modalidade. | RN06–RN10. |
| Uma venda tem uma entrada principal; a entrada de troca pertence ao comprador e é veículo diferente. | RN14, RN16–RN18 e restrições complementares. |
| Formas de pagamento, financiamento e recebimento detalhado foram deixados fora deste recorte. | RN19–RN21; a atividade pede recorte e o projeto não transforma pagamento em entidade. |

## Execução e evidências

Comando: `python3 testes_ddl.py`

| Teste | Restrição verificada | Resultado observado |
|---|---|---|
| Documento repetido | `UNIQUE` | Preencher após execução |
| Funcionário com pessoa inexistente | `FOREIGN KEY` | Preencher após execução |
| Cargo vazio | `NOT NULL` / `CHECK` | Preencher após execução |
| Entrada sem avaliação coerente e aprovada | Regra de negócio via trigger | Preencher após execução |
| Venda com entrada principal de troca | Regra de negócio via trigger | Preencher após execução |
| Veículo principal repetido como troca | Regra de negócio via trigger | Preencher após execução |
| Relação venda–troca e consumo da entrada | Tabela associativa e trigger | Preencher após execução |

### Erros encontrados e correções

Preencher com a tentativa inválida, a mensagem de erro exibida e a correção realizada. Não registrar como ocorrido um erro que não foi observado.

| Tentativa | Erro observado | Correção / aprendizado |
|---|---|---|
|  |  |  |

### Aprendizado da equipe

________________________________________________________________________

________________________________________________________________________

## Observações para validação do grupo

- O recorte testa as regras escolhidas; não substitui o modelo lógico integral do ERP.
- SQLite ativa chaves estrangeiras por conexão; `PRAGMA foreign_keys = ON` está no script.
- Datas são armazenadas como texto ISO (`AAAA-MM-DD`) neste recorte.
- `valor_total` é calculado pelo banco a partir dos componentes do preço.
- Revisar os tipos e domínios caso a disciplina exija outro SGBD ou dialeto.
