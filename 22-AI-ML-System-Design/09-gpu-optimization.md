# GPU Optimization

```mermaid
graph TD
    A[Deep Learning Model] --> B[GPU Memory Hierarchy]
    
    subgraph B[GPU Memory Hierarchy]
        C[Global Memory]
        D[Shared Memory]
        E[L1 Cache]
        F[Registers]
    end
    
    A --> G[Optimization Techniques]
    
    subgraph G[Optimization Techniques]
        H[Kernel Fusion]
        I[Flash Attention]
        J[PagedAttention]
        K[Continuous Batching]
        L[Quantization]
        M[Speculative Decoding]
    end
    
    H --> N[Reduced Kernel Launch Overhead]
    I --> O[O(n) Attention vs O(n²)]
    J --> P[Block-Level KV Cache]
    
    A --> Q[Parallelism Strategies]
    
    subgraph Q[Parallelism Strategies]
        R[Tensor Parallelism]
        S[Pipeline Parallelism]
        T[Data Parallelism]
        U[Sequence Parallelism]
    end
    
    R --> V[Split Weights Across GPUs]
    S --> W[Layer-Stage Pipeline]
    T --> X[Batch Distribution]
    U --> Y[Long Sequence Splitting]
```

## What is GPU Optimization?

GPU optimization encompasses techniques to maximize the performance of deep learning workloads on NVIDIA (and other) GPUs. For LLMs, this is critical because models are memory-bound and compute-bound simultaneously.

### Why GPU Optimization Matters

- **Model size**: 70B+ parameter models exceed single GPU memory (>140GB)
- **Inference cost**: GPU time is the dominant cost in LLM serving
- **Latency**: Users expect sub-second responses
- **Throughput**: Thousands of concurrent requests
- **Memory bandwidth**: The bottleneck for autoregressive generation

### When to Apply GPU Optimization

- Serving any LLM in production
- Training large models (>1B parameters)
- Real-time inference requirements
- Cost-sensitive deployments
- Memory-constrained environments

## CUDA Basics

```cpp
// CUDA kernel for element-wise addition
__global__ void vector_add(float* a, float* b, float* c, int n) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    if (idx < n) {
        c[idx] = a[idx] + b[idx];
    }
}

// Launch configuration
int block_size = 256;
int grid_size = (n + block_size - 1) / block_size;
vector_add<<<grid_size, block_size>>>(d_a, d_b, d_c, n);

// Memory management
cudaMalloc(&d_a, n * sizeof(float));
cudaMemcpy(d_a, h_a, n * sizeof(float), cudaMemcpyHostToDevice);
cudaMemcpy(h_c, d_c, n * sizeof(float), cudaMemcpyDeviceToHost);
```

### CUDA Memory Hierarchy

```python
# Conceptual GPU memory hierarchy
GPU_MEMORY_HIERARCHY = {
    "global_memory": {
        "size": "40-80 GB (A100/H100)",
        "bandwidth": "2-3 TB/s",
        "latency": "~400 cycles",
        "scope": "All threads"
    },
    "shared_memory": {
        "size": "48-228 KB per SM",
        "bandwidth": "~10 TB/s",
        "latency": "~20 cycles",
        "scope": "Thread block"
    },
    "registers": {
        "size": "65536 per SM",
        "bandwidth": "~100 TB/s",
        "latency": "~1 cycle",
        "scope": "Single thread"
    },
    "L1_cache": {
        "size": "192 KB per SM (A100)",
        "bandwidth": "~5 TB/s",
        "latency": "~30 cycles",
        "scope": "Thread block"
    }
}
```

## Kernel Fusion

Kernel fusion combines multiple GPU operations into a single kernel launch to reduce overhead and improve memory locality.

