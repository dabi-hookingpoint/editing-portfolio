export async function transcribeWithDiarization(audioBuffer, contentType, env) {
  const apiKey = env.DEEPGRAM_API_KEY;
  if (!apiKey) {
    return {
      error:
        "DEEPGRAM_API_KEY가 설정되지 않아 자동 화자 구분을 사용할 수 없습니다. Cloudflare Pages 환경변수에 Deepgram API 키를 추가해주세요.",
    };
  }

  const dgRes = await fetch(
    "https://api.deepgram.com/v1/listen?model=nova-2&language=ko&smart_format=true&punctuate=true&diarize=true",
    {
      method: "POST",
      headers: {
        authorization: `Token ${apiKey}`,
        "content-type": contentType || "audio/webm",
      },
      body: audioBuffer,
    }
  );

  if (!dgRes.ok) {
    const errText = await dgRes.text();
    return { error: `Deepgram 요청 실패 (${dgRes.status}): ${errText}` };
  }

  const dgData = await dgRes.json();
  const words = dgData?.results?.channels?.[0]?.alternatives?.[0]?.words || [];

  const rawUtterances = [];
  let current = null;
  for (const w of words) {
    const speakerIndex = w.speaker ?? 0;
    const word = w.punctuated_word || w.word;
    if (!current || current.speakerIndex !== speakerIndex) {
      current = { speakerIndex, text: word };
      rawUtterances.push(current);
    } else {
      current.text += " " + word;
    }
  }

  const speakerLabels = {};
  let nextLabelCode = 65; // 'A'
  const utterances = rawUtterances.map((u) => {
    if (!(u.speakerIndex in speakerLabels)) {
      speakerLabels[u.speakerIndex] = String.fromCharCode(nextLabelCode++);
    }
    return { speaker: speakerLabels[u.speakerIndex], text: u.text };
  });

  return { utterances };
}
