import { requireAiToolsAccess, jsonError } from "./_shared/auth.js";
import { transcribeWithDiarization } from "./_shared/transcribe.js";

export async function onRequestPost({ request, env }) {
  const auth = await requireAiToolsAccess(request, env);
  if (auth.error) return auth.error;

  const contentType = request.headers.get("content-type") || "audio/webm";
  const audioBuffer = await request.arrayBuffer();
  if (!audioBuffer || audioBuffer.byteLength === 0) {
    return jsonError(400, "오디오 데이터가 비어 있습니다.");
  }

  const result = await transcribeWithDiarization(audioBuffer, contentType, env);
  if (result.error) return jsonError(502, result.error);

  return new Response(JSON.stringify(result), { headers: { "content-type": "application/json" } });
}