```python
import torch
from torch import nn

# Unfused operations (multiple kernel launches)
def unfused_forward(x, weight, bias):
    x = torch.matmul(x, weight.t())
    x = x + bias
    x = torch.relu(x)
    x = torch.dropout(x, 0.1, train=True)
    return x

# Fused operations (single kernel)
def fused_forward(x, weight, bias):
    return torch.nn.functional.linear(x, weight, bias)

# Using torch.compile for automatic fusion
@torch.compile
def compiled_forward(x, weight, bias):
    x = torch.matmul(x, weight.t())
    x = x + bias
    x = torch.relu(x)
    return x

# Flash Attention uses kernel fusion
from flash_attn import flash_attn_func

q = torch.randn(1, 8, 128, 64, device="cuda", dtype=torch.float16)
k = torch.randn(1, 8, 128, 64, device="cuda", dtype=torch.float16)
v = torch.randn(1, 8, 128, 64, device="cuda", dtype=torch.float16)

output = flash_attn_func(q, k, v, dropout_p=0.0, causal=True)
```

### Flash Attention

```python
# Standard attention (O(n²) memory)
def standard_attention(q, k, v):
    scores = torch.matmul(q, k.transpose(-2, -1)) * (q.size(-1) ** -0.5)
    attention = torch.softmax(scores, dim=-1)
    output = torch.matmul(attention, v)
    return output

# Flash Attention (O(n) memory)
# Tiling approach - computes attention in blocks
def flash_attention_conceptual(q, k, v, block_size=128):
    batch, heads, seq_len, d_head = q.shape
    
    output = torch.zeros_like(q)
    
    for i in range(0, seq_len, block_size):
        q_block = q[:, :, i:i+block_size]
        
        for j in range(0, seq_len, block_size):
            k_block = k[:, :, j:j+block_size]
            v_block = v[:, :, j:j+block_size]
            
            scores = torch.matmul(q_block, k_block.transpose(-2, -1))
            scores = scores * (d_head ** -0.5)
            
            block_output = torch.matmul(
                torch.softmax(scores, dim=-1), v_block
            )
            
            output[:, :, i:i+block_size] += block_output
    
    return output
```

## vLLM PagedAttention

```python
class PagedAttention:
    def __init__(self, block_size=16, num_blocks=1024):
        self.block_size = block_size
        self.num_blocks = num_blocks
        self.kv_cache = {}
        self.free_blocks = list(range(num_blocks))
    
    def allocate_blocks(self, num_tokens):
        num_blocks_needed = (num_tokens + self.block_size - 1) // self.block_size
        
        if num_blocks_needed > len(self.free_blocks):
            raise MemoryError("Out of KV cache blocks")
        
        allocated = []
        for _ in range(num_blocks_needed):
            block_id = self.free_blocks.pop(0)
            allocated.append(block_id)
        
        return allocated
    
    def store_kv(self, request_id, token_position, key, value):
        block_id = token_position // self.block_size
        offset = token_position % self.block_size
        
        if request_id not in self.kv_cache:
            self.kv_cache[request_id] = self.allocate_blocks(1)
        
        block = self.kv_cache[request_id][block_id]
        self._write_block(block, offset, key, value)
    
    def _write_block(self, block_id, offset, key, value):
        pass
    
    def free_request(self, request_id):
        if request_id in self.kv_cache:
            self.free_blocks.extend(self.kv_cache[request_id])
            del self.kv_cache[request_id]
    
    def memory_usage(self):
        total = self.num_blocks
        used = total - len(self.free_blocks)
        return {
            "total_blocks": total,
            "used_blocks": used,
            "usage_pct": used / total * 100,
            "total_tokens": used * self.block_size
        }
```

## Continuous Batching

