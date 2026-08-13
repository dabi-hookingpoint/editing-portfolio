function heuristicSummarize(text) {
  const sentences = text
    .split(/\n{2,}/)
    .flatMap((block) => block.split(/(?<=[.!?다요])\s+/))
    .map((s) => s.trim())
    .filter(Boolean);

  const cueWords = ["결정", "예정", "다음", "액션", "해야", "부탁", "확인", "필요", "요청", "제안"];
  const highlighted = sentences.filter((s) => cueWords.some((w) => s.includes(w)));

  const speakerLines = text
    .split(/\n{2,}/)
    .map((s) => s.trim())
    .filter((s) => /^\[화자 [A-Z]\]/.test(s));
  const speakers = [...new Set(speakerLines.map((s) => s.match(/^\[화자 ([A-Z])\]/)?.[1]).filter(Boolean))];

  return {
    engine: "heuristic",
    speakers,
    keyPoints: highlighted.length ? highlighted.slice(0, 8) : sentences.slice(0, 5),
    summary:
      highlighted.length > 0
        ? "결정/액션 관련 표현이 포함된 문장을 추출했습니다. 정확한 맥락 요약은 LLM 키 연동 후 가능합니다."
        : "결정/액션으로 읽히는 표현이 감지되지 않아, 텍스트 앞부분 문장을 그대로 보여줍니다. 정확한 맥락 요약은 LLM 키 연동 후 가능합니다.",
  };
}

async function llmSummarizeAnthropic(text, apiKey, env) {
  const model = env.ANTHROPIC_MODEL || "claude-3-5-haiku-20241022";
  const prompt = `당신은 영화/드라마 기획 회의록을 정리하는 어시스턴트입니다. 아래 회의 전사 텍스트(발화자 태그 [화자 A]/[화자 B]가 포함될 수 있음)를 읽고 문맥을 파악해 요약하세요.

반드시 아래 JSON 형식으로만 답하세요:
{"summary": "전체 맥락 요약 3~5문장", "keyPoints": ["핵심 논의/결정 사항 불릿", ...], "speakerNotes": {"A": "화자 A가 주로 말한 내용 한줄", "B": "화자 B가 주로 말한 내용 한줄"}}

텍스트:
"""${text}"""`;

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({ model, max_tokens: 1200, messages: [{ role: "user", content: prompt }] }),
  });
  if (!res.ok) {
    const b = await res.text();
    throw new Error(`Anthropic API 오류 (${res.status}): ${b.slice(0, 300)}`);
  }
  const data = await res.json();
  const raw = data.content?.[0]?.text || "{}";
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  const parsed = JSON.parse(jsonMatch ? jsonMatch[0] : raw);
  return { engine: `anthropic:${model}`, ...parsed };
}

async function llmSummarizeOpenAI(text, apiKey, env) {
  const model = env.OPENAI_MODEL || "gpt-4o-mini";
  const prompt = `당신은 영화/드라마 기획 회의록을 정리하는 어시스턴트입니다. 아래 회의 전사 텍스트(발화자 태그 [화자 A]/[화자 B]가 포함될 수 있음)를 읽고 문맥을 파악해 요약하고, 반드시 JSON으로만 답하세요.

형식: {"summary": "", "keyPoints": [], "speakerNotes": {}}

텍스트:
"""${text}"""`;

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({
      model,
      messages: [{ role: "user", content: prompt }],
      response_format: { type: "json_object" },
    }),
  });
  if (!res.ok) {
    const b = await res.text();
    throw new Error(`OpenAI API 오류 (${res.status}): ${b.slice(0, 300)}`);
  }
  const data = await res.json();
  const parsed = JSON.parse(data.choices?.[0]?.message?.content || "{}");
  return { engine: `openai:${model}`, ...parsed };
}

export async function summarizeTranscript(text, env) {
  const anthropicKey = env.ANTHROPIC_API_KEY;
  const openaiKey = env.OPENAI_API_KEY;

  if (anthropicKey) {
    try {
      return await llmSummarizeAnthropic(text, anthropicKey, env);
    } catch (err) {
      return { ...heuristicSummarize(text), engineError: String(err.message || err) };
    }
  }
  if (openaiKey) {
    try {
      return await llmSummarizeOpenAI(text, openaiKey, env);
    } catch (err) {
      return { ...heuristicSummarize(text), engineError: String(err.message || err) };
    }
  }
  return heuristicSummarize(text);
}
