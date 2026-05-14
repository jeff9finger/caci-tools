# DevoxxGenie RAG (Retrieval-Augmented Generation) Setup

This guide documents how to enable and configure RAG in DevoxxGenie for semantic code search using ChromaDB and embeddings.

## What is RAG?

Retrieval-Augmented Generation enhances AI responses by:
- Indexing your codebase with embeddings (vector representations)
- Storing vectors in ChromaDB (vector database)
- Performing semantic search to find relevant code
- Including matching code in LLM prompts for better context

## When to Enable RAG

**Good use cases:**
- Large codebases (100K+ lines or 1000+ files)
- Semantic queries: "find code that handles authentication" (concept-based)
- Cross-cutting concerns: "where do we use caching?"
- Architecture exploration: "show me all API endpoints"
- Documentation generation: "summarize how payments work"

**Skip RAG if:**
- Small/medium projects (Agent Mode tools work fine)
- Known file/function names (grep is faster)
- Resource-constrained environment
- Rapid code changes (re-indexing overhead)

## Prerequisites

**Required:**
- Docker installed and running
- Ollama running with nomic-embed-text model
- At least 500MB free RAM for ChromaDB container
- 1-5GB disk space per project (vector database storage)

**Check prerequisites:**
```bash
# Verify Docker
docker --version
# Output: Docker version 24.x.x or higher

# Verify Ollama
curl http://localhost:11434/api/tags | jq '.models[] | select(.name | contains("nomic-embed"))'
# Should show nomic-embed-text model

# Check available disk space
df -h
```

## ChromaDB Docker Setup

### Step 1: Pull ChromaDB Image

```bash
docker pull chromadb/chroma
```

**Expected output:**
```
Using default tag: latest
latest: Pulling from chromadb/chroma
...
Status: Downloaded newer image for chromadb/chroma:latest
```

### Step 2: Run ChromaDB Container

**Option A: Foreground (for testing)**
```bash
docker run -p 8000:8000 chromadb/chroma
```
Press Ctrl+C to stop.

**Option B: Background (for permanent use)**
```bash
docker run -d \
  --name chromadb \
  -p 8000:8000 \
  --restart unless-stopped \
  chromadb/chroma
```

**Container management commands:**
```bash
# Check if running
docker ps | grep chromadb

# Stop container
docker stop chromadb

# Start container
docker start chromadb

# View logs
docker logs chromadb

# Remove container
docker rm -f chromadb
```

### Step 3: Verify ChromaDB is Running

```bash
# Test API endpoint
curl http://localhost:8000/api/v1/heartbeat
# Expected: {"nanosecond heartbeat": <timestamp>}

# Check version
curl http://localhost:8000/api/v1/version
# Expected: {"version": "0.4.x"}
```

## DevoxxGenie RAG Configuration

### Step 1: Configure in IntelliJ

1. Open IntelliJ IDEA
2. Settings (⌘,) → Tools → DevoxxGenie → RAG
3. Configure settings:

**RAG Settings:**
- **Enable feature:** ✓ Check this box
- **Chroma DB port:** `8000` (default)
- **Minimum score:** `0.7`
  - Range: 0.0 (everything) to 1.0 (exact matches only)
  - 0.7 = good balance between recall and precision
  - Lower (0.5-0.6) for broader, fuzzier matches
  - Higher (0.8-0.9) for stricter, more relevant matches
- **Maximum results:** `10`
  - How many code snippets to include in prompt context
  - More results = more context but longer prompts
  - 5-10 is reasonable for most use cases

4. Click "Pull Image" button (or verify it shows "ChromaDB Docker image found")
5. Click "Apply" to save

### Step 2: Verify Required Services

Check status in RAG settings:

**Required RAG Services:**
- ✅ **docker** - Docker is installed
- ✅ **chromadb** - ChromaDB Docker image found
- ✅ **ollama** - Ollama is running
- ✅ **nomic** - Nomic Embed model found

All four must be green before proceeding.

## Indexing Projects

### Step 1: Configure Scan & Copy Project

Settings → Tools → DevoxxGenie → Scan & Copy Project

**Recommended settings:**
- **File extensions to include:** `.java,.kt,.xml,.properties,.yaml,.yml,.json,.sql,.md`
  - Add project-specific extensions as needed