```python
class ContinuousBatchScheduler:
    def __init__(self, max_batch_size=64, max_tokens=4096):
        self.max_batch_size = max_batch_size
        self.max_tokens = max_tokens
        self.active_requests = []
        self.pending_requests = []
    
    def add_request(self, prompt, max_new_tokens, request_id):
        self.pending_requests.append({
            "id": request_id,
            "prompt": prompt,
            "max_new_tokens": max_new_tokens,
            "generated_tokens": 0,
            "finished": False
        })
    
    def get_batch(self):
        available = self.max_batch_size - len(self.active_requests)
        
        for req in self.pending_requests[:available]:
            self.active_requests.append(req)
        
        self.pending_requests = self.pending_requests[available:]
        
        return self.active_requests
    
    def step(self):
        batch = self.get_batch()
        
        if not batch:
            return []
        
        for request in batch:
            next_token = self._generate_token(request)
            request["generated_tokens"] += 1
            
            if (request["generated_tokens"] >= request["max_new_tokens"]
                    or next_token == self.eos_token_id):
                request["finished"] = True
        
        completed = [r for r in batch if r["finished"]]
        self.active_requests = [r for r in batch if not r["finished"]]
        
        for req in self.pending_requests:
            if len(self.active_requests) < self.max_batch_size:
                self.active_requests.append(req)
                self.pending_requests.remove(req)
        
        return completed
    
    def _generate_token(self, request):
        return 0
    
    def get_stats(self):
        return {
            "active": len(self.active_requests),
            "pending": len(self.pending_requests),
            "batch_utilization": len(self.active_requests) / self.max_batch_size
        }
```

## Quantization

```python
import torch

class Quantization:
    @staticmethod
    def quantize_fp16(model):
        return model.half()
    
    @staticmethod
    def quantize_int8(tensor):
        abs_max = tensor.abs().max()
        scale = 127.0 / abs_max
        quantized = (tensor * scale).round().to(torch.int8)
        return quantized, scale
    
    @staticmethod
    def dequantize_int8(quantized, scale):
        return quantized.float() / scale
    
    @staticmethod
    def quantize_4bit(tensor, group_size=128):
        original_shape = tensor.shape
        flat = tensor.flatten()
        
        num_groups = (flat.numel() + group_size - 1) // group_size
        groups = flat.view(num_groups, -1)
        
        abs_max = groups.abs().max(dim=1, keepdim=True).values
        scales = abs_max / 7.0
        
        quantized = (groups / scales).round().clamp(-7, 7).to(torch.int8)
        
        return quantized, scales.squeeze(), original_shape
    
    @staticmethod
    def dequantize_4bit(quantized, scales, original_shape):
        dequant = quantized.float() * scales.unsqueeze(1)
        return dequant.view(original_shape)
```

## Speculative Decoding

```python
class SpeculativeDecoding:
    def __init__(self, target_model, draft_model, gamma=5):
        self.target_model = target_model
        self.draft_model = draft_model
        self.gamma = gamma
    
    @torch.no_grad
    def generate(self, input_ids, max_new_tokens=100):
        all_tokens = input_ids.clone()
        
        while len(all_tokens) < max_new_tokens:
            draft_tokens = self._draft(all_tokens)
            
            accepted = self._verify(all_tokens, draft_tokens)
            
            all_tokens = torch.cat([all_tokens, accepted], dim=-1)
        
        return all_tokens
    
    def _draft(self, input_ids):
        drafts = []
        current = input_ids
        
        for _ in range(self.gamma):
            logits = self.draft_model(current).logits[:, -1, :]
            next_token = torch.argmax(logits, dim=-1, keepdim=True)
            drafts.append(next_token)
            current = torch.cat([current, next_token], dim=-1)
        
        return torch.cat(drafts, dim=-1)
    
    def _verify(self, input_ids, draft_tokens):
        full_input = torch.cat([input_ids, draft_tokens], dim=-1)
        target_logits = self.target_model(full_input).logits
        
        draft_logits = self.draft_model(full_input).logits
        
        accepted = []
        for i in range(draft_tokens.shape[-1]):
            token = draft_tokens[0, i]
            
            target_prob = torch.softmax(target_logits[0, -(self.gamma - i) - 1], dim=-1)
            draft_prob = torch.softmax(draft_logits[0, -(self.gamma - i) - 1], dim=-1)
            
            if target_prob[token] > draft_prob[token]:
                accepted.append(token.unsqueeze(0))
            else:
                rejection_prob = 1 - (draft_prob[token] / target_prob[token])
                if torch.rand(1).item() < rejection_prob:
                    adjusted_logits = torch.relu(target_prob - draft_prob)
                    adjusted_logits[:token] = 0
                    adjusted_logits[token] = 0
                    new_token = torch.argmax(adjusted_logits, dim=-1)
                    accepted.append(new_token.unsqueeze(0))
                    break
                else:
                    accepted.append(token.unsqueeze(0))
        
        return torch.stack(accepted) if accepted else torch.tensor([])
```

