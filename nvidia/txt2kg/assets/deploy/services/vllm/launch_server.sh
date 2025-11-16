#!/bin/bash

set -euo pipefail

# vLLM defaults that match the service README and docker-compose configuration
: "${VLLM_MODEL:=meta-llama/Llama-3.2-3B-Instruct}"
: "${VLLM_HOST:=0.0.0.0}"
: "${VLLM_PORT:=8001}"
: "${VLLM_TENSOR_PARALLEL_SIZE:=1}"
: "${VLLM_MAX_MODEL_LEN:=4096}"
: "${VLLM_MAX_NUM_SEQS:=64}"
: "${VLLM_MAX_NUM_BATCHED_TOKENS:=4096}"
: "${VLLM_GPU_MEMORY_UTILIZATION:=0.72}"
: "${VLLM_QUANTIZATION:=fp8}"
: "${VLLM_KV_CACHE_DTYPE:=fp8}"

echo "=== vLLM Configuration ==="
echo "Model: $VLLM_MODEL"
echo "Host: $VLLM_HOST"
echo "Port: $VLLM_PORT"
echo "Tensor Parallel Size: $VLLM_TENSOR_PARALLEL_SIZE"
echo "Max Model Length: $VLLM_MAX_MODEL_LEN"
echo "Max Concurrent Seqs: $VLLM_MAX_NUM_SEQS"
echo "Max Batched Tokens: $VLLM_MAX_NUM_BATCHED_TOKENS"
echo "GPU Memory Utilization: $VLLM_GPU_MEMORY_UTILIZATION"
echo "Quantization: $VLLM_QUANTIZATION"
echo "KV Cache dtype: $VLLM_KV_CACHE_DTYPE"

# Assemble command line arguments based on the documented options
VLLM_CMD=(python3 -m vllm.entrypoints.openai.api_server
    --model "$VLLM_MODEL"
    --host "$VLLM_HOST"
    --port "$VLLM_PORT"
    --tensor-parallel-size "$VLLM_TENSOR_PARALLEL_SIZE"
    --max-model-len "$VLLM_MAX_MODEL_LEN"
    --max-num-seqs "$VLLM_MAX_NUM_SEQS"
    --max-num-batched-tokens "$VLLM_MAX_NUM_BATCHED_TOKENS"
    --gpu-memory-utilization "$VLLM_GPU_MEMORY_UTILIZATION"
    --kv-cache-dtype "$VLLM_KV_CACHE_DTYPE"
    --trust-remote-code
    --served-model-name "$VLLM_MODEL"
)

if [[ -n "${VLLM_QUANTIZATION}" && "${VLLM_QUANTIZATION}" != "none" ]]; then
    VLLM_CMD+=(--quantization "$VLLM_QUANTIZATION")
fi

echo "Starting vLLM OpenAI-compatible server..."
exec "${VLLM_CMD[@]}"