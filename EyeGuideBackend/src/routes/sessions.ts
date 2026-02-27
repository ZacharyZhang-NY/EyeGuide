import { Hono } from "hono";
import { z } from "zod";
import type { Env, Session } from "../types";
import { getDb } from "../db/client";
import { authMiddleware } from "../middleware/auth";

const createSessionSchema = z.object({
  session_type: z
    .enum(["general", "navigation", "reading", "social", "shopping"])
    .default("general"),
  location: z.string().max(500).nullable().optional(),
});

type Variables = {
  userId: string;
};

const sessions = new Hono<{ Bindings: Env; Variables: Variables }>();

sessions.use("*", authMiddleware);

sessions.post("/", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json();
  const parsed = createSessionSchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const { session_type, location } = parsed.data;
  const sql = getDb(c.env);

  const rows = await sql`
    INSERT INTO sessions (user_id, session_type, location)
    VALUES (${userId}, ${session_type}, ${location ?? null})
    RETURNING *
  `;

  return c.json({ session: rows[0] as Session }, 201);
});

sessions.patch("/:id/end", async (c) => {
  const userId = c.get("userId");
  const sessionId = c.req.param("id");
  const sql = getDb(c.env);

  const rows = await sql`
    UPDATE sessions
    SET ended_at = now()
    WHERE id = ${sessionId} AND user_id = ${userId} AND ended_at IS NULL
    RETURNING *
  `;

  if (rows.length === 0) {
    return c.json({ error: "Session not found or already ended" }, 404);
  }

  return c.json({ session: rows[0] as Session });
});

sessions.get("/", async (c) => {
  const userId = c.get("userId");
  const limit = Math.min(parseInt(c.req.query("limit") ?? "20", 10), 100);
  const offset = parseInt(c.req.query("offset") ?? "0", 10);
  const sql = getDb(c.env);

  const rows = await sql`
    SELECT * FROM sessions
    WHERE user_id = ${userId}
    ORDER BY started_at DESC
    LIMIT ${limit} OFFSET ${offset}
  `;

  const countRows = await sql`
    SELECT COUNT(*) as total FROM sessions WHERE user_id = ${userId}
  `;

  return c.json({
    sessions: rows as Session[],
    total: Number(countRows[0].total),
    limit,
    offset,
  });
});

sessions.get("/active", async (c) => {
  const userId = c.get("userId");
  const sql = getDb(c.env);

  const rows = await sql`
    SELECT * FROM sessions
    WHERE user_id = ${userId} AND ended_at IS NULL
    ORDER BY started_at DESC
    LIMIT 1
  `;

  if (rows.length === 0) {
    return c.json({ session: null });
  }

  return c.json({ session: rows[0] as Session });
});

export { sessions };
