#!/usr/bin/env python3
"""
Vector Database Abstraction Layer API

This API provides a unified interface for interacting with different vector databases
(Chroma and Pinecone) through a consistent set of endpoints.
"""

import os
import uuid
import logging
from typing import List, Dict, Any, Optional, Union
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("vector_db_api")

# Configuration from environment variables
DB_TYPE = os.getenv("VECTOR_DB_TYPE", "chroma").lower()
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8001"))

app = FastAPI(title="Vector Database API", description="Unified API for Chroma and Pinecone vector databases")

# Data models
class EmbeddingData(BaseModel):
    """Data model for adding embeddings to the vector database"""
    text: str = Field(..., description="The text content associated with the embedding")
    embedding: List[float] = Field(..., description="The vector embedding")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Additional metadata for the embedding")
    id: Optional[str] = Field(default=None, description="Unique identifier (generated if not provided)")

class QueryData(BaseModel):
    """Data model for querying the vector database"""
    embedding: List[float] = Field(..., description="The query vector embedding")
    n_results: int = Field(default=5, description="Number of results to return")
    where: Optional[Dict[str, Any]] = Field(default=None, description="Filter conditions for the query")

class DeleteData(BaseModel):
    """Data model for deleting embeddings from the vector database"""
    ids: Optional[List[str]] = Field(default=None, description="List of IDs to delete")
    where: Optional[Dict[str, Any]] = Field(default=None, description="Filter conditions for deletion")

class MigrationConfig(BaseModel):
    """Configuration for database migration"""
    source_db_type: str = Field(..., description="Source database type (chroma or pinecone)")
    target_db_type: str = Field(..., description="Target database type (chroma or pinecone)")
    batch_size: int = Field(default=100, description="Batch size for migration")

# Database client initialization
def get_db_client():
    """Initialize and return the appropriate database client based on DB_TYPE"""
    if DB_TYPE == "chroma":
        try:
            import chromadb
            from chromadb.config import Settings
            
            chroma_host = os.getenv("CHROMA_HOST", "localhost")
            chroma_port = int(os.getenv("CHROMA_PORT", "8000"))
            collection_name = os.getenv("CHROMA_COLLECTION", "assistant_collection")
            
            logger.info(f"Connecting to Chroma at {chroma_host}:{chroma_port}")
            client = chromadb.HttpClient(host=chroma_host, port=chroma_port)
            collection = client.get_or_create_collection(
                name=collection_name,
                metadata={"hnsw:space": "cosine"}
            )
            return {"type": "chroma", "client": collection}
        except ImportError:
            logger.error("ChromaDB not installed. Run: pip install chromadb")
            raise HTTPException(status_code=500, detail="ChromaDB not installed")
        except Exception as e:
            logger.error(f"Error connecting to ChromaDB: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Error connecting to ChromaDB: {str(e)}")
    
    elif DB_TYPE == "pinecone":
        try:
            import pinecone
            
            api_key = os.getenv("PINECONE_API_KEY")
            environment = os.getenv("PINECONE_ENVIRONMENT")
            index_name = os.getenv("PINECONE_INDEX")
            
            if not api_key or not environment or not index_name:
                logger.error("Missing Pinecone configuration. Check environment variables.")
                raise HTTPException(
                    status_code=500, 
                    detail="Missing Pinecone configuration. Set PINECONE_API_KEY, PINECONE_ENVIRONMENT, and PINECONE_INDEX."
                )
            
            logger.info(f"Connecting to Pinecone in {environment} environment")
            pinecone.init(api_key=api_key, environment=environment)
            index = pinecone.Index(index_name)
            return {"type": "pinecone", "client": index}
        except ImportError:
            logger.error("Pinecone not installed. Run: pip install pinecone-client")
            raise HTTPException(status_code=500, detail="Pinecone not installed")
        except Exception as e:
            logger.error(f"Error connecting to Pinecone: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Error connecting to Pinecone: {str(e)}")
    
    else:
        logger.error(f"Unsupported database type: {DB_TYPE}")
        raise HTTPException(status_code=500, detail=f"Unsupported database type: {DB_TYPE}")

# API endpoints
@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "name": "Vector Database API",
        "version": "1.0.0",
        "database_type": DB_TYPE,
        "endpoints": [
            "/embeddings/add",
            "/embeddings/query",
            "/embeddings/delete",
            "/embeddings/count",
            "/migration/export",
            "/migration/import",
            "/health"
        ]
    }

