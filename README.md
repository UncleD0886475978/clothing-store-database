<div align="center">

# 👕 clothing-store-database

### Threads & Co. — a neighborhood apparel store going multi-channel, with its whole store in a MySQL 8 database. One command.

![MySQL](https://img.shields.io/badge/MySQL-8-4479A1?logo=mysql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-StatefulSet-326CE5?logo=kubernetes&logoColor=white)
![Threads & Co.](https://img.shields.io/badge/Threads%20%26%20Co.-Apparel%20Retail-success)
![Business Builds](https://img.shields.io/badge/Project-Business%20Builds-blue)

</div>

---

## 🧵 The store

**Threads & Co.** started as a single neighborhood apparel shop — the kind
of place that knows its regulars by name. Now it's going **multi-channel**:
the same racks in the store, a web storefront, and market-day pop-ups, all
drawing on **one** catalog, **one** stock count, and **one** order book.

This repo is that single source of truth: a MySQL 8 database covering the
full life of a garment — category → product → size/color variant → shelf
stock → customer order → payment — plus the promotions that move the Sale
rail. It ships seeded with a realistic sample store (marked as sample data
in the SQL) so every report runs against numbers that look like a real
shop's. The storefront itself runs on Google Cloud GKE in the sibling repo
[clothing-store-gke](https://github.com/UncleD0886475978/clothing-store-gke);
this repo is the database underneath it.

## 🌟 What you get

| Feature | What you get |
|---|---|
| 🚀 **One-command bootstrap** | `./setup.sh` **installs its own prerequisites** on a fresh Ubuntu/Debian VM (base tools via apt, Docker via get.docker.com, kubectl from dl.k8s.io), starts the DB, loads schema + seed, and runs the reports |
| 🗄️ **Complete retail schema** | **9 tables** (`schema.sql`, InnoDB + foreign keys): categories, products, product_variants, inventory, customers, orders, order_items, payments, promotions |
| 👗 **Realistic sample store** | `seed.sql`: 6 categories, 12 products, 30 size/color variants with SKUs (`TC-TSHIRT-M-BLK`), stock for every variant, 5 customers, 4 orders with items + payments, 2 promotions |
| 📊 **Built-in report queries** | The installer finishes with two real reports: **total stock value** (quantity × price across all variants) and **sales by category** |
| 🐳 **Docker mode** | Compose stack (`mysql:8`) with a named volume, `mysqladmin ping` healthcheck, and safe change-me defaults in `.env` |
| ☸️ **Kubernetes mode** | `./setup.sh k8s` — StatefulSet + 10Gi PVC + Secret + ClusterIP & headless Services in the `threads` namespace |
| 💾 **Persistent data** | Your data survives restarts in both modes (Docker volume / Kubernetes PVC); `down` keeps the data |

## 🏗️ How it fits together

```
   Docker mode                          Kubernetes mode
┌──────────────┐                     ┌─────────────────────────────┐
│  storefront /│                     │  namespace: threads         │
│  mysql client│                     │                             │
└──────┬───────┘                     │  Service ──▶ StatefulSet    │
       │ localhost:3306              │               │             │
┌──────▼───────┐                     │               ▼             │
│   MySQL 8    │                     │        PVC (10Gi storage)   │
│  container   │                     └─────────────────────────────┘
└──────┬───────┘
       ▼
  named volume (data)
   schema.sql + seed.sql are piped in by setup.sh in both modes
```

**Schema at a glance:** `categories` 1─n `products` 1─n `product_variants`
1─1 `inventory`; `customers` 1─n `orders` 1─n `order_items` (each item
points at a variant), `orders` 1─n `payments`; `promotions` stand alone
with unique discount codes.

## ✅ Requirements

- **A fresh Ubuntu/Debian VM is all you need** — `setup.sh` installs git,
  curl, Docker (and kubectl for k8s mode) itself. Non-apt platforms get
  printed install guidance instead.
- **Kubernetes mode:** any cluster for `kubectl` to point at (minikube,
  kind, Docker Desktop, EKS, AKS, or GKE).
- No cloud account, no API keys.

## 🚀 Quick start

**One-liner — fresh VM, nothing installed:**

```bash
curl -fsSL https://raw.githubusercontent.com/UncleD0886475978/clothing-store-database/main/setup.sh | bash
```

**Docker — from a checkout:**

```bash
./setup.sh          # same as ./setup.sh docker
```

**Kubernetes — one command:**

```bash
./setup.sh k8s
```

Both modes print your connection info when they're done, after loading the
schema and seed data and running the two report queries. First Docker run
pulls the `mysql:8` image, so give it a minute.

**Stop it (data is kept):**

```bash
./setup.sh down
```

## 🔌 Connect

```bash
# mysql client (from your machine)
mysql -h 127.0.0.1 -P 3306 -u threads -p threads_store

# or inside the running container
docker compose exec db mysql -uthreads -p threads_store
```

On Kubernetes, port-forward first (leave it running), then use the same command as above:

```bash
kubectl -n threads port-forward svc/clothing-store-mysql 3306:3306
# then: mysql -h 127.0.0.1 -P 3306 -u threads -p threads_store
```

Try the reports yourself:

```sql
-- Total stock value
SELECT sum(i.quantity_on_hand * v.price) FROM inventory i
JOIN product_variants v ON v.id = i.variant_id;

-- Sales by category
SELECT c.name, sum(oi.quantity * oi.unit_price) FROM order_items oi
JOIN product_variants v ON v.id = oi.variant_id
JOIN products p ON p.id = v.product_id
JOIN categories c ON c.id = p.category_id GROUP BY c.name;
```

> ⚠️ The default passwords are `threads_change_me` /
> `threads_root_change_me` — fine at home, **change them** in `.env`
> (Docker) or `k8s/secret.yaml` (Kubernetes) for anything real.

## 📁 Project layout

```
clothing-store-database/
├── setup.sh              # THE bootstrap script: docker | k8s | down — installs prerequisites, loads data, runs reports
├── docker-compose.yml    # MySQL 8 + named volume + healthcheck
├── .env.example          # db / user / passwords / port (change-me defaults)
├── schema.sql            # 9-table retail schema (InnoDB, FKs, ENUMs)
├── seed.sql              # SAMPLE Threads & Co. catalog, stock, customers, orders
├── k8s/
│   ├── namespace.yaml        # "threads" namespace
│   ├── secret.example.yaml   # same credentials as .env.example
│   ├── pvc.yaml              # 10Gi persistent storage
│   ├── statefulset.yaml      # the database, with native readiness/liveness probes
│   └── service.yaml          # ClusterIP + headless service
└── README.md
```

## 👨‍👩‍👧 Sibling repos — Business Builds

Themed business databases & cloud environments, same bootstrap pattern:

- [zadc-liberia-database](https://github.com/UncleD0886475978/zadc-liberia-database) — PostgreSQL database for ZADC Inc. Liberia, a national NGO in Nimba County
- [fast-food-database](https://github.com/UncleD0886475978/fast-food-database) — MongoDB fast-food database
- [nursing-home-eks](https://github.com/UncleD0886475978/nursing-home-eks) — nursing home environment on AWS EKS
- [it-services-aks](https://github.com/UncleD0886475978/it-services-aks) — IT services environment on Azure AKS
- [clothing-store-gke](https://github.com/UncleD0886475978/clothing-store-gke) — **the Threads & Co. storefront environment on Google Cloud GKE** — this database, running in the cloud

## 🗺️ Roadmap

- [x] One-command bootstrap install (Docker + Kubernetes) that installs its own prerequisites
- [x] 9-table retail schema with realistic sample store seed
- [x] Built-in report queries (stock value, sales by category)
- [ ] Low-stock / reorder report and view
- [ ] Storefront wired to this database (see clothing-store-gke)
- [ ] Backups (scheduled dumps to object storage)
- [ ] TLS + real secrets management

---

<div align="center">

**Threads & Co. — one store, every channel, one database.** 👕

</div>
