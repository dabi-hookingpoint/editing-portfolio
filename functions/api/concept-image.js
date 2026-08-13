import { requireAiToolsAccess, jsonError } from "./_shared/auth.js";
import { generateConceptImage } from "./_shared/image.js";

export async function onRequestPost({ request, env }) {
  const auth = await requireAiToolsAccess(request, env);
  if (auth.error) return auth.error;

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonError(400, "요청 본문을 읽을 수 없습니다.");
  }
  const prompt = (body?.prompt || "").trim();
  if (!prompt) return jsonError(400, "prompt가 비어 있습니다.");

  const result = await generateConceptImage(prompt, env);
  return new Response(JSON.stringify(result), { headers: { "content-type": "application/json" } });
}
