const ACT1_TURN_KEYWORDS = ["그러나", "하지만", "그런데", "갑자기", "사건", "발작", "연락", "소식", "사망", "발견"];
const ACT2_MID_KEYWORDS = ["대면", "정면", "맞서", "충돌", "배신", "폭로", "진실", "위기", "몰리", "궁지"];
const ACT3_RES_KEYWORDS = ["결국", "마침내", "끝내", "돌아오", "떠나", "단절", "독립", "죽음", "화해", "선택"];

function splitBeats(text) {
  return text
    .split(/\n{2,}|\r\n\r\n/)
    .map((s) => s.trim())
    .filter(Boolean)
    .flatMap((block) => (block.length > 400 ? block.split(/(?<=[.!?다요])\s+/) : [block]))
    .filter((s) => s.length > 0);
}

function bucketByPosition(beats) {
  const totalChars = beats.reduce((sum, b) => sum + b.length, 0) || 1;
  let cum = 0;
  const acts = { act1: [], act2: [], act3: [] };
  for (const beat of beats) {
    const startRatio = cum / totalChars;
    cum += beat.length;
    if (startRatio < 0.25) acts.act1.push(beat);
    else if (startRatio < 0.75) acts.act2.push(beat);
    else acts.act3.push(beat);
  }
  return acts;
}

function countKeywordHits(beats, keywords) {
  const joined = beats.join(" ");
  return keywords.filter((k) => joined.includes(k));
}

function heuristicAnalyze(text) {
  const beats = splitBeats(text);
  if (beats.length < 3) {
    return {
      engine: "heuristic",
      warning: "입력된 텍스트가 너무 짧거나 문단 구분이 없어 정확한 분석이 어렵습니다. 씬/문단 단위로 줄바꿈을 나눠 다시 시도해 주세요.",
      act1: { beatCount: beats.length, ratio: 0, beats, turningPointHits: [] },
      act2: { beatCount: 0, ratio: 0, beats: [], midpointHits: [] },
      act3: { beatCount: 0, ratio: 0, beats: [], resolutionHits: [] },
      overallIssues: ["문단(씬) 수가 부족해 3막 구조를 판단할 최소 근거가 없습니다."],
      recommendations: ["씬 또는 시퀀스 단위로 빈 줄을 넣어 구분한 뒤 다시 분석해 주세요."],
    };
  }

  const acts = bucketByPosition(beats);
  const totalChars = beats.reduce((s, b) => s + b.length, 0) || 1;
  const ratio = (arr) => arr.reduce((s, b) => s + b.length, 0) / totalChars;

  const act1TurnHits = countKeywordHits(acts.act1, ACT1_TURN_KEYWORDS);
  const act2MidHits = countKeywordHits(acts.act2, ACT2_MID_KEYWORDS);
  const act3ResHits = countKeywordHits(acts.act3, ACT3_RES_KEYWORDS);

  const issues = [];
  const recommendations = [];

  const r1 = ratio(acts.act1);
  const r2 = ratio(acts.act2);
  const r3 = ratio(acts.act3);

  if (r1 < 0.12) {
    issues.push("1막(설정)이 전체 분량의 12% 미만으로 지나치게 짧습니다 — 주인공의 일상/욕구/결핍이 충분히 설정되지 않았을 수 있습니다.");
    recommendations.push("1막에 주인공의 평소 상태와 결핍을 보여주는 씬을 1~2개 보강하세요.");
  }
  if (r1 > 0.35) {
    issues.push("1막이 전체의 35%를 넘어 인사이팅 인시던트(사건 촉발)가 늦게 등장할 가능성이 있습니다.");
    recommendations.push("사건 촉발 지점을 앞으로 당기거나, 설정 씬 일부를 2막 초반으로 재배치하세요.");
  }
  if (act1TurnHits.length === 0) {
    issues.push("1막 구간에서 '사건 촉발(inciting incident)'로 읽히는 전환 표현이 감지되지 않았습니다.");
    recommendations.push("1막 끝에 이야기를 되돌릴 수 없게 만드는 명확한 사건 하나를 배치하세요.");
  }

  if (r2 < 0.4) {
    issues.push("2막(대립·전개) 분량이 전체의 40% 미만으로, 갈등이 충분히 심화되지 못했을 수 있습니다.");
    recommendations.push("주인공이 목표를 향해 시도하고 실패하는 장애물 씬을 2막에 추가하세요.");
  }
  if (act2MidHits.length === 0) {
    issues.push("2막 중반부에서 '미드포인트(대면/폭로/위기 심화)'로 읽히는 표현이 감지되지 않았습니다.");
    recommendations.push("2막 중간에 주인공과 대립축이 정면으로 충돌하는 미드포인트 씬을 명확히 배치하세요.");
  }

  if (r3 < 0.1) {
    issues.push("3막(해결) 분량이 전체의 10% 미만으로, 결말이 급하게 처리될 가능성이 있습니다.");
    recommendations.push("클라이맥스 이후 감정적 여운을 남기는 정리 씬을 보강하세요.");
  }
  if (act3ResHits.length === 0) {
    issues.push("3막 구간에서 '해결/전환(결국, 마침내 등)'으로 읽히는 표현이 감지되지 않았습니다 — 결말이 명확히 닫히지 않았을 수 있습니다.");
    recommendations.push("주인공의 최종 선택과 그로 인한 변화를 명시적인 한 문장으로 못박는 씬을 넣으세요.");
  }

  if (issues.length === 0) {
    issues.push("뚜렷한 구조적 결함은 감지되지 않았습니다 — 다만 이는 분량 배분·키워드 기반 점검이므로, 감정선·캐릭터 아크는 별도로 검토가 필요합니다.");
  }

  return {
    engine: "heuristic",
    act1: { beatCount: acts.act1.length, ratio: r1, turningPointHits: act1TurnHits, sample: acts.act1.slice(0, 3) },
    act2: { beatCount: acts.act2.length, ratio: r2, midpointHits: act2MidHits, sample: acts.act2.slice(0, 3) },
    act3: { beatCount: acts.act3.length, ratio: r3, resolutionHits: act3ResHits, sample: acts.act3.slice(0, 3) },
    overallIssues: issues,
    recommendations,
  };
}