@app.post("/embeddings/add")
async def add_embedding(data: EmbeddingData, db: Dict = Depends(get_db_client)):
    """Add an embedding to the vector database"""
    try:
        # Generate ID if not provided
        if not data.id:
            data.id = str(uuid.uuid4())
        
        # Ensure metadata is a dictionary
        metadata = data.metadata or {}
        
        if db["type"] == "chroma":
            db["client"].add(
                embeddings=[data.embedding],
                documents=[data.text],
                metadatas=[metadata],
                ids=[data.id]
            )
        elif db["type"] == "pinecone":
            db["client"].upsert(
                vectors=[{
                    "id": data.id,
                    "values": data.embedding,
                    "metadata": {
                        "text": data.text,
                        **metadata
                    }
                }]
            )
        
        logger.info(f"Added embedding with ID: {data.id}")
        return {"status": "success", "id": data.id}
    
    except Exception as e:
        logger.error(f"Error adding embedding: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/embeddings/query")
async def query_embeddings(data: QueryData, db: Dict = Depends(get_db_client)):
    """Query for similar embeddings in the vector database"""
    try:
        if db["type"] == "chroma":
            results = db["client"].query(
                query_embeddings=[data.embedding],
                n_results=data.n_results,
                where=data.where
            )
            
            # Format results to be consistent across databases
            formatted_results = {
                "matches": []
            }
            
            if results["ids"] and len(results["ids"][0]) > 0:
                for i, id_val in enumerate(results["ids"][0]):
                    formatted_results["matches"].append({
                        "id": id_val,
                        "score": results["distances"][0][i] if "distances" in results and results["distances"] else None,
                        "metadata": {
                            "text": results["documents"][0][i] if "documents" in results and results["documents"] else "",
                            **(results["metadatas"][0][i] if "metadatas" in results and results["metadatas"] else {})
                        }
                    })
            
            return formatted_results
            
        elif db["type"] == "pinecone":
            filter_query = data.where if data.where else {}
            results = db["client"].query(
                vector=data.embedding,
                top_k=data.n_results,
                include_metadata=True,
                filter=filter_query
            )
            
            # Pinecone results are already in a similar format
            return results
    
    except Exception as e:
        logger.error(f"Error querying embeddings: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/embeddings/delete")
async def delete_embeddings(data: DeleteData, db: Dict = Depends(get_db_client)):
    """Delete embeddings from the vector database"""
    try:
        if not data.ids and not data.where:
            raise HTTPException(status_code=400, detail="Either ids or where filter must be provided")
        
        if db["type"] == "chroma":
            if data.ids:
                db["client"].delete(ids=data.ids)
                logger.info(f"Deleted {len(data.ids)} embeddings by ID")
            elif data.where:
                # For Chroma, we need to first get the IDs that match the filter
                matching_ids = db["client"].get(where=data.where)["ids"]
                if matching_ids:
                    db["client"].delete(ids=matching_ids)
                    logger.info(f"Deleted {len(matching_ids)} embeddings by filter")
        
        elif db["type"] == "pinecone":
            if data.ids:
                db["client"].delete(ids=data.ids)
                logger.info(f"Deleted {len(data.ids)} embeddings by ID")
            elif data.where:
                # Pinecone supports deletion by filter
                db["client"].delete(filter=data.where)
                logger.info("Deleted embeddings by filter")
        
        return {"status": "success"}
    
    except Exception as e:
        logger.error(f"Error deleting embeddings: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/embeddings/count")
async def count_embeddings(db: Dict = Depends(get_db_client)):
    """Count the number of embeddings in the database"""
    try:
        if db["type"] == "chroma":
            count = db["client"].count()
        elif db["type"] == "pinecone":
            stats = db["client"].describe_index_stats()
            count = stats.total_vector_count
        
        logger.info(f"Database contains {count} embeddings")
        return {"count": count}
    
    except Exception as e:
        logger.error(f"Error counting embeddings: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check(db: Dict = Depends(get_db_client)):
    """Health check endpoint"""
    try:
        if db["type"] == "chroma":
            # Simple operation to check if Chroma is responsive
            db["client"].count()
        elif db["type"] == "pinecone":
            # Simple operation to check if Pinecone is responsive
            db["client"].describe_index_stats()
        
        return {
            "status": "healthy",
            "database_type": DB_TYPE
        }
    
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=503, detail=f"Health check failed: {str(e)}")

