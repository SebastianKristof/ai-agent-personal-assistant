#!/usr/bin/env python3
"""
Idea Handler for AI Personal Assistant

This script handles the "idea" task type, saving ideas to a JSON file with metadata.
It can be run as a standalone API server or imported as a module.
"""

import os
import json
import time
import logging
import argparse
from datetime import datetime
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("idea_handler")

# Define models
class IdeaRequest(BaseModel):
    task_data: Dict[str, Any]

class IdeaResponse(BaseModel):
    id: str
    content: str
    tags: List[str]
    timestamp: str
    message: str

# Initialize FastAPI app
app = FastAPI(
    title="Idea Handler API",
    description="API for handling idea tasks in the AI Personal Assistant",
    version="1.0.0"
)

def get_ideas_file_path() -> str:
    """Get the path to the ideas JSON file"""
    # Check environment variable first
    ideas_file = os.getenv("IDEAS_FILE_PATH")
    if ideas_file:
        return ideas_file
    
    # Default to data directory
    data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
    os.makedirs(data_dir, exist_ok=True)
    return os.path.join(data_dir, "ideas.json")

def load_ideas() -> List[Dict[str, Any]]:
    """Load ideas from the JSON file"""
    file_path = get_ideas_file_path()
    
    if not os.path.exists(file_path):
        # Create empty ideas file
        with open(file_path, 'w') as f:
            json.dump([], f)
        return []
    
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError:
        logger.error(f"Error decoding ideas file: {file_path}")
        return []

def save_idea(idea_data: Dict[str, Any]) -> Dict[str, Any]:
    """Save an idea to the JSON file"""
    ideas = load_ideas()
    
    # Extract content from the idea data
    content = idea_data.get("content", "")
    if not content:
        content = idea_data.get("original_message", "")
    
    # Generate tags if not provided
    tags = idea_data.get("tags", [])
    if not tags and "category" in idea_data:
        tags.append(idea_data["category"])
    
    # Create idea object
    idea = {
        "id": f"idea_{int(time.time())}",
        "content": content,
        "tags": tags,
        "timestamp": datetime.now().isoformat(),
        "source": "telegram",
        "user_id": idea_data.get("user_id", ""),
        "username": idea_data.get("username", ""),
        "original_message": idea_data.get("original_message", "")
    }
    
    # Add any additional fields from the idea_data
    for key, value in idea_data.items():
        if key not in idea and key not in ["task_type", "task_data"]:
            idea[key] = value
    
    # Add to ideas list
    ideas.append(idea)
    
    # Save to file
    file_path = get_ideas_file_path()
    with open(file_path, 'w') as f:
        json.dump(ideas, f, indent=2)
    
    logger.info(f"Saved idea: {idea['id']}")
    
    return idea

@app.post("/webhook/idea-handler", response_model=Dict[str, Any])
async def handle_idea_webhook(request: Request):
    """Handle incoming idea webhook from n8n"""
    try:
        data = await request.json()
        task_data = data.get("task_data", {})
        
        if not task_data:
            raise HTTPException(status_code=400, detail="Missing task_data")
        
        # Save the idea
        idea = save_idea(task_data)
        
        # Prepare response
        response = {
            "id": idea["id"],
            "content": idea["content"],
            "tags": idea["tags"],
            "timestamp": idea["timestamp"],
            "response": f"I've saved your idea: \"{idea['content']}\""
        }
        
        if idea["tags"]:
            response["response"] += f"\n\nI've tagged it with: {', '.join(idea['tags'])}"
        
        return response
    
    except Exception as e:
        logger.error(f"Error handling idea webhook: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/ideas", response_model=List[Dict[str, Any]])
async def get_ideas():
    """Get all ideas"""
    return load_ideas()

@app.get("/ideas/{idea_id}", response_model=Dict[str, Any])
async def get_idea(idea_id: str):
    """Get a specific idea by ID"""
    ideas = load_ideas()
    
    for idea in ideas:
        if idea["id"] == idea_id:
            return idea
    
    raise HTTPException(status_code=404, detail="Idea not found")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "idea_handler"}

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Idea Handler API")
    
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Host to run the API on (default: 0.0.0.0)"
    )
    
    parser.add_argument(
        "--port",
        type=int,
        default=8080,
        help="Port to run the API on (default: 8080)"
    )
    
    return parser.parse_args()

def main():
    """Main function to run the API server"""
    # Load environment variables
    load_dotenv()
    
    # Parse arguments
    args = parse_arguments()
    
    # Run the API server
    logger.info(f"Starting Idea Handler API on {args.host}:{args.port}")
    uvicorn.run(app, host=args.host, port=args.port)

if __name__ == "__main__":
    main() 