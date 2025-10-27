/**
 * Cloudflare Worker Entry Point
 * Main entry point for the OpenAuth Enterprise SSO system
 */

export interface Env {
  DB: D1Database;
  SESSIONS: KVNamespace;
  JWT_SECRET: string;
  ENVIRONMENT: string;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers for all responses
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // Route to appropriate handlers
      if (path.startsWith('/auth')) {
        return handleAuthRoutes(request, env, path);
      } else if (path.startsWith('/admin')) {
        return handleAdminRoutes(request, env, path);
      } else if (path === '/health') {
        return new Response(JSON.stringify({ status: 'healthy' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      } else {
        return new Response(JSON.stringify({ error: 'Not Found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    } catch (error) {
      console.error('Error handling request:', error);
      return new Response(JSON.stringify({ error: 'Internal Server Error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};

// Placeholder route handlers
async function handleAuthRoutes(request: Request, env: Env, path: string): Promise<Response> {
  // Auth routes implementation will go here
  return new Response(JSON.stringify({ message: 'Auth routes', path }), {
    headers: { 'Content-Type': 'application/json' },
  });
}

async function handleAdminRoutes(request: Request, env: Env, path: string): Promise<Response> {
  // Admin routes implementation will go here
  return new Response(JSON.stringify({ message: 'Admin routes', path }), {
    headers: { 'Content-Type': 'application/json' },
  });
}
