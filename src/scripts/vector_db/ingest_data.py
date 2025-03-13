#!/usr/bin/env python3
"""
Vector Database Data Ingestion Script

This script helps ingest data into the vector database (Chroma or Pinecone)
through the vector_db_api.py abstraction layer.
"""

import os
import sys
import json
import argparse
import requests
import logging
import time
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("vector_db_ingest")

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Ingest data into the vector database")
    
    parser.add_argument(
        "--input",
        required=True,
        help="Input file or directory to ingest (JSON, TXT, or directory of TXT files)"
    )
    
    parser.add_argument(
        "--api-url",
        default="http://localhost:8001",
        help="URL of the Vector Database API (default: http://localhost:8001)"
    )
    
    parser.add_argument(
        "--batch-size",
        type=int,
        default=10,
        help="Batch size for processing items (default: 10)"
    )
    
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=1000,
        help="Size of text chunks in characters (default: 1000)"
    )
    
    parser.add_argument(
        "--chunk-overlap",
        type=int,
        default=200,
        help="Overlap between chunks in characters (default: 200)"
    )
    
    parser.add_argument(
        "--embedding-model",
        default="text-embedding-3-small",
        help="OpenAI embedding model to use (default: text-embedding-3-small)"
    )
    
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Process data but don't store in the database"
    )
    
    return parser.parse_args()

def check_api_health(api_url: str):
    """Check if the API is healthy"""
    try:
        response = requests.get(f"{api_url}/health")
        response.raise_for_status()
        
        health_data = response.json()
        logger.info(f"API health check: {health_data.get('status', 'unknown')} (using {health_data.get('database_type', 'unknown')})")
        
        return health_data.get("database_type")
    except requests.exceptions.RequestException as e:
        logger.error(f"API health check failed: {str(e)}")
        logger.error("Make sure the Vector Database API is running")
        sys.exit(1)

def generate_embedding(text: str, model: str = "text-embedding-3-small") -> List[float]:
    """Generate an embedding for the given text using OpenAI API"""
    try:
        openai_api_key = os.getenv("OPENAI_API_KEY")
        if not openai_api_key:
            logger.error("OPENAI_API_KEY environment variable not set")
            sys.exit(1)
            
        headers = {
            "Authorization": f"Bearer {openai_api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "input": text,
            "model": model
        }
        
        response = requests.post(
            "https://api.openai.com/v1/embeddings",
            headers=headers,
            json=data
        )
        response.raise_for_status()
        
        result = response.json()
        return result["data"][0]["embedding"]
    
    except requests.exceptions.RequestException as e:
        logger.error(f"Error generating embedding: {str(e)}")
        if hasattr(e, 'response') and e.response:
            logger.error(f"Response: {e.response.text}")
        sys.exit(1)

def add_to_vector_db(api_url: str, text: str, embedding: List[float], metadata: Dict[str, Any] = None) -> Dict[str, Any]:
    """Add an embedding to the vector database"""
    try:
        data = {
            "text": text,
            "embedding": embedding,
            "metadata": metadata or {}
        }
        
        response = requests.post(f"{api_url}/embeddings/add", json=data)
        response.raise_for_status()
        
        return response.json()
    
    except requests.exceptions.RequestException as e:
        logger.error(f"Error adding to vector database: {str(e)}")
        if hasattr(e, 'response') and e.response:
            logger.error(f"Response: {e.response.text}")
        sys.exit(1)

def chunk_text(text: str, chunk_size: int = 1000, chunk_overlap: int = 200) -> List[str]:
    """Split text into chunks with overlap"""
    if len(text) <= chunk_size:
        return [text]
    
    chunks = []
    start = 0
    
    while start < len(text):
        end = min(start + chunk_size, len(text))
        
        # Try to find a good breaking point (newline or period)
        if end < len(text):
            # Look for newline
            newline_pos = text.rfind("\n", start, end)
            if newline_pos > start + chunk_size // 2:
                end = newline_pos + 1
            else:
                # Look for period
                period_pos = text.rfind(". ", start, end)
                if period_pos > start + chunk_size // 2:
                    end = period_pos + 2
        
        chunks.append(text[start:end])
        start = end - chunk_overlap
    
    return chunks

