# FinFamily

Sistema de gestão financeira familiar. Controla entradas, saídas e saldos de múltiplas contas bancárias, com módulos dedicados para compra e venda de veículos e para estoque de vestuário.

Todas as contas em um só lugar.

## Stack

- Flutter Web
- Firebase Authentication
- Cloud Firestore
- Firebase Hosting

## Funcionalidades

**Visão geral**  
Lançamentos diários por banco, com entradas, saídas, balanço do dia e saldo acumulado. Navegação por dia através de uma faixa de calendário, com atalhos de teclado.

**Resumo do mês**  
Consolidado mensal com gráficos de patrimônio acumulado, entradas e saídas por dia, despesas por categoria e conferência automática contra o extrato bancário.

**Resumo do ano**  
Visão anual com gráficos mensais de patrimônio, receitas e despesas.

**RobMotors**  
Controle de compra e venda de veículos. Cada carro registra valor de compra, custos incorridos (documentação, vistoria, manutenção) e valor de venda, calculando lucro e margem por unidade.

**Vise Versa**  
Controle de estoque de roupas. Cada peça registra marca, modelo, tipo, quantidade e custo unitário com média ponderada nas reposições. Acompanha vendas, faturamento e lucro realizado.

## Contas e transferências

O sistema opera com múltiplas contas (Sicoob, Itaú, Nubank e vale-alimentação), cada uma com saldo inicial e final independentes. A visão Geral consolida todas.

Transferências entre contas aparecem nos lançamentos e afetam o saldo de cada banco, mas ficam fora das métricas de receita e despesa, já que não alteram o patrimônio total.

## Atalhos de teclado

| Tecla | Ação |
|---|---|
| `G` `S` `I` `N` `V` | Alterna entre as contas |
| `1` a `31` | Seleciona o dia |
| Seta para baixo | Nova saída |
| Seta para cima | Nova entrada |
| Setas e `Enter` | Navega pelos formulários |
| `+` | Novo carro ou nova peça |

## Rodando localmente

```bash
flutter pub get
flutter run -d chrome
```

## Build de produção

```bash
flutter build web --release
```

O resultado fica em `build/web`. No Windows, o arquivo `finfamily.vbs` inicia um servidor local e abre o app em janela dedicada do Chrome.

## Configuração do Firebase

O projeto requer um projeto Firebase com Authentication (e-mail e senha) e Cloud Firestore habilitados.

```bash
flutterfire configure
```

As regras do Firestore restringem leitura e escrita aos membros de cada household, validando o uid contra o mapa `members` do documento pai.

## Estrutura
lib/
data/ Catálogos estáticos (categorias, bancos, tipos)
models/ Entidades e serialização do Firestore
services/ Autenticação e acesso a dados
screens/ Telas principais
widgets/ Componentes e diálogos
theme/ Design system
utils/ Formatação e máscaras


## Licença

Projeto de uso pessoal.