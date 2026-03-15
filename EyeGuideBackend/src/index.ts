import { Hono } from "hono";
import { serve } from "@hono/node-server";
import type { Env } from "./types";
import { corsMiddleware } from "./middleware/cors";
import { users } from "./routes/users";
import { sessions } from "./routes/sessions";
import { usage } from "./routes/usage";
import { ai } from "./routes/ai";

const app = new Hono<{ Bindings: Env }>();

// Populate Hono env bindings from process.env (for Cloud Run / Node.js)
app.use("*", async (c, next) => {
  c.env = {
    DATABASE_URL: process.env.DATABASE_URL!,
    GEMINI_API_KEY: process.env.GEMINI_API_KEY!,
    ENVIRONMENT: process.env.ENVIRONMENT || "production",
  };
  await next();
});

app.use("*", corsMiddleware);

app.get("/", (c) => {
  return c.json({
    name: "EyeGuide API",
    version: "1.0.0",
    status: "operational",
  });
});

app.get("/health", (c) => {
  return c.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.route("/api/users", users);
app.route("/api/sessions", sessions);
app.route("/api/usage", usage);
app.route("/api/ai", ai);

app.notFound((c) => {
  return c.json({ error: "Not found" }, 404);
});

app.onError((err, c) => {
  console.error("Unhandled error:", err.message);
  return c.json({ error: "Internal server error" }, 500);
});

const port = parseInt(process.env.PORT || "8080", 10);

serve({ fetch: app.fetch, port }, () => {
  console.log(`EyeGuide API running on port ${port}`);
});

export default app;
