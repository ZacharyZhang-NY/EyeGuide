import { Hono } from "hono";
import { z } from "zod";
import type { Env, UsageStat } from "../types";
import { getDb } from "../db/client";
import { authMiddleware } from "../middleware/auth";

const recordUsageSchema = z.object({
  feature: z.enum([
    "scene_description",
    "obstacle_detection",
    "object_recognition",
    "social_assistant",
    "text_reading",
    "color_identifier",
    "light_detector",
    "currency_recognizer",
    "navigation",
    "voice_interaction",
  ]),
  duration: z.number().int().positive().nullable().optional(),
  success: z.boolean(),
  error_message: z.string().max(1000).nullable().optional(),
});

type Variables = {
  userId: string;
};

const usage = new Hono<{ Bindings: Env; Variables: Variables }>();

usage.use("*", authMiddleware);

usage.post("/", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json();
  const parsed = recordUsageSchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const { feature, duration, success, error_message } = parsed.data;
  const sql = getDb(c.env);

  const rows = await sql`
    INSERT INTO usage_stats (user_id, feature, duration, success, error_message)
    VALUES (${userId}, ${feature}, ${duration ?? null}, ${success}, ${error_message ?? null})
    RETURNING *
  `;

  return c.json({ stat: rows[0] as UsageStat }, 201);
});

usage.get("/", async (c) => {
  const userId = c.get("userId");
  const limit = Math.min(parseInt(c.req.query("limit") ?? "50", 10), 200);
  const offset = parseInt(c.req.query("offset") ?? "0", 10);
  const feature = c.req.query("feature");
  const sql = getDb(c.env);

  let rows: UsageStat[];
  let countRows: { total: number }[];

  if (feature) {
    rows = (await sql`
      SELECT * FROM usage_stats
      WHERE user_id = ${userId} AND feature = ${feature}
      ORDER BY timestamp DESC
      LIMIT ${limit} OFFSET ${offset}
    `) as UsageStat[];

    countRows = (await sql`
      SELECT COUNT(*) as total FROM usage_stats
      WHERE user_id = ${userId} AND feature = ${feature}
    `) as { total: number }[];
  } else {
    rows = (await sql`
      SELECT * FROM usage_stats
      WHERE user_id = ${userId}
      ORDER BY timestamp DESC
      LIMIT ${limit} OFFSET ${offset}
    `) as UsageStat[];

    countRows = (await sql`
      SELECT COUNT(*) as total FROM usage_stats WHERE user_id = ${userId}
    `) as { total: number }[];
  }

  return c.json({
    stats: rows,
    total: Number(countRows[0].total),
    limit,
    offset,
  });
});

usage.get("/summary", async (c) => {
  const userId = c.get("userId");
  const sql = getDb(c.env);

  const rows = await sql`
    SELECT
      feature,
      COUNT(*) as total_uses,
      COUNT(*) FILTER (WHERE success = true) as successful_uses,
      COALESCE(AVG(duration), 0) as avg_duration
    FROM usage_stats
    WHERE user_id = ${userId}
    GROUP BY feature
    ORDER BY total_uses DESC
  `;

  return c.json({ summary: rows });
});

export { usage };
