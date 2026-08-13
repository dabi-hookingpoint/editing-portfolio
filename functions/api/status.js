import { requireAiToolsAccess } from "./_shared/auth.js";

export async function onRequestGet({ request, env }) {
  const auth = await requireAiToolsAccess(request, env);
  if (auth.error) return auth.error;

  const textEngine = env.ANTHROPIC_API_KEY ? "anthropic" : env.OPENAI_API_KEY ? "openai" : "heuristic";
  const imageEngine = env.AI
    ? "workers-ai"
    : env.COLAB_ENDPOINT_URL
    ? "colab"
    : env.STABILITY_API_KEY
    ? "stability"
    : env.OPENAI_API_KEY
    ? "openai"
    : env.REPLICATE_API_TOKEN
    ? "replicate"
    : "mock";

  return new Response(JSON.stringify({ textEngine, imageEngine }), {
    headers: { "content-type": "application/json" },
  });
}
