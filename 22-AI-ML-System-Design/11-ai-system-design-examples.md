# AI System Design Examples

```mermaid
graph TD
    subgraph A[Chatbot System]
        A1[User] --> A2[API Gateway]
        A2 --> A3[Session Manager]
        A3 --> A4[LLM Router]
        A4 --> A5[Safety Layer]
        A5 --> A6[Context Manager]
        A6 --> A7[Response Generator]
    end
    
    subgraph B[RAG Pipeline]
        B1[Query] --> B2[Query Processor]
        B2 --> B3[Retriever]
        B3 --> B4[Reranker]
        B4 --> B5[Context Builder]
        B5 --> B6[Generator]
    end
    
    subgraph C[Code Assistant]
        C1[Code Context] --> C2[Language Detector]
        C2 --> C3[AST Parser]
        C3 --> C4[Context Builder]
        C4 --> C5[Code Generator]
        C5 --> C6[Syntax Validator]
    end
    
    subgraph D[Recommendation System]
        D1[User] --> D2[Feature Pipeline]
        D2 --> D3[Candidate Generator]
        D3 --> D4[Ranking Model]
        D4 --> D5[Policy Layer]
        D5 --> D6[Serving]
    end
    
    subgraph E[Real-Time Moderation]
        E1[User Content] --> E2[Queue]
        E2 --> E3[Classification]
        E3 --> E4[Policy Engine]
        E4 --> E5[Action Enforcer]
    end
```

## 1. Chatbot System Design

### Requirements

```python
CHATBOT_REQUIREMENTS = {
    "functional": [
        "Handle 100K+ concurrent users",
        "Response latency < 500ms",
        "Maintain conversation context",
        "Support multiple LLM providers",
        "Safety content filtering",
        "Conversation history retrieval"
    ],
    "non_functional": [
        "99.9% uptime",
        "P99 latency < 2s",
        "Cost < $0.01 per conversation",
        "GDPR compliant data handling",
        "Horizontally scalable"
    ]
}
```

### Architecture Design

```python
class ChatbotArchitecture:
    def __init__(self):
        self.components = {
            "api_gateway": {
                "purpose": "Request routing, rate limiting, auth",
                "technology": "Kong / AWS API Gateway",
                "scaling": "Horizontal auto-scaling per user"
            },
            "session_manager": {
                "purpose": "Track conversation state",
                "technology": "Redis (in-memory)", 
                "data": "Session ID, user ID, context tokens"
            },
            "llm_router": {
                "purpose": "Route to appropriate model based on intent/complexity",
                "technology": "Custom router + model registry",
                "strategy": "Simple queries -> small model, complex -> large model"
            },
            "context_manager": {
                "purpose": "Manage conversation history within window",
                "technology": "Sliding window + summarization",
                "max_tokens": "4096 for fast model, 32000 for complex"
            },
            "safety_layer": {
                "purpose": "Filter toxic/unsafe content",
                "technology": "Classifier + rule-based filters",
                "latency": "<50ms added latency"
            }
        }
    
    def handle_message(self, user_id, message):
        session = self.get_session(user_id)
        context = self.context_manager.build(session.history, message)
        
        if self.safety_layer.check_input(message):
            return {"error": "Content blocked"}
        
        model = self.llm_router.select_model(message, context)
        
        response = model.generate(context)
        
        safe_response = self.safety_layer.filter_output(response)
        
        session.history.append((message, safe_response))
        
        return {"response": safe_response, "session_id": session.id}
    
    def get_session(self, user_id):
        return SessionManager.get_or_create(user_id)
```

### Scaling Strategy