# Migration endpoints
@app.post("/migration/export")
async def export_data(db: Dict = Depends(get_db_client)):
    """Export all data from the current database"""
    try:
        if db["type"] == "chroma":
            # Get all data from Chroma
            all_data = db["client"].get(include_embeddings=True)
            
            # Format the data for consistent export
            export_data = {
                "source": "chroma",
                "count": len(all_data["ids"]) if "ids" in all_data else 0,
                "items": []
            }
            
            if "ids" in all_data and all_data["ids"]:
                for i, id_val in enumerate(all_data["ids"]):
                    export_data["items"].append({
                        "id": id_val,
                        "embedding": all_data["embeddings"][i] if "embeddings" in all_data else [],
                        "text": all_data["documents"][i] if "documents" in all_data else "",
                        "metadata": all_data["metadatas"][i] if "metadatas" in all_data else {}
                    })
            
            logger.info(f"Exported {export_data['count']} items from Chroma")
            return export_data
            
        elif db["type"] == "pinecone":
            # For Pinecone, we need to fetch vectors in batches
            # This is a simplified approach - for large datasets, implement pagination
            export_data = {
                "source": "pinecone",
                "count": 0,
                "items": []
            }
            
            # Get index stats to know vector count
            stats = db["client"].describe_index_stats()
            total_vectors = stats.total_vector_count
            
            # Fetch all vectors (this is simplified and may not work for very large datasets)
            # For production, implement proper pagination
            if total_vectors > 0:
                # Fetch IDs first (this is a simplified approach)
                # In a real implementation, you would use pagination
                fetch_response = db["client"].fetch(ids=None, top_k=total_vectors)
                
                for id_val, vector_data in fetch_response.vectors.items():
                    export_data["items"].append({
                        "id": id_val,
                        "embedding": vector_data.values,
                        "text": vector_data.metadata.get("text", ""),
                        "metadata": {k: v for k, v in vector_data.metadata.items() if k != "text"}
                    })
            
            export_data["count"] = len(export_data["items"])
            logger.info(f"Exported {export_data['count']} items from Pinecone")
            return export_data
    
    except Exception as e:
        logger.error(f"Error exporting data: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/migration/import")
async def import_data(export_data: Dict[str, Any], db: Dict = Depends(get_db_client)):
    """Import data into the current database"""
    try:
        if "items" not in export_data or not export_data["items"]:
            return {"status": "success", "count": 0, "message": "No items to import"}
        
        total_items = len(export_data["items"])
        batch_size = 100  # Process in batches to avoid overwhelming the database
        
        if db["type"] == "chroma":
            for i in range(0, total_items, batch_size):
                batch = export_data["items"][i:i+batch_size]
                
                ids = [item["id"] for item in batch]
                embeddings = [item["embedding"] for item in batch]
                documents = [item["text"] for item in batch]
                metadatas = [item["metadata"] for item in batch]
                
                db["client"].add(
                    ids=ids,
                    embeddings=embeddings,
                    documents=documents,
                    metadatas=metadatas
                )
                
                logger.info(f"Imported batch {i//batch_size + 1}/{(total_items-1)//batch_size + 1} to Chroma")
            
        elif db["type"] == "pinecone":
            for i in range(0, total_items, batch_size):
                batch = export_data["items"][i:i+batch_size]
                
                vectors = []
                for item in batch:
                    vectors.append({
                        "id": item["id"],
                        "values": item["embedding"],
                        "metadata": {
                            "text": item["text"],
                            **item["metadata"]
                        }
                    })
                
                db["client"].upsert(vectors=vectors)
                
                logger.info(f"Imported batch {i//batch_size + 1}/{(total_items-1)//batch_size + 1} to Pinecone")
        
        return {
            "status": "success", 
            "count": total_items,
            "message": f"Successfully imported {total_items} items to {db['type']}"
        }
    
    except Exception as e:
        logger.error(f"Error importing data: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    logger.info(f"Starting Vector Database API with {DB_TYPE} backend on {API_HOST}:{API_PORT}")
    uvicorn.run(app, host=API_HOST, port=API_PORT) 