def process_text_file(file_path: str, args) -> List[Dict[str, Any]]:
    """Process a text file and return chunks with metadata"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        chunks = chunk_text(content, args.chunk_size, args.chunk_overlap)
        
        result = []
        for i, chunk in enumerate(chunks):
            result.append({
                "text": chunk,
                "metadata": {
                    "source": file_path,
                    "chunk": i + 1,
                    "total_chunks": len(chunks)
                }
            })
        
        logger.info(f"Processed {file_path}: {len(chunks)} chunks")
        return result
    
    except Exception as e:
        logger.error(f"Error processing {file_path}: {str(e)}")
        return []

def process_json_file(file_path: str, args) -> List[Dict[str, Any]]:
    """Process a JSON file and return items with metadata"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        result = []
        
        # Handle different JSON formats
        if isinstance(data, list):
            # List of items
            for i, item in enumerate(data):
                if isinstance(item, dict) and "text" in item:
                    # Item has text field
                    text = item["text"]
                    metadata = item.get("metadata", {})
                    metadata["source"] = file_path
                    metadata["index"] = i
                    
                    # Chunk if needed
                    chunks = chunk_text(text, args.chunk_size, args.chunk_overlap)
                    for j, chunk in enumerate(chunks):
                        chunk_metadata = metadata.copy()
                        chunk_metadata["chunk"] = j + 1
                        chunk_metadata["total_chunks"] = len(chunks)
                        
                        result.append({
                            "text": chunk,
                            "metadata": chunk_metadata
                        })
                elif isinstance(item, str):
                    # Item is a string
                    chunks = chunk_text(item, args.chunk_size, args.chunk_overlap)
                    for j, chunk in enumerate(chunks):
                        result.append({
                            "text": chunk,
                            "metadata": {
                                "source": file_path,
                                "index": i,
                                "chunk": j + 1,
                                "total_chunks": len(chunks)
                            }
                        })
        elif isinstance(data, dict):
            # Single item or custom format
            if "items" in data and isinstance(data["items"], list):
                # Format with items field
                for i, item in enumerate(data["items"]):
                    if isinstance(item, dict) and "text" in item:
                        text = item["text"]
                        metadata = item.get("metadata", {})
                        metadata["source"] = file_path
                        metadata["index"] = i
                        
                        chunks = chunk_text(text, args.chunk_size, args.chunk_overlap)
                        for j, chunk in enumerate(chunks):
                            chunk_metadata = metadata.copy()
                            chunk_metadata["chunk"] = j + 1
                            chunk_metadata["total_chunks"] = len(chunks)
                            
                            result.append({
                                "text": chunk,
                                "metadata": chunk_metadata
                            })
            elif "text" in data:
                # Single item with text field
                text = data["text"]
                metadata = data.get("metadata", {})
                metadata["source"] = file_path
                
                chunks = chunk_text(text, args.chunk_size, args.chunk_overlap)
                for j, chunk in enumerate(chunks):
                    chunk_metadata = metadata.copy()
                    chunk_metadata["chunk"] = j + 1
                    chunk_metadata["total_chunks"] = len(chunks)
                    
                    result.append({
                        "text": chunk,
                        "metadata": chunk_metadata
                    })
        
        logger.info(f"Processed {file_path}: {len(result)} chunks")
        return result
    
    except Exception as e:
        logger.error(f"Error processing {file_path}: {str(e)}")
        return []

def process_directory(dir_path: str, args) -> List[Dict[str, Any]]:
    """Process all files in a directory"""
    result = []
    
    for root, _, files in os.walk(dir_path):
        for file in files:
            file_path = os.path.join(root, file)
            
            if file.endswith(".txt"):
                result.extend(process_text_file(file_path, args))
            elif file.endswith(".json"):
                result.extend(process_json_file(file_path, args))
    
    logger.info(f"Processed directory {dir_path}: {len(result)} total chunks")
    return result

def main():
    """Main function to run the ingestion"""
    # Load environment variables
    load_dotenv()
    
    # Parse arguments
    args = parse_arguments()
    
    # Check API health
    db_type = check_api_health(args.api_url)
    logger.info(f"Using {db_type} database")
    
    # Process input
    chunks = []
    if os.path.isdir(args.input):
        chunks = process_directory(args.input, args)
    elif args.input.endswith(".txt"):
        chunks = process_text_file(args.input, args)
    elif args.input.endswith(".json"):
        chunks = process_json_file(args.input, args)
    else:
        logger.error(f"Unsupported input format: {args.input}")
        sys.exit(1)
    
    if not chunks:
        logger.error("No data to ingest")
        sys.exit(1)
    
    logger.info(f"Total chunks to process: {len(chunks)}")
    
    if args.dry_run:
        logger.info("Dry run - not storing in database")
        sys.exit(0)
    
    # Process in batches
    total_processed = 0
    start_time = time.time()
    
    for i in range(0, len(chunks), args.batch_size):
        batch = chunks[i:i+args.batch_size]
        
        for item in batch:
            # Generate embedding
            embedding = generate_embedding(item["text"], args.embedding_model)
            
            # Add to vector database
            result = add_to_vector_db(args.api_url, item["text"], embedding, item["metadata"])
            logger.debug(f"Added item with ID: {result.get('id')}")
        
        total_processed += len(batch)
        elapsed = time.time() - start_time
        items_per_second = total_processed / elapsed if elapsed > 0 else 0
        
        logger.info(f"Processed {total_processed}/{len(chunks)} chunks ({items_per_second:.2f} items/sec)")
    
    logger.info(f"Ingestion complete. Processed {total_processed} chunks in {time.time() - start_time:.2f} seconds")

if __name__ == "__main__":
    main() 