```python
class ChatbotScaler:
    def __init__(self):
        self.scaling_rules = {
            "api_servers": {
                "metric": "requests_per_second",
                "threshold": 10000,
                "action": "add 2 pods"
            },
            "llm_instances": {
                "metric": "queue_depth",
                "threshold": 100,
                "action": "add GPU instance"
            },
            "redis_cluster": {
                "metric": "memory_usage",
                "threshold": "70%",
                "action": "add shard"
            }
        }
    
    def cost_per_conversation(self):
        return {
            "llm_api": 0.002,
            "infrastructure": 0.001,
            "storage": 0.0001,
            "monitoring": 0.0001,
            "total": 0.0032
        }

class LoadBalancer:
    def route_request(self, request):
        if request["user_id"] in self.active_sessions:
            return self.active_sessions[request["user_id"]]
        
        server = self.least_loaded_server()
        self.active_sessions[request["user_id"]] = server
        return server
```

## 2. RAG Pipeline Design

### System Architecture

```python
class RAGSystemDesign:
    def __init__(self):
        self.components = {
            "data_pipeline": {
                "ingestion": "Document parser + chunker",
                "embedding": "text-embedding-3-large (3072 dims)",
                "vector_db": "Pinecone pod index",
                "refresh": "CDC from source, daily full refresh"
            },
            "query_pipeline": {
                "input": "User query",
                "preprocessing": "Query rewriting + expansion",
                "retrieval": "Hybrid search (dense + sparse)",
                "reranking": "Cross-encoder reranker",
                "generation": "LLM with context window"
            },
            "storage": {
                "vector_index": "HNSW with IVF fallback",
                "metadata": "PostgreSQL",
                "cache": "Redis, 1 hour TTL"
            }
        }

class QueryPipeline:
    def process(self, query):
        rewritten_query = self.query_rewriter.rewrite(query)
        
        vector_results = self.vector_search(rewritten_query, k=50)
        keyword_results = self.keyword_search(rewritten_query, k=50)
        
        candidates = self.hybrid_fusion(vector_results, keyword_results)
        
        reranked = self.reranker.rerank(query, candidates, k=10)
        
        context = self.build_context(reranked)
        
        response = self.generator.generate(query, context)
        
        return {
            "response": response,
            "sources": [r["source"] for r in reranked],
            "confidence": self.compute_confidence(reranked, response)
        }
    
    def build_context(self, documents, max_tokens=3000):
        context = []
        tokens = 0
        
        for doc in documents:
            doc_tokens = len(doc["content"].split())
            if tokens + doc_tokens > max_tokens:
                break
            context.append(doc["content"])
            tokens += doc_tokens
        
        return "\n\n".join(context)
```

### Performance Budget

```python
class RAGPerformanceBudget:
    def __init__(self):
        self.budget = {
            "query_rewrite": {"max_ms": 100, "model": "gpt-3.5-turbo"},
            "embedding": {"max_ms": 50, "model": "text-embedding-3-small"},
            "vector_search": {"max_ms": 100, "top_k": 100},
            "keyword_search": {"max_ms": 50, "top_k": 100},
            "reranking": {"max_ms": 200, "top_k": 10},
            "generation": {"max_ms": 1500, "model": "gpt-4"},
            "total_budget_ms": 2000
        }

    def estimate_p99_latency(self):
        return sum(self.budget[c]["max_ms"] for c in self.budget if c != "total_budget_ms")
```

## 3. Code Assistant System Design

### System Components

```python
class CodeAssistantDesign:
    def __init__(self):
        self.components = {
            "language_service": [
                "Language detection",
                "AST parsing",
                "Syntax validation",
                "Import resolution"
            ],
            "context_service": [
                "Current file context",
                "Open tabs",
                "Recent edits",
                "Cursor position"
            ],
            "generation_service": [
                "Prefix/suffix analysis",
                "Completion candidate generation",
                "Ranking and filtering",
                "Format adaptation"
            ],
            "infrastructure": [
                "GPU cluster for inference",
                "Model cache for popular snippets",
                "Telemetry pipeline"
            ]
        }
```

### Architecture Implementation

