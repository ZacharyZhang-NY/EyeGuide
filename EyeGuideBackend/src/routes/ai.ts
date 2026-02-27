import { Hono } from "hono";
import { z } from "zod";
import type { Env } from "../types";
import { authMiddleware } from "../middleware/auth";

const sceneAnalysisSchema = z.object({
  image: z.string().min(1),
  detail_level: z.enum(["concise", "standard", "detailed"]).default("standard"),
  language: z.string().default("en"),
});

const textReadingSchema = z.object({
  image: z.string().min(1),
  language: z.string().default("en"),
});

const conversationSchema = z.object({
  message: z.string().min(1).max(2000),
  image: z.string().nullable().optional(),
  conversation_history: z
    .array(
      z.object({
        role: z.enum(["user", "model"]),
        text: z.string(),
      })
    )
    .max(20)
    .optional(),
  language: z.string().default("en"),
});

const objectSearchSchema = z.object({
  image: z.string().min(1),
  target_object: z.string().min(1).max(100),
  language: z.string().default("en"),
});

type Variables = {
  userId: string;
};

const ai = new Hono<{ Bindings: Env; Variables: Variables }>();

ai.use("*", authMiddleware);

ai.get("/config", async (c) => {
  return c.json({
    apiKey: c.env.GEMINI_API_KEY,
    wsUrl:
      "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent",
    model: "gemini-live-2.5-flash-preview",
  });
});

async function callGemini(
  apiKey: string,
  model: string,
  contents: unknown[],
  generationConfig: Record<string, unknown>,
  systemInstruction?: { parts: { text: string }[] }
): Promise<Response> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const body: Record<string, unknown> = {
    contents,
    generationConfig,
  };

  if (systemInstruction) {
    body.systemInstruction = systemInstruction;
  }

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  return response;
}

ai.post("/scene", async (c) => {
  const body = await c.req.json();
  const parsed = sceneAnalysisSchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const { image, detail_level, language } = parsed.data;

  const promptMap: Record<string, string> = {
    concise:
      language === "zh-CN"
        ? "你是盲人导航助手。简洁说出前方最紧急的安全信息，如障碍物、车辆、台阶。30字以内。"
        : "Blind navigation assistant. State the most urgent safety info ahead—obstacles, vehicles, steps. Under 30 words.",
    standard:
      language === "zh-CN"
        ? "你是盲人实时导航助手。用简短自然的口语告诉用户前方情况：有什么障碍物或危险（如车辆、行人、台阶、路障），安全通行方向在哪。像朋友提醒一样说话，不要用列表、JSON或任何格式化输出。50字以内。"
        : "You are a real-time blind navigation assistant. In short, natural speech, tell the user what's ahead: any obstacles or dangers (vehicles, people, steps, barriers) and where to walk safely. Speak like a friend guiding them. No lists, JSON, or formatted output. Under 50 words.",
    detailed:
      language === "zh-CN"
        ? "你是盲人导航助手。详细描述前方环境：所有障碍物及其位置和距离、安全通行路线、地面状况、光线变化。用自然口语，不要用JSON或任何格式化输出。100字以内。"
        : "Blind navigation assistant. Describe surroundings in detail: all obstacles with position and distance, safe paths, ground conditions, lighting. Natural speech, no JSON or formatted output. Under 100 words.",
  };

  const contents = [
    {
      role: "user",
      parts: [
        { text: promptMap[detail_level] },
        {
          inline_data: {
            mime_type: "image/jpeg",
            data: image,
          },
        },
      ],
    },
  ];

  const geminiResponse = await callGemini(c.env.GEMINI_API_KEY, "gemini-2.5-flash", contents, {
    temperature: 0.2,
    max_output_tokens: detail_level === "detailed" ? 2048 : detail_level === "concise" ? 512 : 1024,
  });

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return c.json({ error: "AI service error", details: errorText }, 502);
  }

  const result = await geminiResponse.json();
  return c.json({ result });
});

