# Segurança do banco de dados — ERP Multiplikar Automóveis

## 1. Arquitetura

O banco do sistema é MySQL 8.4. O navegador acessa o site, que chama a API Python; somente a API se conecta ao banco. A conexão deve usar o endereço de loopback 127.0.0.1 para que a porta do MySQL não seja exposta à rede pública.

A configuração observada neste trabalho é a instância local descartável em 127.0.0.1:33306, MySQL Community Server 8.4.13. A configuração de qualquer servidor remoto deve ser conferida no próprio host; não foi medida nesta tarefa.

## 2. Certificados e transporte

Os certificados HTTPS do site permanecem sob a configuração já existente do provedor web e não dependem do banco. Para tráfego de banco que atravesse uma rede, habilite TLS com certificado validado pelo cliente. Na configuração local por loopback, a conexão fica restrita ao host.

## 3. Servidor MySQL

| Controle | Configuração recomendada |
|---|---|
| Versão | MySQL 8.4 |
| Endereço | bind-address=127.0.0.1; não publicar a porta 3306 |
| Autenticação | caching_sha2_password; sem contas anônimas nem autenticação em texto claro |
| Privilégio | Contas de serviço separadas; sem SUPER, FILE, PROCESS ou administração global para a API |
| Transporte remoto | TLS obrigatório caso o banco seja acessado fora do host |
| Segredos | Senhas aleatórias em arquivo de ambiente restrito, nunca no repositório |
| Registro | Logs do serviço e auditoria da aplicação; revisar acesso e retenção |

A instância local usada para demonstração aceita root sem senha e não deve ser exposta nem usada como instalação de produção. Os papéis e grants de produção estão propostos em docs/requisitos-nfr.md.

## 4. Contas da API

Separar leitura, operações negativas revertidas, cadastro e CRM. As contas de cadastro e CRM só devem executar procedures autorizadas. O definidor das rotinas SQL SECURITY DEFINER não deve ter login habilitado e recebe apenas os privilégios que essas rotinas requerem. A API mantém os segredos em variáveis de ambiente e não recebe SQL arbitrário do navegador.

## 5. Dados pessoais

Restringir acesso a CPF/CNPJ, telefone, e-mail, endereço e renda declarada. Registrar consentimento antes de processar renda; mascarar identificadores em consultas de uso público; manter uma finalidade e prazo de retenção para dados do CRM. A aplicação deve atender solicitações de acesso e correção conforme a política de privacidade da loja.

## 6. Backup e auditoria

A recuperação com backup lógico e log binário, incluindo RPO de 15 minutos e RTO de 2 horas, está especificada em docs/requisitos-nfr.md. O procedimento precisa ser implantado e restaurado em ambiente controlado antes de ser considerado operacional. As triggers preservam o histórico comercial; a trilha geral de autor e valores antes/depois continua proposta.

## 7. Limitações

A configuração detalhada de um servidor remoto não foi medida nesta tarefa. Este documento registra o perfil MySQL 8.4 esperado e separa recomendações de segurança dos resultados verificados localmente. A evidência da instância local está em docs/evidencias/verificacao-seguranca.txt.