async function llmAnalyzeAnthropic(text, apiKey, env) {
  const model = env.ANTHROPIC_MODEL || "claude-3-5-haiku-20241022";
  const prompt = `당신은 한국 영화/드라마 기획PD를 돕는 스토리 구조 분석가입니다. 아래 시나리오/시놉시스(또는 씬 단위 노트)를 3막 구조(설정-대립-해결) 기준으로 분석하세요.

반드시 아래 JSON 형식으로만 답하세요(코드블록 없이 순수 JSON):
{
  "act1": {"summary": "1막 요약", "issues": ["문제점1", ...]},
  "act2": {"summary": "2막 요약", "issues": ["문제점1", ...]},
  "act3": {"summary": "3막 요약", "issues": ["문제점1", ...]},
  "overallIssues": ["구조 전반의 문제점"],
  "recommendations": ["구체적인 수정 제안"]
}

텍스트:
"""${text}"""`;

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({ model, max_tokens: 1500, messages: [{ role: "user", content: prompt }] }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Anthropic API 오류 (${res.status}): ${body.slice(0, 300)}`);
  }
  const data = await res.json();
  const raw = data.content?.[0]?.text || "{}";
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  const parsed = JSON.parse(jsonMatch ? jsonMatch[0] : raw);
  return { engine: `anthropic:${model}`, ...parsed };
}

async function llmAnalyzeOpenAI(text, apiKey, env) {
  const model = env.OPENAI_MODEL || "gpt-4o-mini";
  const prompt = `당신은 한국 영화/드라마 기획PD를 돕는 스토리 구조 분석가입니다. 아래 시나리오/시놉시스(또는 씬 단위 노트)를 3막 구조(설정-대립-해결) 기준으로 분석하고, 반드시 JSON으로만 답하세요.

형식:
{"act1": {"summary": "", "issues": []}, "act2": {"summary": "", "issues": []}, "act3": {"summary": "", "issues": []}, "overallIssues": [], "recommendations": []}

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
    const body = await res.text();
    throw new Error(`OpenAI API 오류 (${res.status}): ${body.slice(0, 300)}`);
  }
  const data = await res.json();
  const parsed = JSON.parse(data.choices?.[0]?.message?.content || "{}");
  return { engine: `openai:${model}`, ...parsed };
}

export async function analyzeStructure(text, env) {
  const anthropicKey = env.ANTHROPIC_API_KEY;
  const openaiKey = env.OPENAI_API_KEY;

  if (anthropicKey) {
    try {
      return await llmAnalyzeAnthropic(text, anthropicKey, env);
    } catch (err) {
      return { ...heuristicAnalyze(text), engineError: String(err.message || err) };
    }
  }
  if (openaiKey) {
    try {
      return await llmAnalyzeOpenAI(text, openaiKey, env);
    } catch (err) {
      return { ...heuristicAnalyze(text), engineError: String(err.message || err) };
    }
  }
  return heuristicAnalyze(text);
}
