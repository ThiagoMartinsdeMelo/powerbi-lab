# -*- coding: utf-8 -*-
"""Gera datasets fictícios para o laboratório Power BI (5000+ registros cada)."""

import csv
import random
import os
from datetime import datetime, timedelta

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "data")
RECORD_COUNT = 5000
random.seed(42)

REGIOES = ["Norte", "Nordeste", "Centro-Oeste", "Sudeste", "Sul"]
PRODUTOS = [
    "Notebook Pro", "Monitor 27\"", "Teclado Mecânico", "Mouse Wireless",
    "Headset Gamer", "Webcam HD", "SSD 1TB", "Memória RAM 16GB",
    "Impressora Laser", "Tablet 10\"", "Smartphone", "Roteador WiFi 6",
    "Cadeira Ergonômica", "Mesa Digitalizadora", "Hub USB-C"
]
CANAIS = ["Google Ads", "Facebook", "Instagram", "LinkedIn", "Email", "SEO", "YouTube", "TikTok"]
DEPARTAMENTOS = ["TI", "Vendas", "Marketing", "Financeiro", "RH", "Logística", "Contabilidade"]
CARGOS = ["Analista", "Coordenador", "Gerente", "Diretor", "Assistente", "Estagiário"]
FORNECEDORES = ["TransLog", "RapidFrete", "ExpressCargo", "GlobalShip", "FastDelivery"]
ACOES = [
    ("PETR4", "Petrobras"), ("VALE3", "Vale"), ("ITUB4", "Itaú"),
    ("BBDC4", "Bradesco"), ("ABEV3", "Ambev"), ("WEGE3", "WEG"),
    ("RENT3", "Localiza"), ("MGLU3", "Magazine Luiza"), ("BBAS3", "Banco do Brasil"),
    ("SUZB3", "Suzano")
]
CONTAS = [
    "Receita de Vendas", "Receita de Serviços", "Custo de Mercadorias",
    "Despesas Administrativas", "Despesas com Pessoal", "Marketing",
    "Depreciação", "Juros Passivos", "Impostos", "Outras Receitas"
]


def random_date(start_year=2022, end_year=2025):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    delta = end - start
    return start + timedelta(days=random.randint(0, delta.days))


def write_csv(filename, headers, rows):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)
    print(f"  {filename}: {len(rows)} registros")


def generate_vendas():
    rows = []
    for i in range(1, RECORD_COUNT + 1):
        qtd = random.randint(1, 20)
        preco = round(random.uniform(50, 5000), 2)
        rows.append([
            i,
            random_date().strftime("%Y-%m-%d"),
            random.choice(PRODUTOS),
            random.choice(REGIOES),
            qtd,
            preco,
            round(qtd * preco, 2),
            random.choice(["Online", "Loja Física", "Marketplace", "Televendas"]),
            f"VND-{i:05d}"
        ])
    write_csv("vendas.csv", [
        "id", "data_venda", "produto", "regiao", "quantidade",
        "preco_unitario", "valor_total", "canal", "codigo_pedido"
    ], rows)


def generate_marketing():
    rows = []
    for i in range(1, RECORD_COUNT + 1):
        investimento = round(random.uniform(100, 50000), 2)
        conversoes = random.randint(0, 500)
        rows.append([
            i,
            random_date().strftime("%Y-%m-%d"),
            random.choice(CANAIS),
            random.choice(REGIOES),
            investimento,
            random.randint(1000, 100000),
            conversoes,
            round(conversoes / max(random.randint(100, 10000), 1) * 100, 2),
            random.choice(DEPARTAMENTOS)
        ])
    write_csv("marketing.csv", [
        "id", "data_campanha", "canal", "regiao", "investimento",
        "impressoes", "conversoes", "taxa_conversao", "departamento"
    ], rows)


