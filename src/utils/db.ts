/**
 * Database Utilities
 * Helper functions for D1 database operations
 */

/**
 * Execute a query with parameters
 */
export async function query<T>(
  db: D1Database,
  sql: string,
  params: any[] = []
): Promise<T[]> {
  try {
    const stmt = db.prepare(sql).bind(...params);
    const result = await stmt.all();
    return result.results as T[];
  } catch (error) {
    console.error('Database query error:', error);
    throw new Error('Database operation failed');
  }
}

/**
 * Execute a query and return first result
 */
export async function queryOne<T>(
  db: D1Database,
  sql: string,
  params: any[] = []
): Promise<T | null> {
  try {
    const stmt = db.prepare(sql).bind(...params);
    const result = await stmt.first();
    return result as T | null;
  } catch (error) {
    console.error('Database query error:', error);
    throw new Error('Database operation failed');
  }
}

/**
 * Execute an insert/update/delete operation
 */
export async function execute(
  db: D1Database,
  sql: string,
  params: any[] = []
): Promise<{ success: boolean; meta: any }> {
  try {
    const stmt = db.prepare(sql).bind(...params);
    const result = await stmt.run();
    return {
      success: result.success,
      meta: result.meta,
    };
  } catch (error) {
    console.error('Database execute error:', error);
    throw new Error('Database operation failed');
  }
}

/**
 * Execute multiple statements in a batch
 */
export async function batch(
  db: D1Database,
  statements: { sql: string; params: any[] }[]
): Promise<boolean> {
  try {
    const stmts = statements.map((stmt) => db.prepare(stmt.sql).bind(...stmt.params));
    const results = await db.batch(stmts);
    return results.every((r) => r.success);
  } catch (error) {
    console.error('Database batch error:', error);
    throw new Error('Batch operation failed');
  }
}

/**
 * Create pagination metadata
 */
export function getPaginationMeta(
  total: number,
  page: number,
  limit: number
): { total: number; page: number; limit: number; totalPages: number } {
  return {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
  };
}

/**
 * Build WHERE clause from filters
 */
export function buildWhereClause(
  filters: Record<string, any>
): { clause: string; params: any[] } {
  const conditions: string[] = [];
  const params: any[] = [];

  Object.entries(filters).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      conditions.push(`${key} = ?`);
      params.push(value);
    }
  });

  return {
    clause: conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '',
    params,
  };
}
