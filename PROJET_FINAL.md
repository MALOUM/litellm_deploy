# 🎯 LiteLLM Bedrock Proxy - Configuration Finale

## ✅ Projet nettoyé et opérationnel

### Modèles configurés (2)
1. **claude-3-7-sonnet** - Chat model avec ARN inference profile
2. **titan-embed-text-v2** - Embedding model 1024 dimensions

### Fichiers essentiels
```
.
├── .dockerignore
├── .env                      # Variables d'environnement (Langfuse, AWS)
├── .gitattributes
├── .gitignore
├── Dockerfile                # Image LiteLLM avec boto3
├── LICENSE                   # MIT License
├── README.md                 # Documentation principale
├── config.yaml               # Configuration LiteLLM (2 modèles)
├── docker-compose.yml        # Orchestration Docker
└── logs/                     # Logs du service
```

### Configuration Langfuse ✅
- Méthode : Callback classique (compatible v2.x)
- Format variables : `os.environ/VARIABLE`
- Réseau : `docker_stetai-network`
- Host : `http://stetai-langfuse:3000`

### Déploiement
```bash
# Démarrer
docker-compose up -d

# Arrêter
docker-compose down

# Logs
docker-compose logs -f litellm

# Redémarrer
docker-compose restart litellm
```

### Tests
```bash
# Health check
curl http://localhost:4002/health

# Liste modèles (2)
curl http://localhost:4002/v1/models \
  -H "Authorization: Bearer sk-1234"

# Test chat
curl -X POST http://localhost:4002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-3-7-sonnet",
    "messages": [{"role": "user", "content": "Hello"}]
  }'

# Test embedding
curl -X POST http://localhost:4002/v1/embeddings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "titan-embed-text-v2",
    "input": "Test embedding"
  }'
```

### Pour production (EC2)
Sur EC2 avec IAM role, modifier `docker-compose.yml` :
- Supprimer : `- ~/.aws:/root/.aws:ro`
- L'IAM role fournit automatiquement les credentials AWS

---

**Projet prêt pour la production ! 🚀**