ai.post("/read-text", async (c) => {
  const body = await c.req.json();
  const parsed = textReadingSchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const { image, language } = parsed.data;

  const prompt =
    language === "zh-CN"
      ? "读出这张图片中的所有文字，按从上到下顺序。只读文字内容，不加额外解释。用自然口语。"
      : "Read all text in this image from top to bottom. Just read the text content, no extra explanations. Natural speech.";

  const contents = [
    {
      role: "user",
      parts: [
        { text: prompt },
        {
          inline_data: {
            mime_type: "image/jpeg",
            data: image,
          },
        },
      ],
    },
  ];

  const geminiResponse = await callGemini(c.env.GEMINI_API_KEY, "gemini-2.5-flash", contents, {
    temperature: 0.1,
    max_output_tokens: 2048,
  });

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return c.json({ error: "AI service error", details: errorText }, 502);
  }

  const result = await geminiResponse.json();
  return c.json({ result });
});

ai.post("/conversation", async (c) => {
  const body = await c.req.json();
  const parsed = conversationSchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const { message, image, conversation_history, language } = parsed.data;

  const systemPrompt =
    language === "zh-CN"
      ? "你是EyeGuide智能导盲助手，帮助视障人士理解周围环境。请用简洁、清晰的语言回答问题，优先描述对用户安全和导航最重要的信息。"
      : "You are EyeGuide, an intelligent guide assistant for visually impaired people. Answer questions in clear, concise language, prioritizing information most important for user safety and navigation.";

  const contents: unknown[] = [];

  if (conversation_history && conversation_history.length > 0) {
    for (const entry of conversation_history) {
      contents.push({
        role: entry.role,
        parts: [{ text: entry.text }],
      });
    }
  }

  const userParts: unknown[] = [{ text: message }];
  if (image) {
    userParts.push({
      inline_data: {
        mime_type: "image/jpeg",
        data: image,
      },
    });
  }

  contents.push({
    role: "user",
    parts: userParts,
  });

  const geminiResponse = await callGemini(
    c.env.GEMINI_API_KEY,
    "gemini-2.5-flash",
    contents,
    { temperature: 0.4, max_output_tokens: 1024 },
    { parts: [{ text: systemPrompt }] }
  );

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return c.json({ error: "AI service error", details: errorText }, 502);
  }

  const result = await geminiResponse.json();
  return c.json({ result });
});

ai.post("/find-object", async (c) => {
  const body = await c.req.json();
  const parsed = objectSearchSchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const { image, target_object, language } = parsed.data;

  const prompt =
    language === "zh-CN"
      ? `在图片中找"${target_object}"。如果找到，说出它在哪个方向（左边、右边、正前方、上方、下方）和大概距离。如果没找到，简单说没看到。用自然口语，不要用JSON格式。`
      : `Look for "${target_object}" in this image. If found, say which direction (left, right, ahead, above, below) and approximate distance. If not found, just say not seen. Natural speech, no JSON.`;

  const contents = [
    {
      role: "user",
      parts: [
        { text: prompt },
        {
          inline_data: {
            mime_type: "image/jpeg",
            data: image,
          },
        },
      ],
    },
  ];

  const geminiResponse = await callGemini(c.env.GEMINI_API_KEY, "gemini-2.5-flash", contents, {
    temperature: 0.2,
    max_output_tokens: 1024,
  });

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return c.json({ error: "AI service error", details: errorText }, 502);
  }

  const result = await geminiResponse.json();
  return c.json({ result });
});

ai.post("/social", async (c) => {
  const body = await c.req.json();
  const parsed = z
    .object({
      image: z.string().min(1),
      language: z.string().default("en"),
    })
    .safeParse(body);

  if (!parsed.success) {
    return c.json({ error: "Invalid request", details: parsed.error.issues }, 400);
  }

  const { image, language } = parsed.data;

  const prompt =
    language === "zh-CN"
      ? "描述图片中的人：有几个人、在做什么、表情和肢体语言如何。用自然口语简洁描述，不要用JSON或格式化输出。50字以内。"
      : "Describe people in this image: how many, what they're doing, their expressions and body language. Natural concise speech, no JSON or formatted output. Under 50 words.";

  const contents = [
    {
      role: "user",
      parts: [
        { text: prompt },
        {
          inline_data: {
            mime_type: "image/jpeg",
            data: image,
          },
        },
      ],
    },
  ];

  const geminiResponse = await callGemini(c.env.GEMINI_API_KEY, "gemini-2.5-flash", contents, {
    temperature: 0.3,
    max_output_tokens: 1024,
  });

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return c.json({ error: "AI service error", details: errorText }, 502);
  }

  const result = await geminiResponse.json();
  return c.json({ result });
});

export { ai };
