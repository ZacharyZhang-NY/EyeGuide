import { Hono } from "hono";
import { z } from "zod";
import type { Env, User, UserPreference } from "../types";
import { getDb } from "../db/client";
import { authMiddleware } from "../middleware/auth";

const registerSchema = z.object({
  device_id: z.string().min(1).max(255),
});

const updatePreferencesSchema = z.object({
  voice_speed: z.number().min(0.5).max(2.0).optional(),
  voice_pitch: z.number().min(0.5).max(2.0).optional(),
  description_detail: z.enum(["concise", "standard", "detailed"]).optional(),
  language: z.string().min(2).max(10).optional(),
  vibration_enabled: z.boolean().optional(),
  high_contrast_enabled: z.boolean().optional(),
  enabled_features: z
    .array(
      z.enum([
        "scene_description",
        "obstacle_detection",
        "object_recognition",
        "social_assistant",
        "text_reading",
        "color_identifier",
        "light_detector",
        "currency_recognizer",
        "navigation",
      ])
    )
    .optional(),
  emergency_contact: z.string().max(50).nullable().optional(),
});

type Variables = {
  userId: string;
};

const users = new Hono<{ Bindings: Env; Variables: Variables }>();

users.post("/register", async (c) => {
  const body = await c.req.json();
  const parsed = registerSchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const { device_id } = parsed.data;
  const sql = getDb(c.env);

  const existing = await sql`
    SELECT id, device_id, created_at, updated_at FROM users WHERE device_id = ${device_id}
  `;

  if (existing.length > 0) {
    const user = existing[0] as User;
    const prefs = await sql`
      SELECT * FROM user_preferences WHERE user_id = ${user.id}
    `;
    return c.json({
      user,
      preferences: prefs.length > 0 ? prefs[0] : null,
    });
  }

  const userRows = await sql`
    INSERT INTO users (device_id) VALUES (${device_id})
    RETURNING id, device_id, created_at, updated_at
  `;
  const newUser = userRows[0] as User;

  const prefRows = await sql`
    INSERT INTO user_preferences (user_id)
    VALUES (${newUser.id})
    RETURNING *
  `;

  return c.json(
    {
      user: newUser,
      preferences: prefRows[0] as UserPreference,
    },
    201
  );
});

users.get("/me", authMiddleware, async (c) => {
  const userId = c.get("userId");
  const sql = getDb(c.env);

  const userRows = await sql`
    SELECT id, device_id, created_at, updated_at FROM users WHERE id = ${userId}
  `;

  if (userRows.length === 0) {
    return c.json({ error: "User not found" }, 404);
  }

  const prefRows = await sql`
    SELECT * FROM user_preferences WHERE user_id = ${userId}
  `;

  return c.json({
    user: userRows[0] as User,
    preferences: prefRows.length > 0 ? (prefRows[0] as UserPreference) : null,
  });
});

users.patch("/me/preferences", authMiddleware, async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json();
  const parsed = updatePreferencesSchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const updates = parsed.data;
  const sql = getDb(c.env);

  const setClauses: string[] = [];
  const values: unknown[] = [];

  if (updates.voice_speed !== undefined) {
    setClauses.push("voice_speed");
    values.push(updates.voice_speed);
  }
  if (updates.voice_pitch !== undefined) {
    setClauses.push("voice_pitch");
    values.push(updates.voice_pitch);
  }
  if (updates.description_detail !== undefined) {
    setClauses.push("description_detail");
    values.push(updates.description_detail);
  }
  if (updates.language !== undefined) {
    setClauses.push("language");
    values.push(updates.language);
  }
  if (updates.vibration_enabled !== undefined) {
    setClauses.push("vibration_enabled");
    values.push(updates.vibration_enabled);
  }
  if (updates.high_contrast_enabled !== undefined) {
    setClauses.push("high_contrast_enabled");
    values.push(updates.high_contrast_enabled);
  }
  if (updates.enabled_features !== undefined) {
    setClauses.push("enabled_features");
    values.push(JSON.stringify(updates.enabled_features));
  }
  if (updates.emergency_contact !== undefined) {
    setClauses.push("emergency_contact");
    values.push(updates.emergency_contact);
  }

  if (setClauses.length === 0) {
    return c.json({ error: "No fields to update" }, 400);
  }

  const rows = await sql`
    UPDATE user_preferences
    SET
      voice_speed = COALESCE(${updates.voice_speed ?? null}, voice_speed),
      voice_pitch = COALESCE(${updates.voice_pitch ?? null}, voice_pitch),
      description_detail = COALESCE(${updates.description_detail ?? null}, description_detail),
      language = COALESCE(${updates.language ?? null}, language),
      vibration_enabled = COALESCE(${updates.vibration_enabled ?? null}, vibration_enabled),
      high_contrast_enabled = COALESCE(${updates.high_contrast_enabled ?? null}, high_contrast_enabled),
      enabled_features = COALESCE(${updates.enabled_features ? JSON.stringify(updates.enabled_features) : null}::jsonb, enabled_features),
      emergency_contact = CASE WHEN ${updates.emergency_contact !== undefined} THEN ${updates.emergency_contact ?? null} ELSE emergency_contact END
    WHERE user_id = ${userId}
    RETURNING *
  `;

  if (rows.length === 0) {
    return c.json({ error: "Preferences not found" }, 404);
  }

  return c.json({ preferences: rows[0] as UserPreference });
});

users.delete("/me", authMiddleware, async (c) => {
  const userId = c.get("userId");
  const sql = getDb(c.env);

  await sql`DELETE FROM users WHERE id = ${userId}`;

  return c.json({ success: true });
});

export { users };