```python
class CodeAssistant:
    def __init__(self, model, language_service):
        self.model = model
        self.language_service = language_service
    
    def get_completions(self, context):
        language = self.language_service.detect_language(context["filename"])
        
        parsed = self.language_service.parse(context["content"])
        
        prefix = parsed["prefix"]
        suffix = parsed["suffix"]
        
        cursor_context = self.build_cursor_context(
            prefix, suffix, context["cursor_position"]
        )
        
        cached = self.check_cache(cursor_context)
        if cached:
            return cached
        
        candidates = self.model.generate(
            prompt=self.build_prompt(context, language),
            num_candidates=5,
            max_tokens=128
        )
        
        valid_candidates = []
        for candidate in candidates:
            if self.language_service.validate_syntax(
                prefix + candidate + suffix, language
            ):
                valid_candidates.append(candidate)
        
        ranked = self.rank_candidates(valid_candidates, context)
        
        self.cache_result(cursor_context, ranked)
        
        return ranked[:3]
    
    def build_prompt(self, context, language):
        return f"{context['prefix']}[[CURSOR]]{context['suffix']}\nLanguage: {language}\nComplete the code:"
    
    def check_cache(self, context_hash):
        pass
    
    def rank_candidates(self, candidates, context):
        return sorted(candidates, key=lambda c: self.score_candidate(c, context))
    
    def score_candidate(self, candidate, context):
        return len(candidate)
```

### Latency Optimization

```python
class LatencyOptimizer:
    def __init__(self):
        self.strategies = {
            "anticipatory_loading": {
                "description": "Pre-load model for likely languages",
                "impact": "Saves 200-500ms on first completion"
            },
            "caching": {
                "description": "Cache common patterns",
                "impact": "Cache hit in 30% of cases, instant response"
            },
            "speculation": {
                "description": "Generate while user types",
                "impact": "50ms perceived latency"
            },
            "model_distillation": {
                "description": "Smaller model for simple completions",
                "impact": "2x speed for 80% of traffic"
            }
        }
    
    def optimize(self, request):
        optimized_pipeline = []
        
        if self.is_simple_completion(request):
            optimized_pipeline.append("use_distilled_model")
        
        optimized_pipeline.append("check_cache")
        optimized_pipeline.append("run_inference")
        
        return optimized_pipeline
```

## 4. Recommendation System with ML

### Architecture

```python
class RecommendationSystem:
    def __init__(self):
        self.layers = {
            "candidate_generation": {
                "algorithms": [
                    "Collaborative filtering (ALS)",
                    "Content-based filtering",
                    "Popularity baseline",
                    "Real-time trending"
                ],
                "candidates_per_source": 500,
                "technology": "Spark for batch, Redis for real-time"
            },
            "ranking": {
                "model": "Deep neural network (DNN)",
                "features": [
                    "User features (history, demographics)",
                    "Item features (category, popularity)",
                    "Context features (time, device)",
                    "Cross features (user-item interaction)"
                ],
                "model_architecture": "3-layer MLP with embedding layers",
                "serving": "TensorFlow Serving / Triton"
            },
            "post_ranking": {
                "re_ranking": ["Diversity", "Freshness", "Business rules"],
                "filtering": ["Blocked items", "Age-restricted", "Policy rules"],
                "blending": ["Personalized", "Explore", "Sponsored"]
            }
        }
```

### Feature Pipeline

```python
class FeaturePipeline:
    def __init__(self):
        self.feature_store = "Feast"
        self.online_store = "Redis"
        self.offline_store = "S3 + Parquet"
    
    def compute_features(self, user_id, item_candidates):
        user_features = self.feature_store.get_online_features(
            entity_rows=[{"user_id": user_id}],
            features=["user:age", "user:recent_categories", "user:engagement_score"]
        )
        
        item_features = self.feature_store.get_online_features(
            entity_rows=[{"item_id": i} for i in item_candidates],
            features=["item:category", "item:popularity", "item:avg_rating"]
        )
        
        return self._cross_features(user_features, item_features)
    
    def _cross_features(self, user, items):
        return [
            {
                "user_age": user["age"],
                "item_category_score": self._category_affinity(
                    user["recent_categories"], item["category"]
                ),
                "recency_score": self._time_decay(item["age_days"])
            }
            for item in items
        ]
    
    def _category_affinity(self, user_categories, item_category):
        return 1.0 if item_category in user_categories else 0.1
    
    def _time_decay(self, age_days):
        import math
        return math.exp(-age_days / 30.0)
```

