import { requireAiToolsAccess, jsonError } from "./_shared/auth.js";
import { analyzeStructure } from "./_shared/analyze.js";

export async function onRequestPost({ request, env }) {
  const auth = await requireAiToolsAccess(request, env);
  if (auth.error) return auth.error;

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonError(400, "요청 본문을 읽을 수 없습니다.");
  }
  const text = (body?.text || "").trim();
  if (!text) return jsonError(400, "text가 비어 있습니다.");

  const result = await analyzeStructure(text, env);
  return new Response(JSON.stringify(result), { headers: { "content-type": "application/json" } });
}
