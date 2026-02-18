# SQLModel Best Practices: Complete Implementation Guide

> **Target audience:** Coding agents and developers starting a new SQLModel-based project.  
> **Purpose:** Knowledge seed — read this before writing any SQLModel code.  
> **Last researched:** February 2026

---

## Table of Contents

1. [What is SQLModel?](#what-is-sqlmodel)
2. [Project Setup with uv](#project-setup-with-uv)
3. [Project Structure](#project-structure)
4. [Model Design Patterns](#model-design-patterns)
5. [Database Engine & Session Management](#database-engine--session-management)
6. [Async Setup](#async-setup)
7. [Alembic Migrations](#alembic-migrations)
8. [CRUD Operations](#crud-operations)
9. [FastAPI Integration](#fastapi-integration)
10. [Testing](#testing)
11. [Docker Deployment](#docker-deployment)
12. [Common Pitfalls](#common-pitfalls)
13. [Key Sources](#key-sources)

---

## What is SQLModel?

SQLModel is a Python library for interacting with SQL databases using Python type annotations. It is built on top of **SQLAlchemy** (for DB operations) and **Pydantic** (for data validation), combining both into one unified model class. It was created by the same author as FastAPI and is designed to be its perfect companion.

**Core value proposition:**
- One class that is simultaneously a SQLAlchemy ORM model AND a Pydantic model
- Eliminates duplicate model definitions (no separate "DB model" vs "API schema")
- Full type annotation support with editor autocompletion
- Direct compatibility with FastAPI's dependency injection and `response_model`

**GitHub:** https://github.com/fastapi/sqlmodel  
**Docs:** https://sqlmodel.tiangolo.com

---

## Project Setup with uv

`uv` is a Rust-powered Python package manager that replaces `pip`, `virtualenv`, and `pip-tools`. It is dramatically faster, uses `pyproject.toml` as the single source of truth, and generates a `uv.lock` file for reproducible builds. The FastAPI team has adopted it as their standard tool.

**Install uv:**
```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**Initialize a new project:**
```bash
uv init my-project
cd my-project
```

**Add core dependencies:**
```bash
uv add "fastapi[standard]"
uv add sqlmodel
uv add alembic
uv add psycopg2-binary        # for PostgreSQL (sync)
# OR
uv add asyncpg                # for PostgreSQL (async)
uv add aiosqlite              # for SQLite (async)
```

**Add dev dependencies:**
```bash
uv add --dev pytest pytest-asyncio httpx
uv add --dev ruff mypy
```

**Run commands without activating venv:**
```bash
uv run uvicorn app.main:app --reload
uv run alembic upgrade head
uv run pytest
```

**Resulting `pyproject.toml` structure:**
```toml
[project]
name = "my-project"
version = "0.1.0"
description = "My FastAPI + SQLModel project"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "fastapi[standard]>=0.115.0",
    "sqlmodel>=0.0.22",
    "alembic>=1.13.0",
    "asyncpg>=0.29.0",
]

[dependency-groups]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "httpx>=0.27.0",
    "ruff>=0.6.0",
]

[tool.ruff]
line-length = 88

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

**Key uv commands cheatsheet:**

| Action | Command |
|---|---|
| Add dependency | `uv add <package>` |
| Remove dependency | `uv remove <package>` |
| Install from lock | `uv sync` |
| Run a command | `uv run <cmd>` |
| Update all deps | `uv lock --upgrade` |
| Export requirements.txt | `uv export --format requirements-txt > requirements.txt` |

**Source:** https://docs.astral.sh/uv/guides/integration/fastapi/

---

## Project Structure

Use this layout as the canonical structure for a FastAPI + SQLModel project:

```
my-project/
├── pyproject.toml
├── uv.lock
├── .python-version
├── alembic.ini
├── alembic/
│   ├── versions/
│   ├── env.py
│   ├── script.py.mako
│   └── README
├── app/
│   ├── __init__.py
│   ├── main.py            # FastAPI app, lifespan, router includes
│   ├── config.py          # Settings via pydantic-settings
│   ├── database.py        # Engine, session factory, get_session dep
│   ├── models/
│   │   ├── __init__.py    # Re-export all models (CRITICAL for Alembic)
│   │   ├── hero.py
│   │   └── team.py
│   └── routers/
│       ├── __init__.py
│       ├── heroes.py
│       └── teams.py
└── tests/
    ├── conftest.py
    └── test_heroes.py
```

**Rules:**
- All models must be importable from `app/models/__init__.py` so Alembic can discover them
- Keep engine/session creation in `database.py`, not in `main.py`
- Use routers to organize endpoints by resource

---

## Model Design Patterns

### The Multiple-Model Pattern (REQUIRED for Production)

Never use a single table model for all purposes. Use this inheritance hierarchy:

```python
from typing import Optional
from sqlmodel import Field, SQLModel

# 1. Base — shared fields, no table, no id
class HeroBase(SQLModel):
    name: str = Field(index=True)
    age: Optional[int] = Field(default=None, index=True)

# 2. Table model — DB representation, has primary key
class Hero(HeroBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    secret_name: str  # sensitive field, NOT in base

# 3. Create schema — what clients POST (no id, no secret fields exposed)
class HeroCreate(HeroBase):
    secret_name: str  # required on creation but not returned

# 4. Public schema — what clients receive (no secret fields)
class HeroPublic(HeroBase):
    id: int

# 5. Update schema — PATCH payload, all optional
class HeroUpdate(SQLModel):
    name: Optional[str] = None
    age: Optional[int] = None
    secret_name: Optional[str] = None
```

**Why this matters:**
- `table=True` → SQLAlchemy table model
- No `table=True` → Pure Pydantic model (data model / schema)
- Separating `HeroCreate` from `Hero` prevents clients from setting the `id`
- Separating `HeroPublic` from `Hero` prevents leaking sensitive fields like `secret_name`
- `HeroUpdate` with all-optional fields enables proper PATCH semantics

**Source:** https://sqlmodel.tiangolo.com/tutorial/fastapi/multiple-models/

### Field Configuration

```python
from sqlmodel import Field, SQLModel
from typing import Optional
from datetime import datetime

class Item(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    
    # Indexed columns for fast lookups
    name: str = Field(index=True)
    
    # Unique constraint
    slug: str = Field(unique=True, index=True)
    
    # Nullable foreign key
    team_id: Optional[int] = Field(default=None, foreign_key="team.id")
    
    # Column with default
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Column alias (DB column name differs from Python attribute)
    display_name: str = Field(sa_column_kwargs={"name": "display_name_col"})
```

### Relationships

```python
from typing import Optional, List
from sqlmodel import Field, Relationship, SQLModel

class Team(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    heroes: List["Hero"] = Relationship(back_populates="team")

class Hero(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    team_id: Optional[int] = Field(default=None, foreign_key="team.id")
    team: Optional[Team] = Relationship(back_populates="heroes")
```

> ⚠️ **Lazy loading gotcha:** Accessing a relationship attribute outside a session context raises a `DetachedInstanceError`. Always load relationships within the session scope or use `selectinload`/`joinedload` eagerly.

---

## Database Engine & Session Management

### Engine (Sync)

```python
# app/database.py
from sqlmodel import create_engine, Session
from typing import Generator
from app.config import settings

# One engine per application — never recreate per request
engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.DB_ECHO,        # set True in dev, False in prod
    pool_pre_ping=True,            # verify connections before use
    pool_size=10,                  # number of persistent connections
    max_overflow=20,               # extra connections under load
    # For SQLite only:
    # connect_args={"check_same_thread": False}
)

def get_session() -> Generator[Session, None, None]:
    """FastAPI dependency — yields one session per request."""
    with Session(engine) as session:
        yield session
```

### Engine (Async)

```python
# app/database.py  (async version)
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlmodel.ext.asyncio.session import AsyncSession
from collections.abc import AsyncGenerator
from app.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,        # must use async scheme: postgresql+asyncpg://...
    echo=settings.DB_ECHO,
    pool_pre_ping=True,
    pool_size=10,
)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,       # CRITICAL: prevents DetachedInstanceError after commit
)

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI async dependency."""
    async with async_session_factory() as session:
        yield session
```

**Critical rules:**
- Create **one engine** at startup; never create it per request
- Use **one session per request** via dependency injection
- Never share a session across requests
- Set `expire_on_commit=False` in async to avoid re-querying after commit
- Use `pool_pre_ping=True` in production to handle dropped connections

**Source:** https://sqlmodel.tiangolo.com/tutorial/fastapi/session-with-dependency/

---

## Async Setup

For production workloads, async is strongly recommended. The full async stack:

| Layer | Package |
|---|---|
| FastAPI | `fastapi[standard]` |
| SQLModel async session | `sqlmodel` (includes `sqlmodel.ext.asyncio`) |
| Async engine | `sqlalchemy[asyncio]` |
| PostgreSQL async driver | `asyncpg` |
| SQLite async driver | `aiosqlite` |

**Async URL format:**
```
# PostgreSQL
postgresql+asyncpg://user:password@localhost:5432/dbname

# SQLite (dev only)
sqlite+aiosqlite:///./database.db
```

**Complete async session dependency:**

```python
from sqlmodel.ext.asyncio.session import AsyncSession   # use THIS, not SQLAlchemy's
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from collections.abc import AsyncGenerator

engine = create_async_engine(DATABASE_URL, pool_pre_ping=True)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,          # must be sqlmodel's AsyncSession
    expire_on_commit=False,
)

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session
```

**Async CRUD example:**

```python
from sqlmodel import select

async def get_hero(hero_id: int, session: AsyncSession) -> Hero | None:
    return await session.get(Hero, hero_id)

async def get_heroes(session: AsyncSession, offset: int = 0, limit: int = 100):
    result = await session.exec(select(Hero).offset(offset).limit(limit))
    return result.all()

async def create_hero(hero_create: HeroCreate, session: AsyncSession) -> Hero:
    hero = Hero.model_validate(hero_create)
    session.add(hero)
    await session.commit()
    # No refresh needed if expire_on_commit=False
    return hero
```

> ⚠️ **Import warning:** Always import `AsyncSession` from `sqlmodel.ext.asyncio.session`, NOT from `sqlalchemy.ext.asyncio`. The SQLModel version is required for `exec()` to work correctly with type safety.

**Source:** https://agentfactory.panaversity.org/docs/Building-Custom-Agents/relational-databases-sqlmodel/async-session-management

---

## Alembic Migrations

Never use `SQLModel.metadata.create_all()` in production. Use Alembic for all schema changes.

### Initial Setup

```bash
# For sync projects
alembic init alembic

# For async projects (RECOMMENDED)
alembic init -t async alembic
```

### Configure `alembic.ini`

```ini
# Set your database URL (or manage via env var in env.py)
sqlalchemy.url = postgresql+asyncpg://user:pass@localhost/dbname
```

### Configure `alembic/env.py`

```python
import asyncio
from logging.config import fileConfig
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import pool
from sqlmodel import SQLModel
from alembic import context

# CRITICAL: Import ALL your models here so Alembic can detect tables
# If a model is not imported, its table will NOT be in autogenerate output
from app.models import Hero, Team, User  # import everything

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Point Alembic at SQLModel's metadata
target_metadata = SQLModel.metadata

def get_url():
    import os
    return os.getenv("DATABASE_URL", config.get_main_option("sqlalchemy.url"))

def run_migrations_offline() -> None:
    context.configure(
        url=get_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        render_as_batch=True,   # needed for SQLite constraint changes
    )
    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection):
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        render_as_batch=True,
        user_module_prefix="sqlmodel.sql.sqltypes.",  # ensures correct type output
    )
    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations() -> None:
    engine = create_async_engine(get_url(), poolclass=pool.NullPool)
    async with engine.begin() as conn:
        await conn.run_sync(do_run_migrations)
    await engine.dispose()

def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

### Configure `alembic/script.py.mako`

Add this import at the top of the template so generated migrations use SQLModel types:

```mako
import sqlmodel.sql.sqltypes
```

### Naming Conventions (RECOMMENDED)

Add constraint naming conventions to avoid Alembic errors (especially on SQLite):

```python
# app/models/__init__.py
from sqlmodel import SQLModel

NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}
SQLModel.metadata.naming_convention = NAMING_CONVENTION
```

### Migration Workflow

```bash
# Generate a migration from model changes
uv run alembic revision --autogenerate -m "add users table"

# ALWAYS review the generated file in alembic/versions/ before applying!

# Apply migrations
uv run alembic upgrade head

# Rollback one step
uv run alembic downgrade -1

# Show current revision
uv run alembic current

# Show history
uv run alembic history
```

**Source:** https://arunanshub.hashnode.dev/using-sqlmodel-with-alembic  
**Source:** https://testdriven.io/blog/fastapi-sqlmodel/

---

## CRUD Operations

### Using `session.exec()` (preferred over `session.execute()`)

```python
from sqlmodel import select, Session

# READ - all
def get_heroes(session: Session, offset: int = 0, limit: int = 100):
    return session.exec(select(Hero).offset(offset).limit(limit)).all()

# READ - one by id
def get_hero(session: Session, hero_id: int) -> Hero | None:
    return session.get(Hero, hero_id)

# READ - with filter
def get_hero_by_name(session: Session, name: str) -> Hero | None:
    return session.exec(select(Hero).where(Hero.name == name)).first()

# READ - complex filter
def get_adult_heroes(session: Session):
    return session.exec(select(Hero).where(Hero.age >= 18)).all()

# CREATE
def create_hero(session: Session, hero_create: HeroCreate) -> Hero:
    hero = Hero.model_validate(hero_create)   # Pydantic v2 style
    session.add(hero)
    session.commit()
    session.refresh(hero)   # get auto-generated id and defaults
    return hero

# UPDATE (partial PATCH)
def update_hero(session: Session, hero_id: int, hero_update: HeroUpdate) -> Hero:
    hero = session.get(Hero, hero_id)
    if not hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    # exclude_unset=True applies only changed fields
    update_data = hero_update.model_dump(exclude_unset=True)
    hero.sqlmodel_update(update_data)
    session.add(hero)
    session.commit()
    session.refresh(hero)
    return hero

# DELETE
def delete_hero(session: Session, hero_id: int) -> bool:
    hero = session.get(Hero, hero_id)
    if not hero:
        return False
    session.delete(hero)
    session.commit()
    return True
```

**Key methods:**
- `session.exec(select(...))` — preferred SQLModel query method (typed)
- `session.get(Model, pk)` — fast lookup by primary key
- `session.add(obj)` — stage for insert/update
- `session.commit()` — persist changes
- `session.refresh(obj)` — reload from DB (get generated id, defaults)
- `session.delete(obj)` — stage for delete
- `hero_update.model_dump(exclude_unset=True)` — only fields explicitly provided by client
- `hero.sqlmodel_update(data)` — apply partial update dict to instance

---

## FastAPI Integration

### Application Lifespan (Modern Pattern)

Use `lifespan` context manager instead of deprecated `on_event`:

```python
# app/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import engine
from sqlmodel import SQLModel
from app.routers import heroes, teams

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: only for dev/SQLite — use Alembic in production
    # SQLModel.metadata.create_all(engine)
    yield
    # Shutdown cleanup if needed

app = FastAPI(title="My API", lifespan=lifespan)
app.include_router(heroes.router, prefix="/heroes", tags=["heroes"])
app.include_router(teams.router, prefix="/teams", tags=["teams"])
```

### Router with Dependency Injection

```python
# app/routers/heroes.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
from typing import Annotated
from app.database import get_session
from app.models.hero import Hero, HeroCreate, HeroPublic, HeroUpdate

router = APIRouter()

SessionDep = Annotated[Session, Depends(get_session)]

@router.post("/", response_model=HeroPublic, status_code=201)
def create_hero(hero: HeroCreate, session: SessionDep):
    db_hero = Hero.model_validate(hero)
    session.add(db_hero)
    session.commit()
    session.refresh(db_hero)
    return db_hero

@router.get("/", response_model=list[HeroPublic])
def read_heroes(
    session: SessionDep,
    offset: int = 0,
    limit: Annotated[int, Query(le=100)] = 100,
):
    return session.exec(select(Hero).offset(offset).limit(limit)).all()

@router.get("/{hero_id}", response_model=HeroPublic)
def read_hero(hero_id: int, session: SessionDep):
    hero = session.get(Hero, hero_id)
    if not hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    return hero

@router.patch("/{hero_id}", response_model=HeroPublic)
def update_hero(hero_id: int, hero: HeroUpdate, session: SessionDep):
    db_hero = session.get(Hero, hero_id)
    if not db_hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    update_data = hero.model_dump(exclude_unset=True)
    db_hero.sqlmodel_update(update_data)
    session.add(db_hero)
    session.commit()
    session.refresh(db_hero)
    return db_hero

@router.delete("/{hero_id}", status_code=204)
def delete_hero(hero_id: int, session: SessionDep):
    hero = session.get(Hero, hero_id)
    if not hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    session.delete(hero)
    session.commit()
```

### Configuration with pydantic-settings

```python
# app/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./database.db"
    DB_ECHO: bool = False
    
    class Config:
        env_file = ".env"

settings = Settings()
```

**Source:** https://fastapi.tiangolo.com/tutorial/sql-databases/  
**Source:** https://sqlmodel.tiangolo.com/tutorial/fastapi/session-with-dependency/

---

## Testing

### `conftest.py` with test database

```python
# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from sqlmodel import SQLModel, Session, create_engine
from sqlmodel.pool import StaticPool
from app.main import app
from app.database import get_session

@pytest.fixture(name="session")
def session_fixture():
    engine = create_engine(
        "sqlite://",                          # in-memory SQLite
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session

@pytest.fixture(name="client")
def client_fixture(session: Session):
    def get_session_override():
        return session

    app.dependency_overrides[get_session] = get_session_override
    client = TestClient(app)
    yield client
    app.dependency_overrides.clear()
```

### Writing tests

```python
# tests/test_heroes.py
def test_create_hero(client):
    response = client.post("/heroes/", json={"name": "Deadpond", "secret_name": "Dive Wilson"})
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Deadpond"
    assert "id" in data
    assert "secret_name" not in data  # confirm sensitive fields are hidden

def test_read_hero_not_found(client):
    response = client.get("/heroes/999")
    assert response.status_code == 404
```

---

## Docker Deployment

### `Dockerfile` using uv

```dockerfile
FROM python:3.12-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Install dependencies (cached layer)
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-cache

# Copy application
COPY . .

# Run with uvicorn
CMD ["/app/.venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### `docker-compose.yml` for development

```yaml
services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:password@db:5432/mydb
    depends_on:
      db:
        condition: service_healthy
    develop:
      watch:
        - action: sync
          path: ./app
          target: /app/app

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    volumes:
      - pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pg_data:
```

**Source:** https://docs.astral.sh/uv/guides/integration/fastapi/

---

## Common Pitfalls

### 1. Forgetting to import models before Alembic autogenerate

**Problem:** Alembic won't detect tables it hasn't seen.  
**Fix:** In `alembic/env.py`, explicitly import every model class:
```python
from app.models import Hero, Team, User   # import ALL table models
```

### 2. Using raw `AsyncSession` from SQLAlchemy instead of SQLModel's

**Problem:** `session.exec()` doesn't work with SQLAlchemy's `AsyncSession`.  
**Fix:** Always use:
```python
from sqlmodel.ext.asyncio.session import AsyncSession  # ✅ correct
# NOT: from sqlalchemy.ext.asyncio import AsyncSession  # ❌ wrong
```

### 3. `expire_on_commit=True` causing `DetachedInstanceError`

**Problem:** After `await session.commit()`, accessing model attributes raises errors because the session expired them.  
**Fix:** Set `expire_on_commit=False` in `async_sessionmaker`.

### 4. Accessing lazy-loaded relationships outside session

**Problem:** `hero.team` accessed after session closes raises `DetachedInstanceError`.  
**Fix:** Eager-load with SQLAlchemy's `selectinload`:
```python
from sqlalchemy.orm import selectinload
result = await session.exec(select(Hero).options(selectinload(Hero.team)))
```

### 5. Using `create_all()` in production

**Problem:** `SQLModel.metadata.create_all(engine)` doesn't track or manage schema changes.  
**Fix:** Use Alembic for all production schema management. Only use `create_all` in tests.

### 6. Calling `session.execute()` instead of `session.exec()`

**Problem:** `execute()` returns raw SQLAlchemy results that require `.scalars()` chaining.  
**Fix:** Always use `session.exec()` — it's SQLModel's enhanced method with automatic type handling.

### 7. Missing `check_same_thread=False` for SQLite

**Problem:** FastAPI may use multiple threads; SQLite's default rejects cross-thread access.  
**Fix:**
```python
engine = create_engine("sqlite:///db.db", connect_args={"check_same_thread": False})
```

### 8. `HeroUpdate` fields not truly optional

**Problem:** If you use `HeroUpdate(name: str)` instead of `HeroUpdate(name: Optional[str] = None)`, PATCH breaks.  
**Fix:** All fields in update schemas must be `Optional` with `None` default.

---

## Key Sources

| Resource | URL |
|---|---|
| SQLModel Official Docs | https://sqlmodel.tiangolo.com |
| SQLModel GitHub | https://github.com/fastapi/sqlmodel |
| FastAPI SQL Databases Tutorial | https://fastapi.tiangolo.com/tutorial/sql-databases/ |
| SQLModel FastAPI Tutorial | https://sqlmodel.tiangolo.com/tutorial/fastapi/ |
| SQLModel Session with Dependency | https://sqlmodel.tiangolo.com/tutorial/fastapi/session-with-dependency/ |
| uv + FastAPI integration | https://docs.astral.sh/uv/guides/integration/fastapi/ |
| Async SQLModel + Alembic (TestDriven.io) | https://testdriven.io/blog/fastapi-sqlmodel/ |
| Using SQLModel with Alembic | https://arunanshub.hashnode.dev/using-sqlmodel-with-alembic |
| Async Session Management (Agent Factory) | https://agentfactory.panaversity.org/docs/Building-Custom-Agents/relational-databases-sqlmodel/async-session-management |
| FastAPI Best Architecture (uv) | https://deepwiki.com/fastapi-practices/fastapi_best_architecture/12.4-dependency-management-with-uv |
| FastAPI + SQLModel + Alembic Template | https://github.com/jonra1993/fastapi-alembic-sqlmodel-async |
| uv Deep Dive | https://www.saaspegasus.com/guides/uv-deep-dive/ |

---

*This document is a knowledge seed. Start here, then consult the official docs for edge cases.*