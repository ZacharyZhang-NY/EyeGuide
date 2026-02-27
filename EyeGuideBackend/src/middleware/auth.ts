import { createMiddleware } from "hono/factory";
import type { Env } from "../types";
import { getDb } from "../db/client";

type Variables = {
  userId: string;
};

export const authMiddleware = createMiddleware<{
  Bindings: Env;
  Variables: Variables;
}>(async (c, next) => {
  const deviceId = c.req.header("X-Device-Id");
  if (!deviceId) {
    return c.json({ error: "Missing X-Device-Id header" }, 401);
  }

  const sql = getDb(c.env);

  const rows = await sql`
    SELECT id FROM users WHERE device_id = ${deviceId}
  `;

  if (rows.length === 0) {
    return c.json({ error: "Device not registered" }, 401);
  }

  c.set("userId", rows[0].id as string);
  await next();
  return undefined;
});
