Kali Metasploitable Tester

Projeto de laboratório em Kali Linux usando a ferramenta Medusa para simular cenários de ataque de força bruta em serviços expostos por ambientes vulneráveis, como Metasploitable 2 e DVWA.

⚠️ Uso exclusivo para fins educacionais, em ambientes controlados e com autorização.

🎯 Objetivo do Projeto

Implementar, documentar e compartilhar um conjunto de scripts em Bash que:

Automatizam testes de força bruta com Medusa:

FTP

Formulário Web (DVWA / HTTP simples)

SMB (password spraying)

Fazem enumeração de usuários SMB com enum4linux

Organizam os testes em um menu principal, para que o usuário só precise:

Informar o IP/host alvo

Escolher o cenário de ataque

Selecionar wordlists (ou usar as padrão do projeto)

Esse projeto não é uma ferramenta “pronta para produção”, e sim um laboratório didático para praticar:

Montagem de comandos Medusa

Noções de brute force e password spraying

Enumeração de serviços em ambiente vulnerável

Boas práticas de documentação de testes

🧱 Cenários Implementados
1. FTP – Força Bruta

Script responsável por atacar um serviço FTP no alvo usando Medusa.

Comando base (conceito):

medusa -h $TARGET -U $USERLIST -P $PASSLIST -M ftp -t 6


Funcionalidades esperadas:

Receber IP/host de destino (-t / TARGET)

Usar lista de usuários e senhas (ou arquivos padrão do repositório)

Exibir o comando antes de rodar (para fins didáticos)

Salvar o output em arquivo de log (ex.: logs/ftp_*.log)

2. Formulário Web (HTTP) – Força Bruta

Script para testar brute force em formulários de login web (ex.: DVWA em modo low/medium, sem HTTPS, sem cookies avançados).

Comando base (conceito):

medusa -h $TARGET -U $USERLIST -P $PASSLIST -M http \
  -m PAGE:"$PAGETGT" \
  -m FORM:"username=^USER^&password=^PASS^&Login=Login" \
  -m "FAIL=Login failed" \
  -t 6


Pontos configuráveis pelo script:

TARGET → IP/host do servidor web

PAGETGT → caminho da página de login (ex.: /dvwa/login.php)

Wordlists de usuário/senha

Padrão da resposta de falha (FAIL=)

💡 Focado em cenários simples, sem HTTPS e sem cookies complexos, apenas para demonstração.

3. SMB – Password Spraying

Script para testar credenciais em SMB simulando um cenário de password spraying em ambiente vulnerável (ex.: Metasploitable 2).

Comando base (conceito):

medusa -h $TARGET -U $USERLIST -P $PASSLIST -M smb -t 6


Integração planejada:

Caso o usuário não tenha lista de usuários, o menu poderá sugerir rodar primeiro a enumeração SMB (abaixo).

4. Enumeração de Usuários SMB (enum4linux)

Script para enumerar usuários em um alvo SMB utilizando enum4linux.

Comando base:

enum4linux -a $TARGET | tee output.txt

Funções do script:

Verificar se enum4linux está instalado

Rodar a enumeração com -a

Salvar output em output.txt (ou pasta logs/)

(Opcional / futuro) Extrair usuários de output.txt para um users.txt

🧩 Menu Principal

O projeto possui (ou terá) um script principal que:

Exibe um menu interativo com opções, por exemplo:

[1] FTP – Bruteforce
[2] Web Form – Bruteforce (HTTP)
[3] SMB – Password Spraying
[4] SMB – Enumeração de Usuários (enum4linux)
[0] Sair


Pergunta o IP/host alvo

Pergunta caminhos para wordlists (ou usa defaults)

Chama os scripts individuais dentro da pasta scripts/

⚙️ Requisitos

No Kali Linux (ou outra distro compatível), recomenda-se:

medusa

enum4linux

bash

Ambientes vulneráveis para teste:

Metasploitable 2

DVWA (rodando em outra VM ou container)

Rede configurada (ex.: Host-Only / Internal Network no VirtualBox)

🚀 Como Usar

Clonar o repositório

git clone https://github.com/willianlemest/kali_metasploitable_tester
cd kali_metasploitable_tester

Seguir as instruções na tela

Informar IP/host do alvo

Escolher o cenário (FTP, Web, SMB, Enumeração)

Informar wordlists ou usar as padrão do projeto

📑 Wordlists

O projeto inclui (ou incluirá):

wordlists/users.txt > lista simples de possíveis usuários

wordlists/passwords.txt > lista simples de senhas

wordlists/passwords. > Arquivo básico para testes ( 10 itens que podem ser usados para user e passwords)

🛡️ Ética e Responsabilidade

Este projeto foi criado para fins educacionais, especialmente para:

Estudos de Segurança da Informação

Laboratórios em ambiente controlado

Demonstração de riscos de senhas fracas e serviços expostos

⚠️ Não utilize este projeto para atacar sistemas de terceiros sem autorização formal.
O uso indevido pode ser crime de acordo com a legislação vigente.