#!/usr/bin/env python3
"""
Perplexity MCP Server
Provides web search capabilities to Amazon Q CLI via MCP protocol
Uses secure keyring storage for API key
Handles persistent stdin/stdout communication
"""

import json
import sys
import os
import asyncio
import keyring
import httpx
from typing import Dict, Any, List
import logging

# Set up logging for debugging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class PerplexityMCPServer:
    def __init__(self):
        self.api_key = None
        self.base_url = "https://api.perplexity.ai/chat/completions"
        self.initialized = False
        
    def get_api_key(self):
        """Retrieve API key from secure keyring storage"""
        if self.api_key:
            return self.api_key
            
        service = os.getenv('PERPLEXITY_API_KEY_KEYRING_SERVICE', 'perplexity-api')
        username = os.getenv('PERPLEXITY_API_KEY_KEYRING_USERNAME', 'default')
        
        try:
            self.api_key = keyring.get_password(service, username)
            if not self.api_key:
                raise Exception(f"No API key found in keyring for service '{service}', username '{username}'")
            logger.info(f"Successfully retrieved API key from keyring")
            return self.api_key
        except Exception as e:
            logger.error(f"Failed to retrieve API key from keyring: {e}")
            raise Exception(f"Failed to retrieve API key from keyring: {e}")

    async def search(self, query: str, model: str = "sonar") -> Dict[str, Any]:
        """Perform search using Perplexity API"""
        api_key = self.get_api_key()
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": model,
            "messages": [
                {
                    "role": "user",
                    "content": query
                }
            ],
            "max_tokens": 800,
            "temperature": 0.1
        }
        
        async with httpx.AsyncClient() as client:
            try:
                logger.info(f"Making Perplexity API request for query: {query[:50]}...")
                response = await client.post(
                    self.base_url,
                    headers=headers,
                    json=payload,
                    timeout=30.0
                )
                response.raise_for_status()
                result = response.json()
                
                # Extract the response content
                if 'choices' in result and len(result['choices']) > 0:
                    content = result['choices'][0]['message']['content']
                    citations = result.get('citations', [])
                    
                    logger.info("Perplexity API request successful")
                    return {
                        "success": True,
                        "content": content,
                        "citations": citations,
                        "usage": result.get('usage', {}),
                        "model": model
                    }
                else:
                    logger.error("No response content received from Perplexity API")
                    return {
                        "success": False,
                        "error": "No response content received"
                    }
                    
            except httpx.HTTPStatusError as e:
                logger.error(f"HTTP error from Perplexity API: {e.response.status_code}")
                return {
                    "success": False,
                    "error": f"HTTP {e.response.status_code}: {e.response.text}"
                }
            except Exception as e:
                logger.error(f"Request failed: {str(e)}")
                return {
                    "success": False,
                    "error": f"Request failed: {str(e)}"
                }

    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP protocol requests"""
        method = request.get('method')
        params = request.get('params', {})
        request_id = request.get('id')
        
        logger.info(f"Handling MCP request: {method}")
        
        if method == 'initialize':
            self.initialized = True
            logger.info("MCP server initialized")
            return {
                "id": request_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {
                        "tools": {}
                    },
                    "serverInfo": {
                        "name": "perplexity-mcp-server",
                        "version": "1.0.0"
                    }
                }
            }
        
        elif method == 'tools/list':
            if not self.initialized:
                return {
                    "id": request_id,
                    "error": {
                        "code": -32002,
                        "message": "Server not initialized"
                    }
                }
            
            return {
                "id": request_id,
                "result": {
                    "tools": [
                        {
                            "name": "perplexity_search",
                            "description": "Ask Perplexity AI questions in natural language to get current web information and research. Use complete sentences and conversational queries, not keywords.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "query": {
                                        "type": "string",
                                        "description": "The search query to send to Perplexity"
                                    },
                                    "model": {
                                        "type": "string",
                                        "description": "Perplexity model to use (default: sonar)",
                                        "default": "sonar"
                                    }
                                },
                                "required": ["query"]
                            }
                        }
                    ]
                }
            }
        
        elif method == 'tools/call':
            if not self.initialized:
                return {
                    "id": request_id,
                    "error": {
                        "code": -32002,
                        "message": "Server not initialized"
                    }
                }
            
            tool_name = params.get('name')
            arguments = params.get('arguments', {})
            
            if tool_name == 'perplexity_search':
                query = arguments.get('query')
                model = arguments.get('model', 'sonar')
                
                if not query:
                    return {
                        "id": request_id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": "Error: Query parameter is required"
                                }
                            ],
                            "isError": True
                        }
                    }
                
                # Run the async search
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                try:
                    result = loop.run_until_complete(self.search(query, model))
                finally:
                    loop.close()
                
                if result['success']:
                    response_text = f"**Perplexity Search Results for: {query}**\n\n"
                    response_text += result['content']
                    
                    if result.get('citations'):
                        response_text += "\n\n**Sources:**\n"
                        for i, citation in enumerate(result['citations'][:5], 1):
                            if isinstance(citation, dict):
                                title = citation.get('title', 'Unknown')
                                url = citation.get('url', '')
                                response_text += f"{i}. {title}\n   {url}\n"
                            else:
                                response_text += f"{i}. {citation}\n"
                    
                    return {
                        "id": request_id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": response_text
                                }
                            ]
                        }
                    }
                else:
                    return {
                        "id": request_id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Perplexity search failed: {result['error']}"
                                }
                            ],
                            "isError": True
                        }
                    }
            
            return {
                "id": request_id,
                "error": {
                    "code": -32601,
                    "message": f"Unknown tool: {tool_name}"
                }
            }
        
        return {
            "id": request_id,
            "error": {
                "code": -32601,
                "message": f"Method not found: {method}"
            }
        }

    def run(self):
        """Run the MCP server with persistent stdin/stdout communication"""
        try:
            # Test API key access on startup
            self.get_api_key()
            logger.info("MCP server starting up...")
            
            # Handle persistent stdin/stdout communication
            for line_num, line in enumerate(sys.stdin, 1):
                try:
                    line = line.strip()
                    if not line:
                        continue
                        
                    logger.debug(f"Received line {line_num}: {line[:100]}...")
                    request = json.loads(line)
                    response = self.handle_request(request)
                    
                    # Send response to stdout
                    response_json = json.dumps(response)
                    print(response_json, flush=True)
                    logger.debug(f"Sent response: {response_json[:100]}...")
                    
                except json.JSONDecodeError as e:
                    logger.error(f"JSON decode error on line {line_num}: {e}")
                    error_response = {
                        "id": None,
                        "error": {
                            "code": -32700,
                            "message": "Parse error"
                        }
                    }
                    print(json.dumps(error_response), flush=True)
                except Exception as e:
                    logger.error(f"Error processing request on line {line_num}: {e}")
                    error_response = {
                        "id": request.get('id') if 'request' in locals() else None,
                        "error": {
                            "code": -32603,
                            "message": f"Internal error: {str(e)}"
                        }
                    }
                    print(json.dumps(error_response), flush=True)
                    
        except KeyboardInterrupt:
            logger.info("MCP server shutting down (KeyboardInterrupt)")
        except Exception as e:
            logger.error(f"Server startup error: {e}")
            sys.exit(1)

if __name__ == "__main__":
    server = PerplexityMCPServer()
    server.run()