## Tensor Parallelism

```python
class TensorParallelLinear:
    def __init__(self, in_features, out_features, num_gpus=2):
        self.num_gpus = num_gpus
        self.weight_shards = []
        
        shard_size = out_features // num_gpus
        for i in range(num_gpus):
            shard = torch.randn(shard_size, in_features)
            self.weight_shards.append(shard.to(f"cuda:{i}"))
    
    def forward(self, x):
        partials = []
        
        for i in range(self.num_gpus):
            x_local = x.to(f"cuda:{i}")
            partial = torch.matmul(x_local, self.weight_shards[i].t())
            partials.append(partial.to("cuda:0"))
        
        return torch.cat(partials, dim=-1)

class TensorParallelAttention:
    def __init__(self, hidden_size, num_heads, num_gpus=2):
        self.num_gpus = num_gpus
        self.heads_per_gpu = num_heads // num_gpus
        
        for i in range(num_gpus):
            q_weight = torch.randn(hidden_size, hidden_size // num_gpus)
            setattr(self, f"q_proj_{i}", nn.Linear(hidden_size, self.heads_per_gpu * 64))
    
    def forward(self, hidden_states):
        outputs = []
        
        for i in range(self.num_gpus):
            q = getattr(self, f"q_proj_{i}")(hidden_states)
            outputs.append(q.to("cuda:0"))
        
        return torch.cat(outputs, dim=-1)
```

## Pipeline Parallelism

```python
class PipelineParallelModel:
    def __init__(self, num_layers=32, num_stages=4):
        self.num_stages = num_stages
        self.layers_per_stage = num_layers // num_stages
        
        self.stages = []
        for i in range(num_stages):
            stage_layers = nn.ModuleList([
                nn.Linear(4096, 4096) for _ in range(self.layers_per_stage)
            ])
            self.stages.append(stage_layers.to(f"cuda:{i}"))
    
    def forward(self, x):
        for i, stage in enumerate(self.stages):
            x = x.to(f"cuda:{i}")
            for layer in stage:
                x = layer(x)
        
        return x

class Scheduler:
    def __init__(self, model, micro_batches=4):
        self.model = model
        self.micro_batches = micro_batches
    
    def train_step(self, batch):
        micro_batches = batch.chunk(self.micro_batches)
        
        for micro_batch in micro_batches:
            self.model.forward(micro_batch)
        
        for micro_batch in reversed(micro_batches):
            self.model.backward(micro_batch)
    
    def get_throughput(self):
        pipeline_bubble = (self.model.num_stages - 1) / (
            self.micro_batches + self.model.num_stages - 1
        )
        return {
            "bubble_pct": pipeline_bubble * 100,
            "efficiency": (1 - pipeline_bubble) * 100
        }
```

## GPU Memory Profiling