### Training Pipeline

```python
class RecommendationTrainingPipeline:
    def __init__(self):
        self.training_config = {
            "batch_size": 1024,
            "epochs": 10,
            "learning_rate": 0.001,
            "optimizer": "Adam",
            "loss": "Cross-entropy with negative sampling",
            "negative_samples": 100,
            "validation_split": 0.1
        }
    
    def train(self, start_date, end_date):
        training_data = self.load_training_data(start_date, end_date)
        
        model = self.build_model()
        model.fit(
            training_data["features"],
            training_data["labels"],
            validation_data=training_data["validation"],
            **self.training_config
        )
        
        eval_results = self.evaluate(model, training_data["test"])
        
        if eval_results["auc"] > 0.75:
            self.model_registry.register(model, eval_results)
            return True
        
        return False
    
    def build_model(self):
        import torch.nn as nn
        
        class RecommendationModel(nn.Module):
            def __init__(self, num_features=64, hidden_sizes=[256, 128, 64]):
                super().__init__()
                layers = []
                prev = num_features
                for hidden in hidden_sizes:
                    layers.append(nn.Linear(prev, hidden))
                    layers.append(nn.ReLU())
                    layers.append(nn.BatchNorm1d(hidden))
                    layers.append(nn.Dropout(0.2))
                    prev = hidden
                layers.append(nn.Linear(prev, 1))
                layers.append(nn.Sigmoid())
                
                self.network = nn.Sequential(*layers)
            
            def forward(self, x):
                return self.network(x)
        
        return RecommendationModel()
```

## 5. Real-Time Moderation System

### Architecture

```python
class ModerationSystem:
    def __init__(self):
        self.pipeline_stages = {
            "ingestion": {
                "input": "User-generated content (text, image, video)",
                "queue": "Kafka topic per content type",
                "stream_processor": "Apache Flink / Kafka Streams",
                "throughput": "100K messages/second"
            },
            "classification": {
                "text_model": "RoBERTa-based multi-label classifier",
                "image_model": "Vision transformer (ViT)",
                "ensemble": "Weighted voting of 3 models",
                "threshold": "0.7 for flagging, 0.95 for auto-removal",
                "latency_budget": "100ms"
            },
            "policy_engine": {
                "rules": [
                    "Category-specific thresholds",
                    "User history weighting",
                    "Regional regulation adaptation",
                    "Appeal handling routing"
                ],
                "action_levels": ["Allow", "Flag", "Review", "Block"],
                "caching": "Frequent violator cache"
            },
            "enforcement": {
                "auto_actions": [
                    "Block content",
                    "Shadow ban user",
                    "Limit distribution",
                    "Notify moderator"
                ],
                "throttling": "Rapid-fire posting detection",
                "feedback_loop": "Moderator corrections -> retraining"
            }
        }
```

### Implementation