def generate_financeiro():
    rows = []
    for i in range(1, RECORD_COUNT + 1):
        receita = round(random.uniform(1000, 500000), 2)
        despesa = round(receita * random.uniform(0.3, 0.9), 2)
        rows.append([
            i,
            random_date().strftime("%Y-%m-%d"),
            random.choice(REGIOES),
            receita,
            despesa,
            round(receita - despesa, 2),
            round((receita - despesa) / receita * 100, 2),
            random.choice(["Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
                          "Jul", "Ago", "Set", "Out", "Nov", "Dez"]),
            random.randint(2022, 2025)
        ])
    write_csv("financeiro.csv", [
        "id", "data_lancamento", "regiao", "receita", "despesa",
        "lucro", "margem_percentual", "mes", "ano"
    ], rows)


def generate_rh():
    rows = []
    for i in range(1, RECORD_COUNT + 1):
        salario = round(random.uniform(2000, 25000), 2)
        rows.append([
            i,
            f"Funcionário {i:04d}",
            random.choice(CARGOS),
            random.choice(DEPARTAMENTOS),
            random.choice(REGIOES),
            salario,
            random_date(2015, 2024).strftime("%Y-%m-%d"),
            random.choice(["Ativo", "Ativo", "Ativo", "Férias", "Desligado"]),
            random.randint(18, 65)
        ])
    write_csv("rh.csv", [
        "id", "nome", "cargo", "departamento", "regiao",
        "salario", "data_admissao", "status", "idade"
    ], rows)


def generate_logistica():
    rows = []
    for i in range(1, RECORD_COUNT + 1):
        peso = round(random.uniform(0.5, 500), 2)
        rows.append([
            i,
            random_date().strftime("%Y-%m-%d"),
            f"PED-{i:06d}",
            random.choice(FORNECEDORES),
            random.choice(REGIOES),
            random.choice(REGIOES),
            peso,
            round(random.uniform(10, 500), 2),
            random.randint(1, 15),
            random.choice(["Entregue", "Em Trânsito", "Aguardando", "Devolvido"])
        ])
    write_csv("logistica.csv", [
        "id", "data_envio", "pedido", "transportadora", "origem",
        "destino", "peso_kg", "custo_frete", "dias_entrega", "status"
    ], rows)


def generate_contabilidade():
    rows = []
    for i in range(1, RECORD_COUNT + 1):
        valor = round(random.uniform(100, 100000), 2)
        rows.append([
            i,
            random_date().strftime("%Y-%m-%d"),
            random.choice(CONTAS),
            random.choice(["Débito", "Crédito"]),
            valor,
            random.choice(REGIOES),
            f"DOC-{i:06d}",
            random.choice(DEPARTAMENTOS)
        ])
    write_csv("contabilidade.csv", [
        "id", "data_lancamento", "conta", "tipo", "valor",
        "regiao", "documento", "centro_custo"
    ], rows)


def generate_acoes():
    rows = []
    for i in range(1, RECORD_COUNT + 1):
        ticker, empresa = random.choice(ACOES)
        abertura = round(random.uniform(10, 200), 2)
        variacao = round(random.uniform(-5, 5), 2)
        fechamento = round(abertura + variacao, 2)
        rows.append([
            i,
            random_date().strftime("%Y-%m-%d"),
            ticker,
            empresa,
            abertura,
            round(random.uniform(abertura * 0.98, abertura * 1.02), 2),
            round(random.uniform(abertura * 0.97, abertura * 1.03), 2),
            fechamento,
            random.randint(100000, 50000000),
            round(variacao / abertura * 100, 2)
        ])
    write_csv("acoes.csv", [
        "id", "data", "ticker", "empresa", "abertura", "maxima",
        "minima", "fechamento", "volume", "variacao_percentual"
    ], rows)


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"Gerando {RECORD_COUNT} registros por dataset em {OUTPUT_DIR}...")
    generate_vendas()
    generate_marketing()
    generate_financeiro()
    generate_rh()
    generate_logistica()
    generate_contabilidade()
    generate_acoes()
    print("Concluído!")
