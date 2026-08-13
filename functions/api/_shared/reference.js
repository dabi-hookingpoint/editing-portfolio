// 큐레이션 레퍼런스 DB — 키워드 태그 매칭 휴리스틱용 (LLM 키 없을 때 대체 엔진)
const REFERENCE_DB = [
  { title: "파묘", year: 2024, type: "영화", tags: ["무속", "오컬트", "저주", "가족", "조선", "묘", "굿"] },
  { title: "불신지옥", year: 2015, type: "영화", tags: ["사이비", "종교", "공동체", "고립", "저주", "이웃"] },
  { title: "사바하", year: 2019, type: "영화", tags: ["사이비", "종교", "오컬트", "저주", "교리"] },
  { title: "곤지암", year: 2018, type: "영화", tags: ["오컬트", "귀신", "폐가", "공포"] },
  { title: "유전 (Hereditary)", year: 2018, type: "영화", tags: ["가족", "나르시시스트", "오컬트", "저주", "모성", "숙주", "혈연"] },
  { title: "미드소마 (Midsommar)", year: 2019, type: "영화", tags: ["공동체", "의식", "고립", "컬트", "섬", "마을"] },
  { title: "서브스턴스 (The Substance)", year: 2024, type: "영화", tags: ["여성", "욕망", "신체", "자기파괴", "권력"] },
  { title: "마더", year: 2009, type: "영화", tags: ["모성", "가족", "범죄", "비극", "딸", "엄마"] },
  { title: "벌새", year: 2018, type: "영화", tags: ["성장", "가족", "청춘", "여성", "혈연"] },
  { title: "시그널", year: 2016, type: "드라마", tags: ["형사", "추적", "시간여행", "범죄"] },
  { title: "킹덤", year: 2019, type: "드라마", tags: ["사극", "좀비", "조선", "재난", "권력"] },
  { title: "스카이캐슬", year: 2018, type: "드라마", tags: ["가족", "상류층", "교육", "권력", "욕망", "나르시시스트"] },
  { title: "오징어게임", year: 2021, type: "드라마", tags: ["생존", "폭력", "사회", "욕망", "권력"] },
  { title: "나는 신이다", year: 2023, type: "다큐멘터리", tags: ["사이비", "종교", "피해자", "실화", "교주", "권력"] },
  { title: "지옥", year: 2021, type: "드라마", tags: ["종교", "오컬트", "공포", "사회", "고지"] },
  { title: "콰이어트 플레이스", year: 2018, type: "영화", tags: ["가족", "모성", "생존", "공포"] },
  { title: "곡성", year: 2016, type: "영화", tags: ["오컬트", "마을", "저주", "공포", "미스터리", "무속"] },
  { title: "부산행", year: 2016, type: "영화", tags: ["좀비", "재난", "가족"] },
  { title: "나이브스 아웃", year: 2019, type: "영화", tags: ["가족", "유산", "추리", "코미디", "권력"] },
];

const TAG_VOCAB = [...new Set(REFERENCE_DB.flatMap((r) => r.tags))];

function heuristicReferences(text) {
  const matchedTags = TAG_VOCAB.filter((tag) => text.includes(tag));
  const scored = REFERENCE_DB.map((ref) => {
    const overlap = ref.tags.filter((t) => matchedTags.includes(t));
    return { ...ref, overlap, score: overlap.length };
  })
    .filter((r) => r.score > 0)
    .sort((a, b) => b.score - a.score);

  const top = (scored.length >= 3 ? scored : REFERENCE_DB.map((r) => ({ ...r, overlap: [], score: 0 }))).slice(0, 5);

  return {
    engine: "heuristic",
    detectedTags: matchedTags,
    references: top.map((r) => ({
      title: r.title,
      year: r.year,
      type: r.type,
      reason:
        r.overlap.length > 0
          ? `감지된 요소(${r.overlap.join(", ")})가 겹치는 레퍼런스입니다.`
          : "입력 텍스트에서 명확한 키워드가 감지되지 않아 일반적인 장르 레퍼런스로 제시합니다.",
    })),
  };
}

async function llmReferencesAnthropic(text, apiKey, env) {
  const model = env.ANTHROPIC_MODEL || "claude-3-5-haiku-20241022";
  const prompt = `당신은 한국 영화/드라마 시장을 잘 아는 기획PD 어시스턴트입니다. 아래 시놉시스(또는 씬 노트)를 읽고, 장르·톤·소재가 유사한 실제 영화 또는 드라마 레퍼런스를 최소 3편 이상 추천하세요.

반드시 아래 JSON 형식으로만 답하세요(코드블록 없이 순수 JSON):
{"references": [{"title": "작품명", "year": 2020, "type": "영화 또는 드라마", "reason": "이 시놉시스와 유사한 이유 한두 문장"}]}

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

async function llmReferencesOpenAI(text, apiKey, env) {
  const model = env.OPENAI_MODEL || "gpt-4o-mini";
  const prompt = `당신은 한국 영화/드라마 시장을 잘 아는 기획PD 어시스턴트입니다. 아래 시놉시스(또는 씬 노트)를 읽고, 장르·톤·소재가 유사한 실제 영화 또는 드라마 레퍼런스를 최소 3편 이상 추천하고, 반드시 JSON으로만 답하세요.

형식: {"references": [{"title": "", "year": 0, "type": "", "reason": ""}]}

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

export async function recommendReferences(text, env) {
  const anthropicKey = env.ANTHROPIC_API_KEY;
  const openaiKey = env.OPENAI_API_KEY;

  if (anthropicKey) {
    try {
      return await llmReferencesAnthropic(text, anthropicKey, env);
    } catch (err) {
      return { ...heuristicReferences(text), engineError: String(err.message || err) };
    }
  }
  if (openaiKey) {
    try {
      return await llmReferencesOpenAI(text, openaiKey, env);
    } catch (err) {
      return { ...heuristicReferences(text), engineError: String(err.message || err) };
    }
  }
  return heuristicReferences(text);
}