```python
import torch

class GPUMemoryProfiler:
    def __init__(self):
        self.measurements = []
    
    @torch.no_grad
    def profile_model(self, model, input_shape=(1, 128, 4096)):
        torch.cuda.reset_peak_memory_stats()
        torch.cuda.empty_cache()
        
        start_mem = torch.cuda.memory_allocated()
        
        x = torch.randn(input_shape, device="cuda")
        output = model(x)
        
        peak_mem = torch.cuda.max_memory_allocated()
        end_mem = torch.cuda.memory_allocated()
        
        result = {
            "start_memory_mb": start_mem / 1024 / 1024,
            "peak_memory_mb": peak_mem / 1024 / 1024,
            "end_memory_mb": end_mem / 1024 / 1024,
            "model_weights_mb": (end_mem - start_mem) / 1024 / 1024,
            "activation_memory_mb": (peak_mem - end_mem) / 1024 / 1024
        }
        
        self.measurements.append(result)
        return result
    
    def estimate_kv_cache(self, batch_size, seq_len, num_layers, num_heads, head_dim):
        kv_size = 2 * batch_size * seq_len * num_layers * num_heads * head_dim * 2
        
        return {
            "kv_cache_mb": kv_size / 1024 / 1024,
            "kv_cache_gb": kv_size / 1024 / 1024 / 1024
        }
    
    def generate_report(self):
        report = "# GPU Memory Profile\n\n"
        
        for i, m in enumerate(self.measurements):
            report += f"## Run {i+1}\n"
            report += f"- Peak Memory: {m['peak_memory_mb']:.2f} MB\n"
            report += f"- Model Weights: {m['model_weights_mb']:.2f} MB\n"
            report += f"- Activations: {m['activation_memory_mb']:.2f} MB\n\n"
        
        return report
```

## Cost Considerations

| Technique | Speedup | Memory Reduction | Implementation Complexity |
|---|---|---|---|
| Flash Attention | 2-4x | 2-4x (O(n) vs O(n²)) | Easy (library) |
| PagedAttention | 2-3x | 2-4x | Easy (vLLM) |
| Continuous Batching | 3-10x throughput | - | Moderate |
| INT8 Quantization | 1.5-2x | 2x | Easy |
| INT4 Quantization | 2-3x | 4x | Moderate |
| Speculative Decoding | 2-3x latency | - | Complex |
| Tensor Parallelism | 2-4x | Scales with GPUs | Moderate |
| Pipeline Parallelism | 1.5-2x | Scales with GPUs | Complex |
| Kernel Fusion | 1.2-2x | - | Complex |

## Best Practices

1. **Profile first**: Always measure before optimizing
2. **Match parallelism to model**: Tensor for wide models, pipeline for deep
3. **Use mixed precision**: FP16/BF16 for training, INT8/INT4 for inference
4. **Tune batch sizes**: Larger batches improve throughput but increase latency
5. **Optimize KV cache**: Use PagedAttention or vLLM for long sequences
6. **Fuse kernels**: Use flash attention, fused kernels
7. **Pipeline bubble**: Minimize with more micro-batches
8. **Memory budgeting**: Plan for weights, activations, KV cache, and overhead

## Interview Questions

1. Explain how Flash Attention achieves O(n) memory complexity
2. How does PagedAttention improve memory utilization vs naive KV cache?
3. Compare tensor parallelism vs pipeline parallelism
4. What is the memory hierarchy in a GPU and why does it matter?
5. How does speculative decoding improve inference latency?
6. Explain continuous batching and its throughput benefits
7. What quantization techniques work best for LLM inference?
8. How would you optimize a 70B parameter model on 4 A100 GPUs?
9. What is kernel fusion and when should you use it?
10. How do you minimize the pipeline bubble in pipeline parallelism?

## Real Company Usage Examples

| Company | Technique | Impact |
|---|---|---|
| **OpenAI** | Tensor parallelism | GPT-4 training |
| **Anthropic** | Flash attention | Claude inference |
| **Meta** | Pipeline parallelism | LLaMA training |
| **Google** | TPU optimization | PaLM/Gemini |
| **NVIDIA** | TensorRT-LLM | Inference engine |
| **Mistral** | Sliding window attention | Efficient long context |
| **Together.ai** | vLLM + PagedAttention | Multi-model serving |
| **Hugging Face** | TGI | Optimized inference |
