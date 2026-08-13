function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunkSize));
  }
  return btoa(binary);
}

function containsKorean(text) {
  return /[가-힣]/.test(text);
}

async function translateToEnglish(text, aiBinding) {
  if (!containsKorean(text)) return text;
  try {
    const result = await aiBinding.run("@cf/meta/m2m100-1.2b", {
      text,
      source_lang: "korean",
      target_lang: "english",
    });
    return result?.translated_text || text;
  } catch {
    return text;
  }
}

// 고객이 길게 서술형으로 쓴 씬 설명(한글일 수 있음)을, 이미지 모델이 잘 이해하는
// 짧은 영어 키워드 나열형 프롬프트로 압축합니다. 실패하면 번역만 거친 원문으로 대체합니다.
async function distillPrompt(rawPrompt, aiBinding) {
  try {
    const result = await aiBinding.run("@cf/meta/llama-3.1-8b-instruct", {
      messages: [
        {
          role: "system",
          content:
            "You rewrite a film scene description (it may be written in Korean, as a long sentence) into a concise prompt for a text-to-image diffusion model. Read it carefully and keep every concrete visual detail it implies (era, place, subject, action, camera angle/lens, lighting, mood, color). Output ONLY a comma-separated list of short English visual keywords, 15-25 words total. No full sentences, no explanation, no quotes, no preamble.",
        },
        { role: "user", content: rawPrompt },
      ],
    });
    const text = (result?.response || "").trim();
    return text || null;
  } catch {
    return null;
  }
}

async function genWorkersAI(prompt, aiBinding) {
  // 1) LLM으로 고객의 서술형 프롬프트를 짧은 영어 키워드 프롬프트로 압축(맥락은 유지).
  // 2) 실패 시에는 번역만 거친 원문을 그대로 사용.
  // 3) flux-1-schnell(초고속·저품질) 대신 SDXL로 생성해 정확도를 높입니다.
  const distilled = await distillPrompt(prompt, aiBinding);
  const finalPrompt = distilled || (await translateToEnglish(prompt, aiBinding));
  const output = await aiBinding.run("@cf/stabilityai/stable-diffusion-xl-base-1.0", {
    prompt: finalPrompt,
    num_steps: 20,
  });
  const arrayBuffer = output instanceof ArrayBuffer ? output : await new Response(output).arrayBuffer();
  if (!arrayBuffer || arrayBuffer.byteLength === 0) {
    throw new Error("Cloudflare Workers AI가 이미지를 반환하지 않았습니다.");
  }
  return {
    url: `data:image/png;base64,${arrayBufferToBase64(arrayBuffer)}`,
    provider: "workers-ai:sdxl",
    finalPrompt,
  };
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
  const aiBinding = env.AI;
  const colabUrl = env.COLAB_ENDPOINT_URL;
  const colabSecret = env.COLAB_SHARED_SECRET;
  const stabilityKey = env.STABILITY_API_KEY;
  const openaiKey = env.OPENAI_API_KEY;
  const replicateToken = env.REPLICATE_API_TOKEN;

  try {
    if (aiBinding) return await genWorkersAI(prompt, aiBinding);
    if (colabUrl) return await genColab(prompt, colabUrl, colabSecret);
    if (stabilityKey) return await genStability(prompt, stabilityKey);
    if (openaiKey) return await genOpenAI(prompt, openaiKey, env);
    if (replicateToken) return await genReplicate(prompt, replicateToken);
  } catch (err) {
    return { ...mockImage(prompt), engineError: String(err.message || err) };
  }
  return mockImage(prompt);
}