- **Directories to exclude:** `target,build,.git,.idea,node_modules`
  - Exclude build outputs and dependencies
- **Maximum file size:** `500` KB
  - Skip large generated files
- **Include hidden files:** ❌ Unchecked
  - Usually not needed

### Step 2: Index Current Project

1. Open a project in IntelliJ
2. DevoxxGenie panel → Settings icon → "Index Project"
3. Wait for indexing to complete (progress bar shows status)
   - Small project (100 files): ~30 seconds
   - Medium project (1000 files): ~2-5 minutes
   - Large project (10000 files): ~10-30 minutes

**Monitor indexing:**
- Check progress in DevoxxGenie panel
- View logs: Help → Show Log in Finder/Explorer → `idea.log`
- Look for: `[DevoxxGenie] Indexing completed: X files processed`

### Step 3: Verify Indexing

Settings → Tools → DevoxxGenie → RAG → **Indexed projects**

Should show:
- **Collection:** Your project name
- **Indexed Segments:** Number of code chunks stored
- **Actions:** "Re-index" or "Delete" buttons

## Usage

### Semantic Search with /find Command

In DevoxxGenie chat panel:

```
/find authentication logic
```

**How it works:**
1. Converts query to embedding using nomic-embed-text
2. Searches ChromaDB for similar code vectors
3. Returns top N matching code snippets (by minimum score threshold)
4. Displays results with file paths and similarity scores

**Example queries:**
```
/find database connection pooling
/find error handling patterns
/find API endpoint definitions
/find validation logic
/find caching implementation
```

### Automatic Context in Agent Mode

When RAG is enabled and Agent Mode is active:

1. Agent analyzes user request
2. Generates semantic query automatically
3. Retrieves relevant code via RAG
4. Includes code in context before reasoning
5. Produces more accurate, context-aware responses

**No additional commands needed** - RAG augments Agent Mode transparently.

## Configuration Comparison

| Setting | Conservative | Balanced (Recommended) | Aggressive |
|---------|--------------|------------------------|------------|
| Minimum score | 0.8 | 0.7 | 0.5 |
| Maximum results | 5 | 10 | 20 |
| Use case | Precise matches only | Good relevance | Broad exploration |
| Prompt size | Smaller | Medium | Larger |
| Risk | May miss relevant code | Good balance | May include irrelevant code |

## Maintenance

### Re-indexing

**When to re-index:**
- After major refactoring
- After adding/removing many files
- After changing branches significantly
- If search results become stale

**How to re-index:**
1. Settings → Tools → DevoxxGenie → RAG
2. Find project in "Indexed projects" list
3. Click "Re-index" button
4. Wait for completion

### Deleting Index

**When to delete:**
- Project no longer needed
- Freeing up disk space
- Corrupted index (errors during search)

**How to delete:**
1. Settings → Tools → DevoxxGenie → RAG
2. Find project in "Indexed projects" list
3. Click "Delete" button
4. Confirm deletion

### Monitoring Disk Usage

```bash
# Find ChromaDB data directory
docker inspect chromadb | jq '.[0].Mounts'

# Check size of vector database
du -sh ~/Library/Application\ Support/JetBrains/IntelliJIdea2026.1/devoxxgenie/chromadb
```

**Typical sizes:**
- Small project (100 files): ~10-50MB
- Medium project (1000 files): ~100-500MB
- Large project (10000 files): ~1-5GB

## Troubleshooting

### ChromaDB Connection Failed

**Symptom:** "ChromaDB Docker image not found" or connection errors

**Solutions:**
1. Verify container is running: `docker ps | grep chromadb`
2. If not running: `docker start chromadb`
3. Check port 8000 not in use: `lsof -i :8000`
4. Test endpoint: `curl http://localhost:8000/api/v1/heartbeat`
5. Check Docker logs: `docker logs chromadb`

### Nomic Embed Model Missing

**Symptom:** "Nomic Embed model not found" in RAG settings

**Solutions:**
1. Verify Ollama running: `curl http://localhost:11434/api/tags`
2. Pull nomic-embed-text model:
   ```bash
   ollama pull nomic-embed-text
   ```
3. Restart IntelliJ after pulling model

### Indexing Fails or Hangs

**Symptom:** Indexing never completes or shows errors

