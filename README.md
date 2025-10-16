# LiteLLM Bedrock Proxy

Un proxy LiteLLM prêt à déployer sur EC2 pour accéder aux modèles AWS Bedrock (région eu-west-1) avec intégration Langfuse pour l'observabilité.

## Table des matières

- [Prérequis](#prérequis)
- [Installation rapide](#installation-rapide)
- [Configuration](#configuration)
- [Modèles disponibles](#modèles-disponibles)
- [Utilisation](#utilisation)
- [Intégration Langfuse](#intégration-langfuse)
- [Paramètres LiteLLM](#paramètres-litellm)
- [Intégrations disponibles](#intégrations-disponibles)
- [Troubleshooting](#troubleshooting)

## Prérequis

### Infrastructure AWS

1. **Instance EC2** avec:
   - Docker et Docker Compose installés
   - Profil IAM attaché avec les permissions Bedrock

2. **Permissions IAM requises** pour le rôle EC2:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels",
        "bedrock:GetFoundationModel"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "eu-west-1"
        }
      }
    }
  ]
}
```

### Logiciels

- Docker >= 20.10
- Docker Compose >= 2.0
- Langfuse déjà déployé et accessible (ou utilisez l'URL Langfuse Cloud)

## Installation rapide

### 1. Cloner le repository

```bash
git clone <your-repo-url>
cd LiteLLMProxy
```

### 2. Configurer les variables d'environnement

```bash
cp .env.example .env
nano .env  # ou vim, code, etc.
```

Remplissez les valeurs requises:

```env
LANGFUSE_PUBLIC_KEY=pk-lf-xxxxxxxx
LANGFUSE_SECRET_KEY=sk-lf-xxxxxxxx
LANGFUSE_HOST=http://localhost:3000
```

### 3. Déployer avec le script automatique

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Ou manuellement:

```bash
# Build l'image
docker-compose build

# Démarrer le service
docker-compose up -d

# Vérifier les logs
docker-compose logs -f litellm
```

### 4. Vérifier le déploiement

```bash
curl http://localhost:4002/health
```

Réponse attendue:
```json
{"status": "healthy"}
```

## Configuration

### Structure des fichiers

```
LiteLLMProxy/
├── Dockerfile                 # Image Docker LiteLLM
├── docker-compose.yml         # Orchestration Docker
├── config.yaml                # Configuration LiteLLM principale
├── .env                       # Variables d'environnement (à créer)
├── .env.example               # Template des variables
├── .gitignore                 # Fichiers à ignorer
├── README.md                  # Cette documentation
└── scripts/
    └── deploy.sh              # Script de déploiement automatique
```

### Configuration principale (config.yaml)

Le fichier `config.yaml` contient:

- **model_list**: Liste des modèles Bedrock configurés
- **litellm_settings**: Paramètres globaux du proxy
- **general_settings**: Sécurité et accès API
- **router_settings**: Stratégies de routing et fallback

### Modifier la configuration

Pour ajouter ou modifier un modèle:

```yaml
model_list:
  - model_name: mon-modele-custom
    litellm_params:
      model: bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0
      aws_region_name: eu-west-1
      max_tokens: 4096
      temperature: 0.7
    model_info:
      mode: chat
      supports_function_calling: true
```

Après modification, redémarrer:

```bash
docker-compose restart litellm
```

## Modèles disponibles

### Anthropic Claude (recommandé)

| Nom du modèle | ID Bedrock | Context | Use Case |
|---------------|------------|---------|----------|
| `claude-3-5-sonnet` | `anthropic.claude-3-5-sonnet-20241022-v2:0` | 200K | Meilleur équilibre performance/coût |
| `claude-3-opus` | `anthropic.claude-3-opus-20240229-v1:0` | 200K | Tâches complexes |
| `claude-3-sonnet` | `anthropic.claude-3-sonnet-20240229-v1:0` | 200K | Tâches courantes |
| `claude-3-haiku` | `anthropic.claude-3-haiku-20240307-v1:0` | 200K | Rapide et économique |

### Amazon Titan

| Nom du modèle | ID Bedrock | Context | Use Case |
|---------------|------------|---------|----------|
| `titan-text-express` | `amazon.titan-text-express-v1` | 8K | Génération de texte |
| `titan-text-lite` | `amazon.titan-text-lite-v1` | 4K | Texte simple, rapide |
| `titan-embed-text` | `amazon.titan-embed-text-v1` | - | Embeddings |
| `titan-embed-text-v2` | `amazon.titan-embed-text-v2:0` | - | Embeddings v2 |

### Meta Llama

| Nom du modèle | ID Bedrock | Context | Use Case |
|---------------|------------|---------|----------|
| `llama3-1-70b` | `meta.llama3-1-70b-instruct-v1:0` | 128K | Chat, instruction |
| `llama3-1-8b` | `meta.llama3-1-8b-instruct-v1:0` | 128K | Chat léger |

### Mistral AI

| Nom du modèle | ID Bedrock | Context | Use Case |
|---------------|------------|---------|----------|
| `mistral-large` | `mistral.mistral-large-2402-v1:0` | 32K | Tâches complexes |
| `mixtral-8x7b` | `mistral.mixtral-8x7b-instruct-v0:1` | 32K | MoE performant |
| `mistral-7b` | `mistral.mistral-7b-instruct-v0:2` | 8K | Léger et efficace |

## Utilisation

### API OpenAI-Compatible

LiteLLM expose une API compatible OpenAI:

```bash
curl http://localhost:4002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-3-5-sonnet",
    "messages": [
      {"role": "user", "content": "Bonjour, comment vas-tu?"}
    ],
    "max_tokens": 1024,
    "temperature": 0.7
  }'
```

### Avec Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-1234",
    base_url="http://localhost:4002/v1"
)

response = client.chat.completions.create(
    model="claude-3-5-sonnet",
    messages=[
        {"role": "user", "content": "Explique-moi l'IA en 3 phrases"}
    ],
    max_tokens=500,
    temperature=0.7
)

print(response.choices[0].message.content)
```

### Streaming

```python
response = client.chat.completions.create(
    model="claude-3-5-sonnet",
    messages=[{"role": "user", "content": "Écris une courte histoire"}],
    stream=True
)

for chunk in response:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

### Embeddings

```python
response = client.embeddings.create(
    model="titan-embed-text-v2",
    input="Texte à vectoriser"
)

embedding = response.data[0].embedding
print(f"Dimension: {len(embedding)}")
```

### Function Calling (Claude)

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Obtenir la météo d'une ville",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "Nom de la ville"}
                },
                "required": ["city"]
            }
        }
    }
]

response = client.chat.completions.create(
    model="claude-3-5-sonnet",
    messages=[{"role": "user", "content": "Quelle est la météo à Paris?"}],
    tools=tools,
    tool_choice="auto"
)

if response.choices[0].message.tool_calls:
    print("Function appelée:", response.choices[0].message.tool_calls[0].function.name)
```

### Avec LangChain

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="claude-3-5-sonnet",
    openai_api_key="sk-1234",
    openai_api_base="http://localhost:4002/v1",
    temperature=0.7
)

response = llm.invoke("Bonjour!")
print(response.content)
```

## Intégration Langfuse

### Configuration

Langfuse est configuré pour tracer automatiquement tous les appels:

```yaml
# Dans config.yaml
litellm_settings:
  success_callback: ["langfuse"]
  failure_callback: ["langfuse"]
```

Variables d'environnement requises:
```env
LANGFUSE_PUBLIC_KEY=pk-lf-xxxxxxxx
LANGFUSE_SECRET_KEY=sk-lf-xxxxxxxx
LANGFUSE_HOST=http://votre-langfuse:3000
```

### Traces automatiques

Chaque requête génère automatiquement:
- **Latence**: Temps de réponse
- **Tokens**: Input/output tokens comptabilisés
- **Coût**: Calcul automatique du coût
- **Métadonnées**: Modèle, région, paramètres
- **Erreurs**: Stack traces en cas d'échec

### Accéder aux traces

1. Ouvrez Langfuse: `http://votre-langfuse:3000`
2. Naviguez vers **Traces**
3. Filtrez par modèle, utilisateur, ou tags

### Tags personnalisés

```python
response = client.chat.completions.create(
    model="claude-3-5-sonnet",
    messages=[{"role": "user", "content": "Hello"}],
    metadata={
        "user_id": "user-123",
        "session_id": "session-456",
        "environment": "production"
    }
)
```

## Paramètres LiteLLM

### Paramètres de requête

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `model` | string | Nom du modèle à utiliser | Required |
| `messages` | array | Liste des messages | Required |
| `max_tokens` | integer | Nombre max de tokens générés | Model default |
| `temperature` | float | Créativité (0-1) | 1.0 |
| `top_p` | float | Nucleus sampling (0-1) | 1.0 |
| `top_k` | integer | Top-K sampling | - |
| `stream` | boolean | Streaming de la réponse | false |
| `stop` | array/string | Séquences d'arrêt | null |
| `presence_penalty` | float | Pénalité de présence (-2 à 2) | 0 |
| `frequency_penalty` | float | Pénalité de fréquence (-2 à 2) | 0 |
| `n` | integer | Nombre de complétions | 1 |
| `user` | string | ID utilisateur | null |
| `metadata` | object | Métadonnées personnalisées | {} |

### Paramètres globaux (config.yaml)

#### Retry & Timeout

```yaml
litellm_settings:
  num_retries: 3                    # Nombre de tentatives
  request_timeout: 600              # Timeout en secondes
  retry_after: 10                   # Délai entre retries
  max_parallel_requests: 100        # Requêtes parallèles max
```

#### Rate Limiting

```yaml
litellm_settings:
  rpm: 1000                         # Requests per minute
  tpm: 100000                       # Tokens per minute
```

#### Fallbacks

```yaml
litellm_settings:
  fallbacks: 
    - model: claude-3-5-sonnet
      fallback: claude-3-haiku      # Fallback si erreur
    - model: claude-3-opus
      fallback: claude-3-sonnet
  
  context_window_fallbacks:
    - model: claude-3-5-sonnet
      fallback: claude-3-opus       # Fallback si contexte trop long
```

#### Caching

```yaml
router_settings:
  redis_host: localhost
  redis_port: 6379
  redis_password: your-password
  cache_responses: true
  cache_kwargs:
    ttl: 3600                       # Cache TTL en secondes
```

### Routing Strategies

```yaml
router_settings:
  routing_strategy: "simple-shuffle"  # Options disponibles
```

Stratégies disponibles:
- **simple-shuffle**: Round-robin aléatoire
- **least-busy**: Route vers le modèle le moins occupé
- **usage-based-routing**: Route basé sur l'utilisation
- **latency-based-routing**: Route vers le plus rapide

### Logging

```yaml
litellm_settings:
  set_verbose: true                 # Logs détaillés
  json_logs: true                   # Format JSON
  log_raw_request_response: false   # Log requêtes brutes (attention à la taille!)
```

## Intégrations disponibles

LiteLLM supporte de nombreuses intégrations pour l'observabilité et le monitoring:

### Observabilité

| Intégration | Type | Configuration |
|-------------|------|---------------|
| **Langfuse** | Traces complètes | Via `success_callback: ["langfuse"]` |
| **Weights & Biases** | ML Ops | `success_callback: ["wandb"]` |
| **Lunary** | LLM Ops | `success_callback: ["lunary"]` |
| **Helicone** | Monitoring | `success_callback: ["helicone"]` |
| **Traceloop** | OpenTelemetry | `success_callback: ["traceloop"]` |
| **Promptlayer** | Prompt management | `success_callback: ["promptlayer"]` |

### Exemple: Ajouter Weights & Biases

```yaml
# config.yaml
litellm_settings:
  success_callback: ["langfuse", "wandb"]

# .env
WANDB_API_KEY=your-wandb-key
WANDB_PROJECT=litellm-bedrock
```

### Bases de données

Pour la persistance (logs, cache, analytics):

```yaml
general_settings:
  database_url: "postgresql://user:pass@host:5432/litellm"
```

Bases supportées:
- PostgreSQL (recommandé)
- MySQL
- SQLite

### Alertes et monitoring

```yaml
litellm_settings:
  alerting: ["slack", "email"]
  alerting_threshold: 5             # Alertes après 5 erreurs

# .env
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
ALERT_EMAIL=admin@example.com
```

### Authentification avancée

```yaml
general_settings:
  master_key: sk-1234               # Clé principale
  
  # Support de multiples clés
  api_keys:
    - key: sk-team-a
      spend_limit: 100              # Limite en USD
      models: ["claude-3-5-sonnet", "claude-3-haiku"]
    
    - key: sk-team-b
      spend_limit: 50
      models: ["titan-text-express"]
```

### Webhooks

```yaml
litellm_settings:
  success_callback: ["webhook"]
  
# .env
WEBHOOK_URL=https://your-api.com/webhook
WEBHOOK_HEADERS='{"Authorization": "Bearer token"}'
```

## Troubleshooting

### Le service ne démarre pas

```bash
# Vérifier les logs
docker-compose logs litellm

# Vérifier la configuration
docker-compose config

# Rebuild complet
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Erreur: "Could not access Bedrock"

**Cause**: Permissions IAM insuffisantes

**Solution**:
1. Vérifier que le rôle IAM est attaché à l'EC2
2. Tester les permissions AWS:

```bash
aws bedrock list-foundation-models --region eu-west-1
```

3. Vérifier les logs:

```bash
docker-compose logs litellm | grep -i bedrock
```

### Erreur: "Region not supported"

**Cause**: Bedrock non disponible dans la région

**Solution**: Vérifier que vous utilisez `eu-west-1`:

```bash
curl http://localhost:4002/model/info
```

### Langfuse ne reçoit pas les traces

**Vérifications**:

1. Variables d'environnement:
```bash
docker-compose exec litellm env | grep LANGFUSE
```

2. Connexion réseau:
```bash
docker-compose exec litellm curl -v $LANGFUSE_HOST/api/public/health
```

3. Clés API valides:
```bash
# Tester dans Langfuse UI: Settings > API Keys
```

### Latence élevée

**Optimisations**:

1. Activer le cache Redis:
```yaml
router_settings:
  redis_host: localhost
  cache_responses: true
```

2. Augmenter les workers:
```dockerfile
CMD ["litellm", "--config", "/app/config.yaml", "--port", "4002", "--num_workers", "8"]
```

3. Utiliser les modèles plus rapides:
- `claude-3-haiku` au lieu de `claude-3-opus`
- `titan-text-lite` au lieu de `titan-text-express`

### Rate Limiting

Si vous dépassez les limites Bedrock:

```yaml
litellm_settings:
  rpm: 500                          # Réduire les requêtes/minute
  request_timeout: 900              # Augmenter le timeout
  
  fallbacks:
    - model: claude-3-5-sonnet
      fallback: claude-3-haiku      # Fallback automatique
```

### Debug mode

Activer le mode debug complet:

```yaml
litellm_settings:
  set_verbose: true
  debug: true
  log_raw_request_response: true
```

```bash
# Redémarrer et suivre les logs
docker-compose restart litellm
docker-compose logs -f litellm
```

### Vérifier la santé du service

```bash
# Health check
curl http://localhost:4002/health

# Modèles disponibles
curl http://localhost:4002/models

# Métriques (si activées)
curl http://localhost:4002/metrics
```

## Support et ressources

- [Documentation LiteLLM](https://docs.litellm.ai/)
- [Documentation AWS Bedrock](https://docs.aws.amazon.com/bedrock/)
- [Documentation Langfuse](https://langfuse.com/docs)
- [GitHub LiteLLM](https://github.com/BerriAI/litellm)

## License

Ce projet est fourni tel quel à des fins éducatives et de déploiement.