```python
import asyncio
from typing import Dict, Any

class ContentModerator:
    def __init__(self):
        self.text_classifier = self._load_text_classifier()
        self.image_classifier = self._load_image_classifier()
        self.policy_engine = PolicyEngine()
        self.action_enforcer = ActionEnforcer()
    
    async def moderate(self, content: Dict[str, Any]) -> Dict[str, Any]:
        tasks = []
        
        if "text" in content:
            tasks.append(self._classify_text(content["text"]))
        if "image_url" in content:
            tasks.append(self._classify_image(content["image_url"]))
        
        classifications = await asyncio.gather(*tasks)
        
        policy_decision = self.policy_engine.evaluate(
            content, classifications
        )
        
        action = self.action_enforcer.execute(policy_decision)
        
        return {
            "content_id": content["id"],
            "decision": policy_decision["action"],
            "confidence": policy_decision["confidence"],
            "categories": policy_decision["categories"],
            "action_taken": action
        }
    
    async def _classify_text(self, text: str) -> Dict:
        labels = self.text_classifier(text)
        return {
            "toxic": float(labels["toxic"]),
            "harassment": float(labels["harassment"]),
            "hate_speech": float(labels["hate_speech"]),
            "spam": float(labels["spam"])
        }
    
    async def _classify_image(self, image_url: str) -> Dict:
        labels = self.image_classifier(image_url)
        return labels
    
    def _load_text_classifier(self):
        pass
    
    def _load_image_classifier(self):
        pass

class PolicyEngine:
    def evaluate(self, content, classifications):
        text_scores = classifications[0] if len(classifications) > 0 else {}
        image_scores = classifications[1] if len(classifications) > 1 else {}
        
        max_text_score = max(text_scores.values()) if text_scores else 0
        max_image_score = max(image_scores.values()) if image_scores else 0
        
        combined_score = max(max_text_score, max_image_score)
        
        if combined_score > 0.95:
            action = "Block"
        elif combined_score > 0.7:
            action = "Review"
        elif combined_score > 0.3:
            action = "Flag"
        else:
            action = "Allow"
        
        return {
            "action": action,
            "confidence": combined_score,
            "categories": list(text_scores.keys()) + list(image_scores.keys())
        }

class ActionEnforcer:
    def __init__(self):
        self.actions_taken = []
    
    def execute(self, decision):
        action = {
            "Block": self._block_content,
            "Review": self._queue_for_review,
            "Flag": self._flag_user,
            "Allow": lambda: None
        }[decision["action"]]()
        
        self.actions_taken.append(decision)
        return action
    
    def _block_content(self):
        return {"type": "block", "severity": "high"}
    
    def _queue_for_review(self):
        return {"type": "queue", "severity": "medium"}
    
    def _flag_user(self):
        return {"type": "flag_user", "severity": "low"}
```

### Scaling Considerations

```python
class ModerationScaling:
    def __init__(self):
        self.scaling_config = {
            "throughput": {
                "target": "100K req/s",
                "current": "10K req/s",
                "bottleneck": "Model inference",
                "solution": "Batch inference + GPU auto-scaling"
            },
            "latency": {
                "target_p99": "500ms",
                "current_p99": "1.2s",
                "bottleneck": "Image classification",
                "solution": "Image resize + parallel GPU execution"
            },
            "cost": {
                "per_request": "$0.0005",
                "daily_cost": "$4,320 at 100M requests",
                "optimization": "Cascade models (fast first, slow only if needed)"
            }
        }
    
    def cascade_classification(self, content):
        fast_classifier = self.run_fast_classifier(content)
        
        if fast_classifier["confidence"] > 0.95:
            return fast_classifier
        
        slow_classifier = self.run_accurate_classifier(content)
        return slow_classifier
```

## Interview Questions for AI System Design

1. Design a chatbot system serving 10M daily active users
2. How would you design a RAG pipeline for legal document Q&A?
3. Design a code completion system like GitHub Copilot
4. Design a personalized recommendation system for a video platform
5. Design a real-time content moderation system for a social network
6. How would you handle multi-modal inputs (text + image) in a RAG system?
7. Design a system for real-time translation of live streams
8. How would you design an AI-powered search system?
9. Design a model serving platform for 100+ models
10. How would you design a system for automated document summarization?

## Real Company Architecture Patterns

| Company | System | Key Architecture Decisions |
|---|---|---|
| **ChatGPT** | Chatbot | Multi-model cascade, Redis context, safety layers |
| **Perplexity** | RAG | Hybrid search, real-time web crawling, answer synthesis |
| **GitHub Copilot** | Code assistant | Context-aware prefix/suffix, AST validation, caching |
| **Netflix** | Recommendations | Multi-stage (candidate gen -> ranking -> policy) |
| **Meta** | Moderation | Multi-classifier ensemble, policy engine, feedback loop |
| **Google Search** | Search + AI | MUM, BERT, index + retrieval + ranking + synthesis |
| **Spotify** | Music recommendations | Collaborative + content-based + audio features |
| **Notion AI** | RAG + chat | Vector search, user-specific indexing, caching |
