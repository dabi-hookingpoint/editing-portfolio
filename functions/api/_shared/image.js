function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunkSize));
  }
  return btoa(binary);
}

async function genColab(prompt, endpointUrl, sharedSecret) {
  const base = endpointUrl.replace(/\/$/, "");
  const res = await fetch(`${base}/generate`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(sharedSecret ? { "x-shared-secret": sharedSecret } : {}),
    },
    body: JSON.stringify({ prompt }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Colab 서버 오류 (${res.status}): ${body.slice(0, 300)}`);
  }
  const data = await res.json();
  if (!data.image_base64) throw new Error("Colab 서버가 이미지를 반환하지 않았습니다.");
  return { url: `data:image/png;base64,${data.image_base64}`, provider: "colab-stable-diffusion" };
}

async function genStability(prompt, apiKey) {
  const form = new FormData();
  form.append("prompt", prompt);
  form.append("output_format", "png");
  form.append("aspect_ratio", "16:9");

  const res = await fetch("https://api.stability.ai/v2beta/stable-image/generate/core", {
    method: "POST",
    headers: { authorization: `Bearer ${apiKey}`, accept: "image/*" },
    body: form,
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Stability API 오류 (${res.status}): ${body.slice(0, 300)}`);
  }
  const buf = await res.arrayBuffer();
  return { url: `data:image/png;base64,${arrayBufferToBase64(buf)}`, provider: "stability-diffusion" };
}

async function genOpenAI(prompt, apiKey, env) {
  const model = env.OPENAI_IMAGE_MODEL || "dall-e-3";
  const res = await fetch("https://api.openai.com/v1/images/generations", {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({ model, prompt, size: "1024x1024", n: 1 }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`OpenAI Image API 오류 (${res.status}): ${body.slice(0, 300)}`);
  }
  const data = await res.json();
  const item = data.data?.[0];
  if (item?.b64_json) {
    return { url: `data:image/png;base64,${item.b64_json}`, provider: `openai:${model}` };
  }
  return { url: item.url, provider: `openai:${model}`, external: true };
}

async function genReplicate(prompt, apiToken) {
  const start = await fetch("https://api.replicate.com/v1/models/stability-ai/sdxl/predictions", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${apiToken}`,
      Prefer: "wait",
    },
    body: JSON.stringify({ input: { prompt } }),
  });
  if (!start.ok) {
    const body = await start.text();
    throw new Error(`Replicate API 오류 (${start.status}): ${body.slice(0, 300)}`);
  }
  const prediction = await start.json();
  const output = prediction.output;
  const imageUrl = Array.isArray(output) ? output[0] : output;
  if (!imageUrl) throw new Error("Replicate가 이미지를 반환하지 않았습니다.");
  return { url: imageUrl, provider: "replicate:sdxl", external: true };
}

function mockImage(prompt) {
  const hue = Math.abs(prompt.split("").reduce((a, c) => a + c.charCodeAt(0), 0)) % 360;
  const escaped = prompt.slice(0, 60).replace(/[<&>]/g, "");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="576" viewBox="0 0 1024 576">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="hsl(${hue},45%,18%)" />
      <stop offset="100%" stop-color="hsl(${(hue + 60) % 360},40%,8%)" />
    </linearGradient>
  </defs>
  <rect width="1024" height="576" fill="url(#g)" />
  <text x="50%" y="46%" text-anchor="middle" fill="#e8e6df" font-family="sans-serif" font-size="22" opacity="0.85">MOCK CONCEPT IMAGE (API 키 미설정)</text>
  <text x="50%" y="56%" text-anchor="middle" fill="#c9c6bb" font-family="sans-serif" font-size="16">${escaped}${prompt.length > 60 ? "…" : ""}</text>
</svg>`;
  return { url: `data:image/svg+xml,${encodeURIComponent(svg)}`, provider: "mock" };
}

export async function generateConceptImage(prompt, env) {
  const colabUrl = env.COLAB_ENDPOINT_URL;
  const colabSecret = env.COLAB_SHARED_SECRET;
  const stabilityKey = env.STABILITY_API_KEY;
  const openaiKey = env.OPENAI_API_KEY;
  const replicateToken = env.REPLICATE_API_TOKEN;

  try {
    if (colabUrl) return await genColab(prompt, colabUrl, colabSecret);
    if (stabilityKey) return await genStability(prompt, stabilityKey);
    if (openaiKey) return await genOpenAI(prompt, openaiKey, env);
    if (replicateToken) return await genReplicate(prompt, replicateToken);
  } catch (err) {
    return { ...mockImage(prompt), engineError: String(err.message || err) };
  }
  return mockImage(prompt);
}
