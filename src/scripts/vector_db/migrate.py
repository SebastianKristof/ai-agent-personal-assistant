#!/usr/bin/env python3
"""
Vector Database Migration Script

This script helps migrate data between Chroma and Pinecone vector databases.
It uses the vector_db_api.py abstraction layer to perform the migration.
"""

import os
import sys
import json
import argparse
import requests
import logging
from typing import Dict, Any
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("vector_db_migration")

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Migrate data between vector databases")
    
    parser.add_argument(
        "--source",
        choices=["chroma", "pinecone"],
        required=True,
        help="Source database type"
    )
    
    parser.add_argument(
        "--target",
        choices=["chroma", "pinecone"],
        required=True,
        help="Target database type"
    )
    
    parser.add_argument(
        "--api-url",
        default="http://localhost:8001",
        help="URL of the Vector Database API (default: http://localhost:8001)"
    )
    
    parser.add_argument(
        "--batch-size",
        type=int,
        default=100,
        help="Batch size for processing items (default: 100)"
    )
    
    parser.add_argument(
        "--output-file",
        help="Save exported data to a JSON file (optional)"
    )
    
    parser.add_argument(
        "--input-file",
        help="Import data from a JSON file instead of source database (optional)"
    )
    
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Export data but don't import to target (useful with --output-file)"
    )
    
    return parser.parse_args()

def setup_environment(db_type: str):
    """Set up environment variables for the specified database type"""
    # Load environment variables from .env file
    load_dotenv()
    
    # Set the database type for the API
    os.environ["VECTOR_DB_TYPE"] = db_type
    
    # Check for required environment variables
    if db_type == "pinecone":
        required_vars = ["PINECONE_API_KEY", "PINECONE_ENVIRONMENT", "PINECONE_INDEX"]
        for var in required_vars:
            if not os.getenv(var):
                logger.error(f"Missing required environment variable: {var}")
                sys.exit(1)
    elif db_type == "chroma":
        # Chroma uses defaults if not specified, but log a warning
        if not os.getenv("CHROMA_HOST") or not os.getenv("CHROMA_PORT"):
            logger.warning("CHROMA_HOST or CHROMA_PORT not set, using defaults")

def export_data(api_url: str) -> Dict[str, Any]:
    """Export data from the source database"""
    try:
        logger.info(f"Exporting data from source database...")
        response = requests.post(f"{api_url}/migration/export")
        response.raise_for_status()
        
        export_data = response.json()
        logger.info(f"Successfully exported {export_data.get('count', 0)} items from {export_data.get('source', 'unknown')}")
        
        return export_data
    except requests.exceptions.RequestException as e:
        logger.error(f"Error exporting data: {str(e)}")
        if hasattr(e, 'response') and e.response:
            logger.error(f"Response: {e.response.text}")
        sys.exit(1)

def import_data(api_url: str, data: Dict[str, Any]) -> Dict[str, Any]:
    """Import data to the target database"""
    try:
        logger.info(f"Importing data to target database...")
        response = requests.post(f"{api_url}/migration/import", json=data)
        response.raise_for_status()
        
        result = response.json()
        logger.info(f"Import result: {result.get('message', 'Unknown')}")
        
        return result
    except requests.exceptions.RequestException as e:
        logger.error(f"Error importing data: {str(e)}")
        if hasattr(e, 'response') and e.response:
            logger.error(f"Response: {e.response.text}")
        sys.exit(1)

def save_to_file(data: Dict[str, Any], filename: str):
    """Save data to a JSON file"""
    try:
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        logger.info(f"Data saved to {filename}")
    except Exception as e:
        logger.error(f"Error saving data to file: {str(e)}")
        sys.exit(1)

def load_from_file(filename: str) -> Dict[str, Any]:
    """Load data from a JSON file"""
    try:
        with open(filename, 'r') as f:
            data = json.load(f)
        logger.info(f"Loaded data from {filename} with {data.get('count', 0)} items")
        return data
    except Exception as e:
        logger.error(f"Error loading data from file: {str(e)}")
        sys.exit(1)

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

def main():
    """Main function to run the migration"""
    args = parse_arguments()
    
    if args.source == args.target and not (args.input_file or args.output_file):
        logger.error("Source and target databases are the same. Use --input-file or --output-file for this scenario.")
        sys.exit(1)
    
    # Step 1: Export data from source or load from file
    if args.input_file:
        logger.info(f"Loading data from file: {args.input_file}")
        export_data_result = load_from_file(args.input_file)
    else:
        # Set up environment for source database
        setup_environment(args.source)
        
        # Check API health with source database
        current_db = check_api_health(args.api_url)
        if current_db != args.source:
            logger.error(f"API is using {current_db} database, but source is set to {args.source}")
            logger.error("Make sure the VECTOR_DB_TYPE environment variable is set correctly")
            sys.exit(1)
        
        # Export data from source
        export_data_result = export_data(args.api_url)
    
    # Step 2: Save to file if requested
    if args.output_file:
        save_to_file(export_data_result, args.output_file)
    
    # Step 3: Import data to target (unless dry run)
    if not args.dry_run:
        if args.source != args.target:
            # Set up environment for target database
            setup_environment(args.target)
            
            # Check API health with target database
            current_db = check_api_health(args.api_url)
            if current_db != args.target:
                logger.error(f"API is using {current_db} database, but target is set to {args.target}")
                logger.error("Make sure the VECTOR_DB_TYPE environment variable is set correctly")
                sys.exit(1)
        
        # Import data to target
        import_data(args.api_url, export_data_result)
        
        logger.info("Migration completed successfully")
    else:
        logger.info("Dry run completed (no data imported)")

if __name__ == "__main__":
    main() 