**Solutions:**
1. Check idea.log for errors: Help → Show Log in Finder/Explorer
2. Verify ChromaDB has disk space: `df -h`
3. Restart ChromaDB container: `docker restart chromadb`
4. Try smaller project first (test with sample project)
5. Reduce maximum file size in "Scan & Copy Project" settings

### Search Returns No Results

**Symptom:** `/find` command returns "Nothing to show"

**Check:**
1. Project is indexed (verify in RAG settings → Indexed projects)
2. Minimum score not too high (try lowering to 0.5)
3. Query is semantic, not exact string match
4. Files matching extensions in "Scan & Copy Project" settings

**Debug search:**
1. Enable debug logs: Settings → DevoxxGenie → Agent Mode → Enable debug logs
2. Run search again
3. Check logs for similarity scores
4. Adjust minimum score threshold

### High Memory Usage

**Symptom:** ChromaDB container using excessive RAM (>1GB)

**Solutions:**
1. Reduce number of indexed projects (delete unused)
2. Limit maximum results in RAG settings
3. Increase Docker memory limits (Docker Desktop → Settings → Resources)
4. Consider batch processing (index one project at a time)

## Performance Considerations

### Embedding Generation

- **Speed:** ~100 files/minute (depends on file size)
- **CPU intensive:** Uses Ollama for embedding generation
- **Batch size:** DevoxxGenie processes files in batches of 10

**Optimization:**
- Close other applications during indexing
- Use faster Ollama models (nomic-embed-text is good balance)
- Index during breaks (not while actively coding)

### Search Latency

- **Vector search:** ~10-50ms (ChromaDB lookup)
- **Embedding query:** ~50-100ms (Ollama)
- **Total:** ~100-200ms for semantic search

**Factors affecting speed:**
- Database size (more vectors = slower)
- Maximum results setting (more results = more retrieval)
- Ollama model (larger models = slower but more accurate)

## Advanced Configuration

### Custom Embedding Model

To use a different embedding model:

1. Pull model in Ollama:
   ```bash
   ollama pull <model-name>
   ```
2. DevoxxGenie currently uses nomic-embed-text (hardcoded)
3. Check plugin documentation for custom model support

### Multiple ChromaDB Instances

Run separate ChromaDB containers for different use cases:

```bash
# Development ChromaDB
docker run -d --name chromadb-dev -p 8000:8000 chromadb/chroma

# Production ChromaDB (different port)
docker run -d --name chromadb-prod -p 8001:8000 chromadb/chroma
```

Configure port in DevoxxGenie settings.

### Remote ChromaDB Server

Deploy ChromaDB on remote server:

```bash
# On server
docker run -d -p 8000:8000 \
  -v /path/to/data:/chroma/chroma \
  chromadb/chroma

# In DevoxxGenie settings
# Change localhost:8000 to server-ip:8000
```

**Security considerations:**
- Use firewall to restrict access
- Consider HTTPS proxy (nginx, Caddy)
- ChromaDB has basic auth support (check docs)

## Summary

**Quick Start Commands:**
```bash
# Setup
docker pull chromadb/chroma
docker run -d --name chromadb -p 8000:8000 --restart unless-stopped chromadb/chroma

# Verify
curl http://localhost:8000/api/v1/heartbeat
```

**IntelliJ Configuration:**
1. Settings → Tools → DevoxxGenie → RAG
2. Enable feature
3. Set minimum score: 0.7
4. Set maximum results: 10
5. Index project: DevoxxGenie panel → Settings → Index Project

**Usage:**
- Semantic search: `/find <query>`
- Automatic in Agent Mode (no commands needed)

**When to Enable:**
- Large codebases (100K+ lines)
- Semantic/concept-based searches
- Cross-cutting concern exploration
- Architecture understanding tasks

**When to Skip:**
- Small/medium projects
- Known file/function locations
- Resource constraints
- Rapid development (frequent changes)

## References

- [DevoxxGenie RAG Documentation](https://genie.devoxx.com/docs/features/rag)
- [ChromaDB Official Docs](https://docs.trychroma.com/)
- [Ollama Embedding Models](https://ollama.com/library)
- [Nomic Embed Text Model](https://ollama.com/library/nomic-embed-text)
- [INTELLIJ_AI_SETUP.md](INTELLIJ_AI_SETUP.md) - DevoxxGenie base setup
