@echo off
rem Set the release to load code on demand (interactive) instead of preloading (embedded).
rem set RELEASE_MODE=interactive

rem Set the release to work across nodes.
rem RELEASE_DISTRIBUTION must be "sname" (local), "name" (distributed) or "none".
rem set RELEASE_DISTRIBUTION=name
rem set RELEASE_NODE=embed_ex

set DATABASE_URL="ecto://postgres:postgres@localhost/demo_db"

set MODEL_EMBEDDING="text-embedding-3-small"
set MODEL_TOKENIZER="text-embedding-ada-002"
set MODEL_COMPLETION="gpt-3.5-turbo-0125"
